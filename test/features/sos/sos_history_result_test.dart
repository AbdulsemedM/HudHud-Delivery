import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/sos/model/sos_history_result.dart';

void main() {
  test('parses paginated SOS history response', () {
    final result = SosHistoryResult.fromResponseData({
      'current_page': 1,
      'data': [
        {
          'id': 1,
          'user_id': '36',
          'order_id': '2',
          'alert_type': 'emergency',
          'status': 'active',
          'priority': 'high',
          'latitude': '40.71280000',
          'longitude': '-74.00600000',
          'location_address': '123 Main St, Downtown, NY 10001',
          'description': 'Feeling unsafe, need immediate assistance',
          'created_at': '2026-05-28T08:09:30.000000Z',
          'order': {
            'order_number': 'ORD-20260516-0177709886',
          },
        },
      ],
      'last_page': 1,
      'total': 1,
    });

    expect(result.items, hasLength(1));
    expect(result.items.first.status, 'active');
    expect(result.items.first.orderNumber, 'ORD-20260516-0177709886');
    expect(result.hasMore, isFalse);
  });
}
