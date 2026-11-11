import '../../../core/localization/tour_localizations.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../data/models/floor_definition.dart';

/// Compact floating floor selection menu card anchored above the bottom menu bar.
class FloorSelectionMenu extends StatelessWidget {
  final List<FloorDefinition> floors;
  final String activeFloorId;
  final ValueChanged<String> onSelectFloor;
  final VoidCallback onClose;

  const FloorSelectionMenu({
    super.key,
    required this.floors,
    required this.activeFloorId,
    required this.onSelectFloor,
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
                  Icons.layers_rounded,
                  size: 16.0,
                  color: colors.primary,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Select Floor'.tourText,
                  style: TextStyle(
                    color: colors.foreground,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                Semantics(
                  label: 'Close floor menu'.tourText,
                  button: true,
                  child: InkWell(
                    key: const Key('close_floor_menu_button'),
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

          // Vertical Floor Options List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: floors.map((floor) {
                final isSelected = floor.id == activeFloorId ||
                    (activeFloorId.contains('underground') && floor.id.contains('underground')) ||
                    (activeFloorId.contains('1') && floor.id.contains('1')) ||
                    (activeFloorId.contains('2') && floor.id.contains('2')) ||
                    (activeFloorId.contains('3') && floor.id.contains('3'));

                return _FloorMenuRow(
                  key: Key('floor_menu_item_${floor.id}'),
                  floor: floor,
                  isSelected: isSelected,
                  onTap: () => onSelectFloor(floor.id),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloorMenuRow extends StatelessWidget {
  final FloorDefinition floor;
  final bool isSelected;
  final VoidCallback onTap;

  const _FloorMenuRow({
    super.key,
    required this.floor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      label: isSelected
          ? '${floor.displayName}, current floor'
          : floor.displayName,
      button: true,
      selected: isSelected,
      child: Container(
        height: 48.0,
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
                  // Active indicator / checkmark
                  if (isSelected) ...[
                    Icon(
                      Icons.check_rounded,
                      size: 18.0,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 10.0),
                  ] else ...[
                    const SizedBox(width: 28.0), // Indent to align with checked items
                  ],

                  // Floor name
                  Expanded(
                    child: Text(
                      floor.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? colors.primary : colors.foreground,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 13.5,
                      ),
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
