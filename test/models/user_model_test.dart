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
}
