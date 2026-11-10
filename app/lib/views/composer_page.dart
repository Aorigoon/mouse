import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../connection/live_typing.dart';
import '../connection/server_connection.dart';
import '../theme.dart';

/// Composer — ek seedha notepad page: jo likho/dictate karo wo real-time
/// PC ke focused window me type hota hai (add + delete dono). Bas.
///
/// Voice typing bhi hai: neeche wala bada oval button par tap karo, bolo,
/// aur alfaz khud type hote jayenge (Google ki speech recognition — Android
/// par system wali, bilkul free, koi API key ya limit nahi). Oval ke
/// center me hamara custom mic icon hai (capsule, neeche koi dandi nahi),
/// uske neeche "Tap to speak" likha hai. Chip hamesha neeche rehti hai —
/// keyboard band ho to bottom (tab bar) ke upar, keyboard khule to uske
/// upar.
///
/// Pura page gray hai (koi alag box nahi). Upar do dark chips hain:
/// left me back button ki chip, right me horizontal three dots ki chip.
/// "Typing" text nahi hai.
class ComposerPage extends StatefulWidget {
  const ComposerPage({super.key});

  @override
  State<ComposerPage> createState() => _ComposerPageState();
}

class _ComposerPageState extends State<ComposerPage> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _speech = SpeechToText();
  String _lastSent = '';
  bool _isListening = false;
  // Is utterance se pehle ka text — pehchan ke alfaz isi ke aage judte hain.
  String _dictationBase = '';
  // Watchdog: recognizer khud ruk jaye (khamoshi/timeout) to UI wapas idle.
  Timer? _listenWatchdog;
  bool _speechStarted = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _focus.addListener(_onFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _listenWatchdog?.cancel();
    // Page band ho to sunna bhi band karo.
    if (_isListening) {
      _speech.stop();
    }
    _controller.removeListener(_onChanged);
    _focus.removeListener(_onFocusChanged);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    final conn = context.read<MousifyConnection>();
    if (!conn.isReady) return;
    final delta = computeTextDelta(_lastSent, _controller.text);
    _lastSent = _controller.text;
    if (delta.deleteCount == 0 && delta.insert.isEmpty) return;
    if (delta.deleteCount > 0) conn.backspace(delta.deleteCount);
    if (delta.insert.isEmpty) return;
    conn.send({'t': 'text', 's': delta.insert});
  }

  /// User ne field par tap kiya (keyboard se type karega) — voice band karo.
  void _onFocusChanged() {
    if (_focus.hasFocus && _isListening) {
      _speech.stop();
      _stopListeningState();
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 2000),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Mic chip par tap — sunna shuru ya band karo.
  Future<void> _toggleListening() async {
    HapticFeedback.selectionClick();
    if (_isListening) {
      await _speech.stop();
      _stopListeningState();
      return;
    }
    // Voice mode me keyboard nahi chahiye — band karo.
    _focus.unfocus();
    bool available = false;
    try {
      // finalTimeout 50ms — is se kam par plugin stop ke baad apna
      // fallback Timer nahi banata (test me pending Timer reh jata hai,
      // aur real phone par final result waise bhi platform se aata hai).
      available = await _speech.initialize(
        finalTimeout: const Duration(milliseconds: 50),
      );
    } catch (_) {
      available = false;
    }
    if (!mounted) return;
    if (!available) {
      _showSnack('Speech recognition not available');
      return;
    }
    _dictationBase = _controller.text;
    try {
      await _speech.listen(
        // `result` ka type SpeechResultListener se infer hota hai —
        // SpeechRecognitionResult main library se export nahi hota.
        onResult: (result) => _applySpeechResult(
          result.recognizedWords,
          result.finalResult,
        ),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
          pauseFor: const Duration(seconds: 5),
          listenFor: const Duration(seconds: 60),
          cancelOnError: true,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not start listening');
      return;
    }
    if (!mounted) return;
    setState(() {
      _isListening = true;
      _speechStarted = false;
    });
    _listenWatchdog?.cancel();
    _listenWatchdog = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      if (_speech.isListening) {
        _speechStarted = true;
        return;
      }
      if (_speechStarted) {
        _stopListeningState();
      }
    });
  }

  void _stopListeningState() {
    _listenWatchdog?.cancel();
    _listenWatchdog = null;
    if (!mounted) return;
    setState(() {
      _isListening = false;
      _dictationBase = _controller.text;
    });
  }

  /// Pehchane hue alfaz field me daalo — _onChanged inhe PC par bhej dega.
  void _applySpeechResult(String words, bool isFinal) {
    if (!mounted) return;
    final base = _dictationBase;
    final text =
        words.isEmpty ? base : (base.isEmpty ? words : '$base $words');
    if (text == _controller.text) {
      if (isFinal) _dictationBase = text;
      return;
    }
    _controller.text = text;
    if (isFinal) {
      _dictationBase = text;
    }
  }

  void _clear() {
    final conn = context.read<MousifyConnection>();
    final text = _controller.text;
    if (text.isNotEmpty) {
      conn.backspace(text.length);
    }
    _controller.clear();
  }

  /// Poora text phone ke clipboard mein copy kare.
  Future<void> _copyAll() async {
    final text = _controller.text;
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Re-type: poora text dobara PC par bhejta hai (desktop focus ke liye).
  void _reType() {
    final conn = context.read<MousifyConnection>();
    if (!conn.isReady) return;
    final text = _controller.text;
    if (text.isEmpty) return;
    // Sab kuch delete karke dobara type karein
    conn.backspace(text.length);
    conn.send({'t': 'text', 's': text});
  }

  /// Vertical three-dot par tap — Clear / Copy / Re-type wali bottom sheet.
  void _showActionsSheet() {
    final hasText = _controller.text.isNotEmpty;
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _ComposerActionsSheet(
        hasText: hasText,
        onClear: () {
          Navigator.of(sheetCtx).pop();
          _clear();
        },
        onCopy: () {
          Navigator.of(sheetCtx).pop();
          _copyAll();
        },
        onReType: () {
          Navigator.of(sheetCtx).pop();
          _reType();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      // Pura page gray hai — koi alag box nahi, koi white kinare nahi.
      backgroundColor: scheme.surfaceContainerHighest,
      body: Stack(
        children: [
          Column(
            children: [
              SafeArea(
                top: true,
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button — left side wali chip.
                      _HeaderChip(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop();
                        },
                        child: CustomPaint(
                          size: const Size(30, 24),
                          painter: _BackArrowPainter(Colors.white),
                        ),
                      ),
                      // Three dots (horizontal) — right side wali chip.
                      _HeaderChip(
                        onTap: _showActionsSheet,
                        child: const Icon(
                          Icons.more_horiz,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 17,
                    height: 1.7,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Start writing…',
                    hintStyle: TextStyle(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                      fontSize: 17,
                      height: 1.7,
                    ),
                    // Neeche 160px — bade oval button ke liye jagah,
                    // taaki aakhri line oval ke neeche na chhupe.
                    contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 160),
                    // Theme ka focused/enabled border bhi none.
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          // Voice mic chip — hamesha neeche: keyboard band ho to bottom
          // (tab bar) ke upar, keyboard khule to uske upar (overlay).
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _VoiceMicChip(
                isListening: _isListening,
                onTap: _toggleListening,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Voice typing button — bada horizontal oval (gol, lamba), dark.
/// Center me hamara custom mic icon (capsule, neeche koi dandi nahi),
/// uske neeche "Tap to speak" / "Listening…" likha hai. Sunte waqt
/// mic laal + sound bars. Animation sirf button par hai, background
/// me koi rings ya color nahi.
class _VoiceMicChip extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;

  const _VoiceMicChip({required this.isListening, required this.onTap});

  @override
  State<_VoiceMicChip> createState() => _VoiceMicChipState();
}

class _VoiceMicChipState extends State<_VoiceMicChip>
    with TickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isListening) {
      _waveController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _VoiceMicChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _waveController.repeat();
    } else if (!widget.isListening && oldWidget.isListening) {
      _waveController.stop();
      _waveController.reset();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final micColor = widget.isListening
        ? const Color(0xFFFF453A)
        : Colors.white;
    return Material(
      color: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(67),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(67),
        ),
        child: SizedBox(
          width: 250,
          height: 134,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomPaint(
                  size: const Size(44, 56),
                  painter: _CustomMicPainter(micColor),
                ),
                const SizedBox(height: 10),
                if (widget.isListening)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SoundBars(controller: _waveController),
                      const SizedBox(width: 10),
                      const Text(
                        'Listening…',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                else
                  const Text(
                    'Tap to speak',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom mic icon — sirf capsule (mic ka gol sir) + uske niche ek
/// rounded line (U jaisi curve, back button wali gol line jaisi).
/// Capsule patla hai (horizontally kam chauda) aur chhota hai;
/// capsule aur U ke beech gap bahut kam hai. Capsule ke andar
/// koi lines nahi, aur neeche koi dandi/stem nahi.
class _CustomMicPainter extends CustomPainter {
  final Color color;

  const _CustomMicPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // Capsule — mic ka body (plain, andar koi line nahi).
    final body = Paint()..color = color;
    final capsule = RRect.fromRectAndRadius(
      const Rect.fromLTWH(11, 0, 22, 40),
      const Radius.circular(11),
    );
    canvas.drawRRect(capsule, body);
    // Rounded line — capsule ke niche U jaisi curve (back button
    // jaisi gol line), stroke, round caps. Gap capsule se sirf 3px.
    // U horizontally chaudi hai (capsule se 12 zyada).
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: const Offset(22, 43),
        width: 34,
        height: 16,
      ),
      0,
      math.pi,
      false,
      line,
    );
  }

  @override
  bool shouldRepaint(covariant _CustomMicPainter old) => old.color != color;
}

/// Chhoti sound bars — sunte waqt upar-neeche hoti hain.
class _SoundBars extends StatelessWidget {
  final AnimationController controller;

  const _SoundBars({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(5, (i) {
            final phase = i * 0.7;
            final h = 6 +
                11 *
                    (0.5 +
                        0.5 *
                            math.sin(
                              controller.value * 2 * math.pi + phase,
                            ));
            return Container(
              width: 3,
              height: h,
              margin: EdgeInsets.only(right: i == 4 ? 0 : 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Header ka button — poora gol (circle, 48×48), dark (#1C1C1E,
/// voice chip jaisa), safed content. Back button (left) aur
/// horizontal three dots (right) dono isi gol button me hain.
class _HeaderChip extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _HeaderChip({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1C1C1E),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Arrow paint karta hai — "(" curve (tip) + piche choti horizontal line.
class _BackArrowPainter extends CustomPainter {
  final Color color;

  _BackArrowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    // Arrow ko thoda aage (left) karo — pehle glyph circle ke center se
    // ~3.5px right (peeche) tha; 5px left shift se front aage aa jata hai.
    canvas.translate(-5, 0);
    // "(" curve — arrow ka tip, pehle jitna hi rounded aur utna hi size.
    // (Fixed coordinates taaki canvas chauda karne se curve na badhe.)
    final head = Path()
      ..moveTo(16.9, 2)
      ..quadraticBezierTo(1.04, size.height / 2, 16.9, size.height - 2);
    canvas.drawPath(head, paint);
    // Piche choti si line — arrow ki shaft, tip se right ki taraf.
    // Tip curve ka leftmost point hai (~8.97).
    canvas.drawLine(
      Offset(8.97, size.height / 2),
      Offset(size.width - 2, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BackArrowPainter old) => old.color != color;
}

/// Clear / Copy / Re-type wali bottom sheet — Settings sheet jaisi dark,
/// flat matte, koi border nahi.
class _ComposerActionsSheet extends StatelessWidget {
  final bool hasText;
  final VoidCallback onClear;
  final VoidCallback onCopy;
  final VoidCallback onReType;

  const _ComposerActionsSheet({
    required this.hasText,
    required this.onClear,
    required this.onCopy,
    required this.onReType,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceGray,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SheetActionRow(
                        icon: Icons.delete_outline,
                        label: 'Clear',
                        color: const Color(0xFFFF453A),
                        enabled: hasText,
                        onTap: onClear,
                      ),
                      _sheetDivider(),
                      _SheetActionRow(
                        icon: Icons.content_copy_outlined,
                        label: 'Copy',
                        color: Colors.white,
                        enabled: hasText,
                        onTap: onCopy,
                      ),
                      _sheetDivider(),
                      _SheetActionRow(
                        icon: Icons.replay_outlined,
                        label: 'Re-type',
                        color: Colors.white,
                        enabled: hasText,
                        onTap: onReType,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetDivider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.white.withValues(alpha: 0.08),
      );
}

/// Bottom sheet ki ek row — icon + label. Text khaali ho to halki
/// (disabled) aur tap nahi hoti.
class _SheetActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _SheetActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = enabled ? color : color.withValues(alpha: 0.35);
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: c),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
