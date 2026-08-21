/// Pure helpers for the Google mobile sign-in session contract.
library;

/// Validates a successful Google login JSON body.
///
/// Accepts flat `{ success, token, user }` or nested `{ data: { token, user } }`.
/// Throws [FormatException] when the payload is not a successful session.
Map<String, dynamic> normalizeGoogleLoginPayload(dynamic raw) {
  if (raw is! Map) {
    throw const FormatException('Google sign-in failed.');
  }
  final map = Map<String, dynamic>.from(raw);
  final successFlag = map['success'];
  if (successFlag == false) {
    final msg = map['message']?.toString();
    throw FormatException(
      (msg != null && msg.isNotEmpty) ? msg : 'Google sign-in failed.',
    );
  }

  Map<String, dynamic> session = map;
  final inner = map['data'];
  if (inner is Map &&
      (map['token'] == null || map['user'] == null) &&
      inner['token'] != null) {
    session = Map<String, dynamic>.from(inner);
  }

  final token = session['token']?.toString();
  if (token == null || token.isEmpty || session['user'] == null) {
    final msg = map['message']?.toString();
    throw FormatException(
      (msg != null && msg.isNotEmpty) ? msg : 'Google sign-in failed.',
    );
  }
  session['token'] = token;
  return session;
}

/// Prefer API message; fill in contract-aware fallbacks when empty/generic.
String googleSignInFailureMessage({
  required String? code,
  required String apiMessage,
  String fallback = 'Google sign-in failed.',
}) {
  final trimmed = apiMessage.trim();
  final hasUsefulMessage = trimmed.isNotEmpty &&
      trimmed != fallback &&
      trimmed.toLowerCase() != 'google login failed' &&
      trimmed.toLowerCase() != 'google sign-in failed.';

  if (hasUsefulMessage) return trimmed;

  switch (code) {
    case 'GOOGLE_TOKEN_AUDIENCE_INVALID':
      return 'Google sign-in is not configured for this app build. '
          'Please try again later or contact support.';
    case 'GOOGLE_IDENTITY_UNVERIFIED':
      return 'Please choose a verified Google account and try again.';
    case 'GOOGLE_ID_TOKEN_INVALID':
      return 'Google sign-in expired. Please try again.';
    case 'GOOGLE_LOGIN_TEMPORARILY_UNAVAILABLE':
      return 'Google sign-in is temporarily unavailable. Please try again.';
    default:
      return trimmed.isNotEmpty ? trimmed : fallback;
  }
}
