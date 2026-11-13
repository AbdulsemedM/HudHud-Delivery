import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/utils/api_error_result.dart';
import 'package:hudhud_delivery/features/cancellation/data/cancellation_models.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_cancel.dart';
import 'package:hudhud_delivery/features/orders/data/models/order_cancel_result.dart';

void main() {
  group('CancellationStanding', () {
    test('disabled when enabled flag missing or false', () {
      expect(CancellationStanding.fromResponseBody({'data': {}}).enabled, isFalse);
      expect(
        CancellationStanding.fromResponseBody({
          'data': {'enabled': false, 'points': 40},
        }).enabled,
        isFalse,
      );
    });

    test('parses a fine-due standing', () {
      final s = CancellationStanding.fromResponseBody({
        'success': true,
        'data': {
          'enabled': true,
          'points': 55,
          'fine_threshold': 50,
          'ban_threshold': 100,
          'points_per_late_cancel': 10,
          'decay_days': 30,
          'next_decay_at': '2026-12-01T10:00:00Z',
          'next_decay_points': 10,
          'status': 'fine_due',
          'fine': {'id': 7, 'amount': '200.00', 'currency': 'etb'},
          'suspended_until': null,
        },
      });
      expect(s.enabled, isTrue);
      expect(s.points, 55);
      expect(s.status, CancellationStandingStatus.fineDue);
      expect(s.fine!.id, 7);
      expect(s.fine!.amount, 200);
      expect(s.fine!.currency, 'ETB');
      expect(s.isBlocked, isTrue);
      expect(s.needsAttention, isTrue);
      expect(s.nextThreshold, 100);
    });

    test('suspension in the past no longer blocks', () {
      final s = CancellationStanding.fromResponseBody({
        'data': {
          'enabled': true,
          'points': 100,
          'status': 'suspended',
          'suspended_until': '2020-01-01T00:00:00Z',
        },
      });
      expect(s.isSuspended, isFalse);
      expect(s.isBlocked, isFalse);
    });
  });

  group('CancellationPreview', () {
    test('null without can_cancel (older backend shape)', () {
      expect(CancellationPreview.fromResponseBody({'data': {}}), isNull);
    });

    test('free cancel', () {
      final p = CancellationPreview.fromResponseBody({
        'data': {'can_cancel': true, 'penalty_points': 0},
      })!;
      expect(p.canCancel, isTrue);
      expect(p.isFree, isTrue);
    });

    test('penalised cancel that triggers a fine', () {
      final p = CancellationPreview.fromResponseBody({
        'data': {
          'can_cancel': true,
          'penalty_points': 10,
          'points_before': 45,
          'fine_threshold': 50,
          'ban_threshold': 100,
          'consequence': 'fine',
          'fine_amount': 200,
          'currency': 'ETB',
        },
      })!;
      expect(p.isFree, isFalse);
      expect(p.pointsAfter, 55); // derived when points_after is missing
      expect(p.consequence, CancellationConsequence.fine);
      expect(p.fineAmount, 200);
    });

    test('blocked after pickup', () {
      final p = CancellationPreview.fromResponseBody({
        'data': {'can_cancel': false, 'reason_code': 'ALREADY_PICKED_UP'},
      })!;
      expect(p.canCancel, isFalse);
      expect(p.reasonCode, 'ALREADY_PICKED_UP');
    });
  });

  group('CancellationPenaltyOutcome', () {
    test('reads penalty from top level or data', () {
      final a = CancellationPenaltyOutcome.fromResponseBody({
        'message': 'ok',
        'penalty': {'points_added': 10, 'points_total': 30},
      })!;
      expect(a.pointsAdded, 10);
      expect(a.pointsTotal, 30);
      final b = CancellationPenaltyOutcome.fromResponseBody({
        'data': {
          'penalty': {
            'points_added': 10,
            'points_total': 100,
            'consequence': 'suspension',
            'suspended_until': '2030-01-01T00:00:00Z',
          },
        },
      })!;
      expect(b.consequence, CancellationConsequence.suspension);
      expect(b.suspendedUntil, isNotNull);
    });

    test('free cancel has no outcome', () {
      expect(
        CancellationPenaltyOutcome.fromResponseBody({
          'penalty': {'points_added': 0},
        }),
        isNull,
      );
      expect(CancellationPenaltyOutcome.fromResponseBody({'message': 'ok'}),
          isNull);
    });

    test('order cancel result carries the penalty', () {
      final r = OrderCancelResult.fromResponseBody({
        'message': 'Order cancelled',
        'penalty': {'points_added': 10, 'points_total': 20},
      });
      expect(r.penalty!.pointsTotal, 20);
    });
  });

  group('ApiErrorResult cancellation blocks', () {
    test('unpaid fine', () {
      final e = parseApiErrorResult({
        'code': 'CANCELLATION_FINE_UNPAID',
        'message': 'Pay your fine',
        'fine_id': 7,
        'amount': 200,
        'currency': 'ETB',
      }, statusCode: 403);
      expect(e.isCancellationFineUnpaid, isTrue);
      expect(e.isCancellationBlock, isTrue);
      expect(e.fineId, 7);
      expect(e.amount, 200);
    });

    test('suspension', () {
      final e = parseApiErrorResult({
        'code': 'ACCOUNT_SUSPENDED_CANCELLATIONS',
        'message': 'Paused',
        'suspended_until': '2030-01-01T00:00:00Z',
      }, statusCode: 403);
      expect(e.isSuspendedForCancellations, isTrue);
      expect(e.suspendedUntil, isNotNull);
    });
  });

  group('canCancelCourierDelivery', () {
    test('old rule: blocked once assigned', () {
      expect(canCancelCourierDelivery('pending'), isTrue);
      expect(canCancelCourierDelivery('pickup_assigned'), isFalse);
      expect(canCancelCourierDelivery('en_route_pickup'), isFalse);
    });

    test('penalty rule: allowed until pickup', () {
      bool can(String s) => canCancelCourierDelivery(s, allowUntilPickup: true);
      expect(can('pending'), isTrue);
      expect(can('pickup_assigned'), isTrue);
      expect(can('courier_assigned'), isTrue);
      expect(can('en_route_pickup'), isTrue);
      expect(can('at_pickup'), isTrue);
      expect(can('picked_up'), isFalse);
      expect(can('package_picked_up'), isFalse);
      expect(can('en_route_dropoff'), isFalse);
      expect(can('in_transit'), isFalse);
      expect(can('delivered'), isFalse);
      expect(can('cancelled'), isFalse);
    });
  });
}
