import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _DockPageState extends State<DockPage> {
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

  @override
  void initState() {
    super.initState();
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
    _sub?.cancel();
    _conn.removeListener(_connListener);
    _queryController.removeListener(_onQueryChanged);
    _queryController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
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
    HapticFeedback.mediumImpact();
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
          // Floating search bar — floating nav se upar
          Positioned(
            left: 16,
            right: 16,
            bottom: 112, // Floating nav ke upar
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

/// Beautiful floating search bar for Apps page.
/// - Red "search bar" text
/// - No yellow underline
/// - Floats up slightly above keyboard when focused
/// - Transparent sides, compact, not attached to nav bar
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
  late final AnimationController _animationController;
  late final Animation<double> _translateAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _shadowAnimation;
  late final Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _translateAnimation = Tween<double>(
      begin: 0,
      end: -80, // Float up slightly above keyboard (not too far)
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _shadowAnimation = Tween<double>(
      begin: 0.08,
      end: 0.25,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _widthAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96, // Slightly narrower when floating
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(covariant _BeautifulSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFocused != oldWidget.isFocused) {
      if (widget.isFocused) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasText = widget.controller.text.isNotEmpty;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _translateAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: double.infinity,
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.92 * _widthAnimation.value,
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    // Semi-transparent background - sides will show through
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.85),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: _shadowAnimation.value),
                        blurRadius: 24,
                        offset: const Offset(0, -8),
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(
                      color: widget.isFocused
                          ? scheme.primary.withValues(alpha: 0.6)
                          : scheme.outline.withValues(alpha: 0.2),
                      width: widget.isFocused ? 1.5 : 1,
                    ),
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
                      hintText: 'search bar',
                      hintStyle: TextStyle(
                        color: Colors.red, // Red color for "search bar" text
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
            ),
          ),
        );
      },
    );
  }
}