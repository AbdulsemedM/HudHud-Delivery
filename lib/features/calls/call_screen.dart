/// The call screen: a name, a state, and three buttons.
///
/// It shows [CallState.connecting] as "Connecting…" and not "Connected",
/// because telling someone they are connected before audio is flowing is the
/// lie that makes people say "hello?" into silence.
library;

import 'package:flutter/material.dart';

import 'call_controller.dart';
import 'call_session.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
    required this.controller,
    this.onClosed,
  });

  final CallController controller;
  final VoidCallback? onClosed;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {});
    if (widget.controller.state == CallState.ended ||
        widget.controller.failure != null) {
      // A beat so the user reads why, rather than the screen vanishing.
      Future<void>.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) widget.onClosed?.call();
      });
    }
  }

  String get _status {
    final c = widget.controller;
    if (c.failure != null) return c.failureMessage ?? 'Call failed';
    switch (c.state) {
      case CallState.idle:
        return '';
      case CallState.dialling:
        return 'Calling…';
      case CallState.ringing:
        return 'Incoming call';
      case CallState.connecting:
        return 'Connecting…';
      case CallState.active:
        return _formatted(c.elapsed);
      case CallState.ended:
        return _endedLabel(c.endReason);
    }
  }

  static String _endedLabel(CallEndReason? reason) {
    switch (reason) {
      case CallEndReason.declined:
        return 'Call declined';
      case CallEndReason.missed:
        return 'No answer';
      case CallEndReason.busy:
        return 'They are on another call';
      case CallEndReason.failed:
        return 'Call failed';
      case CallEndReason.cancelled:
        return 'Call cancelled';
      case CallEndReason.hungUp:
      case null:
        return 'Call ended';
    }
  }

  static String _formatted(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final ringing = c.state == CallState.ringing;
    final over = c.state == CallState.ended || c.failure != null;

    return Scaffold(
      backgroundColor: const Color(0xFF101828),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const Spacer(),
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white24,
                child: Text(
                  (c.peerName?.trim().isNotEmpty ?? false)
                      ? c.peerName!.trim()[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontSize: 36, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                c.peerName ?? 'HudHud',
                style: const TextStyle(
                  fontSize: 24, color: Colors.white, fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _status,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),

              // Said before the call, not discovered during it. Without a
              // relay a call connects on wifi and fails on mobile data, and
              // the user is owed the warning rather than the silence.
              if (!c.turnAvailable && !over) ...[
                const SizedBox(height: 12),
                const Text(
                  'Call quality may be poor on mobile data.',
                  style: TextStyle(fontSize: 13, color: Color(0xFFFBBF24)),
                  textAlign: TextAlign.center,
                ),
              ],

              const Spacer(),

              if (c.state == CallState.active || c.state == CallState.connecting)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Round(
                      icon: c.muted ? Icons.mic_off : Icons.mic,
                      label: c.muted ? 'Unmute' : 'Mute',
                      onTap: c.toggleMute,
                    ),
                    const SizedBox(width: 24),
                    _Round(
                      icon: c.speakerOn ? Icons.volume_up : Icons.hearing,
                      label: 'Speaker',
                      onTap: c.toggleSpeaker,
                    ),
                  ],
                ),

              const SizedBox(height: 28),

              if (!over)
                Row(
                  mainAxisAlignment: ringing
                      ? MainAxisAlignment.spaceEvenly
                      : MainAxisAlignment.center,
                  children: [
                    _Round(
                      icon: Icons.call_end,
                      label: ringing ? 'Decline' : 'End',
                      color: const Color(0xFFDC2626),
                      large: true,
                      onTap: ringing ? c.decline : c.hangUp,
                    ),
                    if (ringing)
                      _Round(
                        icon: Icons.call,
                        label: 'Answer',
                        color: const Color(0xFF16A34A),
                        large: true,
                        onTap: c.answer,
                      ),
                  ],
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Round extends StatelessWidget {
  const _Round({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white24,
    this.large = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 72.0 : 56.0;
    return Semantics(
      button: true,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: color,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: size,
                height: size,
                child: Icon(icon, color: Colors.white, size: large ? 32 : 24),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
