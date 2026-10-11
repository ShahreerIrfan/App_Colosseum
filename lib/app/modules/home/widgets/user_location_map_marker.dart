import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Clean Google Maps style user location marker for FlutterMap.
/// Features a high-contrast glowing blue navigation dot with accuracy halo
/// and an optional directional heading arrow pointing in the user's facing direction.
class UserLocationMapMarker extends StatelessWidget {
  final double? headingDegrees;
  final Color puckColor;

  const UserLocationMapMarker({
    super.key,
    this.headingDegrees,
    this.puckColor = const Color(0xFF00A6FF),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44.0,
      height: 44.0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Semi-translucent accuracy halo
          Container(
            width: 44.0,
            height: 44.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: puckColor.withValues(alpha: 0.20),
            ),
          ),

          // 2. Directional heading pointer (if heading is known)
          if (headingDegrees != null)
            Transform.rotate(
              angle: (headingDegrees! * math.pi) / 180.0,
              child: CustomPaint(
                size: const Size(44.0, 44.0),
                painter: _HeadingPointerPainter(color: puckColor),
              ),
            ),

          // 3. Central bright location dot with white border & shadow
          Container(
            width: 16.0,
            height: 16.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: puckColor,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.30),
                  blurRadius: 4.0,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeadingPointerPainter extends CustomPainter {
  final Color color;

  const _HeadingPointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Directional arrow tip pointing forward (upward)
    final arrowPath = Path()
      ..moveTo(center.dx, center.dy - 18.0)
      ..lineTo(center.dx + 5.0, center.dy - 8.0)
      ..lineTo(center.dx, center.dy - 10.0)
      ..lineTo(center.dx - 5.0, center.dy - 8.0)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(arrowPath, borderPaint);
    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(covariant _HeadingPointerPainter oldDelegate) =>
      oldDelegate.color != color;
}
