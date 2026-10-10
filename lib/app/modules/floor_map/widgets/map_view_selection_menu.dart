import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../data/models/map_view_type.dart';

/// Compact floating map view selection menu card anchored above the bottom action bar.
class MapViewSelectionMenu extends StatelessWidget {
  final MapViewType activeViewType;
  final ValueChanged<MapViewType> onSelectMapView;
  final VoidCallback onClose;

  const MapViewSelectionMenu({
    super.key,
    required this.activeViewType,
    required this.onSelectMapView,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(
          color: colors.border,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.foreground.withValues(alpha: 0.12),
            blurRadius: 18.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 10.0, 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.map_rounded,
                  size: 16.0,
                  color: colors.primary,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Select map view',
                  style: TextStyle(
                    color: colors.foreground,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                Semantics(
                  label: 'Close map view menu',
                  button: true,
                  child: InkWell(
                    key: const Key('close_map_view_menu_button'),
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(12.0),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18.0,
                        color: colors.foreground.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1.0,
            thickness: 1.0,
            color: colors.border.withValues(alpha: 0.5),
          ),

          // Vertical Map View Options List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: MapViewType.values.map((type) {
                final isSelected = type == activeViewType;

                return _MapViewMenuRow(
                  key: Key('map_view_item_${type.name}'),
                  type: type,
                  isSelected: isSelected,
                  onTap: () => onSelectMapView(type),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapViewMenuRow extends StatelessWidget {
  final MapViewType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _MapViewMenuRow({
    super.key,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final icon = type == MapViewType.satellite
        ? Icons.satellite_alt_rounded
        : Icons.map_outlined;

    return Semantics(
      label: isSelected
          ? '${type.displayName}, selected map view'
          : type.displayName,
      button: true,
      selected: isSelected,
      child: Container(
        height: 52.0,
        margin: const EdgeInsets.symmetric(vertical: 2.0),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.09)
              : Colors.transparent,
          borderRadius: AppRadius.borderMd,
          border: isSelected
              ? Border.all(
                  color: colors.primary.withValues(alpha: 0.35),
                  width: 1.0,
                )
              : Border.all(color: Colors.transparent, width: 1.0),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.borderMd,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  // Icon badge
                  Container(
                    width: 32.0,
                    height: 32.0,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary.withValues(alpha: 0.16)
                          : colors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      icon,
                      size: 17.0,
                      color: isSelected
                          ? colors.primary
                          : colors.foreground.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 12.0),

                  // Map View Title and Subtitle
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected
                                ? colors.primary
                                : colors.foreground,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            fontSize: 13.5,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 1.5),
                        Text(
                          type.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.foreground.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w500,
                            fontSize: 11.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Active checkmark indicator
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 16.0,
                        color: colors.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
