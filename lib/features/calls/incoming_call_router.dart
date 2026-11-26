/// Turning a push into a ringing phone.
///
/// A websocket cannot do this. iOS and Android drop the socket when the app
/// is not in front, which is exactly when a call arrives — so the server
/// sends `incoming` as a high-priority FCM DATA message and this decides what
/// to do with it.
///
/// The parsing is separated from the showing so it can be tested without a
/// Firebase instance or a navigator, which is where the mistakes are: a
/// payload read wrong means a phone that does not ring and no error anywhere.
library;

/// What a call push is asking for.
class IncomingCallPush {
  const IncomingCallPush({
    required this.callUid,
    required this.signal,
    this.callerName,
    this.callerId,
  });

  final String callUid;

  /// incoming | accepted | rejected | ended | busy
  final String signal;

  /// Shown on the ring. For support calls the server sends the company
  /// name, never the agent's.
  final String? callerName;
  final int? callerId;

  bool get isRing => signal == 'incoming';

  /// Reads a call push out of an FCM data payload.
  ///
  /// FCM data values are STRINGS, always — a numeric id arrives as "41", not
  /// 41, and reading it as an int gives null on every real push while
  /// working perfectly in a test that passes an int. Both are accepted here
  /// for that reason.
  ///
  /// Returns null for anything that is not a call push, so this can be
  /// handed every message the app receives.
  static IncomingCallPush? fromData(Map<String, dynamic>? data) {
    if (data == null) return null;
    if (data['kind'] != 'call_signal') return null;

    final uid = data['call_uid'];
    if (uid is! String || uid.isEmpty) return null;

    final signal = data['signal'];
    if (signal is! String || signal.isEmpty) return null;

    final name = data['caller_name'];
    final rawId = data['caller_id'];

    return IncomingCallPush(
      callUid: uid,
      signal: signal,
      callerName: (name is String && name.trim().isNotEmpty) ? name.trim() : null,
      callerId: rawId is int ? rawId : int.tryParse('${rawId ?? ''}'),
    );
  }
}
