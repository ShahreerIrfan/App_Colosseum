import 'package:flutter/material.dart';

import '../../../data/models/landmark_marker_model.dart';

/// Styling tokens and dimension defaults for landmark location name badges (tooltips).
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

/// A compact, styled rounded-pill label badge (tooltip) displayed for the landmark.
/// If a landmark name has more than three words, it automatically formats across two lines.
/// Adapts padding and font sizing at lower zoom levels to eliminate badge overlap.
class LandmarkLabelBubble extends StatelessWidget {
  final LandmarkMarkerModel landmark;
  final bool isSelected;
  final double currentZoom;
  final LandmarkMarkerStyle style;

  const LandmarkLabelBubble({
    super.key,
    required this.landmark,
    this.isSelected = false,
    this.currentZoom = 16.5,
    this.style = const LandmarkMarkerStyle(),
  });

  /// Automatically breaks landmark names with more than 3 words into two lines.
  static String formatName(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length <= 3) {
      return name;
    }
    final mid = (words.length / 2).ceil();
    final line1 = words.sublist(0, mid).join(' ');
    final line2 = words.sublist(mid).join(' ');
    return '$line1\n$line2';
  }

  @override
  Widget build(BuildContext context) {
    final displayName = formatName(landmark.name);
    final isMultiLine = displayName.contains('\n');
    final isCompact = currentZoom < 15.8;

    // Distinct visual emphasis between default and selected states
    final backgroundColor = isSelected ? landmark.color : Colors.white;
    final textColor = isSelected ? Colors.white : const Color(0xFF1E293B);
    final borderColor = isSelected
        ? Colors.white.withValues(alpha: 0.95)
        : landmark.color.withValues(alpha: 0.55);

    final fontSize = isCompact
        ? (isSelected ? 10.5 : 10.0)
        : (isSelected ? style.selectedLabelFontSize : style.labelFontSize);

    final horizontalPadding = isCompact
        ? (isSelected ? 7.5 : 6.5)
        : (isSelected ? 9.5 : 8.0);

    final verticalPadding = isCompact
        ? (isMultiLine ? 3.0 : 2.0)
        : (isMultiLine ? 5.0 : 4.0);

    final dotSize = isCompact ? 5.5 : 7.0;

    return Container(
      constraints: BoxConstraints(maxWidth: isCompact ? 145 : 165),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
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
          // Color indicator dot in default state; checkmark in selected state
          if (!isSelected) ...[
            Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: landmark.color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: isCompact ? 4.0 : 5.0),
          ],
          Flexible(
            child: Text(
              displayName,
              maxLines: isMultiLine ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: 0.2,
                height: 1.15,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.check_circle_rounded,
              size: isCompact ? 11 : 12,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ],
        ],
      ),
    );
  }
}

/// Reusable marker widget rendering the location name badge (tooltip) directly
/// anchored at the landmark's geographic coordinates without the teardrop location pin.
/// Adapts displacement dynamically when zooming out to maintain zero badge collision.
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

  /// Calculates dynamic zoom-adaptive offset to prevent overlap as map zooms out.
  Offset get _effectiveOffset {
    if (landmark.labelOffset == Offset.zero) return Offset.zero;
    // When zooming out from default 16.5 down to 13.0, dynamically scale directional separation
    final zoomDelta = (16.5 - currentZoom).clamp(0.0, 3.5);
    final factor = 1.0 + (zoomDelta * 0.35);
    return Offset(
      landmark.labelOffset.dx * factor,
      landmark.labelOffset.dy * factor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: isSelected ? '${landmark.name}, selected' : landmark.name,
      button: true,
      child: GestureDetector(
        key: ValueKey('landmark_tap_${landmark.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Transform.translate(
            offset: _effectiveOffset,
            child: LandmarkLabelBubble(
              landmark: landmark,
              isSelected: isSelected,
              currentZoom: currentZoom,
              style: style,
            ),
          ),
        ),
      ),
    );
  }
}
