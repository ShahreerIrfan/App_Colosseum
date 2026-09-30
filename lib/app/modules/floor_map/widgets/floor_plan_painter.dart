import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// High-fidelity top-down architectural floor plan painter for Colosseum Level 1.
class FloorPlanPainter extends CustomPainter {
  final AppColors colors;
  final bool isUnderground;

  const FloorPlanPainter({
    required this.colors,
    this.isUnderground = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final maxR = math.min(size.width, size.height) * 0.44;

    // 1. Outer Floor boundary fill (subtle stone/pavement tone)
    final outerPath = Path();
    outerPath.addOval(
      Rect.fromCenter(
        center: center,
        width: maxR * 2.05,
        height: maxR * 1.76,
      ),
    );

    final floorFillPaint = Paint()
      ..color = colors.secondary.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawPath(outerPath, floorFillPaint);

    // 2. Ambulatory Walkway ring fill (accentuated corridor for navigation)
    final walkwayPaint = Paint()
      ..color = colors.card
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: maxR * 1.95,
        height: maxR * 1.66,
      ),
      walkwayPaint,
    );

    // 3. Middle Tier / Cavea fill
    final caveaFillPaint = Paint()
      ..color = colors.secondary.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: maxR * 1.55,
        height: maxR * 1.28,
      ),
      caveaFillPaint,
    );

    // 4. Central Arena Floor / Hypogeum outline
    final arenaFillPaint = Paint()
      ..color = colors.card
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: maxR * 0.96,
        height: maxR * 0.68,
      ),
      arenaFillPaint,
    );

    // 5. Architectural Wall Strokes
    final outerWallPaint = Paint()
      ..color = colors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final innerWallPaint = Paint()
      ..color = colors.border.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final detailWallPaint = Paint()
      ..color = colors.border.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw outer elliptical boundary wall
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: maxR * 2.05,
        height: maxR * 1.76,
      ),
      outerWallPaint,
    );

    // Draw 2nd annular wall
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: maxR * 1.75,
        height: maxR * 1.46,
      ),
      innerWallPaint,
    );

    // Draw 3rd annular wall (podium boundary)
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: maxR * 1.25,
        height: maxR * 0.98,
      ),
      innerWallPaint,
    );

    // Draw arena perimeter wall
    final arenaWallPaint = Paint()
      ..color = colors.primary.withValues(alpha: isUnderground ? 0.85 : 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isUnderground ? 2.8 : 2.2;
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: maxR * 0.96,
        height: maxR * 0.68,
      ),
      arenaWallPaint,
    );

    // 6. Radial Pillars & Vomitoria (Radial structural arches)
    final radialPaint = Paint()
      ..color = colors.border.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const numRadialWalls = 24;
    for (int i = 0; i < numRadialWalls; i++) {
      final angle = (i * 2 * math.pi) / numRadialWalls;
      final cosA = math.cos(angle);
      final sinA = math.sin(angle);

      final p1 = Offset(
        center.dx + cosA * (maxR * 1.02),
        center.dy + sinA * (maxR * 0.88),
      );
      final p2 = Offset(
        center.dx + cosA * (maxR * 0.87),
        center.dy + sinA * (maxR * 0.73),
      );
      canvas.drawLine(p1, p2, radialPaint);

      final p3 = Offset(
        center.dx + cosA * (maxR * 0.77),
        center.dy + sinA * (maxR * 0.64),
      );
      final p4 = Offset(
        center.dx + cosA * (maxR * 0.62),
        center.dy + sinA * (maxR * 0.49),
      );
      canvas.drawLine(p3, p4, detailWallPaint);
    }

    // 7. Hypogeum (Subterranean central chamber grid & Corridor H)
    final hypogeumPaint = Paint()
      ..color = isUnderground
          ? colors.primary.withValues(alpha: 0.7)
          : colors.border.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isUnderground ? 1.8 : 1.0;

    // Longitudinal central axis (Corridor H)
    canvas.drawLine(
      Offset(center.dx - maxR * 0.45, center.dy),
      Offset(center.dx + maxR * 0.45, center.dy),
      hypogeumPaint,
    );

    // Transverse corridors and hoist shafts
    for (double offset = -0.32; offset <= 0.33; offset += 0.16) {
      final h = math.sqrt(math.max(0, 1 - math.pow(offset / 0.45, 2))) * maxR * 0.3;
      canvas.drawLine(
        Offset(center.dx + offset * maxR, center.dy - h),
        Offset(center.dx + offset * maxR, center.dy + h),
        hypogeumPaint,
      );
    }

    // 8. North Entrance & Imperial Tribune accents
    final entranceAccentPaint = Paint()
      ..color = colors.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    // North imperial entrance
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy - maxR * 0.88),
          width: 24,
          height: 14,
        ),
        const Radius.circular(3),
      ),
      entranceAccentPaint,
    );

    // South imperial box
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + maxR * 0.88),
          width: 24,
          height: 14,
        ),
        const Radius.circular(3),
      ),
      entranceAccentPaint,
    );

    // Subtle arena / hypogeum label in center
    final labelText = isUnderground ? 'HYPOGEUM · CORRIDOR H' : 'ARENA FLOOR';
    final textPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: TextStyle(
          color: colors.foreground.withValues(alpha: isUnderground ? 0.45 : 0.32),
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2 - (isUnderground ? 14.0 : 0.0),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant FloorPlanPainter oldDelegate) =>
      oldDelegate.colors != colors ||
      oldDelegate.isUnderground != isUnderground;
}
