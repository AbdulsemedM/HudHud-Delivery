import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/app/notifications/notification_events.dart';
import 'package:hudhud_delivery/core/utils/money_format.dart';
import 'package:hudhud_delivery/features/growth/data/models/checkout_quote.dart';
import 'package:hudhud_delivery/features/growth/data/models/growth_config.dart';
import 'package:hudhud_delivery/features/growth/data/models/home_feed.dart';
import 'package:hudhud_delivery/features/growth/data/models/market.dart';
import 'package:hudhud_delivery/features/growth/data/models/plus.dart';
import 'package:hudhud_delivery/features/growth/data/models/sponsored.dart';

void main() {
  group('Market', () {
    test('parses GET /api/markets list and keeps active markets only', () {
      final markets = Market.listFromResponseBody({
        'success': true,
        'data': [
          {
            'code': 'addis_ababa',
            'name': 'Addis Ababa',
            'currency': 'ETB',
            'timezone': 'Africa/Addis_Ababa',
            'is_active': true,
            'default_lat': 9.03,
            'default_lng': '38.74',
            'phone_prefix': '+251',
            'payment_methods': ['wallet', 'cash_on_delivery', 'telebirr'],
          },
          {
            'code': 'HARGEISA',
            'name': 'Hargeisa',
            'currency': 'usd',
            'is_active': false,
            'phone_prefix': '+252',
          },
          {'code': 'addis_ababa', 'name': 'duplicate'},
          {'name': 'no code'},
          'garbage',
        ],
      });
      expect(markets, hasLength(1));
      final addis = markets.single;
      expect(addis.code, 'addis_ababa');
      expect(addis.isDefault, isTrue);
      expect(addis.currency, 'ETB');
      expect(addis.defaultLng, closeTo(38.74, 0.0001));
      expect(addis.phonePrefix, '+251');
      expect(addis.paymentMethods, contains('telebirr'));
    });

    test('normalizes code and currency case', () {
      final m = Market.fromJson({
        'code': 'HARGEISA',
        'name': 'Hargeisa',
        'currency': 'usd',
      });
      expect(m.code, 'hargeisa');
      expect(m.currency, 'USD');
      expect(m.isActive, isTrue);
    });

    test('accepts data.markets and fails safe', () {
      expect(
        Market.listFromResponseBody({
          'success': true,
          'data': {
            'markets': [
              {'code': 'hargeisa', 'currency': 'USD'},
            ],
          },
        }).single.code,
        'hargeisa',
      );
      expect(Market.listFromResponseBody({'success': false, 'data': []}),
          isEmpty);
      expect(Market.listFromResponseBody(null), isEmpty);
      expect(Market.listFromResponseBody('<html>'), isEmpty);
    });

    test('parses resolve: object, nested, or null', () {
      expect(
        Market.tryParseResolveBody({
          'success': true,
          'data': {'code': 'addis_ababa', 'currency': 'ETB'},
        })?.code,
        'addis_ababa',
      );
      expect(
        Market.tryParseResolveBody({
          'success': true,
          'data': {
            'market': {'code': 'hargeisa', 'currency': 'USD'},
          },
        })?.currency,
        'USD',
      );
      expect(
        Market.tryParseResolveBody({'success': true, 'data': null}),
        isNull,
      );
      expect(
        Market.tryParseResolveBody({
          'success': true,
          'data': {'market': null},
        }),
        isNull,
      );
    });
  });

  group('GrowthConfig market (Phase 3)', () {
    test('reads market when present', () {
      final c = GrowthConfig.fromResponseBody({
        'success': true,
        'data': {
          'currency': 'USD',
          'market': {'code': 'Hargeisa', 'currency': 'usd'},
        },
      });
      expect(c.marketCode, 'hargeisa');
      expect(c.marketCurrency, 'USD');
      expect(c.adsEnabled, isTrue);
    });

    test('absent market keeps Phase 2 defaults', () {
      final c = GrowthConfig.fromResponseBody({'success': true, 'data': {}});
      expect(c.marketCode, isNull);
      expect(c.marketCurrency, isNull);
      expect(GrowthConfig.disabled.adsEnabled, isFalse);
    });

    test('explicit ads.enabled false wins', () {
      final c = GrowthConfig.fromResponseBody({
        'success': true,
        'data': {
          'ads': {'enabled': false},
        },
      });
      expect(c.adsEnabled, isFalse);
    });
  });

  group('PlusStatus', () {
    test('parses the contract payload with an active subscription', () {
      final s = PlusStatus.fromResponseBody({
        'success': true,
        'data': {
          'enabled': true,
          'price': 199.00,
          'currency': 'ETB',
          'period_days': 30,
          'benefits': {
            'free_delivery_min_basket': 500.00,
            'parcel_discount_percent': 10,
          },
          'subscription': {
            'status': 'active',
            'current_period_end': '2026-12-04T10:00:00Z',
            'cancel_at_period_end': false,
            'price': '199.00',
          },
          'estimated_savings_last_30d': 145.5,
        },
      });
      expect(s.loaded, isTrue);
      expect(s.available, isTrue);
      expect(s.isMember, isTrue);
      expect(s.price, 199.0);
      expect(s.periodDays, 30);
      expect(s.freeDeliveryMinBasket, 500.0);
      expect(s.parcelDiscountPercent, 10.0);
      expect(s.estimatedSavingsLast30d, 145.5);
      final sub = s.subscription!;
      expect(sub.status, PlusSubscriptionStatus.active);
      expect(sub.currentPeriodEnd, DateTime.utc(2026, 12, 4, 10));
      expect(sub.canCancel, isTrue);
      expect(sub.canResume, isFalse);
      expect(sub.currency, 'ETB');
    });

    test('non-member, cancelled-at-period-end and past_due', () {
      final none = PlusStatus.fromResponseBody({
        'success': true,
        'data': {'enabled': true, 'price': 199, 'subscription': null},
      });
      expect(none.available, isTrue);
      expect(none.isMember, isFalse);
      expect(none.subscription, isNull);

      final ending = PlusSubscription.fromJson({
        'status': 'active',
        'cancel_at_period_end': 1,
      });
      expect(ending.canCancel, isFalse);
      expect(ending.canResume, isTrue);

      final pastDue = PlusSubscription.fromJson({'status': 'past_due'});
      expect(pastDue.isPastDue, isTrue);
      expect(pastDue.isActive, isFalse);
      expect(parsePlusSubscriptionStatus('weird'),
          PlusSubscriptionStatus.unknown);
    });

    test('savings may be an {amount} object', () {
      final s = PlusStatus.fromJson({
        'enabled': true,
        'estimated_savings_last_30d': {'amount': '60.25', 'currency': 'ETB'},
      });
      expect(s.estimatedSavingsLast30d, 60.25);
    });

    test('disabled / failure stays hidden', () {
      final off = PlusStatus.fromResponseBody({
        'success': true,
        'data': {'enabled': false},
      });
      expect(off.loaded, isTrue);
      expect(off.available, isFalse);
      expect(PlusStatus.fromResponseBody({'success': false}).loaded, isFalse);
      expect(PlusStatus.fromResponseBody(null).available, isFalse);
      expect(PlusStatus.disabled.isMember, isFalse);
    });

    test('INSUFFICIENT_FUNDS details', () {
      final f = PlusInsufficientFunds.tryParse({
        'success': false,
        'code': 'INSUFFICIENT_FUNDS',
        'message': 'Insufficient funds',
        'data': {'required': 199.0, 'balance': '50.00'},
      })!;
      expect(f.requiredAmount, 199.0);
      expect(f.balance, 50.0);
      expect(f.shortfall, 149.0);
      final top = PlusInsufficientFunds.tryParse({
        'code': 'INSUFFICIENT_FUNDS',
        'required': 10,
        'balance': 20,
      })!;
      expect(top.shortfall, 0);
      expect(PlusInsufficientFunds.tryParse({'code': 'X'}), isNull);
      expect(PlusInsufficientFunds.tryParse(null), isNull);
    });

    test('quote plus object', () {
      final q = CheckoutQuote.tryParseResponseBody({
        'success': true,
        'data': {
          'subtotal': 600,
          'delivery_fee': 0,
          'delivery_fee_before_discounts': 80,
          'total': 600,
          'currency': 'ETB',
          'free_delivery': {'enabled': false, 'applied': true},
          'plus': {'member': true, 'applied': true},
        },
      })!;
      expect(q.plus?.member, isTrue);
      expect(q.plusApplied, isTrue);

      final noPlus = CheckoutQuote.tryParseResponseBody({
        'success': true,
        'data': {'subtotal': 100, 'total': 150, 'delivery_fee': 50},
      })!;
      expect(noPlus.plus, isNull);
      expect(noPlus.plusApplied, isFalse);
    });
  });

  group('SponsoredItem', () {
    test('parses GET /api/ads/sponsored', () {
      final items = SponsoredItem.listFromResponseBody(
        {
          'success': true,
          'data': {
            'items': [
              {
                'ad_id': 7,
                'impression_token': 'tok-1',
                'vendor': {
                  'id': 42,
                  'name': 'Burger Hub',
                  'image_url': 'https://cdn.example.com/b.jpg',
                  'rating': '4.6',
                  'is_open': true,
                },
                'label': 'Sponsored',
              },
              {
                'ad_id': 8,
                'impression_token': 'tok-2',
                'vendor': {'id': 42, 'name': 'Duplicate vendor'},
              },
              {'ad_id': 0, 'vendor': {'id': 3}},
              {'ad_id': 9, 'vendor': null},
              'garbage',
            ],
          },
        },
        placement: SponsoredPlacement.search,
      );
      expect(items, hasLength(1));
      final a = items.single;
      expect(a.adId, 7);
      expect(a.impressionToken, 'tok-1');
      expect(a.vendorId, 42);
      expect(a.vendorName, 'Burger Hub');
      expect(a.rating, 4.6);
      expect(a.isOpen, isTrue);
      expect(a.label, 'Sponsored');
      expect(a.placement, 'search');
    });

    test('accepts data as a bare list and fails safe', () {
      expect(
        SponsoredItem.listFromResponseBody(
          {
            'success': true,
            'data': [
              {'ad_id': 1, 'impression_token': 't', 'vendor': {'id': 5}},
            ],
          },
          placement: SponsoredPlacement.home,
        ).single.vendorId,
        5,
      );
      expect(
        SponsoredItem.listFromResponseBody(
          {'success': false},
          placement: SponsoredPlacement.home,
        ),
        isEmpty,
      );
      expect(
        SponsoredItem.listFromResponseBody(null,
            placement: SponsoredPlacement.home),
        isEmpty,
      );
    });

    test('home feed sponsored array', () {
      final feed = HomeFeed.fromJson({
        'banners': [],
        'collections': [],
        'sponsored': [
          {
            'ad_id': 3,
            'impression_token': 'h',
            'vendor': {'id': 11, 'name': 'Cafe'},
          },
        ],
      });
      expect(feed.sponsored, hasLength(1));
      expect(feed.sponsored.single.placement, 'home');
      expect(feed.isEmpty, isFalse);

      final old = HomeFeed.fromJson({'banners': [], 'collections': []});
      expect(old.sponsored, isEmpty);
      expect(old.isEmpty, isTrue);
      expect(HomeFeed.empty.sponsored, isEmpty);
    });
  });

  group('formatMoneyAmount', () {
    test('ETB and unknown match formatEtbAmount exactly', () {
      expect(formatMoneyAmount(12.5), formatEtbAmount(12.5));
      expect(formatMoneyAmount(12.5, currency: 'ETB'), 'ETB 12.50');
      expect(formatMoneyAmount(12.5, currency: 'etb'), 'ETB 12.50');
      expect(formatMoneyAmount(12.5, currency: ''), 'ETB 12.50');
      expect(formatMoneyAmount(10, currency: null, fractionDigits: 0),
          'ETB 10');
    });

    test('other currencies use their code', () {
      expect(formatMoneyAmount(3, currency: 'usd'), 'USD 3.00');
      expect(isEtbCurrency('USD'), isFalse);
      expect(isEtbCurrency(null), isTrue);
      expect(normalizeCurrencyCode('  usd '), 'USD');
    });
  });

  group('Plus notifications', () {
    test('matches on type or event', () {
      expect(isPlusPayload({'type': 'plus_renewed'}), isTrue);
      expect(isPlusPayload({'type': 'PLUS_PAYMENT_FAILED'}), isTrue);
      expect(isPlusPayload({'event': 'plus-expired'}), isTrue);
      expect(isPlusPayload({'type': 'on_time_credit'}), isFalse);
      expect(isPlusPayload({}), isFalse);
    });
  });
}
