import 'package:flutter/material.dart';

/// Custom painter for rendering a walking route between user location and active viewpoint.
class RoutePainter extends CustomPainter {
  final List<Offset> normalizedPoints;
  final Color routeColor;

  const RoutePainter({
    required this.normalizedPoints,
    required this.routeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (normalizedPoints.length < 2) return;

    final path = Path();
    final first = Offset(
      normalizedPoints.first.dx * size.width,
      normalizedPoints.first.dy * size.height,
    );
    path.moveTo(first.dx, first.dy);

    for (int i = 1; i < normalizedPoints.length; i++) {
      final p = Offset(
        normalizedPoints[i].dx * size.width,
        normalizedPoints[i].dy * size.height,
      );
      path.lineTo(p.dx, p.dy);
    }

    // Outer subtle glow
    final glowPaint = Paint()
      ..color = routeColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, glowPaint);

    // Main route line (dashed/solid with round joints)
    final mainPaint = Paint()
      ..color = routeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, mainPaint);
  }

  @override
  bool shouldRepaint(covariant RoutePainter oldDelegate) =>
      oldDelegate.normalizedPoints != normalizedPoints ||
      oldDelegate.routeColor != routeColor;
}
