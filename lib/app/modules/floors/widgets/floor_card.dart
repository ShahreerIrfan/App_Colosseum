import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../data/models/floor_model.dart';




/// Interactive floor card representing a level and its available viewpoints.
class FloorCard extends StatelessWidget {
  final FloorModel floor;
  final bool isSelected;
  final VoidCallback onTap;

  const FloorCard({
    super.key,
    required this.floor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    final cardBorderColor = isSelected ? colors.primary : colors.border;
    final cardBorderWidth = isSelected ? 1.8 : 1.0;
    final checkmarkColor = const Color(0xFF2E7D32); // Deep forest green matching wireframe annotation style

    return Semantics(
      label: '${floor.floorName}, ${floor.viewpointCount} viewpoints, ${isSelected ? 'selected' : 'unselected'}',
      button: true,
      selected: isSelected,
      child: Material(
        color: colors.card,
        borderRadius: BorderRadius.circular(26.0),
        elevation: isSelected ? 3 : 1,
        shadowColor: colors.foreground.withValues(alpha: isSelected ? 0.12 : 0.04),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26.0),
          splashColor: colors.primary.withValues(alpha: 0.08),
          highlightColor: colors.primary.withValues(alpha: 0.04),
          child: Container(
            constraints: const BoxConstraints(minHeight: 122.0),
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26.0),
              border: Border.all(
                color: cardBorderColor,
                width: cardBorderWidth,
              ),
            ),
            child: Stack(
              children: [
                // Left Column: Floor Title and Viewpoint Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Floor Title
                    Text(
                      floor.floorName,
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.foreground,
                        fontWeight: FontWeight.w700,
                        fontSize: 19.0,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 12.0),

                    // Viewpoint Count Badge + Indicator
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 5.0,
                          ),
                          decoration: BoxDecoration(
                            color: colors.secondary.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: colors.border.withValues(alpha: 0.6),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '${floor.viewpointCount} viewpoints',
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.secondaryForeground,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18.0,
                          color: colors.mutedForeground.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ],
                ),

                // Large Selection Checkmark (Positioned in upper center-right area)
                if (isSelected)
                  Positioned.fill(
                    child: Align(
                      alignment: const Alignment(0.35, -0.3),
                      child: Icon(
                        Icons.check_rounded,
                        size: 38.0,
                        color: checkmarkColor,
                      ),
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
