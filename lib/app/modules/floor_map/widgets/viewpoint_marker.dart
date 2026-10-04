import 'package:flutter/material.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../data/models/viewpoint_model.dart';

/// Interactive numbered viewpoint marker on the landmark floor plan.
class ViewpointMarker extends StatelessWidget {
  final ViewpointModel viewpoint;
  final bool isSelected;
  final bool isPlaying;
  final bool isTarget;
  final VoidCallback onTap;

  const ViewpointMarker({
    super.key,
    required this.viewpoint,
    required this.isSelected,
    this.isPlaying = false,
    this.isTarget = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final primaryColor = colors.primary;
    final isThreeDigits = viewpoint.order >= 100;
    final markerWidth = isThreeDigits
        ? (isSelected ? 42.0 : 34.0)
        : (isSelected ? 34.0 : 28.0);
    final markerHeight = isSelected ? 34.0 : 28.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Active / Now Playing Callout Badge above marker
          if (isSelected) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 4.0),
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 3.0,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPlaying) ...[
                    Container(
                      width: 6.0,
                      height: 6.0,
                      margin: const EdgeInsets.only(right: 5.0),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  Flexible(
                    child: Text(
                      isPlaying
                          ? 'Stop ${viewpoint.order} · Now Playing'
                          : (viewpoint.isVisited
                              ? 'Stop ${viewpoint.order} · Visited'
                              : 'Stop ${viewpoint.order}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Numbered Pin (circular or rounded pill for 3 digits)
          Stack(
            alignment: Alignment.center,
            children: [
              // Halo for active target or selected marker
              if (isSelected || isTarget)
                Container(
                  width: markerWidth + (isSelected ? 10.0 : 6.0),
                  height: markerHeight + (isSelected ? 10.0 : 6.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: primaryColor.withValues(
                      alpha: isSelected ? 0.22 : 0.14,
                    ),
                  ),
                ),

              // Main Marker Body
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: markerWidth,
                height: markerHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17.0),
                  color: isSelected
                      ? primaryColor
                      : (viewpoint.isVisited
                          ? primaryColor.withValues(alpha: 0.14)
                          : colors.card),
                  border: Border.all(
                    color: isSelected ? Colors.white : primaryColor,
                    width: isSelected ? 2.0 : 1.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 4.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '${viewpoint.order}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : primaryColor,
                    fontSize: isThreeDigits
                        ? (isSelected ? 11.0 : 10.5)
                        : (isSelected ? 13.0 : 12.0),
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),

              // Visited status corner indicator
              if (viewpoint.isVisited && !isSelected)
                Positioned(
                  top: -4.0,
                  right: -4.0,
                  child: Container(
                    width: 13.0,
                    height: 13.0,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.check_rounded,
                      size: 8.5,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
