import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/models/user_model.dart';

void main() {
  group('UserModel.userMapFromApiEnvelope', () {
    test('parses update-profile response shape', () {
      final map = UserModel.userMapFromApiEnvelope({
        'success': true,
        'message': 'Profile updated successfully.',
        'data': {
          'id': 40,
          'name': 'Abdusemed Mj',
          'email': 'sendabdu22@gmail.com',
          'phone': '251946514836',
        },
        'avatar_url':
            'https://api.hudhuddelivery.com/storage/42/scaled_avatar.jpg',
        'avatar_thumb_url':
            'https://api.hudhuddelivery.com/storage/42/conversions/thumb.jpg',
      });

      expect(map, isNotNull);
      expect(map!['name'], 'Abdusemed Mj');
      expect(map['avatar_url'], contains('scaled_avatar'));
      expect(map['avatar_thumb_url'], contains('thumb'));
    });

    test('parses legacy user key', () {
      final map = UserModel.userMapFromApiEnvelope({
        'success': true,
        'user': {'id': 1, 'name': 'Test'},
      });

      expect(map?['name'], 'Test');
    });
  });

  group('UserModel.fromMap avatar', () {
    test('uses avatar_thumb_url when avatar_url missing', () {
      final user = UserModel.fromMap({
        'id': 1,
        'avatar_thumb_url': 'https://example.com/thumb.jpg',
      });

      expect(user.avatarUrl, 'https://example.com/thumb.jpg');
    });
  });

  group('UserModel.marketingConsent', () {
    test('defaults to false when omitted', () {
      final user = UserModel.fromMap({'id': 1});
      expect(user.marketingConsent, isFalse);
    });

    test('treats null, 0, and false as not consented', () {
      expect(
        UserModel.fromMap({'marketing_consent': null}).marketingConsent,
        isFalse,
      );
      expect(
        UserModel.fromMap({'marketing_consent': 0}).marketingConsent,
        isFalse,
      );
      expect(
        UserModel.fromMap({'marketing_consent': false}).marketingConsent,
        isFalse,
      );
      expect(
        UserModel.fromMap({'marketing_consent': 'false'}).marketingConsent,
        isFalse,
      );
    });

    test('opts in only for explicit true values', () {
      expect(
        UserModel.fromMap({'marketing_consent': true}).marketingConsent,
        isTrue,
      );
      expect(
        UserModel.fromMap({'marketing_consent': 1}).marketingConsent,
        isTrue,
      );
      expect(
        UserModel.fromMap({'marketing_consent': 'true'}).marketingConsent,
        isTrue,
      );
    });

    test('reads nested settings.marketing_consent', () {
      final user = UserModel.fromMap({
        'id': 2,
        'settings': {'marketing_consent': true},
      });
      expect(user.marketingConsent, isTrue);
    });

    test('copies envelope-level marketing_consent onto user map', () {
      final map = UserModel.userMapFromApiEnvelope({
        'success': true,
        'data': {'id': 3, 'name': 'A'},
        'marketing_consent': true,
      });
      expect(map, isNotNull);
      expect(UserModel.fromMap(map!).marketingConsent, isTrue);
    });

    test('round-trips through toMap', () {
      final user = UserModel(id: 4, marketingConsent: true);
      expect(UserModel.fromMap(user.toMap()).marketingConsent, isTrue);
    });
  });
}
