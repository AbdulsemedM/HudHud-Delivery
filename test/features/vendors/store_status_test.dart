import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';
import 'package:hudhud_delivery/features/growth/data/models/growth_json.dart';
import 'package:hudhud_delivery/features/orders/data/models/vendor_model.dart';
import 'package:hudhud_delivery/features/vendors/data/models/store_status.dart';
import 'package:hudhud_delivery/features/vendors/data/repository/store_status_repository.dart';
import 'package:hudhud_delivery/features/vendors/presentation/widgets/store_status_widgets.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final now = DateTime(2026, 11, 8, 10, 0);

  group('StoreStatus.tryParse', () {
    test('open, paused (busy) and closed states', () {
      expect(StoreStatus.tryParse({'state': 'open'})!.acceptingOrders, isTrue);
      final busy = StoreStatus.tryParse({
        'state': 'paused',
        'resumes_at': DateTime(2026, 11, 8, 10, 30).toIso8601String(),
        'reason': 'busy',
      })!;
      expect(busy.isBusy, isTrue);
      expect(busy.acceptingOrders, isFalse);
      expect(busy.resumesAt, isNotNull);
      final closed = StoreStatus.tryParse({
        'state': 'closed',
        'reason': 'holiday',
      })!;
      expect(closed.isClosed, isTrue);
      expect(closed.isHoliday, isTrue);
    });

    test('falls back to code / accepting_orders; null for junk', () {
      expect(
        StoreStatus.tryParse({'code': 'STORE_PAUSED'})!.state,
        StoreState.busy,
      );
      expect(
        StoreStatus.tryParse({'accepting_orders': false})!.state,
        StoreState.closed,
      );
      expect(StoreStatus.tryParse({'foo': 1}), isNull);
      expect(StoreStatus.tryParse('closed'), isNull);
      expect(StoreStatus.tryParse(null), isNull);
    });

    test('reads the nested vendor_profile block (public vendors list)', () {
      final status = StoreStatus.fromVendorJson({
        'id': 12,
        'vendor_profile': {
          'store_status': {'state': 'closed'},
        },
      });
      expect(status?.isClosed, isTrue);
    });
  });

  group('VendorModel', () {
    test('public vendor list: shop fields and status from vendor_profile', () {
      final vendor = VendorModel.fromVendorListJson({
        'id': 12,
        'name': 'Owner Person',
        'status': 'active',
        'vendor_profile': {
          'id': 3,
          'shop_name': 'Kaldis Bole',
          'description': 'Coffee',
          'store_status': {
            'state': 'paused',
            'accepting_orders': false,
          },
        },
      });
      expect(vendor.id, 12, reason: 'owner user id drives product calls');
      expect(vendor.name, 'Kaldis Bole');
      expect(vendor.description, 'Coffee');
      expect(vendor.storeStatus?.isBusy, isTrue);
      expect(vendor.acceptingOrders, isFalse);
    });

    test('no store_status means open (older backend)', () {
      final vendor = VendorModel.fromVendorListJson({
        'id': 1,
        'shop_name': 'A',
      });
      expect(vendor.storeStatus, isNull);
      expect(vendor.acceptingOrders, isTrue);
    });
  });

  group('labels', () {
    test('opens today, tomorrow and later', () {
      StoreStatus closedAt(DateTime opens) =>
          StoreStatus(state: StoreState.closed, opensAt: opens.toUtc());
      expect(
        storeStatusLine(en, closedAt(DateTime(2026, 11, 8, 17, 5)), now: now),
        'Closed · Opens 17:05',
      );
      expect(
        storeStatusWhenLabel(
          en,
          closedAt(DateTime(2026, 11, 9, 8, 0)),
          now: now,
        ),
        'Opens tomorrow 08:00',
      );
      expect(
        storeStatusWhenLabel(
          en,
          closedAt(DateTime(2026, 11, 12, 9, 0)),
          now: now,
        ),
        'Opens 12/11 09:00',
      );
    });

    test('busy with and without a resume time, holiday, open', () {
      expect(
        storeStatusLine(
          en,
          StoreStatus(
            state: StoreState.busy,
            resumesAt: DateTime(2026, 11, 8, 10, 30).toUtc(),
          ),
          now: now,
        ),
        'Busy · Back at 10:30',
      );
      expect(
        storeStatusLine(en, const StoreStatus(state: StoreState.busy)),
        'Busy',
      );
      expect(
        storeStatusWhenLabel(
          en,
          const StoreStatus(state: StoreState.closed, reason: 'holiday'),
        ),
        'Closed today',
      );
      expect(storeStatusWhenLabel(en, StoreStatus.open), isNull);
    });
  });

  group('StoreStatusRepository', () {
    test('caches within the TTL and keeps the last status on failure',
        () async {
      var calls = 0;
      var fail = false;
      var clock = DateTime(2026, 11, 8, 10);
      final repo = StoreStatusRepository(
        clock: () => clock,
        fetchVendor: (id) async {
          calls++;
          if (fail) return {'statusCode': 500, 'data': null};
          return {
            'statusCode': 200,
            'data': {
              'success': true,
              'data': {
                'id': id,
                'vendor_profile': {
                  'store_status': {'state': 'closed'},
                },
              },
            },
          };
        },
      );
      expect((await repo.statusFor(5))!.isClosed, isTrue);
      expect((await repo.statusFor(5))!.isClosed, isTrue);
      expect(calls, 1);

      clock = clock.add(const Duration(minutes: 2));
      fail = true;
      expect((await repo.statusFor(5))!.isClosed, isTrue);
      expect(calls, 2);
    });

    test('no block on the vendor means open; remember / peek', () async {
      final repo = StoreStatusRepository(
        fetchVendor: (id) async => {
          'statusCode': 200,
          'data': {
            'data': {'id': id},
          },
        },
      );
      expect((await repo.statusFor(9))!.acceptingOrders, isTrue);
      repo.remember(9, const StoreStatus(state: StoreState.busy));
      expect(repo.peek(9)!.isBusy, isTrue);
      expect(await repo.statusFor(0), isNull);
    });
  });

  group('sold out today', () {
    test('sold_out_until in the future blocks ordering', () {
      final future = DateTime.now().add(const Duration(hours: 3));
      final product = CategoriesProductsModel.fromMap({
        'id': 1,
        'name': 'Shiro',
        'is_available': true,
        'status': 'active',
        'sold_out_until': future.toIso8601String(),
      });
      expect(product.isSoldOut, isTrue);
      expect(product.canOrder, isFalse);
      expect(
        product.isSoldOutAt(future.add(const Duration(minutes: 1))),
        isFalse,
      );
    });

    test('no or past sold_out_until keeps the item orderable', () {
      final product = CategoriesProductsModel.fromMap({
        'id': 2,
        'is_available': true,
        'sold_out_until': '2020-01-01T00:00:00Z',
      });
      expect(product.isSoldOut, isFalse);
      expect(product.canOrder, isTrue);
    });
  });

  group('feed open flag', () {
    test('store_status wins over the legacy is_open', () {
      expect(
        storeOpenFlag({
          'is_open': false,
          'store_status': {'state': 'open', 'accepting_orders': true},
        }),
        isTrue,
      );
      expect(
        storeOpenFlag({
          'is_open': true,
          'store_status': {'state': 'paused'},
        }),
        isFalse,
      );
      expect(storeOpenFlag({'is_open': false}), isFalse);
      expect(storeOpenFlag({'is_open': false}, legacy: false), isNull);
      expect(storeOpenFlag(<String, dynamic>{}), isNull);
    });
  });

  group('widgets', () {
    Widget wrap(Widget child, {Locale locale = const Locale('en')}) =>
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(width: 320, child: child),
          ),
        );

    final closed = StoreStatus(
      state: StoreState.closed,
      opensAt: DateTime(2026, 11, 9, 8, 0).toUtc(),
    );

    testWidgets('pill and banner are hidden while open', (tester) async {
      await tester.pumpWidget(wrap(const Column(
        children: [
          StoreStatusPill(status: StoreStatus.open),
          StoreStatusBanner(status: StoreStatus.open),
        ],
      )));
      expect(find.byKey(const ValueKey('store_status_pill')), findsNothing);
      expect(find.byKey(const ValueKey('store_status_banner')), findsNothing);
    });

    testWidgets('closed store shows state, time and explanation',
        (tester) async {
      await tester.pumpWidget(wrap(Column(
        children: [
          StoreStatusPill(status: closed, now: now),
          StoreStatusBanner(status: closed, now: now),
        ],
      )));
      expect(find.text('Closed · Opens tomorrow 08:00'), findsNWidgets(2));
      expect(find.text(en.p12StoreClosedBanner), findsOneWidget);
    });

    testWidgets('Arabic (RTL) renders without overflow', (tester) async {
      await tester.pumpWidget(wrap(
        Column(
          children: [
            StoreStatusPill(status: closed, now: now, compact: true),
            StoreStatusBanner(status: closed, now: now),
          ],
        ),
        locale: const Locale('ar'),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final ar = lookupAppLocalizations(const Locale('ar'));
      expect(find.text(ar.p12StoreClosed), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(StoreStatusBanner))),
        TextDirection.rtl,
      );
    });
  });
}
