import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';

/// Who decides when a customer is signed out.
///
/// The app used to answer "me, after 24 hours", three times over, in three
/// copies of the same defaulted expression. Nothing on the server asks for
/// that: Sanctum runs with `'expiration' => null`, the sign-in response
/// carries no `expires_in` and no refresh token, and `/api/auth/refresh` does
/// not exist. So the invented clock was the only thing ending a session, and
/// when it fired the customer went back to the code screen — an SMS and a paid
/// Telegram Gateway message to re-establish a session that was never invalid.
void main() {
  final now = DateTime.utc(2026, 11, 13, 21, 0);

  group('sessionExpiryFrom', () {
    test('no server expiry means the session does not expire on its own', () {
      // The case that costs money. If this ever returns a DateTime again,
      // every customer pays for a new code on that cadence.
      expect(sessionExpiryFrom(null, now: now), isNull);
    });

    test('a server expiry is honoured exactly', () {
      expect(
        sessionExpiryFrom(3600, now: now),
        DateTime.utc(2026, 11, 13, 22, 0),
      );
    });

    test('zero and negative lifetimes are not an instant sign-out', () {
      // No server means "already expired"; reading it that way would log the
      // customer out in the same breath as signing them in.
      expect(sessionExpiryFrom(0, now: now), isNull);
      expect(sessionExpiryFrom(-60, now: now), isNull);
    });

    test('a short lifetime is still respected', () {
      // Not every expiry is a mistake: if the server ever starts sending one,
      // the app must follow it rather than second-guessing.
      expect(
        sessionExpiryFrom(300, now: now),
        DateTime.utc(2026, 11, 13, 21, 5),
      );
    });
  });
}
