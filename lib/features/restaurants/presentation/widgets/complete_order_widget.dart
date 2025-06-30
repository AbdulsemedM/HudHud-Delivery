import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/orders/presentation/widgets/orders_widget.dart';

class DeliverySummaryCard extends StatelessWidget {
  final double amount;
  final String duration;
  final double distance;
  final String deliveryType;

  const DeliverySummaryCard({
    super.key,
    required this.amount,
    required this.duration,
    required this.distance,
    required this.deliveryType,
  });

  @override
  Widget build(BuildContext context) {
    // Format amount with comma
    String formattedAmount = amount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFA07A),
            Color(0xFFFFF3E0),
          ],
          stops: [0.0, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/car_icon.png',
            height: 70,
          ),
          // const SizedBox(height: 20),
          Text(
            'ETB $formattedAmount',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                duration,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${distance.toStringAsFixed(1)} KM',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              deliveryType.toUpperCase(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.deepOrange,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LocationPoint extends StatelessWidget {
  final bool isPickup;
  final String location;
  final String details;

  const LocationPoint({
    super.key,
    required this.isPickup,
    required this.location,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPickup ? Colors.green : Colors.pink,
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                location,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                details,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Update the connection line between location points
class LocationConnector extends StatelessWidget {
  const LocationConnector({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 5),
      width: 2,
      height: 32,
      child: CustomPaint(
        painter: DashedLineVerticalPainter(),
      ),
    );
  }
}

class DashedLineVerticalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 4, dashSpace = 4, startY = 0;
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class BillingDetailsTable extends StatelessWidget {
  final double baseFare;
  final double distanceCharges;
  final double minutesCharges;
  final double tip;
  final double total;

  const BillingDetailsTable({
    super.key,
    required this.baseFare,
    required this.distanceCharges,
    required this.minutesCharges,
    required this.tip,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Billing Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildRow('Base fare', baseFare),
        _buildRow('Distance Charges', distanceCharges),
        _buildRow('Minutes Charges', minutesCharges),
        _buildRow('Tip', tip),
        const SizedBox(height: 8),
        _buildRow('Total', total, isTotal: true),
      ],
    );
  }

  Widget _buildRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isTotal ? Colors.black : Colors.grey[600],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            'ETB ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              color: isTotal ? Colors.purple : Colors.grey[600],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class DriverInfo extends StatelessWidget {
  final String name;
  final String imageUrl;

  const DriverInfo({
    super.key,
    required this.name,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const StoryRing(
          child: CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage('assets/images/profile.png'),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'YOUR DRIVER',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CommentSection extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const CommentSection({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Your Comments if any....',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Submit',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
