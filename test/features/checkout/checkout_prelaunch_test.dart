import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/checkout/data/models/delivery_fee_quote.dart';
import 'package:hudhud_delivery/features/checkout/presentation/widgets/checkout_issue_card.dart';
import 'package:hudhud_delivery/features/courier/parcel_v2/parcel_v2_models.dart';
import 'package:hudhud_delivery/features/courier/parcel_v2/parcel_v2_widgets.dart';
import 'package:hudhud_delivery/features/payment/bloc/payment_bloc.dart';
import 'package:hudhud_delivery/features/wallet/data/customer_dues_repository.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

void main() {
  group('customer dues', () {
    test('parses GET /customer/dues summary', () {
      final dues = CustomerDuesRepository.parseSummary({
        'success': true,
        'data': {
          'summary': {
            'count': 1,
            'amounts': [
              {'currency': 'ETB', 'amount': 30},
            ],
          },
          'dues': [],
        },
      });
      expect(dues!.hasDues, isTrue);
      expect(dues.amounts, {'ETB': 30.0});
    });

    test('summary null (table not migrated) means no dues', () {
      final dues = CustomerDuesRepository.parseSummary({
        'success': true,
        'data': {'summary': null, 'dues': []},
      });
      expect(dues!.hasDues, isFalse);
    });

    test('fetch failures are unknown, never a crash', () async {
      final repo = CustomerDuesRepository(
        fetch: () async => throw Exception('offline'),
      );
      expect(await repo.fetchSummary(), isNull);
      expect(CustomerDuesRepository.parseSummary('nope'), isNull);
    });

    test('parcel booking maps OUTSTANDING_DUES', () {
      expect(
        parcelErrorKind('OUTSTANDING_DUES'),
        ParcelErrorKind.outstandingDues,
      );
    });
  });

  group('order refusal details', () {
    test('PaymentFailure carries status and body', () {
      const failure = PaymentFailure(
        error: 'closed',
        code: 'STORE_CLOSED',
        statusCode: 422,
        details: {
          'store_status': {'state': 'closed'}
        },
      );
      expect(failure.statusCode, 422);
      expect(failure.details!['store_status'], isA<Map>());
      expect(
        failure,
        isNot(const PaymentFailure(error: 'closed', code: 'STORE_CLOSED')),
      );
    });

    test('delivery-fee quote: a plain 422 is a validation error', () {
      const plain = DeliveryFeeQuoteException(
        message: 'x',
        statusCode: 422,
        code: 'validation_error',
      );
      expect(plain.isValidation, isTrue);
      const store = DeliveryFeeQuoteException(
        message: 'closed',
        statusCode: 422,
        code: 'STORE_CLOSED',
        details: {'code': 'STORE_CLOSED'},
      );
      expect(store.isValidation, isFalse);
      expect(store.details!['code'], 'STORE_CLOSED');
    });
  });

  group('widgets', () {
    Widget wrap(Widget child, {Locale locale = const Locale('en')}) =>
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SingleChildScrollView(child: child)),
        );

    testWidgets('dues banner offers Pay now', (tester) async {
      var taps = 0;
      final en = lookupAppLocalizations(const Locale('en'));
      await tester.pumpWidget(wrap(ParcelDuesBanner(
        dues: const ParcelDuesSummary(count: 1, amounts: {'USD': 1.5}),
        message: en.p12DuesCheckoutBody,
        onPayNow: () => taps++,
      )));
      expect(find.textContaining(r'$1.50'), findsOneWidget);
      expect(find.textContaining('Cash on delivery is off'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('dues_pay_now')));
      expect(taps, 1);
    });

    testWidgets('dues banner without action keeps the parcel text',
        (tester) async {
      await tester.pumpWidget(wrap(const ParcelDuesBanner(
        dues: ParcelDuesSummary(count: 1, amounts: {'ETB': 30}),
      )));
      expect(find.textContaining('You owe ETB 30.00'), findsOneWidget);
      expect(find.byKey(const ValueKey('dues_pay_now')), findsNothing);
    });

    testWidgets('issue card runs its fix-it action (RTL too)', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrap(
        CheckoutIssueCard(
          icon: Icons.remove_shopping_cart_outlined,
          message: 'Shiro is sold out today. Remove it to continue.',
          actionLabel: 'Remove item',
          onAction: () => taps++,
        ),
        locale: const Locale('ar'),
      ));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('checkout_issue_action')));
      expect(taps, 1);
    });
  });
}
