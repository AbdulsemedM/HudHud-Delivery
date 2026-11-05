import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hudhud_delivery/core/utils/money_format.dart';
import 'package:hudhud_delivery/features/checkout/data/data_provider/checkout_data_provider.dart';
import 'package:hudhud_delivery/features/checkout/data/models/create_order_result.dart';
import 'package:hudhud_delivery/features/gifting/gift_phone.dart';
import 'package:hudhud_delivery/features/gifting/gift_session.dart';
import 'package:hudhud_delivery/features/gifting/presentation/gift_widgets.dart';
import 'package:hudhud_delivery/features/growth/data/models/growth_config.dart';
import 'package:hudhud_delivery/features/growth/data/models/market.dart';
import 'package:hudhud_delivery/features/orders/data/models/order_model.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

const _addis = Market(code: 'addis_ababa', name: 'Addis Ababa', currency: 'ETB');
const _hargeisa = Market(
  code: 'hargeisa',
  name: 'Hargeisa',
  currency: 'USD',
  phonePrefix: '+252',
  defaultLat: 9.56,
  defaultLng: 44.065,
);

Map<String, dynamic> _orderJson(Map<String, dynamic> extra) => {
      'id': 41,
      'order_number': 'ORD-20261105-41',
      'user_id': 7,
      'vendor_id': 3,
      'subtotal': '9.00',
      'delivery_fee': '1.50',
      'tax_amount': '0.00',
      'discount_amount': '0.00',
      'total_amount': '10.50',
      'payment_method': 'waafi',
      'status': 'paid',
      'delivery_address': 'Jigjiga Yar, Hargeisa',
      'created_at': '2026-11-05T10:00:00Z',
      'updated_at': '2026-11-05T10:00:00Z',
      ...extra,
    };

void main() {
  group('GiftPhonePlan (mirrors App\\Support\\MarketPhone)', () {
    final plan = GiftPhonePlan.forMarket(_hargeisa);

    test('Hargeisa falls back to the 9-digit 63/65/66 plan', () {
      expect(plan.dialPrefix, '+252');
      expect(plan.nationalLength, 9);
      expect(plan.mobilePrefixes, ['63', '65', '66']);
    });

    test('normalizes national, trunk-zero and international input', () {
      expect(plan.normalize('634123456'), '+252634123456');
      expect(plan.normalize('0634123456'), '+252634123456');
      expect(plan.normalize('252 65 412 3456'), '+252654123456');
      expect(plan.normalize('+252-66-4123456'), '+252664123456');
      expect(plan.normalize('00252634123456'), '+252634123456');
    });

    test('rejects wrong length and non-mobile prefixes', () {
      expect(plan.normalize('63412345'), isNull);
      expect(plan.normalize('6341234567'), isNull);
      expect(plan.normalize('614123456'), isNull);
      expect(plan.normalize(''), isNull);
      expect(plan.normalize(null), isNull);
    });

    test('a market phone plan from the API wins over the fallback', () {
      final market = Market.fromJson({
        'code': 'hargeisa',
        'name': 'Hargeisa',
        'currency': 'USD',
        'phone_prefix': '+252',
        'settings': {
          'phone': {
            'national_length': 9,
            'mobile_prefixes': [63, '90'],
          },
        },
      });
      expect(market.phoneNationalLength, 9);
      expect(market.phoneMobilePrefixes, ['63', '90']);
      final custom = GiftPhonePlan.forMarket(market);
      expect(custom.normalize('904123456'), '+252904123456');
      expect(custom.normalize('654123456'), isNull);
    });

    test('unknown market without prefix uses +252 and the Hargeisa plan', () {
      final fallback = GiftPhonePlan.forMarket(null);
      expect(fallback.dialPrefix, '+252');
      expect(fallback.normalize('634123456'), '+252634123456');
    });

    test('other markets get a generic 7–10 digit check', () {
      const nairobi = Market(
        code: 'nairobi',
        name: 'Nairobi',
        currency: 'KES',
        phonePrefix: '+254',
      );
      final generic = GiftPhonePlan.forMarket(nairobi);
      expect(generic.normalize('0712345678'), '+254712345678');
      expect(generic.normalize('12345'), isNull);
    });

    test('example hint starts with a mobile prefix', () {
      expect(plan.exampleNational.startsWith('63 '), isTrue);
      expect(plan.exampleNational.replaceAll(' ', '').length, 9);
    });
  });

  group('gifting availability', () {
    test('needs a non-default market', () {
      expect(
        giftingAvailable(
          config: GrowthConfig.disabled,
          markets: const [_addis],
          serverUnavailable: false,
        ),
        isFalse,
      );
      expect(
        giftingAvailable(
          config: GrowthConfig.disabled,
          markets: const [_addis, _hargeisa],
          serverUnavailable: false,
        ),
        isTrue,
      );
    });

    test('a FEATURE_DISABLED answer or explicit config flag hides it', () {
      expect(
        giftingAvailable(
          config: GrowthConfig.disabled,
          markets: const [_addis, _hargeisa],
          serverUnavailable: true,
        ),
        isFalse,
      );
      final off = GrowthConfig.fromJson({
        'gifting': {'enabled': false},
      });
      expect(off.giftingEnabled, isFalse);
      expect(
        giftingAvailable(
          config: off,
          markets: const [_addis, _hargeisa],
          serverUnavailable: false,
        ),
        isFalse,
      );
    });

    test('growth config without a gifting block says nothing', () {
      expect(GrowthConfig.fromJson(const {}).giftingEnabled, isNull);
    });

    test('gift markets skip Addis and put Hargeisa first', () {
      const djibouti = Market(code: 'djibouti', name: 'Djibouti', currency: 'DJF');
      expect(
        giftMarkets(const [_addis, djibouti, _hargeisa]).map((m) => m.code),
        ['hargeisa', 'djibouti'],
      );
    });
  });

  group('GiftSession', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      GiftSession.instance.resetForTest();
    });

    test('start / clear', () {
      GiftSession.instance.start(_hargeisa);
      expect(GiftSession.instance.active, isTrue);
      expect(GiftSession.instance.market?.currency, 'USD');
      GiftSession.instance.clear();
      expect(GiftSession.instance.active, isFalse);
    });

    test('markUnavailable ends the session for the cooldown', () async {
      GiftSession.instance.start(_hargeisa);
      await GiftSession.instance.markUnavailable();
      expect(GiftSession.instance.active, isFalse);
      expect(GiftSession.instance.serverUnavailable, isTrue);

      await GiftSession.instance.markUnavailable(
        now: DateTime.now().subtract(
          GiftSession.unavailableCooldown + const Duration(minutes: 1),
        ),
      );
      expect(GiftSession.instance.serverUnavailable, isFalse);
    });

    test('restore reads a persisted answer', () async {
      SharedPreferences.setMockInitialValues({
        'p9_gifting_unavailable_at': DateTime.now().toIso8601String(),
      });
      await GiftSession.instance.restore();
      expect(GiftSession.instance.serverUnavailable, isTrue);
    });

    test('codes that mean "gifting is off"', () {
      expect(GiftSession.unavailableCodes, contains('FEATURE_DISABLED'));
      expect(GiftSession.unavailableCodes, contains('GIFTING_NOT_READY'));
    });
  });

  group('POST /customer/gift-orders body', () {
    final orderBody = CheckoutDataProvider.buildOrderBody(
      vendorId: 3,
      items: const [
        {'product_id': 10, 'quantity': 2},
      ],
      deliveryAddress: 'Jigjiga Yar, Hargeisa',
      deliveryLocation: 'Jigjiga Yar, Hargeisa',
      deliveryLatitude: 9.56,
      deliveryLongitude: 44.06,
      paymentMethod: 'waafi',
      branchId: 5,
      redeemPoints: 200,
    );

    test('order body keeps the /customer/orders fields', () {
      expect(orderBody['vendor_id'], 3);
      expect(orderBody['branch_id'], 5);
      expect(orderBody['payment_method'], 'waafi');
      expect(orderBody['delivery_latitude'], 9.56);
      expect(orderBody['items'], [
        {'product_id': 10, 'quantity': 2},
      ]);
      expect(orderBody['redeem_points'], 200);
    });

    test('adds recipient fields and drops points', () {
      final body = CheckoutDataProvider.buildGiftOrderBody(
        orderBody: orderBody,
        recipientName: '  Amina Yusuf ',
        recipientPhone: '+252634123456',
        giftMessage: ' Happy Eid! ',
      );
      expect(body['recipient_name'], 'Amina Yusuf');
      expect(body['recipient_phone'], '+252634123456');
      expect(body['gift_message'], 'Happy Eid!');
      expect(body.containsKey('redeem_points'), isFalse);
      expect(body['vendor_id'], 3);
    });

    test('omits an empty message and caps lengths to the API limits', () {
      final body = CheckoutDataProvider.buildGiftOrderBody(
        orderBody: orderBody,
        recipientName: 'A' * 200,
        recipientPhone: '+252634123456',
        giftMessage: '   ',
      );
      expect(body.containsKey('gift_message'), isFalse);
      expect(
        (body['recipient_name'] as String).length,
        CheckoutDataProvider.giftRecipientNameMaxLength,
      );
      final long = CheckoutDataProvider.buildGiftOrderBody(
        orderBody: orderBody,
        recipientName: 'Amina',
        recipientPhone: '+252634123456',
        giftMessage: 'x' * 400,
      );
      expect(
        (long['gift_message'] as String).length,
        CheckoutDataProvider.giftMessageMaxLength,
      );
    });

    test('the 201 gift response parses like an order', () {
      final created = parseCreateOrderResponse({
        'success': true,
        'message': 'Gift order created. Complete the payment to send it.',
        'order': {
          'id': 41,
          'total_amount': '10.50',
          'currency': 'USD',
          'status': 'pending',
          'delivery_fee': '1.50',
        },
        'gift': {
          'recipient_name': 'Amina',
          'recipient_phone': '+252634123456',
          'gift_message': null,
        },
        'payment': {
          'endpoint': '/api/payments/initiate',
          'amount': 10.5,
          'currency': 'USD',
        },
      });
      expect(created.orderId, 41);
      expect(created.totalAmount, 10.5);
      expect(created.currency, 'USD');
    });
  });

  group('USD display', () {
    test('formatMoneyPriceString keeps ETB output and uses \$ for USD', () {
      expect(formatMoneyPriceString('12.5'), 'ETB 12.50');
      expect(formatMoneyPriceString('12.5', currency: 'ETB'), 'ETB 12.50');
      expect(formatMoneyPriceString('12.5', currency: 'USD'), r'$12.50');
      expect(formatMoneyPriceString(r'$4', currency: 'usd'), r'$4.00');
      expect(formatMoneyPriceString('USD 1,250.5', currency: 'USD'),
          r'$1250.50');
      expect(formatMoneyAmount(-3, currency: 'USD'), r'-$3.00');
      expect(moneyPrefix('USD'), r'$');
      expect(moneyPrefix(null), 'ETB ');
    });

    test('a Hargeisa gift order shows dollars and the recipient', () {
      final order = OrderModel.fromJson(_orderJson({
        'currency': 'usd',
        'is_gift': true,
        'recipient_name': 'Amina Yusuf',
        'recipient_phone': '252634123456',
        'gift_message': 'Happy Eid!',
      }));
      expect(order.currency, 'USD');
      expect(order.formattedTotal, r'$10.50');
      expect(order.formattedDeliveryFee, r'$1.50');
      expect(order.isGift, isTrue);
      expect(order.giftRecipientDisplayName, 'Amina Yusuf');
      expect(order.giftRecipientPhoneDisplay, '+252634123456');
      expect(order.giftMessage, 'Happy Eid!');
      expect(order.items, isEmpty);
    });

    test('an Addis order without currency is unchanged', () {
      final order = OrderModel.fromJson(_orderJson({'is_gift': 0}));
      expect(order.currency, isNull);
      expect(order.formattedTotal, 'ETB 10.50');
      expect(order.isGift, isFalse);
      expect(order.giftRecipientDisplayName, isNull);
    });
  });

  group('gift widgets', () {
    Widget wrap(Widget child) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SingleChildScrollView(child: child)),
        );

    testWidgets('recipient form shows the market dial prefix and errors',
        (tester) async {
      final name = TextEditingController();
      final phone = TextEditingController();
      final message = TextEditingController();
      addTearDown(name.dispose);
      addTearDown(phone.dispose);
      addTearDown(message.dispose);

      await tester.pumpWidget(wrap(GiftRecipientForm(
        nameController: name,
        phoneController: phone,
        messageController: message,
        phonePlan: GiftPhonePlan.forMarket(_hargeisa),
        nameError: "Enter the recipient's name",
      )));

      expect(find.text("Recipient's name"), findsOneWidget);
      expect(find.text("Recipient's mobile number"), findsOneWidget);
      expect(find.text("Enter the recipient's name"), findsOneWidget);
      expect(
        find.text(
          'The recipient gets an SMS with a tracking link and a 4-digit delivery code.',
        ),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('gift-recipient-phone')),
        '63 412 3456',
      );
      await tester.pump();
      expect(find.text('+252 '), findsOneWidget);
      expect(GiftPhonePlan.forMarket(_hargeisa).normalize(phone.text),
          '+252634123456');
    });

    testWidgets('placed banner and gift label', (tester) async {
      await tester.pumpWidget(wrap(const Column(
        children: [
          GiftPlacedBanner(recipientName: 'Amina'),
          GiftForLabel(name: 'Amina'),
        ],
      )));
      expect(find.text('Gift order placed'), findsOneWidget);
      expect(find.textContaining('Amina gets an SMS'), findsOneWidget);
      expect(find.text('Gift for Amina'), findsOneWidget);
    });
  });
}
