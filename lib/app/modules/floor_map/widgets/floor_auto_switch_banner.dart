import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/theme_extensions.dart';

/// Floating non-intrusive banner indicating an automatic floor detection switch
/// with a 5-second countdown timer and an [Undo] action.
class FloorAutoSwitchBanner extends StatefulWidget {
  final String floorName;
  final VoidCallback onUndo;
  final VoidCallback onDismiss;
  final Duration duration;

  const FloorAutoSwitchBanner({
    super.key,
    required this.floorName,
    required this.onUndo,
    required this.onDismiss,
    this.duration = const Duration(seconds: 5),
  });

  @override
  State<FloorAutoSwitchBanner> createState() => _FloorAutoSwitchBannerState();
}

class _FloorAutoSwitchBannerState extends State<FloorAutoSwitchBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();

    _dismissTimer = Timer(widget.duration, () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Material(
        elevation: 6,
        color: colors.card,
        borderRadius: AppRadius.borderLg,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderLg,
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.20),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: AppRadius.borderMd,
                      ),
                      child: Icon(
                        Icons.stairs_rounded,
                        color: colors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Moved to ${widget.floorName}?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: colors.foreground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Detected stair movement',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Undo Button
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        backgroundColor: colors.primary.withValues(alpha: 0.1),
                      ),
                      onPressed: () {
                        _dismissTimer?.cancel();
                        widget.onUndo();
                      },
                      child: Text(
                        'Undo',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Dismiss Button
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: colors.mutedForeground,
                        size: 18,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        _dismissTimer?.cancel();
                        widget.onDismiss();
                      },
                    ),
                  ],
                ),
              ),
              // Linear countdown progress bar
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, _) {
                  return ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    child: LinearProgressIndicator(
                      value: 1.0 - _progressController.value,
                      minHeight: 2.5,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
