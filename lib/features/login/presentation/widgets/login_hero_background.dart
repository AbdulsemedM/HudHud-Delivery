import 'package:flutter/material.dart';



/// Soft circular highlights across the full login background (non-interactive).

class LoginHeroBlobs extends StatelessWidget {

  const LoginHeroBlobs({super.key});



  @override

  Widget build(BuildContext context) {

    return const SizedBox.expand(

      child: CustomPaint(

        painter: _LoginHeroBlobsPainter(),

      ),

    );

  }

}



class _LoginHeroBlobsPainter extends CustomPainter {

  const _LoginHeroBlobsPainter();



  @override

  void paint(Canvas canvas, Size size) {

    final w = size.width;

    final h = size.height;



    void drawBlob(Offset c, double r, double opacity) {

      final paint = Paint()

        ..style = PaintingStyle.fill

        ..color = Colors.white.withValues(alpha: opacity);

      canvas.drawCircle(c, r, paint);

    }



    // Coverage across entire viewport — partial off-screen blobs read softer at edges.

    drawBlob(Offset(w * -0.08, h * 0.08), w * 0.48, 0.11);

    drawBlob(Offset(w * 1.02, h * -0.02), w * 0.36, 0.085);

    drawBlob(Offset(w * 0.48, h * 0.32), w * 0.40, 0.065);

    drawBlob(Offset(w * -0.14, h * 0.42), w * 0.32, 0.075);

    drawBlob(Offset(w * 0.92, h * 0.38), w * 0.30, 0.055);

    drawBlob(Offset(w * 0.18, h * 0.62), w * 0.26, 0.05);

    drawBlob(Offset(w * 0.72, h * 0.68), w * 0.44, 0.09);

    drawBlob(Offset(w * -0.06, h * 1.05), w * 0.34, 0.07);

    drawBlob(Offset(w * 0.92, h * 1.02), w * 0.38, 0.068);

    drawBlob(Offset(w * 0.52, h * -0.08), w * 0.22, 0.045);

  }



  @override

  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

}


