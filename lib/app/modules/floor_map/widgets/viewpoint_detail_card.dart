import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../data/models/viewpoint_model.dart';

/// Contextual bottom sheet/card showing details of the selected viewpoint.
/// Supports both expanded and collapsed (mini-player) presentation modes with
/// buttery-smooth animated transitions and independent audio playback controls.
class ViewpointDetailCard extends StatelessWidget {
  final ViewpointModel viewpoint;
  final bool isPlaying;
  final bool isCollapsed;
  final double progress;
  final VoidCallback onToggleAudio;
  final VoidCallback onToggleCollapse;
  final VoidCallback onToggleVisited;
  final VoidCallback onClose;
  final VoidCallback? onDirections;

  const ViewpointDetailCard({
    super.key,
    required this.viewpoint,
    required this.isPlaying,
    this.isCollapsed = false,
    this.progress = 0.0,
    required this.onToggleAudio,
    required this.onToggleCollapse,
    required this.onToggleVisited,
    required this.onClose,
    this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22.0),
        border: Border.all(
          color: colors.border,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.foreground.withValues(alpha: 0.09),
            blurRadius: 18.0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Smooth Crossfade between Collapsed Mini-Player and Expanded Full Guide
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              firstCurve: Curves.easeInOutCubic,
              secondCurve: Curves.easeInOutCubic,
              sizeCurve: Curves.easeInOutCubic,
              crossFadeState: isCollapsed
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: _buildCollapsedMiniPlayer(context),
              secondChild: _buildExpandedFullView(context),
            ),

            // Optional Mini Playback Progress Bar (visible in both modes when audio is active/progressing)
            if (isPlaying || progress > 0.0)
              ClipRRect(
                child: LinearProgressIndicator(
                  value: progress > 0.0 ? progress : null,
                  minHeight: 2.5,
                  backgroundColor: colors.border.withValues(alpha: 0.4),
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Collapsed Mini-Player: slightly taller 2-row layout showing full viewpoint title on row 1
  /// and [✓ Mark as Visited], [Play/Pause], [▲ Expand], and [✕ Close] buttons on row 2.
  Widget _buildCollapsedMiniPlayer(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14.0,
        vertical: 13.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Stop Badge on left + Full Viewpoint Title (left-aligned, up to 2 lines)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildStopBadge(colors, size: 38.0),
              const SizedBox(width: 12.0),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggleCollapse,
                  child: Text(
                    viewpoint.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      color: colors.foreground,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      height: 1.25,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10.0),

          // Row 2: [✓ Mark as Visited] (left) + [Play/Pause] [▲ Expand] [✕ Close] (right)
          Row(
            children: [
              // 1. [✓ Mark as Visited] / [✓ Visited] Compact Control
              Material(
                color: viewpoint.isVisited
                    ? colors.primary.withValues(alpha: 0.12)
                    : colors.border.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20.0),
                child: InkWell(
                  key: const Key('toggle_visited_button_collapsed'),
                  onTap: onToggleVisited,
                  borderRadius: BorderRadius.circular(20.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: viewpoint.isVisited
                            ? colors.primary.withValues(alpha: 0.5)
                            : colors.border.withValues(alpha: 0.85),
                        width: 1.1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          viewpoint.isVisited
                              ? Icons.check_circle_rounded
                              : Icons.check_rounded,
                          size: 14.0,
                          color: viewpoint.isVisited
                              ? colors.primary
                              : colors.foreground.withValues(alpha: 0.75),
                        ),
                        const SizedBox(width: 5.0),
                        Text(
                          viewpoint.isVisited ? 'Visited' : 'Mark as Visited',
                          style: TextStyle(
                            color: viewpoint.isVisited
                                ? colors.primary
                                : colors.foreground.withValues(alpha: 0.82),
                            fontWeight: viewpoint.isVisited
                                ? FontWeight.w700
                                : FontWeight.w600,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // 2. Play / Pause Button (Controls audio directly in collapsed state)
              Material(
                color: colors.primary,
                shape: const CircleBorder(),
                elevation: 1.0,
                shadowColor: colors.primary.withValues(alpha: 0.3),
                child: InkWell(
                  key: const Key('toggle_audio_collapsed'),
                  onTap: onToggleAudio,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 40.0,
                    height: 40.0,
                    child: Center(
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: colors.primaryForeground,
                        size: 22.0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6.0),

              // 3. ▲ Expand Icon Button
              Material(
                color: colors.border.withValues(alpha: 0.45),
                shape: const CircleBorder(),
                child: InkWell(
                  key: const Key('expand_card_button'),
                  onTap: onToggleCollapse,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 40.0,
                    height: 40.0,
                    child: Center(
                      child: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: colors.foreground,
                        size: 24.0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6.0),

              // 4. Explicit Close Button
              Material(
                color: colors.border.withValues(alpha: 0.45),
                shape: const CircleBorder(),
                child: InkWell(
                  key: const Key('close_viewpoint_card'),
                  onTap: onClose,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 40.0,
                    height: 40.0,
                    child: Center(
                      child: Icon(
                        Icons.close_rounded,
                        color: colors.foreground,
                        size: 20.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Expanded Full View:
  /// Row 1: [Stop Number Badge] (top-left)  ----------------  [▼ Collapse] [✕ Close] (top-right)
  /// Row 2: Centered Viewpoint Title
  /// Row 3: Centered [✓ Mark as Visited] / [✓ Visited] Compact Secondary Control
  /// Row 4: Viewpoint Image with GPS Badge
  /// Row 5: Detailed Description
  /// Row 6: Listen Guide / Audio Action Buttons
  Widget _buildExpandedFullView(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Action Row: Stop Badge on left, Collapse & Close buttons on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Stop Number Badge (Top-Left)
              _buildStopBadge(colors, size: 40.0),

              // Action Buttons (Top-Right): ▼ Collapse and ✕ Close
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ▼ Dedicated Collapse Button (>=48dp touch target)
                  Material(
                    color: colors.border.withValues(alpha: 0.45),
                    shape: const CircleBorder(),
                    child: InkWell(
                      key: const Key('collapse_card_button'),
                      onTap: onToggleCollapse,
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 44.0,
                        height: 44.0,
                        child: Center(
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: colors.foreground,
                            size: 26.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),

                  // ✕ Explicit Close Button (>=48dp touch target, high contrast)
                  Material(
                    color: colors.border.withValues(alpha: 0.45),
                    shape: const CircleBorder(),
                    child: InkWell(
                      key: const Key('close_viewpoint_card'),
                      onTap: onClose,
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 44.0,
                        height: 44.0,
                        child: Center(
                          child: Icon(
                            Icons.close_rounded,
                            color: colors.foreground,
                            size: 22.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10.0),

          // 2. Viewpoint Title (Centered horizontally on its own row)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Text(
              viewpoint.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w800,
                fontSize: 16.5,
                height: 1.25,
                letterSpacing: -0.2,
              ),
            ),
          ),

          const SizedBox(height: 8.0),

          // 3. Centered Compact "Mark as Visited" / "Visited" Control
          Center(
            child: Material(
              color: viewpoint.isVisited
                  ? colors.primary.withValues(alpha: 0.12)
                  : colors.border.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20.0),
              child: InkWell(
                key: const Key('toggle_visited_button'),
                onTap: onToggleVisited,
                borderRadius: BorderRadius.circular(20.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: viewpoint.isVisited
                          ? colors.primary.withValues(alpha: 0.5)
                          : colors.border.withValues(alpha: 0.85),
                      width: 1.1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        viewpoint.isVisited
                            ? Icons.check_circle_rounded
                            : Icons.check_rounded,
                        size: 14.5,
                        color: viewpoint.isVisited
                            ? colors.primary
                            : colors.foreground.withValues(alpha: 0.75),
                      ),
                      const SizedBox(width: 5.5),
                      Text(
                        viewpoint.isVisited ? 'Visited' : 'Mark as Visited',
                        style: TextStyle(
                          color: viewpoint.isVisited
                              ? colors.primary
                              : colors.foreground.withValues(alpha: 0.82),
                          fontWeight: viewpoint.isVisited
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Viewpoint Image (Displayed cleanly below the viewpoint header)
          if (viewpoint.imageAsset != null) ...[
            const SizedBox(height: 12.0),
            ClipRRect(
              borderRadius: BorderRadius.circular(14.0),
              child: Stack(
                children: [
                  Image.asset(
                    viewpoint.imageAsset!,
                    height: 135.0,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 135.0,
                      width: double.infinity,
                      color: colors.border.withValues(alpha: 0.3),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_not_supported_rounded,
                        color: colors.muted,
                        size: 36.0,
                      ),
                    ),
                  ),
                  // Location coordinates badge overlay
                  if (viewpoint.latitude != null && viewpoint.longitude != null)
                    Positioned(
                      bottom: 8.0,
                      left: 8.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 11.0,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3.0),
                            Text(
                              '${viewpoint.latitude!.toStringAsFixed(6)}, ${viewpoint.longitude!.toStringAsFixed(6)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Detailed Narration Text
          if (viewpoint.description.isNotEmpty) ...[
            const SizedBox(height: 10.0),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 95.0),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  viewpoint.description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.foreground.withValues(alpha: 0.84),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 14.0),

          // Action Buttons: Audio Guide Play/Pause + Guide Route
          Row(
            children: [
              // Play / Pause Audio Guide Button
              Expanded(
                flex: 3,
                child: FilledButton.icon(
                  key: const Key('toggle_audio_expanded'),
                  onPressed: onToggleAudio,
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    size: 20.0,
                    color: colors.primaryForeground,
                  ),
                  label: Text(
                    isPlaying ? 'Pause Audio' : 'Listen Guide',
                    style: TextStyle(
                      color: colors.primaryForeground,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 11.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ),

              if (onDirections != null) ...[
                const SizedBox(width: 10.0),
                // Route directions button
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: onDirections,
                    icon: Icon(
                      Icons.navigation_rounded,
                      size: 17.0,
                      color: colors.primary,
                    ),
                    label: Text(
                      'Directions',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.0,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 11.0,
                      ),
                      side: BorderSide(
                        color: colors.primary.withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStopBadge(dynamic colors, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      alignment: Alignment.center,
      child: Text(
        '${viewpoint.order}',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: viewpoint.order >= 100 ? (size > 36 ? 12.5 : 11.5) : (size > 36 ? 15.0 : 13.5),
        ),
      ),
    );
  }
}
