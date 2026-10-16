import 'package:flutter/material.dart';

import '../../../core/theme/theme_extensions.dart';

/// Compact, responsive viewpoint completion progress indicator pill designed
/// for the persistent bottom bar of the Colosseum floor map screen.
class FloorProgressIndicator extends StatelessWidget {
  final int completedCount;
  final int totalCount;
  final double progressRatio;
  final bool isCompleted;
  final String text;
  final String? semanticLabel;

  const FloorProgressIndicator({
    super.key,
    required this.completedCount,
    required this.totalCount,
    required this.progressRatio,
    required this.isCompleted,
    required this.text,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final successColor = const Color(0xFF10B981); // Emerald green
    final effectiveAccentColor = isCompleted ? successColor : colors.primary;

    return Semantics(
      label: semanticLabel ?? text,
      readOnly: true,
      child: Container(
        key: const Key('floor_progress_indicator'),
        padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 4.5),
        decoration: BoxDecoration(
          color: isCompleted
              ? successColor.withValues(alpha: 0.10)
              : colors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isCompleted
                ? successColor.withValues(alpha: 0.35)
                : colors.border.withValues(alpha: 0.60),
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Icon + Text row
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.task_alt_rounded,
                  size: 12.0,
                  color: effectiveAccentColor,
                ),
                const SizedBox(width: 3.5),
                Flexible(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: Text(
                      text,
                      key: ValueKey(text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCompleted
                            ? successColor
                            : colors.foreground,
                        fontWeight: FontWeight.w800,
                        fontSize: 10.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2.5),

            // Micro progress track bar
            ClipRRect(
              borderRadius: BorderRadius.circular(2.0),
              child: SizedBox(
                width: 48.0,
                height: 2.5,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0.0, end: progressRatio),
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      backgroundColor: colors.border.withValues(alpha: 0.45),
                      valueColor: AlwaysStoppedAnimation<Color>(effectiveAccentColor),
                      minHeight: 2.5,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
