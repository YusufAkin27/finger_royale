import 'dart:math';
import 'package:flutter/material.dart';

class CheaterArrow extends StatelessWidget {
  final Offset centerPosition;
  final Offset cheaterPosition;
  final Animation<double> animation;

  const CheaterArrow({
    super.key,
    required this.centerPosition,
    required this.cheaterPosition,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate angle between center and cheater position
    final dx = cheaterPosition.dx - centerPosition.dx;
    final dy = cheaterPosition.dy - centerPosition.dy;
    final angle = atan2(dy, dx);

    // Calculate animation values
    final animatedSize = 50.0 + (20.0 * animation.value);
    final animatedOpacity = 0.7 * animation.value;

    return Positioned(
      left: centerPosition.dx - animatedSize / 2,
      top: centerPosition.dy - animatedSize / 2,
      child: Transform.rotate(
        angle: angle,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Opacity(
              opacity: animatedOpacity,
              child: Container(
                width: animatedSize,
                height: animatedSize,
                decoration: const BoxDecoration(color: Colors.transparent),
                child: CustomPaint(
                  painter: ArrowPainter(Colors.red),
                  size: Size(animatedSize, animatedSize),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ArrowPainter extends CustomPainter {
  final Color color;

  ArrowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill
          ..strokeWidth = 4.0;

    final path = Path();
    // Arrow shaft
    path.moveTo(0, size.height / 2);
    path.lineTo(size.width * 0.7, size.height / 2);

    // Arrow head
    path.lineTo(size.width * 0.7, size.height * 0.2);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width * 0.7, size.height * 0.8);
    path.lineTo(size.width * 0.7, size.height / 2);

    // Close the path
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ArrowPainter oldDelegate) => color != oldDelegate.color;
}
