import 'dart:async';
import '../utils/haptics.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connection/server_connection.dart';
import '../connection/settings_store.dart';

class _AppInfo {
  final String id;
  final String name;

  _AppInfo(this.id, this.name);
}

/// Dock / Apps — PC ki installed apps: search, pinned, all apps grid.
class DockPage extends StatefulWidget {
  const DockPage({super.key});

  @override
  State<DockPage> createState() => _DockPageState();
}

class _DockPageState extends State<DockPage> with WidgetsBindingObserver {
  List<_AppInfo> _apps = [];
  bool _loading = true;
  bool _error = false;
  late final MousifyConnection _conn;
  late final VoidCallback _connListener;
  String _requestedFor = '';
  StreamSubscription? _sub;

  // Search related
  final _queryController = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  bool _isSearchFocused = false;
  // Keyboard pehle khula tha ya nahi — band hone par focus hatane
  // ke liye chahiye (neeche didChangeMetrics dekho).
  bool _wasKeyboardOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _conn = context.read<MousifyConnection>();
    _sub = _conn.events.listen(_onEvent);
    _connListener = () {
      if (_conn.isReady) _requestIfNeeded();
    };
    _conn.addListener(_connListener);
    _queryController.addListener(_onQueryChanged);
    _focusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestIfNeeded());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _conn.removeListener(_connListener);
    _queryController.removeListener(_onQueryChanged);
    _queryController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    // Keyboard ka asli haal — raw view insets se. Keyboard band hua
    // aur field abhi bhi focused hai (Android back par keyboard
    // band hota hai, focus rehta hai) to focus hata do, taaki bar
    // wapas apni jagah (112, nav ke upar) aa jaye aur pill bhi
    // chhota ho jaye. `_wasKeyboardOpen` guard is liye hai taaki
    // keyboard khulte waqt ki pehli 0-reading par focus na hate.
    final keyboardOpen =
        MediaQueryData.fromView(View.of(context)).viewInsets.bottom > 0;
    if (_wasKeyboardOpen && !keyboardOpen && _focusNode.hasFocus) {
      _focusNode.unfocus();
    }
    _wasKeyboardOpen = keyboardOpen;
    setState(() {});
  }

  void _onQueryChanged() {
    setState(() {
      _query = _queryController.text;
    });
  }

  void _onFocusChange() {
    setState(() {
      _isSearchFocused = _focusNode.hasFocus;
    });
  }

  void _onEvent(Map<String, dynamic> msg) {
    if (!mounted) return;
    if (msg['t'] != 'apps') return;
    final list = (msg['apps'] as List? ?? [])
        .map((a) => _AppInfo(a['id'] as String, a['name'] as String))
        .toList();
    setState(() {
      _apps = list;
      _loading = false;
      _error = false;
    });
    context.read<AppSettings>().setAppsCache(
          jsonEncode(list.map((a) => {'id': a.id, 'name': a.name}).toList()),
        );
  }

  void _requestIfNeeded() {
    if (!_conn.isReady) {
      final cached = _loadCache();
      setState(() {
        _apps = cached;
        _loading = false;
        _error = cached.isEmpty;
      });
      return;
    }
    if (_requestedFor == '${_conn.host}:${_conn.port}' && _apps.isNotEmpty) {
      return;
    }
    _requestedFor = '${_conn.host}:${_conn.port}';
    if (_apps.isEmpty) setState(() => _loading = true);
    _conn.send({'t': 'apps-list'});
  }

  List<_AppInfo> _loadCache() {
    final json = context.read<AppSettings>().appsCacheJson;
    if (json == null || json.isEmpty) return [];
    try {
      final list = (jsonDecode(json) as List)
          .map((e) => _AppInfo(e['id'] as String, e['name'] as String))
          .toList();
      _requestedFor = '${_conn.host}:${_conn.port}';
      return list;
    } catch (_) {
      return [];
    }
  }

  void _launch(_AppInfo app) {
    if (!_conn.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Connect to your PC in Settings first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Haptics.impact();
    late final StreamSubscription sub;
    sub = _conn.events.listen((msg) {
      if (msg['t'] == 'launched') {
        if (mounted) {
          final switched = msg['mode'] == 'focused';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                switched ? 'Switched to ${app.name} ✓' : 'Opening ${app.name}…',
              ),
              duration: const Duration(milliseconds: 1000),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        sub.cancel();
      }
    });
    _conn.send({'t': 'launch', 'id': app.id});
  }

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<MousifyConnection>();
    final settings = context.watch<AppSettings>();
    final scheme = Theme.of(context).colorScheme;

    final query = _query.toLowerCase();
    final filtered = query.isEmpty
        ? _apps
        : _apps.where((a) => a.name.toLowerCase().contains(query)).toList();
    final pinned = filtered
        .where((a) => settings.pinnedApps.contains(a.id))
        .toList();
    final rest = filtered
        .where((a) => !settings.pinnedApps.contains(a.id))
        .toList();

    // Keyboard ka asli haal — raw view insets se. MediaQuery.of ka
    // viewInsets yahan hamesha 0 hota hai (HomeShell ka outer
    // Scaffold apni body ke MediaQuery se bottom inset hata deta
    // hai), is liye us se nahi chalta. Focus se bhi nahi chalta:
    // Android back par keyboard band hota hai, focus rehta hai —
    // bar 16 par atka rehta tha aur nav ke peeche chala jata tha
    // (Zain ki screenshot wali shikayat). fromView wala inset
    // Scaffold se nahi kat-ta, is liye ye sahi signal hai.
    final keyboardOpen =
        MediaQueryData.fromView(View.of(context)).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: const Text(
          'Apps',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        actions: const [],
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildApps(context, conn, pinned, rest),
              ),
            ],
          ),
          // Floating search bar — keyboard band ho to floating nav
          // ke upar (bottom 112); keyboard khula ho to seedha
          // keyboard ke upar (bottom 16).
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            left: 16,
            right: 16,
            bottom: keyboardOpen ? 16 : 112,
            child: _BeautifulSearchBar(
              controller: _queryController,
              focusNode: _focusNode,
              isFocused: _isSearchFocused,
              onClear: () {
                _queryController.clear();
                _focusNode.unfocus();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApps(
    BuildContext context,
    MousifyConnection conn,
    List<_AppInfo> pinned,
    List<_AppInfo> rest,
  ) {
    final scheme = Theme.of(context).colorScheme;
    if (!conn.isReady && _apps.isEmpty) {
      return const _Message(
        icon: Icons.lan_outlined,
        title: 'Not connected',
        subtitle: 'Connect to your PC in Settings to load the dock',
      );
    }
    if (_loading && _apps.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
    }
    if (_error && _apps.isEmpty) {
      return _Message(
        icon: Icons.error_outline,
        title: "Couldn't load apps",
        subtitle: 'Server se connect karke dobara try karo',
        onRetry: _requestIfNeeded,
      );
    }
    if (_apps.isEmpty) {
      return _Message(
        icon: Icons.apps_rounded,
        title: 'No apps found',
        subtitle: 'Server did not report any applications',
        onRetry: _requestIfNeeded,
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        _conn.send({'t': 'apps-list'});
        await Future.delayed(const Duration(milliseconds: 400));
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120), // Floating nav ke liye jagah
        children: [
          if (pinned.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Text(
                'Pinned',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final app in pinned)
                    _AppTile(
                      app: app,
                      iconUrl: _iconUrl(app.id),
                      pinned: true,
                      onTap: () => _launch(app),
                      onLongPress: () =>
                          context.read<AppSettings>().togglePinnedApp(app.id),
                    ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Text(
              pinned.isEmpty ? 'All apps — long-press to pin' : 'All apps',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 8,
              childAspectRatio: 0.78,
            ),
            itemCount: rest.length,
            itemBuilder: (context, i) {
              final app = rest[i];
              return _AppTile(
                app: app,
                iconUrl: _iconUrl(app.id),
                pinned: false,
                onTap: () => _launch(app),
                onLongPress: () =>
                    context.read<AppSettings>().togglePinnedApp(app.id),
              );
            },
          ),
        ],
      ),
    );
  }

  String? _iconUrl(String id) {
    final host = _conn.host;
    if (host == null || host.isEmpty) return null;
    return 'http://$host:${_conn.port + 1}/icon/$id';
  }
}

class _AppTile extends StatelessWidget {
  final _AppInfo app;
  final String? iconUrl;
  final bool pinned;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AppTile({
    required this.app,
    required this.iconUrl,
    required this.pinned,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: scheme.surface,
                  border: Border.all(color: scheme.outline),
                ),
                child: iconUrl == null
                    ? Center(
                        child: Text(
                          app.name.isNotEmpty ? app.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.network(
                          iconUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Center(
                            child: Text(
                              app.name.isNotEmpty
                                  ? app.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                                  ? child
                                  : Center(
                                      child: SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                        ),
                      ),
              ),
              if (pinned)
                Positioned(
                  right: -2,
                  top: -2,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: scheme.primary,
                    child: Icon(
                      Icons.push_pin,
                      size: 9,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            app.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: scheme.onSurface),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  const _Message({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ]
          ],
        ),
      ));
  }
}

/// Beautiful floating search bar for Apps page — center me, bottom
/// navigation ke upar, khubsurat tareeke se.
///
/// - Centered pill (unfocused) — tap par smoothly full width ho jata hai.
/// - Focus par halka sa upar uthta hai aur shadow gehra hota hai.
/// - Keyboard khule to bottom nav chhup jata hai (HomeShell) aur bar
///   seedha keyboard ke upar aa jata hai (bottom 16) — nav beech me
///   nahi aata, bar keyboard se door nahi rehta.
/// - Hint "Search apps" — proper hint color (pehle red tha, wo bug tha).
class _BeautifulSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final VoidCallback onClear;

  const _BeautifulSearchBar({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.onClear,
  });

  @override
  State<_BeautifulSearchBar> createState() => _BeautifulSearchBarState();
}

class _BeautifulSearchBarState extends State<_BeautifulSearchBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _focusController;
  late final Animation<double> _expand;
  late final Animation<double> _lift;

  @override
  void initState() {
    super.initState();
    _focusController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    // Ek hi curve poori animation me — smooth, koi jhatka nahi.
    final curved = CurvedAnimation(
      parent: _focusController,
      curve: Curves.easeInOutCubic,
    );
    // Focus par bar chauda ho (centered pill se full width tak).
    _expand = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    // Focus par halka sa upar uthe — zyada nahi, bas float jaisa.
    _lift = Tween<double>(begin: 0.0, end: -6.0).animate(curved);
    if (widget.isFocused) _focusController.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant _BeautifulSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFocused != oldWidget.isFocused) {
      if (widget.isFocused) {
        _focusController.forward();
      } else {
        _focusController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasText = widget.controller.text.isNotEmpty;
    final screenW = MediaQuery.of(context).size.width;
    // Centered pill (unfocused) se full width (focused) tak.
    final narrowW = (screenW - 140).clamp(0.0, 280.0);
    final wideW = screenW - 32;

    return AnimatedBuilder(
      animation: _focusController,
      builder: (context, child) {
        final w = narrowW + (wideW - narrowW) * _expand.value;
        return Transform.translate(
          offset: Offset(0, _lift.value),
          child: Center(
            child: Container(
              width: w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                // Flat matte — koi shadow nahi, koi border nahi.
                color:
                    scheme.surfaceContainerHighest.withValues(alpha: 0.92),
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search apps',
                  hintStyle: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 10),
                    child: Icon(
                      Icons.search_rounded,
                      size: 22,
                      color: widget.isFocused
                          ? scheme.primary
                          : scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  suffixIcon: hasText
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: scheme.onSurfaceVariant,
                          ),
                          onPressed: widget.onClear,
                        )
                      : null,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 14,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                ),
                cursorColor: scheme.primary,
                cursorWidth: 2,
              ),
            ),
          ),
        );
      },
    );
  }
}