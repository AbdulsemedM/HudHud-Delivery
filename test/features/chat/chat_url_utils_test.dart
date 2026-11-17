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

    test('normalize fixes a duplicated host that is not the configured one', () {
      // The case that actually occurs in production: rows written before the
      // API moved off api.hudhuddelivery.com. The old implementation deduped
      // only the host in BASE_URL, so these passed through untouched.
      const broken =
          'https://deliveryapi.hudhudexpress.comhttps://deliveryapi.hudhudexpress.com/storage/b.png';
      expect(
        ChatUrlUtils.normalize(broken),
        'https://deliveryapi.hudhudexpress.com/storage/b.png',
      );
    });

    test('normalize leaves a clean absolute URL alone', () {
      const clean = 'https://api.hudhuddelivery.com/storage/foo.png';
      expect(ChatUrlUtils.normalize(clean), clean);
    });

    test('normalize does not mangle a nested URL in a query string', () {
      // Guards the de-duplication regex: the first group excludes `/?#`, so it
      // can only match a bare origin. A path before the second scheme means no
      // match, which is what keeps a redirect parameter intact.
      const redirect =
          'https://api.hudhuddelivery.com/go?to=https://other.example/x';
      expect(ChatUrlUtils.normalize(redirect), redirect);
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
