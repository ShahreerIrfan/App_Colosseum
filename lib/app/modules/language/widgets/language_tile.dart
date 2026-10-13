import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/theme_extensions.dart';

/// Language list item styled after the client design, supporting Light Mode tokens.
class LanguageTile extends StatelessWidget {
  const LanguageTile({
    super.key,
    required this.title,
    required this.nativeName,
    required this.subtitle,
    required this.flag,
    required this.isSelected,
    this.isAvailable = true,
    required this.onTap,
  });

  final String title;
  final String nativeName;
  final String subtitle;
  final String flag;
  final bool isSelected;
  final bool isAvailable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: isSelected
            ? colors.secondary
            : (isAvailable
                ? colors.card
                : colors.card.withValues(alpha: 0.65)),
        borderRadius: AppRadius.borderLg,
        child: InkWell(
          borderRadius: AppRadius.borderLg,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            decoration: BoxDecoration(
              borderRadius: AppRadius.borderLg,
              border: Border.all(
                color: isSelected
                    ? colors.primary
                    : (isAvailable
                        ? colors.border
                        : colors.border.withValues(alpha: 0.5)),
                width: isSelected ? 1.5 : 0.8,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.08),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Circular Flag Container
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? colors.card
                        : (isAvailable
                            ? colors.background
                            : colors.background.withValues(alpha: 0.6)),
                    border: Border.all(
                      color: isSelected
                          ? colors.primary.withValues(alpha: 0.4)
                          : colors.border.withValues(alpha: 0.45),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    flag,
                    style: const TextStyle(fontSize: 19),
                  ),
                ),
                const SizedBox(width: 12),
                // Language Name & Native Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          color: colors.foreground,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              nativeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: isSelected
                                    ? colors.primary
                                    : (isAvailable
                                        ? colors.mutedForeground
                                        : colors.mutedForeground
                                            .withValues(alpha: 0.7)),
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (subtitle.isNotEmpty)
                            Flexible(
                              child: Text(
                                ' • $subtitle',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  color: isSelected
                                      ? colors.primary
                                      : (isAvailable
                                          ? colors.mutedForeground
                                          : colors.mutedForeground
                                              .withValues(alpha: 0.7)),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Trailing Status Badge
                if (isAvailable) ...[
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: colors.primary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Active',
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Icon(
                      Icons.radio_button_unchecked_rounded,
                      color: colors.mutedForeground.withValues(alpha: 0.5),
                      size: 20,
                    ),
                ] else ...[
                  // Coming Soon Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: colors.secondary.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colors.border.withValues(alpha: 0.7),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: colors.mutedForeground.withValues(alpha: 0.75),
                          size: 11,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Coming Soon',
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.mutedForeground.withValues(alpha: 0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
