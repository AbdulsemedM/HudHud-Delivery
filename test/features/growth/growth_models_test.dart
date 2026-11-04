import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/app/notifications/notification_events.dart';
import 'package:hudhud_delivery/features/growth/data/models/home_feed.dart';
import 'package:hudhud_delivery/features/growth/data/models/referral_summary.dart';
import 'package:hudhud_delivery/features/growth/data/models/reorder.dart';
import 'package:hudhud_delivery/features/growth/data/models/rewards_summary.dart';
import 'package:hudhud_delivery/features/growth/data/models/hudhud_deep_link.dart';

void main() {
  group('RewardsSummary', () {
    test('parses summary and history', () {
      final s = RewardsSummary.fromJson({
        'points': 340,
        'value': 34.00,
        'redeem_points': 100,
        'redeem_value': 10.00,
        'min_redeem_points': 100,
        'enabled': true,
        'history': [
          {
            'id': 1,
            'points': 85,
            'type': 'earned',
            'order_id': 55,
            'note': 'Order #55',
            'created_at': '2026-11-01T10:00:00Z',
          },
          {'id': 2, 'points': -200, 'type': 'redeemed'},
          'garbage',
        ],
      });
      expect(s.points, 340);
      expect(s.value, 34.0);
      expect(s.enabled, isTrue);
      expect(s.history, hasLength(2));
      expect(s.history.first.orderId, 55);
      expect(s.history.first.isDebit, isFalse);
      expect(s.history.first.createdAt, isNotNull);
      expect(s.history.last.points, 200);
      expect(s.history.last.isDebit, isTrue);
    });
  });

  group('ReferralSummary', () {
    test('parses extended summary', () {
      final s = ReferralSummary.fromJson({
        'referral_code': 'AMIN42',
        'referral_link': 'https://old',
        'share_url': 'https://hudhuddelivery.com/r/AMIN42',
        'share_text': 'Get 50 ETB',
        'enabled': true,
        'reward_amount': 50.00,
        'max_per_user': 10,
        'stats': {
          'invited': 4,
          'rewarded': 2,
          'pending': 2,
          'earned_total': 100.00,
        },
        'pending_verification': false,
      });
      expect(s.hasCode, isTrue);
      expect(s.enabled, isTrue);
      expect(s.bestLink, 'https://hudhuddelivery.com/r/AMIN42');
      expect(s.invited, 4);
      expect(s.rewarded, 2);
      expect(s.pending, 2);
      expect(s.earnedTotal, 100.0);
    });

    test('legacy summary (no enabled, empty stats) stays hidden', () {
      final s = ReferralSummary.fromJson({
        'referral_code': 'ABC',
        'referral_link': 'https://x',
        'stats': [],
        'pending_verification': true,
      });
      expect(s.enabled, isFalse);
      expect(s.invited, 0);
      expect(s.bestLink, 'https://x');
    });
  });

  group('HomeFeed', () {
    test('parses banners and collections; drops empty collections', () {
      final feed = HomeFeed.fromJson({
        'banners': [
          {
            'id': 2,
            'title': 'B',
            'image_url': 'https://img/2',
            'action': {'type': 'promo', 'value': 'SAVE'},
            'sort_order': 1,
          },
          {
            'id': 1,
            'title': 'A',
            'image_url': 'https://img/1',
            'action': {'type': 'vendor', 'value': '12'},
            'sort_order': 0,
          },
        ],
        'collections': [
          {
            'id': 3,
            'title': 'Under 300 ETB',
            'slug': 'under-300',
            'item_type': 'product',
            'items': [
              {
                'id': 88,
                'type': 'product',
                'name': 'Burger',
                'price': 250.00,
                'vendor_id': 12,
              },
            ],
          },
          {'id': 4, 'title': 'Empty', 'item_type': 'vendor', 'items': []},
        ],
      });
      expect(feed.banners.map((b) => b.id), [1, 2]);
      expect(feed.banners.first.actionType, HomeFeedActionType.vendor);
      expect(feed.banners.last.actionType, HomeFeedActionType.promo);
      expect(feed.banners.last.actionValue, 'SAVE');
      expect(feed.collections, hasLength(1));
      final c = feed.collections.single;
      expect(c.matchesKey('3'), isTrue);
      expect(c.matchesKey('UNDER-300'), isTrue);
      expect(c.items.single.isVendor, isFalse);
      expect(c.items.single.price, 250.0);
    });

    test('unknown action type is none', () {
      expect(parseHomeFeedActionType('weird'), HomeFeedActionType.none);
      expect(parseHomeFeedActionType(null), HomeFeedActionType.none);
    });
  });

  group('Reorder', () {
    test('parses reorder result into cart products', () {
      final r = ReorderResult.tryParseResponseBody({
        'success': true,
        'data': {
          'vendor_id': 12,
          'items': [
            {
              'product_id': 88,
              'variant_id': null,
              'modifiers': [],
              'quantity': 2,
              'unit_price': 250.00,
              'name': 'Burger',
              'image_url': 'https://img',
            },
            {
              'product_id': 89,
              'variant_id': 4,
              'modifiers': [
                {'option_id': 7},
                9,
              ],
              'quantity': 1,
              'unit_price': 10,
              'name': 'Fries',
            },
          ],
          'unavailable': [
            {'product_id': 90, 'name': 'Shake', 'reason': 'out_of_stock'},
          ],
        },
      });
      expect(r, isNotNull);
      expect(r!.vendorId, 12);
      expect(r.items, hasLength(2));
      expect(r.unavailable.single.reason, 'out_of_stock');

      final first = r.items.first.toCartProduct();
      expect(first.id, 88);
      expect(first.vendor_id, 12);
      expect(first.price, '250.00');
      expect(first.canOrder, isTrue);
      expect(first.options, isNull);

      final second = r.items.last.toCartProduct();
      expect(second.options!['variant_id'], 4);
      expect(second.options!['modifier_option_ids'], [7, 9]);
    });

    test('parses reorder suggestions (current backend shape)', () {
      final list = ReorderSuggestion.listFromResponseBody({
        'success': true,
        'data': {
          'orders': [
            {
              'id': 55,
              'status': 'delivered',
              'total_amount': '880.00',
              'currency': 'ETB',
              'created_at': '2026-11-01T10:00:00.000000Z',
            },
            {'id': 0},
          ],
        },
      });
      expect(list, hasLength(1));
      expect(list.single.orderId, 55);
      expect(list.single.totalAmount, 880.0);
      expect(list.single.vendorName, isNull);
    });
  });

  group('Deep links', () {
    test('parses referral and order links', () {
      final r = HudhudDeepLink.parse(
        Uri.parse('https://hudhuddelivery.com/r/amin42'),
      );
      expect(r?.referralCode, 'AMIN42');
      final o = HudhudDeepLink.parse(
        Uri.parse('https://www.hudhuddelivery.com/o/55'),
      );
      expect(o?.orderId, 55);
    });

    test('ignores foreign or malformed links', () {
      expect(HudhudDeepLink.parse(Uri.parse('https://evil.com/r/X1')), isNull);
      expect(
        HudhudDeepLink.parse(Uri.parse('https://hudhuddelivery.com/o/abc')),
        isNull,
      );
      expect(
        HudhudDeepLink.parse(Uri.parse('https://hudhuddelivery.com/r/')),
        isNull,
      );
    });
  });

  group('Wallet credit notifications', () {
    test('matches on type or event', () {
      expect(isWalletCreditPayload({'type': 'on_time_credit'}), isTrue);
      expect(isWalletCreditPayload({'event': 'REFERRAL_REWARD'}), isTrue);
      expect(isWalletCreditPayload({'type': 'order_created'}), isFalse);
      expect(isWalletCreditPayload({}), isFalse);
    });
  });
}
