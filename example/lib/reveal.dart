import 'dart:async';

import 'package:flutter/widgets.dart';

typedef RevealBuilder = Widget Function(BuildContext context, bool revealed, int secondsLeft);

/// Tap to unlock, tap again to hide. Hides by itself after [visibleFor],
/// when the app goes to the background, and when the widget leaves the tree.
class SecureReveal extends StatefulWidget {
  const SecureReveal({
    super.key,
    required this.unlock,
    required this.builder,
    this.visibleFor = const Duration(seconds: 10),
  });

  /// Return true once the user has proved it's them (Face ID, PIN, ...).
  final Future<bool> Function() unlock;
  final RevealBuilder builder;
  final Duration visibleFor;

  @override
  State<SecureReveal> createState() => _SecureRevealState();
}

class _SecureRevealState extends State<SecureReveal> {
  late final AppLifecycleListener _lifecycle;
  Timer? _timer;
  int _secondsLeft = 0;
  bool _busy = false;

  bool get _revealed => _secondsLeft > 0;

  @override
  void initState() {
    super.initState();
    // onHide, not onInactive: the Face ID sheet makes the app inactive too,
    // and hiding there would undo the unlock the user is in the middle of.
    _lifecycle = AppLifecycleListener(onHide: _hide);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_revealed) return _hide();
    if (_busy) return;
    _busy = true;
    final ok = await widget.unlock();
    _busy = false;
    if (!ok || !mounted) return;
    setState(() => _secondsLeft = widget.visibleFor.inSeconds);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 1) return _hide();
      setState(() => _secondsLeft--);
    });
  }

  void _hide() {
    _timer?.cancel();
    if (_revealed && mounted) setState(() => _secondsLeft = 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: widget.builder(context, _revealed, _secondsLeft),
    );
  }
}

/// Shows the secret only while a finger is down. Lifting, sliding off into a
/// scroll, or a system gesture taking over all hide it again.
class HoldToReveal extends StatefulWidget {
  const HoldToReveal({super.key, required this.builder});

  final Widget Function(BuildContext context, bool held) builder;

  @override
  State<HoldToReveal> createState() => _HoldToRevealState();
}

class _HoldToRevealState extends State<HoldToReveal> {
  bool _held = false;

  void _set(bool held) {
    if (held != _held) setState(() => _held = held);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: widget.builder(context, _held),
    );
  }
}
