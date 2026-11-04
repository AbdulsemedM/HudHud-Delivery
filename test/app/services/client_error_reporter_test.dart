import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/app/services/client_error_reporter.dart';

const _meta = ClientErrorMetadata(
  appVersion: '1.1.1',
  buildNumber: '35',
  platform: 'android',
  osVersion: 'Android 14',
  deviceModel: 'Tecno KI5',
  deviceId: 'abc123',
);

class _Harness {
  _Harness({List<int?>? statuses}) : _statuses = statuses ?? [201];

  final List<int?> _statuses;
  final List<Map<String, dynamic>> bodies = [];
  DateTime now = DateTime.utc(2026, 11, 5, 10);

  late final ClientErrorReporter reporter = ClientErrorReporter(
    enabled: true,
    metadata: () async => _meta,
    clock: () => now,
    // Timers never fire during a test; flush() is called directly.
    flushDelay: const Duration(hours: 1),
    retryDelay: const Duration(hours: 1),
    sender: (body) async {
      bodies.add(body);
      return _statuses.length > 1 ? _statuses.removeAt(0) : _statuses.first;
    },
  );
}

void main() {
  test('single report uses the exact contract shape', () async {
    final h = _Harness();
    h.reporter.localeProvider = () => 'am';
    h.reporter.currentRoute = '/checkout';
    h.reporter.record(StateError('boom'), StackTrace.current, fatal: true);
    await h.reporter.flush();

    expect(h.bodies, hasLength(1));
    final body = h.bodies.single;
    expect(body.containsKey('reports'), isFalse);
    expect(body['app'], 'customer');
    expect(body['app_version'], '1.1.1');
    expect(body['build_number'], '35');
    expect(body['platform'], 'android');
    expect(body['os_version'], 'Android 14');
    expect(body['device_model'], 'Tecno KI5');
    expect(body['device_id'], 'abc123');
    expect(body['error_type'], 'StateError');
    expect(body['message'], contains('boom'));
    expect(body['stack'], isA<String>());
    expect(body['fatal'], isTrue);
    expect(body['context'], {
      'screen': null,
      'route': '/checkout',
      'locale': 'am',
    });
    expect(body['occurred_at'], '2026-11-05T10:00:00.000Z');
    expect(h.reporter.queuedCount, 0);
  });

  test('batches up to 20 as {reports: [...]}', () async {
    final h = _Harness();
    for (var i = 0; i < 5; i++) {
      h.reporter.record(Exception('e$i'), null);
    }
    await h.reporter.flush();
    expect(h.bodies, hasLength(1));
    expect((h.bodies.single['reports'] as List), hasLength(5));
  });

  test('rate limit: max 20 per minute, duplicates once per minute', () async {
    final h = _Harness();
    for (var i = 0; i < 30; i++) {
      h.reporter.record(Exception('e$i'), null);
    }
    expect(h.reporter.queuedCount, ClientErrorReporter.maxPerMinute);

    final dup = _Harness();
    for (var i = 0; i < 5; i++) {
      dup.reporter.record(Exception('same'), null);
    }
    expect(dup.reporter.queuedCount, 1);
    dup.now = dup.now.add(const Duration(minutes: 2));
    dup.reporter.record(Exception('same'), null);
    expect(dup.reporter.queuedCount, 2);
  });

  test('drops a batch after maxAttempts failures', () async {
    final h = _Harness(statuses: [500]);
    h.reporter.record(Exception('x'), null);
    for (var i = 0; i < ClientErrorReporter.maxAttempts; i++) {
      await h.reporter.flush();
    }
    expect(h.bodies, hasLength(ClientErrorReporter.maxAttempts));
    expect(h.reporter.queuedCount, 0);
  });

  test('4xx is dropped at once; 404 disables reporting', () async {
    final h = _Harness(statuses: [422]);
    h.reporter.record(Exception('x'), null);
    await h.reporter.flush();
    expect(h.reporter.queuedCount, 0);

    final missing = _Harness(statuses: [404]);
    missing.reporter.record(Exception('x'), null);
    await missing.reporter.flush();
    missing.reporter.record(Exception('y'), null);
    expect(missing.reporter.queuedCount, 0);
  });

  test('disabled reporter queues nothing', () {
    final r = ClientErrorReporter(enabled: false, metadata: () async => _meta);
    r.record(Exception('x'), null);
    expect(r.queuedCount, 0);
  });

  test('sender exceptions never escape', () async {
    final r = ClientErrorReporter(
      enabled: true,
      metadata: () async => _meta,
      flushDelay: const Duration(hours: 1),
      retryDelay: const Duration(hours: 1),
      sender: (_) async => throw StateError('network'),
    );
    r.record(Exception('x'), null);
    await r.flush();
    expect(r.queuedCount, 1); // kept for retry
  });
}
