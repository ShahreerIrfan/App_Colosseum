import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../data/models/itinerary_segment_model.dart';

/// Custom painter for rendering directional architectural walking itineraries with arrowheads.
class ItineraryPainter extends CustomPainter {
  final List<ItinerarySegmentModel> segments;
  final Color activeColor;
  final Color completedColor;

  const ItineraryPainter({
    required this.segments,
    required this.activeColor,
    required this.completedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;

    for (final segment in segments) {
      if (segment.points.length < 2) continue;

      final isCompleted = segment.isCompleted;
      final segmentColor = isCompleted ? completedColor : activeColor;

      // 1. Construct Path
      final path = Path();
      final firstPoint = Offset(
        segment.points.first.dx * size.width,
        segment.points.first.dy * size.height,
      );
      path.moveTo(firstPoint.dx, firstPoint.dy);

      for (int i = 1; i < segment.points.length; i++) {
        final currentPoint = Offset(
          segment.points[i].dx * size.width,
          segment.points[i].dy * size.height,
        );
        path.lineTo(currentPoint.dx, currentPoint.dy);
      }

      // 2. Outer Soft Glow
      final glowPaint = Paint()
        ..color = segmentColor.withValues(alpha: isCompleted ? 0.35 : 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, glowPaint);

      // 3. Main Itinerary Stroke
      final mainPaint = Paint()
        ..color = segmentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, mainPaint);

      // 4. Directional Walking Arrowheads along each sub-segment
      for (int i = 0; i < segment.points.length - 1; i++) {
        final pA = Offset(
          segment.points[i].dx * size.width,
          segment.points[i].dy * size.height,
        );
        final pB = Offset(
          segment.points[i + 1].dx * size.width,
          segment.points[i + 1].dy * size.height,
        );

        final distance = (pB - pA).distance;
        if (distance > 18.0) {
          final mid = Offset((pA.dx + pB.dx) / 2, (pA.dy + pB.dy) / 2);
          final angle = math.atan2(pB.dy - pA.dy, pB.dx - pA.dx);
          _drawArrowhead(canvas, mid, angle, segmentColor);
        }
      }
    }
  }

  void _drawArrowhead(Canvas canvas, Offset center, double angle, Color color) {
    const arrowLength = 7.5;
    const arrowWidth = 5.0;

    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    final tip = Offset(
      center.dx + (arrowLength * 0.5) * cosA,
      center.dy + (arrowLength * 0.5) * sinA,
    );

    final leftWing = Offset(
      tip.dx - arrowLength * cosA + arrowWidth * sinA,
      tip.dy - arrowLength * sinA - arrowWidth * cosA,
    );

    final rightWing = Offset(
      tip.dx - arrowLength * cosA - arrowWidth * sinA,
      tip.dy - arrowLength * sinA + arrowWidth * cosA,
    );

    final notch = Offset(
      tip.dx - (arrowLength * 0.65) * cosA,
      tip.dy - (arrowLength * 0.65) * sinA,
    );

    final arrowPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(leftWing.dx, leftWing.dy)
      ..lineTo(notch.dx, notch.dy)
      ..lineTo(rightWing.dx, rightWing.dy)
      ..close();

    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(arrowPath, arrowPaint);

    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(arrowPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant ItineraryPainter oldDelegate) =>
      oldDelegate.segments != segments ||
      oldDelegate.activeColor != activeColor ||
      oldDelegate.completedColor != completedColor;
}
