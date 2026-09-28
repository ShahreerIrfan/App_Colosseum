import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../data/models/poi_model.dart';

class PoiMarkerWidget extends StatelessWidget {
  final PoiModel poi;
  final bool isSelected;
  final VoidCallback onTap;
  final double currentZoom;

  const PoiMarkerWidget({
    super.key,
    required this.poi,
    required this.isSelected,
    required this.onTap,
    this.currentZoom = 16.5,
  });

  /// Calculates dynamic dimension based on zoom level
  double get _calculatedSize {
    final baseSize = poi.baseMarkerSize;
    if (currentZoom >= 17.5) {
      return baseSize * 1.35;
    } else if (currentZoom >= 16.0) {
      return baseSize;
    } else if (currentZoom >= 14.5) {
      return baseSize * 0.75;
    } else {
      return baseSize * 0.55;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = _calculatedSize;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Selected Landmark Label Badge
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.82),
                borderRadius: AppRadius.borderPill,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                poi.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ),

          // Landmark Illustration (Direct Transparent PNG)
          AnimatedScale(
            scale: isSelected ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: SizedBox(
              width: size,
              height: size,
              child: Image.asset(
                poi.assetPath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
