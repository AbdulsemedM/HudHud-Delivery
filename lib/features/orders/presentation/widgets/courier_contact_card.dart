import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/phone_dialer.dart';
import 'package:hudhud_delivery/features/calls/call_presenter.dart';
import 'package:hudhud_delivery/features/orders/data/models/order_model.dart';

/// The courier, and a way to reach them, on a FOOD order.
///
/// The parcel tracking screen has had this since calling shipped; the food
/// order screen never did, so on the flow that carries most of the business
/// a customer had no way to reach their courier at all -- not in the app,
/// not even by phone. Calling looked switched off because on this screen it
/// was absent, which from the outside is the same thing.
///
/// Renders nothing until a driver is assigned, and nothing once the order is
/// over: `CallEligibility` closes the line when the job ends, so a Call
/// button after delivery could only produce a 403.
class CourierContactCard extends StatelessWidget {
  const CourierContactCard({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final driver = order.driver;
    if (driver == null || order.isTerminal) {
      return const SizedBox.shrink();
    }

    final name = driver.name.trim();
    final phone = driver.phone.trim();
    final hasInApp = driver.id > 0;
    // Nothing to offer at all: no in-app route and no number.
    if (!hasInApp && phone.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.brandOrange.withOpacity(0.12),
                child: Text(
                  name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandOrange,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your courier',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name.isNotEmpty ? name : 'Your courier',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    key: const ValueKey('order-call-courier'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => _call(context, driverId: driver.id,
                        name: name, phone: phone, hasInApp: hasInApp),
                    icon: Icon(
                      hasInApp
                          ? Icons.wifi_calling_3_rounded
                          : Icons.call_outlined,
                    ),
                    label: const Text('Call'),
                  ),
                ),
              ),
              // The phone network, kept as a SECOND action -- and only when
              // Call is the in-app one, or it would do the same thing twice.
              if (hasInApp && phone.isNotEmpty) ...[
                const SizedBox(width: 10),
                SizedBox(
                  height: 50,
                  width: 50,
                  child: OutlinedButton(
                    key: const ValueKey('order-call-courier-on-phone'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => PhoneDialer.call(phone),
                    child: const Icon(Icons.call_outlined, size: 20),
                  ),
                ),
              ],
            ],
          ),
          if (hasInApp) ...[
            const SizedBox(height: 10),
            Text(
              'Calling uses your data. Neither of you sees the other\'s number.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _call(
    BuildContext context, {
    required int driverId,
    required String name,
    required String phone,
    required bool hasInApp,
  }) async {
    // Tapping Call places the call. It does not ask which kind -- the same
    // rule as the parcel screen. Only with no in-app route at all does Call
    // fall straight through to the dialler, because a button that explains
    // why it cannot work is worse than one that works.
    if (!hasInApp) {
      await PhoneDialer.call(phone);
      return;
    }
    await startOutgoingCall(
      context,
      calleeId: driverId,
      displayName: name.isNotEmpty ? name : null,
    );
  }
}
