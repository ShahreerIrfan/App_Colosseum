import 'package:flutter/material.dart';

import '../../../data/models/landmark_marker_model.dart';

/// Styling tokens and dimension defaults for landmark map pins and labels.
class LandmarkMarkerStyle {
  final double defaultPinWidth;
  final double defaultPinHeight;
  final double selectedPinWidth;
  final double selectedPinHeight;
  final double labelFontSize;
  final double selectedLabelFontSize;
  final double borderRadius;
  final double elevation;

  const LandmarkMarkerStyle({
    this.defaultPinWidth = 28.0,
    this.defaultPinHeight = 38.0,
    this.selectedPinWidth = 34.0,
    this.selectedPinHeight = 44.0,
    this.labelFontSize = 11.5,
    this.selectedLabelFontSize = 12.0,
    this.borderRadius = 12.0,
    this.elevation = 3.0,
  });
}

/// Custom painter rendering a classic Google Maps–style teardrop location pin.
///
/// Features:
/// - Vertically oriented teardrop with rounded circular head and pointed tip
/// - Crisp white outer contrast border ensuring legibility over any map tile
/// - Inner white circle with color-matched center dot
/// - Soft drop shadow and selected glow effect
class ClassicMapPinPainter extends CustomPainter {
  final Color pinColor;
  final bool isSelected;
  final Color borderColor;

  const ClassicMapPinPainter({
    required this.pinColor,
    this.isSelected = false,
    this.borderColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w / 2;
    final tipY = h - 1.5;

    final path = Path();
    // Start at pointed bottom tip
    path.moveTo(w / 2, tipY);
    // Left curve sweeping up to circular head
    path.cubicTo(
      w * 0.08,
      tipY * 0.65,
      0,
      r * 1.18,
      0,
      r,
    );
    // Top circle arc
    path.arcToPoint(
      Offset(w, r),
      radius: Radius.circular(r),
      clockwise: true,
    );
    // Right curve sweeping back down to pointed tip
    path.cubicTo(
      w,
      r * 1.18,
      w * 0.92,
      tipY * 0.65,
      w / 2,
      tipY,
    );
    path.close();

    // 1. Subtle drop shadow
    final shadowPath = path.shift(const Offset(0, 1.5));
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isSelected ? 0.35 : 0.22)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isSelected ? 4.0 : 2.5);
    canvas.drawPath(shadowPath, shadowPaint);

    // 2. Active glow when selected
    if (isSelected) {
      final glowPaint = Paint()
        ..color = pinColor.withValues(alpha: 0.40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
      canvas.drawPath(path, glowPaint);
    }

    // 3. Pin body fill
    final fillPaint = Paint()
      ..color = pinColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawPath(path, fillPaint);

    // 4. Outer contrast border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.5
      ..isAntiAlias = true;
    canvas.drawPath(path, borderPaint);

    // 5. Classic inner white circular core
    final innerCircleRadius = r * 0.42;
    final innerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(w / 2, r), innerCircleRadius, innerCirclePaint);

    // 6. Color-matched center dot inside the core
    final coreDotPaint = Paint()
      ..color = pinColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(w / 2, r), r * 0.20, coreDotPaint);
  }

  @override
  bool shouldRepaint(covariant ClassicMapPinPainter oldDelegate) =>
      oldDelegate.pinColor != pinColor ||
      oldDelegate.isSelected != isSelected ||
      oldDelegate.borderColor != borderColor;
}

/// A compact, styled rounded-pill label bubble displayed above the location pin.
class LandmarkLabelBubble extends StatelessWidget {
  final LandmarkMarkerModel landmark;
  final bool isSelected;
  final LandmarkMarkerStyle style;

  const LandmarkLabelBubble({
    super.key,
    required this.landmark,
    this.isSelected = false,
    this.style = const LandmarkMarkerStyle(),
  });

  @override
  Widget build(BuildContext context) {
    // Distinct visual emphasis between default and selected states
    final backgroundColor = isSelected ? landmark.color : Colors.white;
    final textColor = isSelected ? Colors.white : const Color(0xFF1E293B);
    final borderColor = isSelected
        ? Colors.white.withValues(alpha: 0.90)
        : landmark.color.withValues(alpha: 0.55);

    return Container(
      constraints: const BoxConstraints(maxWidth: 155),
      padding: EdgeInsets.symmetric(
        horizontal: isSelected ? 9.0 : 7.5,
        vertical: isSelected ? 3.5 : 2.5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(style.borderRadius),
        border: Border.all(
          color: borderColor,
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? landmark.color.withValues(alpha: 0.45)
                : Colors.black.withValues(alpha: 0.18),
            blurRadius: isSelected ? 8.0 : 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Color indicator dot in default state; star/icon in selected state
          if (!isSelected) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: landmark.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              landmark.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: isSelected
                    ? style.selectedLabelFontSize
                    : style.labelFontSize,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: 0.2,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.check_circle_rounded,
              size: 11,
              color: Colors.white.withValues(alpha: 0.90),
            ),
          ],
        ],
      ),
    );
  }
}

/// Reusable composite marker widget attaching a styled label bubble above
/// a classic Google Maps–style teardrop pin.
///
/// Anchoring Guarantee:
/// The widget aligns to [Alignment.bottomCenter] so that the pointed bottom tip
/// of the teardrop pin aligns precisely with the marker's geographic coordinate.
class LandmarkMapMarker extends StatelessWidget {
  final LandmarkMarkerModel landmark;
  final bool isSelected;
  final VoidCallback? onTap;
  final double currentZoom;
  final LandmarkMarkerStyle style;

  const LandmarkMapMarker({
    super.key,
    required this.landmark,
    this.isSelected = false,
    this.onTap,
    this.currentZoom = 16.5,
    this.style = const LandmarkMarkerStyle(),
  });

  @override
  Widget build(BuildContext context) {
    final pinWidth = isSelected ? style.selectedPinWidth : style.defaultPinWidth;
    final pinHeight =
        isSelected ? style.selectedPinHeight : style.defaultPinHeight;

    // Zoom-dependent label visibility: labels stay visible at standard tour zoom (>= 13.8)
    // or when the landmark is actively selected.
    final showLabel = currentZoom >= 13.8 || isSelected;

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: isSelected ? '${landmark.name}, selected' : landmark.name,
      button: true,
      child: GestureDetector(
        key: ValueKey('landmark_tap_${landmark.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Transform.translate(
            offset: landmark.labelOffset,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showLabel) ...[
                  LandmarkLabelBubble(
                    landmark: landmark,
                    isSelected: isSelected,
                    style: style,
                  ),
                  const SizedBox(height: 2.5),
                ],
                // Classic teardrop location pin
                CustomPaint(
                  key: ValueKey('landmark_pin_${landmark.id}'),
                  size: Size(pinWidth, pinHeight),
                  painter: ClassicMapPinPainter(
                    pinColor: landmark.color,
                    isSelected: isSelected,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
