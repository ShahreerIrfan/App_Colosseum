import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../data/models/tour_navigation_state.dart';
import '../controllers/floor_map_controller.dart';
import '../widgets/entry_exit_marker.dart';
import '../widgets/floor_plan_painter.dart';
import '../widgets/itinerary_painter.dart';
import '../widgets/user_location_puck.dart';
import '../widgets/viewpoint_detail_card.dart';
import '../widgets/viewpoint_marker.dart';

/// Screen displaying top-down architectural floor map with indoor positioning and viewpoints.
class FloorMapView extends GetView<FloorMapController> {
  const FloorMapView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Dominant Interactive Floor Map Canvas (Interactive Pinch & Pan)
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: controller.transformationController,
                panEnabled: true,
                scaleEnabled: true,
                minScale: 0.8,
                maxScale: 3.5,
                boundaryMargin: const EdgeInsets.symmetric(
                  horizontal: 140.0,
                  vertical: 180.0,
                ),
                alignment: Alignment.center,
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Maintain a square aspect map viewport based on available screen space
                      final mapDimension = constraints.maxWidth < constraints.maxHeight
                          ? constraints.maxWidth
                          : constraints.maxHeight * 0.75;

                      final mapSize = Size(mapDimension, mapDimension);

                      return SizedBox(
                        width: mapSize.width,
                        height: mapSize.height,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Layer 1: Top-down Architectural Floor Plan
                            Obx(
                              () => CustomPaint(
                                size: mapSize,
                                painter: FloorPlanPainter(
                                  colors: colors,
                                  isUnderground: controller.floorId.value
                                      .contains('underground'),
                                ),
                              ),
                            ),

                            // Layer 2: Guided Itinerary Tour Walking Path (ENTRY -> 100 -> ... -> 106 -> EXIT)
                            Obx(() {
                              if (controller.itinerarySegments.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return CustomPaint(
                                size: mapSize,
                                painter: ItineraryPainter(
                                  segments: controller.itinerarySegments,
                                  activeColor: colors.primary,
                                  completedColor: const Color(0xFF10B981),
                                ),
                              );
                            }),

                            // Layer 3: Portal Markers (ENTRY & EXIT)
                            Obx(() {
                              if (!controller.floorId.value.contains('underground')) {
                                return const SizedBox.shrink();
                              }
                              const entry = FloorMapController.undergroundEntryLocation;
                              const exit = FloorMapController.undergroundExitLocation;

                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    left: entry.dx * mapSize.width,
                                    top: entry.dy * mapSize.height,
                                    child: const FractionalTranslation(
                                      translation: Offset(-0.5, -0.5),
                                      child: EntryExitMarker(
                                        key: Key('itinerary_entry_marker'),
                                        type: EntryExitType.entry,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: exit.dx * mapSize.width,
                                    top: exit.dy * mapSize.height,
                                    child: const FractionalTranslation(
                                      translation: Offset(-0.5, -0.5),
                                      child: EntryExitMarker(
                                        key: Key('itinerary_exit_marker'),
                                        type: EntryExitType.exit,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),

                            // Layer 4: Animated User Indoor Location Puck
                            Obx(() {
                              final user = controller.userLocation.value;
                              final px = user.normalizedX * mapSize.width;
                              final py = user.normalizedY * mapSize.height;

                              return Positioned(
                                left: px - 30.0,
                                top: py - 30.0,
                                child: UserLocationPuck(
                                  headingDegrees: user.headingDegrees,
                                  accuracyMeters: user.accuracyMeters,
                                ),
                              );
                            }),

                            // Layer 6: Interactive Viewpoint Markers (100–106)
                            Obx(() {
                              final selectedVp = controller.selectedViewpoint.value;
                              final isPlaying = controller.isPlayingAudio.value;
                              final currentTargetId = controller.tourState.value.navigationTargetId;

                              return Stack(
                                clipBehavior: Clip.none,
                                children: controller.viewpoints.map((vp) {
                                  final isSelected = selectedVp?.id == vp.id;
                                  final isTarget = currentTargetId == vp.id;
                                  final px = vp.normalizedX * mapSize.width;
                                  final py = vp.normalizedY * mapSize.height;

                                  // Center the marker horizontally on normalized point and align pin center
                                  return Positioned(
                                    left: px,
                                    top: py,
                                    child: FractionalTranslation(
                                      translation: Offset(
                                        -0.5,
                                        isSelected ? -0.78 : -0.5,
                                      ),
                                      child: ViewpointMarker(
                                        viewpoint: vp,
                                        isSelected: isSelected,
                                        isPlaying: isSelected && isPlaying,
                                        isTarget: isTarget,
                                        onTap: () => controller.selectViewpoint(vp),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // 2. Compact Minimal Top App Bar (Back Button + Landmark & Floor Title)
            Positioned(
              top: 12.0,
              left: 16.0,
              right: 16.0,
              child: Row(
                children: [
                  // Back Button
                  Material(
                    color: colors.card,
                    shape: const CircleBorder(),
                    elevation: 2.0,
                    shadowColor: colors.foreground.withValues(alpha: 0.1),
                    child: InkWell(
                      onTap: () => Get.back(),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 44.0,
                        height: 44.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.border,
                            width: 1.0,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: colors.foreground,
                          size: 20.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),

                  // Landmark Name & Floor Title Container
                  Expanded(
                    child: Obx(
                      () => Container(
                        height: 44.0,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(22.0),
                          border: Border.all(
                            color: colors.border,
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.foreground.withValues(alpha: 0.05),
                              blurRadius: 6.0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                controller.landmarkName.value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleSmall?.copyWith(
                                  color: colors.foreground,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9.0,
                                  vertical: 3.0,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: Text(
                                  controller.floorName.value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Compact Horizontal Map Toolbar (Zoom In, Zoom Out, Recenter) Centered Horizontally
            Positioned(
              top: 68.0,
              left: 0.0,
              right: 0.0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: colors.border,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.foreground.withValues(alpha: 0.08),
                        blurRadius: 8.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Zoom In Button
                        _ToolbarButton(
                          icon: Icons.add_rounded,
                          tooltip: 'Zoom In',
                          onPressed: controller.zoomIn,
                          colors: colors,
                        ),
                        VerticalDivider(
                          width: 1.0,
                          thickness: 1.0,
                          color: colors.border,
                          indent: 6.0,
                          endIndent: 6.0,
                        ),
                        // Zoom Out Button
                        _ToolbarButton(
                          icon: Icons.remove_rounded,
                          tooltip: 'Zoom Out',
                          onPressed: controller.zoomOut,
                          colors: colors,
                        ),
                        VerticalDivider(
                          width: 1.0,
                          thickness: 1.0,
                          color: colors.border,
                          indent: 6.0,
                          endIndent: 6.0,
                        ),
                        // Recenter on Location Button
                        _ToolbarButton(
                          icon: Icons.my_location_rounded,
                          tooltip: 'Recenter',
                          onPressed: controller.recenter,
                          colors: colors,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 4. Compact Guided Tour HUD (Navigation Status, Distance, Settings & Skip)
            Positioned(
              top: 112.0,
              left: 16.0,
              right: 16.0,
              child: Obx(() {
                if (!controller.floorId.value.contains('underground')) {
                  return const SizedBox.shrink();
                }

                final state = controller.tourState.value;
                final statusText = _getTourStatusText(state);
                final statusIcon = _getTourStatusIcon(state.navigationStatus);

                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 5.0,
                    ),
                    decoration: BoxDecoration(
                      color: colors.card.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(18.0),
                      border: Border.all(
                        color: colors.border,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.foreground.withValues(alpha: 0.06),
                          blurRadius: 8.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 14.0,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 6.0),
                        Flexible(
                          child: Text(
                            statusText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.foreground,
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        // Voice Guidance Toggle
                        InkWell(
                          key: const Key('toggle_voice_guidance_button'),
                          onTap: () => controller.toggleVoiceGuidance(),
                          borderRadius: BorderRadius.circular(12.0),
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Icon(
                              state.isVoiceGuidanceEnabled
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_off_rounded,
                              size: 15.0,
                              color: state.isVoiceGuidanceEnabled
                                  ? colors.primary
                                  : colors.foreground.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        // Auto-Play Toggle
                        InkWell(
                          key: const Key('toggle_autoplay_button'),
                          onTap: () => controller.toggleAutoPlay(),
                          borderRadius: BorderRadius.circular(12.0),
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Icon(
                              state.isAutoPlayEnabled
                                  ? Icons.bolt_rounded
                                  : Icons.flash_off_rounded,
                              size: 15.0,
                              color: state.isAutoPlayEnabled
                                  ? const Color(0xFFEAB308)
                                  : colors.foreground.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),

            // 5. Contextual Bottom Viewpoint Detail Card
            Positioned(
              left: 16.0,
              right: 16.0,
              bottom: 16.0,
              child: Obx(() {
                final selectedVp = controller.selectedViewpoint.value;

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  reverseDuration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.25),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: selectedVp == null
                      ? const SizedBox.shrink(key: ValueKey('empty_viewpoint_card'))
                      : ViewpointDetailCard(
                          key: ValueKey(selectedVp.id),
                          viewpoint: selectedVp,
                          isPlaying: controller.isPlayingAudio.value,
                          isCollapsed: controller.isCardCollapsed.value,
                          progress: controller.audioProgress.value,
                          onToggleAudio: controller.toggleAudio,
                          onToggleCollapse: controller.toggleCardCollapse,
                          onToggleVisited: controller.toggleVisited,
                          onClose: controller.deselectViewpoint,
                        ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _getTourStatusText(TourNavigationState state) {
    switch (state.navigationStatus) {
      case TourNavigationStatus.idle:
        return 'Tour Ready';
      case TourNavigationStatus.navigating:
      case TourNavigationStatus.navigatingToNext:
        if (state.navigationTargetId == 'EXIT') {
          return state.distanceToTarget != null
              ? 'Exit ahead (${state.distanceToTarget!.toStringAsFixed(0)}m)'
              : 'Heading to Exit';
        }
        final targetNum = state.navigationTargetId?.replaceAll('vp_', '');
        return state.distanceToTarget != null
            ? 'Stop $targetNum (${state.distanceToTarget!.toStringAsFixed(0)}m)'
            : 'Heading to Stop $targetNum';
      case TourNavigationStatus.approaching:
        final targetNum = state.navigationTargetId?.replaceAll('vp_', '');
        return 'Approaching Stop $targetNum (${state.distanceToTarget?.toStringAsFixed(0)}m)';
      case TourNavigationStatus.arrivalPending:
        final targetNum = state.navigationTargetId?.replaceAll('vp_', '');
        return 'Confirming arrival at Stop $targetNum…';
      case TourNavigationStatus.arrived:
        final targetNum = state.navigationTargetId?.replaceAll('vp_', '');
        return 'Arrived at Stop $targetNum';
      case TourNavigationStatus.viewpointAudioPlaying:
        final targetNum = state.activeAudioViewpointId?.replaceAll('vp_', '');
        return 'Listening to Stop $targetNum';
      case TourNavigationStatus.waitingAtViewpoint:
        final targetNum = state.reachedViewpointId?.replaceAll('vp_', '');
        return 'Exploring Stop $targetNum';
      case TourNavigationStatus.waitingForVisited:
        final targetNum = state.reachedViewpointId?.replaceAll('vp_', '');
        return 'Stop $targetNum · Mark Visited';
      case TourNavigationStatus.waitingForDeparture:
        final targetNum = state.previousTargetId?.replaceAll('vp_', '');
        return 'Departing Stop $targetNum';
      case TourNavigationStatus.locationUncertain:
        return 'Calibrating indoor GPS…';
      case TourNavigationStatus.itineraryComplete:
        return 'Underground Tour Complete';
    }
  }

  IconData _getTourStatusIcon(TourNavigationStatus status) {
    switch (status) {
      case TourNavigationStatus.idle:
        return Icons.map_rounded;
      case TourNavigationStatus.navigating:
      case TourNavigationStatus.navigatingToNext:
      case TourNavigationStatus.approaching:
        return Icons.navigation_rounded;
      case TourNavigationStatus.arrivalPending:
      case TourNavigationStatus.arrived:
        return Icons.location_on_rounded;
      case TourNavigationStatus.viewpointAudioPlaying:
        return Icons.volume_up_rounded;
      case TourNavigationStatus.waitingAtViewpoint:
      case TourNavigationStatus.waitingForVisited:
        return Icons.check_circle_outline_rounded;
      case TourNavigationStatus.waitingForDeparture:
        return Icons.directions_walk_rounded;
      case TourNavigationStatus.locationUncertain:
        return Icons.gps_not_fixed_rounded;
      case TourNavigationStatus.itineraryComplete:
        return Icons.flag_rounded;
    }
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final dynamic colors;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(9.0),
        child: SizedBox(
          width: 38.0,
          height: 35.0,
          child: Center(
            child: Icon(
              icon,
              size: 18.0,
              color: colors.foreground,
            ),
          ),
        ),
      ),
    );
  }
}
