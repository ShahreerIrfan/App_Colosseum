import 'package:flutter/material.dart';

enum EntryExitType { entry, exit }

/// Architectural portal marker (ENTRY / EXIT) displayed on the floor plan itinerary.
class EntryExitMarker extends StatelessWidget {
  final EntryExitType type;
  final VoidCallback? onTap;

  const EntryExitMarker({
    super.key,
    required this.type,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEntry = type == EntryExitType.entry;
    final label = isEntry ? 'ENTRY' : 'EXIT';
    final icon = isEntry ? Icons.login_rounded : Icons.logout_rounded;
    final accentColor = isEntry
        ? const Color(0xFF10B981) // Emerald Green
        : const Color(0xFFEF4444); // Crimson / Amber Red

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(9.0),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.85),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.35),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 11.5,
              color: accentColor,
            ),
            const SizedBox(width: 4.0),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
