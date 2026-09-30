import 'package:flutter/material.dart';

import '../../../core/theme/theme_extensions.dart';

/// Custom painter for rendering a modern teardrop map pointer pin.
class MapPinPainter extends CustomPainter {
  final Color pinColor;
  final Color borderColor;

  const MapPinPainter({
    required this.pinColor,
    this.borderColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final radius = w / 2;

    final path = Path();
    // Start at bottom tip
    path.moveTo(w / 2, h);
    // Left curve leading up to circle
    path.cubicTo(
      w * 0.08,
      h * 0.65,
      0,
      radius * 1.15,
      0,
      radius,
    );
    // Top circle arc
    path.arcToPoint(
      Offset(w, radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    // Right curve leading back down to bottom tip
    path.cubicTo(
      w,
      radius * 1.15,
      w * 0.92,
      h * 0.65,
      w / 2,
      h,
    );
    path.close();

    // Subtle drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.save();
    canvas.translate(0, 2);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Fill pin background
    final fillPaint = Paint()
      ..color = pinColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawPath(path, fillPaint);

    // Outer border for contrast on any map tile
    final borderPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant MapPinPainter oldDelegate) =>
      oldDelegate.pinColor != pinColor || oldDelegate.borderColor != borderColor;
}

/// A standalone UI map marker with a label above and a numbered pin below.
class MapMarkerWidget extends StatelessWidget {
  final String label;
  final String number;
  final VoidCallback? onTap;

  const MapMarkerWidget({
    super.key,
    required this.label,
    required this.number,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pinColor = colors.primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Label above the marker
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Numbered Pin
            CustomPaint(
              size: const Size(34, 44),
              painter: MapPinPainter(pinColor: pinColor),
              child: SizedBox(
                width: 34,
                height: 44,
                child: Align(
                  alignment: const Alignment(0.0, -0.45),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      number,
                      style: TextStyle(
                        color: pinColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.none,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );


  }
}
