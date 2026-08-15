import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/app/config/app_env.dart';

void main() {
  group('normalizeApiBaseUrl', () {
    test('appends /api/ when missing', () {
      expect(
        normalizeApiBaseUrl('https://example.com'),
        'https://example.com/api/',
      );
    });

    test('keeps existing /api suffix', () {
      expect(
        normalizeApiBaseUrl('https://example.com/api'),
        'https://example.com/api/',
      );
      expect(
        normalizeApiBaseUrl('https://example.com/api/'),
        'https://example.com/api/',
      );
    });

    test('rejects empty values', () {
      expect(() => normalizeApiBaseUrl(''), throwsArgumentError);
      expect(() => normalizeApiBaseUrl('   '), throwsArgumentError);
    });
  });
}
