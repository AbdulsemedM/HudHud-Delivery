import 'package:flutter/material.dart';

class OrdersHeader extends StatelessWidget {
  final VoidCallback onFilterTap;

  const OrdersHeader({
    super.key,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage('https://via.placeholder.com/40'),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: Colors.black,
          ),
          onPressed: () {},
        ),
      ],
    );
  }
}

class OrdersTitle extends StatelessWidget {
  final VoidCallback onFilterTap;

  const OrdersTitle({
    super.key,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'My Orders',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: onFilterTap,
          child: const Text(
            'Filter',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class OrderItem extends StatelessWidget {
  final String distance;
  final String amount;
  final String dateTime;

  const OrderItem({
    super.key,
    required this.distance,
    required this.amount,
    required this.dateTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/car_icon.png',
            width: 40,
            height: 40,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$distance KMs',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'ETB $amount',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateTime,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
