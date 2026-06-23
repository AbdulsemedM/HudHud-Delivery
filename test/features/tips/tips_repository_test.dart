import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/tips/data/tips_data_provider.dart';
import 'package:hudhud_delivery/features/tips/data/tips_repository.dart';
import 'package:hudhud_delivery/features/tips/model/tip_history_query.dart';

class _FakeTipsDataProvider extends TipsDataProvider {
  _FakeTipsDataProvider() : super(apiService: ApiService.instance);

  Map<String, dynamic>? lastCalculateBody;
  Map<String, dynamic>? lastAddBody;
  int calculateStatus = 200;
  int addStatus = 200;

  @override
  Future<Map<String, dynamic>> getRates() async {
    return {
      'statusCode': 200,
      'data': {
        'data': [
          {
            'id': 1,
            'name': 'No Tip',
            'type': 'fixed',
            'value': '0.00',
            'is_default': true,
            'display_order': 1,
            'is_active': true,
          },
        ],
      },
    };
  }

  @override
  Future<Map<String, dynamic>> calculateTip({
    required int orderId,
    required int tipOptionId,
    num? customAmount,
  }) async {
    lastCalculateBody = {
      'order_id': orderId,
      'tip_option_id': tipOptionId,
      if (customAmount != null) 'custom_amount': customAmount,
    };
    if (calculateStatus != 200) {
      return {
        'statusCode': calculateStatus,
        'data': null,
        'errorMessage': 'Calculate failed',
      };
    }
    return {
      'statusCode': 200,
      'data': {
        'data': {
          'amount': 10,
          'percentage': 5,
          'tip_option_id': tipOptionId,
          'is_custom': customAmount != null,
        },
      },
    };
  }

  @override
  Future<Map<String, dynamic>> addTip({
    required int orderId,
    required num amount,
    required int tipOptionId,
    required String recipientType,
    required String paymentMethod,
    String? message,
    bool isAnonymous = false,
  }) async {
    lastAddBody = {
      'order_id': orderId,
      'amount': amount,
      'tip_option_id': tipOptionId,
      'recipient_type': recipientType,
      'payment_method': paymentMethod,
      'is_anonymous': isAnonymous,
    };
    if (addStatus != 200) {
      return {
        'statusCode': addStatus,
        'data': null,
        'errorMessage': 'Add failed',
      };
    }
    return {
      'statusCode': 200,
      'data': {
        'data': {
          'id': 1,
          'order_id': orderId,
          'amount': amount.toString(),
          'driver_amount': amount.toString(),
          'vendor_amount': '0.00',
          'recipient_type': recipientType,
          'payment_method': paymentMethod,
          'payment_status': 'completed',
        },
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getHistory(TipHistoryQuery query) async {
    return {
      'statusCode': 200,
      'data': {
        'data': {
          'current_page': 1,
          'last_page': 1,
          'total': 0,
          'data': <dynamic>[],
        },
        'stats': {
          'total_tips_given': 0,
          'total_amount_tipped': 0,
          'average_tip': 0,
        },
      },
    };
  }
}

void main() {
  group('TipsRepository', () {
    late _FakeTipsDataProvider provider;
    late TipsRepository repository;

    setUp(() {
      provider = _FakeTipsDataProvider();
      repository = TipsRepository(dataProvider: provider);
    });

    test('getRates returns active sorted rates', () async {
      final rates = await repository.getRates();
      expect(rates.length, 1);
      expect(rates.first.name, 'No Tip');
    });

    test('calculateTip returns parsed result', () async {
      final result = await repository.calculateTip(
        orderId: 2,
        tipOptionId: 3,
      );
      expect(result.amount, 10);
      expect(provider.lastCalculateBody?['order_id'], 2);
    });

    test('calculateTip throws on error status', () async {
      provider.calculateStatus = 422;
      expect(
        () => repository.calculateTip(orderId: 2, tipOptionId: 3),
        throwsA(isA<Exception>()),
      );
    });

    test('addTipWallet sends wallet payment method', () async {
      final result = await repository.addTipWallet(
        orderId: 2,
        amount: 5,
        tipOptionId: 2,
        recipientType: 'driver',
      );
      expect(result.paymentMethod, 'wallet');
      expect(provider.lastAddBody?['payment_method'], 'wallet');
    });

    test('addTipWallet throws on error status', () async {
      provider.addStatus = 400;
      expect(
        () => repository.addTipWallet(
          orderId: 2,
          amount: 5,
          tipOptionId: 2,
          recipientType: 'driver',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
