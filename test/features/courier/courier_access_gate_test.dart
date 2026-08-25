import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/courier/utils/courier_access_gate.dart';
import 'package:hudhud_delivery/models/user_model.dart';

UserModel _user({DateTime? phoneVerifiedAt}) {
  return UserModel(
    id: 1,
    name: 'Test User',
    email: 'test@example.com',
    phone: '251912345678',
    phoneVerifiedAt: phoneVerifiedAt,
  );
}

void main() {
  group('canSendCourierPackage', () {
    test('returns false when user is null', () {
      expect(
        canSendCourierPackage(user: null),
        isFalse,
      );
    });

    test('returns false when phone is not verified', () {
      expect(
        canSendCourierPackage(user: _user()),
        isFalse,
      );
    });

    test('returns true when signed in and phone verified', () {
      expect(
        canSendCourierPackage(
          user: _user(phoneVerifiedAt: DateTime(2026, 1, 1)),
        ),
        isTrue,
      );
    });
  });
}
