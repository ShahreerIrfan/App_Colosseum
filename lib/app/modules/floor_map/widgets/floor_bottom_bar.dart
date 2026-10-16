import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/theme_extensions.dart';

/// Navigation item model for the persistent bottom action/navigation bar.
class BottomNavItem {
  final Key? key;
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final String? semanticLabel;

  const BottomNavItem({
    this.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.isSelected = false,
    required this.onTap,
    this.semanticLabel,
  });
}

/// Reusable persistent bottom navigation / bottom action bar.
///
/// Designed to host extensible navigation options (Floor Selection, Map View, Tour, Audio, Info)
/// alongside live contextual indicators (Floor Completion Progress)
/// while maintaining the application's native theme, radius tokens, and elevation.
class FloorBottomBar extends StatelessWidget {
  final List<BottomNavItem> items;
  final Widget? trailing;
  final EdgeInsetsGeometry? margin;

  const FloorBottomBar({
    super.key,
    required this.items,
    this.trailing,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16.0),
      height: 56.0,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: AppRadius.borderXl,
        border: Border.all(
          color: colors.border,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.foreground.withValues(alpha: 0.08),
            blurRadius: 10.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: trailing != null && items.length == 1
            ? _buildSingleItemWithTrailing(context, items.first, trailing!)
            : trailing != null && items.length == 2
                ? _buildDualItemsWithTrailing(context, items[0], items[1], trailing!)
                : items.length == 1
                    ? _buildSingleItem(context, items.first)
                    : items.length == 2
                        ? _buildDualItems(context, items[0], items[1])
                        : _buildMultipleItems(context, items),
      ),
    );
  }

  Widget _buildSingleItem(BuildContext context, BottomNavItem item) {
    final colors = context.colors;

    return Semantics(
      label: item.semanticLabel ?? item.label,
      button: true,
      selected: item.isSelected,
      child: InkWell(
        key: item.key ?? const Key('floor_selection_bottom_button'),
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 38.0,
                height: 38.0,
                decoration: BoxDecoration(
                  color: item.isSelected
                      ? colors.primary.withValues(alpha: 0.16)
                      : colors.primary.withValues(alpha: 0.10),
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(
                    color: item.isSelected
                        ? colors.primary.withValues(alpha: 0.40)
                        : colors.primary.withValues(alpha: 0.18),
                    width: 1.0,
                  ),
                ),
                child: Icon(
                  item.icon,
                  size: 20.0,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 12.0),

              // Title and current floor subtitle
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.label,
                        maxLines: 1,
                        style: TextStyle(
                          color: colors.foreground,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 1.0),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.subtitle!,
                          maxLines: 1,
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Animated chevron indicator showing upward expansion
              Container(
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: item.isSelected
                      ? colors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.isSelected
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_up_rounded,
                  size: 22.0,
                  color: item.isSelected
                      ? colors.primary
                      : colors.foreground.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Segmented dual-action layout for [Floor Selection] and [Map View] without trailing
  Widget _buildDualItems(
    BuildContext context,
    BottomNavItem leftItem,
    BottomNavItem rightItem,
  ) {
    final colors = context.colors;

    return Row(
      children: [
        Expanded(
          child: _buildSegmentButton(context, leftItem, isLeft: true),
        ),
        Container(
          width: 1.0,
          height: 28.0,
          color: colors.border.withValues(alpha: 0.7),
        ),
        Expanded(
          child: _buildSegmentButton(context, rightItem, isRight: true),
        ),
      ],
    );
  }

  /// Segmented layout with [Floor Selection] taking maximum space and [Trailing Progress Indicator]
  Widget _buildSingleItemWithTrailing(
    BuildContext context,
    BottomNavItem item,
    Widget trailing,
  ) {
    final colors = context.colors;

    return Row(
      children: [
        // Left action button (Floor Selection) expanded to fill all available horizontal space
        Expanded(
          child: _buildFloorSelectionSegment(context, item),
        ),
        Container(
          width: 1.0,
          height: 28.0,
          color: colors.border.withValues(alpha: 0.65),
        ),

        // Compact trailing progress indicator pill
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Center(child: trailing),
        ),
      ],
    );
  }

  /// Segment button specifically tuned for Floor Selection when occupying the primary bar space,
  /// ensuring maximum room for the full floor display name.
  Widget _buildFloorSelectionSegment(BuildContext context, BottomNavItem item) {
    final colors = context.colors;

    return Semantics(
      label: item.semanticLabel ?? item.label,
      button: true,
      selected: item.isSelected,
      child: InkWell(
        key: item.key ?? const Key('floor_selection_bottom_button'),
        onTap: item.onTap,
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(AppRadius.xl),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          decoration: BoxDecoration(
            color: item.isSelected
                ? colors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(AppRadius.xl),
            ),
          ),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 34.0,
                height: 34.0,
                decoration: BoxDecoration(
                  color: item.isSelected
                      ? colors.primary.withValues(alpha: 0.16)
                      : colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: item.isSelected
                        ? colors.primary.withValues(alpha: 0.40)
                        : colors.primary.withValues(alpha: 0.18),
                    width: 1.0,
                  ),
                ),
                child: Icon(
                  item.icon,
                  size: 18.0,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 8.0),

              // Title and full floor name subtitle
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.label,
                        maxLines: 1,
                        style: TextStyle(
                          color: colors.foreground,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 1.0),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.subtitle!,
                          maxLines: 1,
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Animated chevron indicator showing upward expansion
              Container(
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: item.isSelected
                      ? colors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.isSelected
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_up_rounded,
                  size: 20.0,
                  color: item.isSelected
                      ? colors.primary
                      : colors.foreground.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Segmented layout with [Floor Selection], [Map View], and [Trailing Progress Indicator]
  Widget _buildDualItemsWithTrailing(
    BuildContext context,
    BottomNavItem leftItem,
    BottomNavItem middleItem,
    Widget trailing,
  ) {
    final colors = context.colors;

    return Row(
      children: [
        // Left action button (Floor Selection)
        Expanded(
          flex: 6,
          child: _buildSegmentButton(context, leftItem, isLeft: true),
        ),
        Container(
          width: 1.0,
          height: 28.0,
          color: colors.border.withValues(alpha: 0.65),
        ),

        // Middle action button (Map View)
        Expanded(
          flex: 5,
          child: _buildSegmentButton(context, middleItem),
        ),
        Container(
          width: 1.0,
          height: 28.0,
          color: colors.border.withValues(alpha: 0.65),
        ),

        // Right progress pill (Completed: 2/7)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Center(child: trailing),
        ),
      ],
    );
  }

  Widget _buildSegmentButton(
    BuildContext context,
    BottomNavItem item, {
    bool isLeft = false,
    bool isRight = false,
  }) {
    final colors = context.colors;

    return Semantics(
      label: item.semanticLabel ?? item.label,
      button: true,
      selected: item.isSelected,
      child: InkWell(
        key: item.key,
        onTap: item.onTap,
        borderRadius: BorderRadius.horizontal(
          left: isLeft ? Radius.circular(AppRadius.xl) : Radius.zero,
          right: isRight ? Radius.circular(AppRadius.xl) : Radius.zero,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          decoration: BoxDecoration(
            color: item.isSelected
                ? colors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.horizontal(
              left: isLeft ? Radius.circular(AppRadius.xl) : Radius.zero,
              right: isRight ? Radius.circular(AppRadius.xl) : Radius.zero,
            ),
          ),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 28.0,
                height: 28.0,
                decoration: BoxDecoration(
                  color: item.isSelected
                      ? colors.primary.withValues(alpha: 0.16)
                      : colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(7.0),
                  border: Border.all(
                    color: item.isSelected
                        ? colors.primary.withValues(alpha: 0.40)
                        : colors.primary.withValues(alpha: 0.18),
                    width: 1.0,
                  ),
                ),
                child: Icon(
                  item.icon,
                  size: 15.0,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 6.0),

              // Title and Subtitle
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.foreground,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 1.0),
                      Text(
                        item.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10.0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Indicator chevron
              Icon(
                item.isSelected
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_up_rounded,
                size: 16.0,
                color: item.isSelected
                    ? colors.primary
                    : colors.foreground.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultipleItems(BuildContext context, List<BottomNavItem> items) {
    final colors = context.colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: items.map((item) {
        return Expanded(
          child: Semantics(
            label: item.semanticLabel ?? item.label,
            button: true,
            selected: item.isSelected,
            child: InkWell(
              key: item.key,
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 20.0,
                      color: item.isSelected
                          ? colors.primary
                          : colors.foreground.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      item.label,
                      style: TextStyle(
                        color:
                            item.isSelected ? colors.primary : colors.foreground,
                        fontWeight:
                            item.isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 11.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
