import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/chat/utils/chat_url_utils.dart';

void main() {
  group('ChatUrlUtils', () {
    test('normalize fixes duplicated host', () {
      const broken =
          'https://api.hudhuddelivery.comhttps://api.hudhuddelivery.com/storage/foo.png';
      final fixed = ChatUrlUtils.normalize(broken);
      expect(fixed, 'https://api.hudhuddelivery.com/storage/foo.png');
    });

    test('resolveAttachmentUrl prefers url field', () {
      final resolved = ChatUrlUtils.resolveAttachmentUrl(
        url: 'https://api.hudhuddelivery.com/storage/a.png',
        fullPath: null,
        filePath: null,
      );
      expect(resolved, contains('storage/a.png'));
    });
  });
}
