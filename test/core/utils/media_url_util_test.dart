import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/utils/media_url_util.dart';

void main() {
  test('prefers logo_urls.original over broken conversion logo_path', () {
    final url = resolveVendorMediaUrl(
      path:
          'https://api.hudhuddelivery.com/storage/38/conversions/download-medium.jpg',
      urls: {
        'original':
            'https://api.hudhuddelivery.com/storage/38/download.jpeg',
        'medium':
            'https://api.hudhuddelivery.com/storage/38/conversions/download-medium.jpg',
      },
    );
    expect(url, 'https://api.hudhuddelivery.com/storage/38/download.jpeg');
  });

  test('derives original candidates from conversion logo_path', () {
    final candidates = vendorMediaUrlCandidates(
      path:
          'https://api.hudhuddelivery.com/storage/38/conversions/download-medium.jpg',
    );
    expect(
      candidates.first,
      'https://api.hudhuddelivery.com/storage/38/download.jpeg',
    );
    expect(
      candidates,
      contains(
        'https://api.hudhuddelivery.com/storage/38/conversions/download-medium.jpg',
      ),
    );
  });
}
