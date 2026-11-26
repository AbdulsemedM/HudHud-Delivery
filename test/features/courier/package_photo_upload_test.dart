import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/courier/data/data_provider/courier_data_provider.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';

/// Replies with the given status codes in order, recording each call.
class _ScriptedProvider extends CourierDataProvider {
  _ScriptedProvider(this.statuses) : super(apiService: ApiService.instance);

  final List<int> statuses;
  final calls = <int>[];

  @override
  Future<Map<String, dynamic>> uploadPackagePhoto({
    required int deliveryId,
    required String filePath,
  }) async {
    calls.add(deliveryId);
    final status = statuses[calls.length - 1];
    return {'statusCode': status, 'data': null, 'errorMessage': null};
  }
}

void main() {
  late File photo;

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('package_photo_test');
    photo = File('${dir.path}${Platform.pathSeparator}item.jpg');
    await photo.writeAsBytes([0xFF, 0xD8, 0xFF, 0xD9]);
  });

  Future<bool> upload(_ScriptedProvider provider, {String? path}) {
    return CourierRepository(courierDataProvider: provider).uploadPackagePhoto(
      deliveryId: 42,
      filePath: path ?? photo.path,
      initialDelay: Duration.zero,
    );
  }

  group('CourierRepository.uploadPackagePhoto', () {
    test('succeeds on the first 201', () async {
      final provider = _ScriptedProvider([201]);
      expect(await upload(provider), isTrue);
      expect(provider.calls, [42]);
    });

    test('retries a server error and a dropped connection, then succeeds', () async {
      final provider = _ScriptedProvider([503, 0, 201]);
      expect(await upload(provider), isTrue);
      expect(provider.calls.length, 3);
    });

    test('gives up after three failed attempts', () async {
      final provider = _ScriptedProvider([500, 500, 500]);
      expect(await upload(provider), isFalse);
      expect(provider.calls.length, 3);
    });

    test('does not retry a refusal such as the photo limit or a picked-up parcel', () async {
      for (final status in [404, 409, 422]) {
        final provider = _ScriptedProvider([status]);
        expect(await upload(provider), isFalse, reason: 'status $status');
        expect(provider.calls.length, 1, reason: 'status $status');
      }
    });

    test('does nothing when the photo file is gone', () async {
      final provider = _ScriptedProvider([201]);
      expect(await upload(provider, path: '${photo.path}.missing'), isFalse);
      expect(provider.calls, isEmpty);
    });
  });
}
