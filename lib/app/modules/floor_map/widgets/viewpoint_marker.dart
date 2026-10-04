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
    // Fixed dimensions ensure the pin center NEVER shifts when selected or played
    final markerWidth = isThreeDigits ? 38.0 : 30.0;
    final markerHeight = 30.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: SizedBox(
          width: 48.0,
          height: 48.0,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Halo for active target or selected / playing marker
              if (isSelected || isTarget)
                Container(
                  width: markerWidth + (isSelected ? 10.0 : 6.0),
                  height: markerHeight + (isSelected ? 10.0 : 6.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: isPlaying
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.28)
                        : primaryColor.withValues(
                            alpha: isSelected ? 0.25 : 0.14,
                          ),
                  ),
                ),

              // Main Marker Body - Anchored perfectly at the exact center (0, 0)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: markerWidth,
                height: markerHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  color: isSelected
                      ? (isPlaying ? const Color(0xFF2E7D32) : primaryColor)
                      : (viewpoint.isVisited
                          ? primaryColor.withValues(alpha: 0.14)
                          : colors.card),
                  border: Border.all(
                    color: isPlaying
                        ? const Color(0xFF4CAF50)
                        : (isSelected ? Colors.white : primaryColor),
                    width: isSelected ? 2.0 : 1.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isSelected ? 0.25 : 0.18),
                      blurRadius: isSelected ? 6.0 : 4.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '${viewpoint.order}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : primaryColor,
                    fontSize: isThreeDigits ? 10.5 : 12.0,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),

              // Visited status corner indicator
              if (viewpoint.isVisited && !isSelected)
                Positioned(
                  top: 4.0,
                  right: 2.0,
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
        ),
      ),
    );
  }
}
