import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/sos/model/sos_trigger_request.dart';

void main() {
  test('toJson includes order_id when set', () {
    const request = SosTriggerRequest(
      orderId: 2,
      latitude: 40.7128,
      longitude: -74.006,
      locationAddress: '123 Main St',
      description: 'Need help',
    );

    final json = request.toJson();
    expect(json['order_id'], 2);
    expect(json['alert_type'], 'emergency');
    expect(json['priority'], 'high');
    expect(json['latitude'], 40.7128);
  });

  test('toJson omits order_id when null', () {
    const request = SosTriggerRequest(
      latitude: 40.7128,
      longitude: -74.006,
      locationAddress: '123 Main St',
      description: 'Need help',
    );

    expect(request.toJson().containsKey('order_id'), isFalse);
  });
}
