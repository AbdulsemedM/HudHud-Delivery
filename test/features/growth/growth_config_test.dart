import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/growth/data/models/growth_config.dart';

void main() {
  group('GrowthConfig', () {
    test('parses the contract payload', () {
      final config = GrowthConfig.fromResponseBody({
        'success': true,
        'data': {
          'currency': 'ETB',
          'promo_codes': {'enabled': true},
          'free_delivery': {'enabled': true, 'threshold': 1000.00},
          'rewards': {
            'enabled': true,
            'redeem_points': 100,
            'redeem_value': 10.00,
            'min_redeem_points': 100,
          },
          'referral': {
            'enabled': true,
            'reward_amount': 50.00,
            'max_per_user': 10,
          },
          'on_time': {
            'enabled': false,
            'credit_amount': 50.00,
            'grace_minutes': 15,
          },
          'home_feed': {'enabled': true},
        },
      });

      expect(config.loaded, isTrue);
      expect(config.currency, 'ETB');
      expect(config.promoCodesEnabled, isTrue);
      expect(config.freeDeliveryEnabled, isTrue);
      expect(config.freeDeliveryThreshold, 1000.0);
      expect(config.rewardsEnabled, isTrue);
      expect(config.rewardsRedeemPoints, 100);
      expect(config.rewardsRedeemValue, 10.0);
      expect(config.rewardsMinRedeemPoints, 100);
      expect(config.referralEnabled, isTrue);
      expect(config.referralRewardAmount, 50.0);
      expect(config.referralMaxPerUser, 10);
      expect(config.onTimeEnabled, isFalse);
      expect(config.onTimeCreditAmount, 50.0);
      expect(config.onTimeGraceMinutes, 15);
      expect(config.homeFeedEnabled, isTrue);
      expect(config.reorderEnabled, isTrue);
      expect(config.checkoutQuoteEnabled, isTrue);
    });

    test('defaults everything off when flags are missing', () {
      final config = GrowthConfig.fromJson(const {});
      expect(config.loaded, isTrue);
      expect(config.promoCodesEnabled, isFalse);
      expect(config.freeDeliveryEnabled, isFalse);
      expect(config.rewardsEnabled, isFalse);
      expect(config.referralEnabled, isFalse);
      expect(config.homeFeedEnabled, isFalse);
      expect(config.checkoutQuoteEnabled, isFalse);
    });

    test('accepts string / numeric booleans and numbers', () {
      final config = GrowthConfig.fromJson({
        'promo_codes': {'enabled': '1'},
        'free_delivery': {'enabled': 1, 'threshold': '750.50'},
        'rewards': {'enabled': 'true', 'redeem_points': '0'},
      });
      expect(config.promoCodesEnabled, isTrue);
      expect(config.freeDeliveryEnabled, isTrue);
      expect(config.freeDeliveryThreshold, 750.5);
      expect(config.rewardsEnabled, isTrue);
      // Guard against a zero divisor in points math.
      expect(config.rewardsRedeemPoints, 100);
    });

    test('failed envelope falls back to disabled', () {
      expect(
        GrowthConfig.fromResponseBody({'success': false, 'message': 'x'}),
        same(GrowthConfig.disabled),
      );
      expect(GrowthConfig.fromResponseBody(null), same(GrowthConfig.disabled));
      expect(GrowthConfig.fromResponseBody('oops'), same(GrowthConfig.disabled));
      expect(GrowthConfig.disabled.loaded, isFalse);
      expect(GrowthConfig.disabled.checkoutQuoteEnabled, isFalse);
      expect(GrowthConfig.disabled.reorderEnabled, isFalse);
    });

    test('explicit reorder flag wins', () {
      final config = GrowthConfig.fromJson({
        'reorder': {'enabled': false},
      });
      expect(config.reorderEnabled, isFalse);
    });
  });
}
