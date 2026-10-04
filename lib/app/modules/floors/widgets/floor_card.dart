import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../data/models/floor_model.dart';

/// Reusable interactive floor card representing a level and its available viewpoints.
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

    final cardBorderColor =
        isSelected ? colors.primary : colors.border.withValues(alpha: 0.7);
    final cardBorderWidth = isSelected ? 1.8 : 1.0;
    final cardBgColor = isSelected
        ? Color.alphaBlend(colors.primary.withValues(alpha: 0.04), colors.card)
        : colors.card;

    return Semantics(
      label:
          '${floor.floorName}, ${floor.viewpointCount} viewpoints, completed: ${floor.completedCount}${isSelected ? ', current floor' : ''}${floor.isCompleted ? ', completed' : ''}',
      button: true,
      selected: isSelected,
      child: Material(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16.0),
        elevation: isSelected ? 2 : 0,
        shadowColor: colors.primary.withValues(alpha: isSelected ? 0.12 : 0.03),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
          splashColor: colors.primary.withValues(alpha: 0.08),
          highlightColor: colors.primary.withValues(alpha: 0.04),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: cardBorderColor,
                width: cardBorderWidth,
              ),
            ),
            child: Row(
              children: [
                // Left Column: Floor Title, Viewpoint Badge, and Completed Count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Floor Title
                      Text(
                        floor.floorName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          color: colors.foreground,
                          fontWeight: FontWeight.w700,
                          fontSize: 18.0,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 8.0),

                      // Viewpoint Count Badge & Completed Count Badge
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 6.0,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color: colors.secondary.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(6.0),
                              border: Border.all(
                                color: colors.border.withValues(alpha: 0.5),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '${floor.viewpointCount} viewpoints',
                              style: textTheme.labelSmall?.copyWith(
                                color: colors.secondaryForeground,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.0,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color: floor.isCompleted
                                  ? const Color(0xFF2E7D32).withValues(alpha: 0.10)
                                  : (floor.completedCount > 0
                                      ? colors.primary.withValues(alpha: 0.10)
                                      : colors.secondary.withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(6.0),
                              border: Border.all(
                                color: floor.isCompleted
                                    ? const Color(0xFF2E7D32).withValues(alpha: 0.28)
                                    : (floor.completedCount > 0
                                        ? colors.primary.withValues(alpha: 0.25)
                                        : colors.border.withValues(alpha: 0.5)),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (floor.isCompleted) ...[
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 13.0,
                                    color: Color(0xFF2E7D32),
                                  ),
                                  const SizedBox(width: 4.0),
                                ],
                                Text(
                                  floor.isCompleted
                                      ? 'Completed'
                                      : 'completed: ${floor.completedCount}',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: floor.isCompleted
                                        ? const Color(0xFF2E7D32)
                                        : (floor.completedCount > 0
                                            ? colors.primary
                                            : colors.mutedForeground),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11.5,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Linear Progress Bar
                      if (floor.viewpointCount > 0) ...[
                        const SizedBox(height: 9.0),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2.0),
                          child: SizedBox(
                            height: 3.5,
                            child: LinearProgressIndicator(
                              value: floor.progress,
                              backgroundColor: colors.border.withValues(alpha: 0.35),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                floor.isCompleted
                                    ? const Color(0xFF2E7D32)
                                    : colors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 12.0),

                // Right side: Integrated Status Indicator + Chevron
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Container(
                        width: 26.0,
                        height: 26.0,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.25),
                            width: 1.0,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.check_rounded,
                            size: 16.0,
                            color: colors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                    ],
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 22.0,
                      color: isSelected
                          ? colors.primary
                          : colors.mutedForeground.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
