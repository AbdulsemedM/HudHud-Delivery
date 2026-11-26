/// Putting a ringing call on the screen.
///
/// Kept apart from the router so the router has no opinion about WebRTC, and
/// so the parsing in incoming_call_router.dart stays testable without any of
/// this.
library;

import 'package:flutter/material.dart';

import 'call_controller.dart';
import 'call_screen.dart';
import 'incoming_call_router.dart';

/// The call currently on screen, if any.
///
/// A single slot, not a stack. A second ring while one call is up must not
/// stack two full-screen call UIs over each other — the server refuses a
/// second call with CALLEE_BUSY anyway, so anything that gets here is a
/// duplicate push for the call already showing.
CallController? _current;
String? _currentUid;

bool get isCallOnScreen => _current != null;

/// Show an incoming call, or apply a late lifecycle push to the one showing.
Future<void> presentIncomingCall(BuildContext context, IncomingCallPush push) async {
  if (!push.isRing) {
    // accepted / rejected / ended arrive by push too. The poller is the
    // authority on those; there is nothing to open.
    return;
  }

  // The same ring delivered twice — foreground message and notification tap,
  // which is ordinary — must not open a second screen.
  if (_currentUid == push.callUid) return;
  if (_current != null) return;

  final controller = CallController();
  _current = controller;
  _currentUid = push.callUid;

  await controller.receiveCall(push.callUid, callerName: push.callerName);

  if (!context.mounted) {
    _release(controller);
    return;
  }

  await Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (ctx) => CallScreen(
        controller: controller,
        onClosed: () {
          if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
        },
      ),
    ),
  );

  _release(controller);
}

/// Place a call from a screen that knows who to ring.
Future<CallController?> startOutgoingCall(
  BuildContext context, {
  required int calleeId,
  String? displayName,
}) async {
  if (_current != null) return null;

  final controller = CallController();
  _current = controller;

  final started = await controller.placeCall(calleeId, displayName: displayName);
  _currentUid = controller.callUid;

  if (!context.mounted) {
    _release(controller);
    return null;
  }

  // Shown even when it did not start: the reason the server refused — no
  // active delivery, they are on another call — belongs in front of the
  // user, not swallowed.
  await Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (ctx) => CallScreen(
        controller: controller,
        onClosed: () {
          if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
        },
      ),
    ),
  );

  _release(controller);
  return started ? controller : null;
}

void _release(CallController controller) {
  if (identical(_current, controller)) {
    _current = null;
    _currentUid = null;
  }
  controller.dispose();
}
