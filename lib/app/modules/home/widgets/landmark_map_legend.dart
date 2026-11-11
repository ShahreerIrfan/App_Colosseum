import '../../../core/localization/tour_localizations.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../data/models/landmark_marker_model.dart';

/// Architecture-ready legend component displaying the color-coding system for landmarks.
class LandmarkMapLegend extends StatelessWidget {
  final List<LandmarkMarkerModel> landmarks;
  final String? selectedLandmarkId;
  final ValueChanged<String>? onLandmarkSelected;

  const LandmarkMapLegend({
    super.key,
    required this.landmarks,
    this.selectedLandmarkId,
    this.onLandmarkSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.95),
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.foreground.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Landmarks'.tourText,
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 6),
          ...landmarks.map((landmark) {
            final isSelected = landmark.id == selectedLandmarkId;
            return InkWell(
              onTap: () => onLandmarkSelected?.call(landmark.id),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: landmark.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black87 : Colors.transparent,
                          width: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      landmark.name,
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? colors.primary : colors.foreground,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
