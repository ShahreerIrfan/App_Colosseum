import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/geodesic_utils.dart';
import '../../../data/models/map_view_type.dart';
import '../../../data/models/tour_navigation_state.dart';
import '../controllers/floor_map_controller.dart';
import '../widgets/floor_bottom_bar.dart';
import '../widgets/floor_progress_indicator.dart';
import '../widgets/floor_selection_menu.dart';
import '../widgets/map_view_selection_menu.dart';
import '../widgets/user_location_puck.dart';
import '../widgets/viewpoint_detail_card.dart';
import '../widgets/viewpoint_marker.dart';

/// Screen displaying Google Maps Satellite View with indoor positioning and viewpoints.
class FloorMapView extends GetView<FloorMapController> {
  const FloorMapView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    return PopScope(
      canPop:
          !controller.isFloorMenuOpen.value &&
          !controller.isMapViewMenuOpen.value,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (controller.isFloorMenuOpen.value ||
            controller.isMapViewMenuOpen.value) {
          controller.closeAllBottomMenus();
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Stack(
            children: [
              // 1. Dominant Google Maps Viewport (General / Satellite)
              Positioned.fill(
                child: FlutterMap(
                  mapController: controller.mapController,
                  options: MapOptions(
                    initialCenter: controller.activeCenter,
                    initialZoom: controller.activeZoom,
                    minZoom: FloorMapController.minZoom,
                    maxZoom: FloorMapController.maxZoom,
                    onPositionChanged: controller.onPositionChanged,
                    onTap: (tapPosition, latLng) {
                      if (controller.isPlaygroundMode.value) {
                        controller.setSimulatedLocation(latLng);
                      }
                    },
                    cameraConstraint: CameraConstraint.containCenter(
                      bounds: GeodesicUtils.createBoundsFromDimensions(
                        center: controller.activeCenter,
                        widthMeters: 450.0,
                        heightMeters: 450.0,
                      ),
                    ),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    // Layer 1: Dynamic Google Maps Base Tiles (General vs Satellite)
                    Obx(() {
                      final viewType = controller.selectedMapView.value;
                      final isSatellite = viewType == MapViewType.satellite;

                      return TileLayer(
                        key: ValueKey(viewType),
                        urlTemplate: isSatellite
                            ? 'https://mt{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}'
                            : 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                        subdomains: const ['0', '1', '2', '3'],
                        userAgentPackageName: 'com.example.colosseum_client',
                        maxZoom: 21,
                        errorTileCallback: (tile, error, stackTrace) {
                          if (isSatellite) {
                            controller.onSatelliteTileError();
                          }
                        },
                      );
                    }),

                    // Layer 3: Guided Itinerary Tour Walking Path & Architectural Geometry
                    Obx(() {
                      final itinerary = controller.itinerarySegments;
                      final architectural = controller
                          .buildFloorArchitecturalPolylines(colors);
                      if (itinerary.isEmpty && architectural.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return PolylineLayer(
                        polylines: [
                          ...architectural,
                          ...controller.buildItineraryPolylines(colors),
                        ],
                      );
                    }),

                    // Layer 3: Interactive Viewpoint Markers
                    Obx(() {
                      final selectedVp = controller.selectedViewpoint.value;
                      final isPlaying = controller.isPlayingAudio.value;
                      final currentTargetId =
                          controller.tourState.value.navigationTargetId;

                      return MarkerLayer(
                        markers: controller.viewpoints.map((vp) {
                          final isSelected = selectedVp?.id == vp.id;
                          final isTarget = currentTargetId == vp.id;

                          return Marker(
                            point: vp.latLng,
                            width: 48.0,
                            height: 48.0,
                            alignment: Alignment.center,
                            child: ViewpointMarker(
                              viewpoint: vp,
                              isSelected: isSelected,
                              isPlaying: isSelected && isPlaying,
                              isTarget: isTarget,
                              onTap: () => controller.animateToViewpoint(vp),
                            ),
                          );
                        }).toList(),
                      );
                    }),

                    // Layer 4: Animated User Indoor Location Puck (Visible ONLY when in location)
                    Obx(() {
                      if (!controller.isUserInLocation.value ||
                          controller.userLocation.value == null) {
                        return const SizedBox.shrink();
                      }

                      final user = controller.userLocation.value!;
                      final heading = controller.effectiveHeading;
                      final isViewingOther = controller.isViewingDifferentFloor;

                      return MarkerLayer(
                        markers: [
                          Marker(
                            point: user.latLng,
                            width: 64.0,
                            height: 64.0,
                            alignment: Alignment.center,
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: isViewingOther ? 0.40 : 1.0,
                                child: UserLocationPuck(
                                  headingDegrees: heading,
                                  accuracyMeters: user.accuracyMeters,
                                  puckColor: isViewingOther
                                      ? colors.foreground.withValues(alpha: 0.6)
                                      : const Color(0xFF00A6FF), // Sky blue
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),

              // 2. Exit Landmark Button (Top Right)
              Positioned(
                top: 12.0,
                right: 16.0,
                child: Semantics(
                  button: true,
                  label: 'Exit landmark view and return to itinerary map',
                  child: Material(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(22.0),
                    elevation: 2.0,
                    shadowColor: colors.foreground.withValues(alpha: 0.08),
                    child: InkWell(
                      key: const Key('exit_landmark_button'),
                      onTap: () {
                        if (controller.isFloorMenuOpen.value) {
                          controller.closeFloorMenu();
                        }
                        Get.back();
                      },
                      borderRadius: BorderRadius.circular(22.0),
                      child: Container(
                        height: 44.0,
                        padding: const EdgeInsets.symmetric(horizontal: 14.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22.0),
                          border: Border.all(color: colors.border, width: 1.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.exit_to_app_rounded,
                              color: colors.destructive,
                              size: 18.0,
                            ),
                            const SizedBox(width: 5.0),
                            Text(
                              'Exit',
                              style: TextStyle(
                                color: colors.foreground,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.0,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
                      border: Border.all(color: colors.border, width: 1.0),
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
                          VerticalDivider(
                            width: 1.0,
                            thickness: 1.0,
                            color: colors.border,
                            indent: 6.0,
                            endIndent: 6.0,
                          ),
                          // Toggle Map View (Satellite vs General) Button
                          Obx(() {
                            final isSatellite =
                                controller.selectedMapView.value ==
                                MapViewType.satellite;
                            return _ToolbarButton(
                              key: const Key('toolbar_toggle_map_view_button'),
                              icon: isSatellite
                                  ? Icons.map_rounded
                                  : Icons.satellite_alt_rounded,
                              tooltip: isSatellite
                                  ? 'Switch to General View'
                                  : 'Switch to Satellite View',
                              onPressed: controller.toggleMapView,
                              colors: colors,
                              isActive: isSatellite,
                              activeColor: colors.primary,
                            );
                          }),
                          VerticalDivider(
                            width: 1.0,
                            thickness: 1.0,
                            color: colors.border,
                            indent: 6.0,
                            endIndent: 6.0,
                          ),
                          // Field Test (Playground Mode) Toggle Button
                          Obx(
                            () => _ToolbarButton(
                              icon: Icons.explore_rounded,
                              tooltip: controller.isPlaygroundMode.value
                                  ? 'Field Test Mode (Active)'
                                  : 'Enable Field Test Mode',
                              onPressed: controller.togglePlaygroundMode,
                              colors: colors,
                              isActive: controller.isPlaygroundMode.value,
                              activeColor: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Guided Tour HUD, Out-of-Location Badge or Field Test Badge
              Positioned(
                top: 112.0,
                left: 16.0,
                right: 16.0,
                child: Obx(() {
                  if (!controller.isUserInLocation.value) {
                    return Center(
                      child: Container(
                        key: const Key('out_of_location_badge'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 5.0,
                        ),
                        decoration: BoxDecoration(
                          color: colors.card.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(18.0),
                          border: Border.all(color: colors.border, width: 1.0),
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
                              Icons.location_off_rounded,
                              size: 14.0,
                              color: colors.foreground.withValues(alpha: 0.6),
                            ),
                            Flexible(
                              child: Text(
                                'You are not in the location',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.foreground.withValues(
                                    alpha: 0.8,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            // Quick toggle for Field Test Mode
                            InkWell(
                              key: const Key('quick_field_test_button'),
                              onTap: controller.togglePlaygroundMode,
                              borderRadius: BorderRadius.circular(12.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10.0),
                                  border: Border.all(
                                    color: colors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.directions_walk_rounded,
                                      size: 12.0,
                                      color: colors.primary,
                                    ),
                                    const SizedBox(width: 4.0),
                                    Text(
                                      'Field Test',
                                      style: TextStyle(
                                        color: colors.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final state = controller.tourState.value;
                  final isPlayground = controller.isPlaygroundMode.value;
                  final isViewingOther = controller.isViewingDifferentFloor;
                  final statusText = isViewingOther
                      ? 'Viewing ${controller.currentFloor.value.displayName}'
                      : _getTourStatusText(state);
                  final statusIcon = isViewingOther
                      ? Icons.visibility_rounded
                      : _getTourStatusIcon(state.navigationStatus);

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
                          color: isPlayground
                              ? colors.primary.withValues(alpha: 0.4)
                              : colors.border,
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
                            isPlayground
                                ? Icons.directions_walk_rounded
                                : statusIcon,
                            size: 14.0,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 6.0),
                          Flexible(
                            child: Text(
                              isPlayground
                                  ? 'Field Test · $statusText'
                                  : statusText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.foreground,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                          if (isPlayground) ...[
                            const SizedBox(width: 6.0),
                            // Pause / Resume Walking (Relocate) Button
                            Tooltip(
                              message: controller.isDisplacementPaused.value
                                  ? 'Resume Walking from Current Physical Spot'
                                  : 'Pause Walking to Relocate Physically Without Moving Puck',
                              child: InkWell(
                                key: const Key('toggle_pause_walk_button'),
                                onTap: controller.togglePauseDisplacement,
                                borderRadius: BorderRadius.circular(10.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6.0,
                                    vertical: 2.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: controller.isDisplacementPaused.value
                                        ? const Color(0xFF10B981)
                                              .withValues(alpha: 0.15)
                                        : colors.primary.withValues(
                                            alpha: 0.10,
                                          ),
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: Border.all(
                                      color:
                                          controller.isDisplacementPaused.value
                                          ? const Color(0xFF10B981)
                                                .withValues(alpha: 0.40)
                                          : Colors.transparent,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        controller.isDisplacementPaused.value
                                            ? Icons.play_arrow_rounded
                                            : Icons.pause_rounded,
                                        size: 12.0,
                                        color:
                                            controller
                                                .isDisplacementPaused
                                                .value
                                            ? const Color(0xFF10B981)
                                            : colors.primary,
                                      ),
                                      const SizedBox(width: 3.0),
                                      Text(
                                        controller.isDisplacementPaused.value
                                            ? 'Resume'
                                            : 'Pause',
                                        style: TextStyle(
                                          color:
                                              controller
                                                  .isDisplacementPaused
                                                  .value
                                              ? const Color(0xFF10B981)
                                              : colors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 9.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4.0),
                            // Snap to Target Button
                            Tooltip(
                              message: 'Snap/Re-anchor to Current Target Stop',
                              child: InkWell(
                                key: const Key('snap_target_button'),
                                onTap: controller.snapToTarget,
                                borderRadius: BorderRadius.circular(10.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6.0,
                                    vertical: 2.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.primary.withValues(
                                      alpha: 0.10,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.center_focus_strong_rounded,
                                        size: 11.0,
                                        color: colors.primary,
                                      ),
                                      const SizedBox(width: 3.0),
                                      Text(
                                        'Snap Stop',
                                        style: TextStyle(
                                          color: colors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 9.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4.0),
                            // Reset Origin Button
                            Tooltip(
                              message:
                                  'Reset Origin (Set Origin to Current Spot)',
                              child: InkWell(
                                key: const Key('reset_origin_button'),
                                onTap: controller.resetPlaygroundOrigin,
                                borderRadius: BorderRadius.circular(10.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6.0,
                                    vertical: 2.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.primary.withValues(
                                      alpha: 0.10,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.refresh_rounded,
                                        size: 11.0,
                                        color: colors.primary,
                                      ),
                                      const SizedBox(width: 3.0),
                                      Text(
                                        'Reset',
                                        style: TextStyle(
                                          color: colors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 9.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
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

              // 4b. Walking Paused / Relocation Floating Banner
              Positioned(
                top: 152.0,
                left: 20.0,
                right: 20.0,
                child: Obx(() {
                  if (!controller.isPlaygroundMode.value ||
                      !controller.isDisplacementPaused.value) {
                    return const SizedBox.shrink();
                  }

                  return Center(
                    child: Container(
                      key: const Key('walking_paused_banner'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(
                          color: const Color(0xFFF59E0B),
                          width: 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8.0,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.pause_circle_rounded,
                            size: 16.0,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 6.0),
                          const Flexible(
                            child: Text(
                              'Walking Paused · Relocate to an open path & tap Resume',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF92400E),
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          InkWell(
                            key: const Key('banner_resume_button'),
                            onTap: controller.togglePauseDisplacement,
                            borderRadius: BorderRadius.circular(10.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 3.0,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD97706),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_arrow_rounded,
                                    size: 12.0,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 2.0),
                                  Text(
                                    'Resume',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),

              // 5. Non-blocking Compass Calibration Notification (only when sensor accuracy is low)
              Positioned(
                top: 196.0,
                left: 20.0,
                right: 20.0,
                child: Obx(() {
                  final orientation = controller.userOrientation.value;
                  if (!orientation.isCalibrating) {
                    return const SizedBox.shrink();
                  }

                  return Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: colors.card.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: Colors.amber.shade700.withValues(alpha: 0.35),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.explore_outlined,
                            size: 14.0,
                            color: Colors.amber.shade800,
                          ),
                          const SizedBox(width: 6.0),
                          Text(
                            'Move phone in figure-8 to improve compass accuracy',
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.foreground,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),

              // 5. Contextual Bottom Viewpoint Detail Card (floats above persistent bottom bar)
              Positioned(
                left: 16.0,
                right: 16.0,
                bottom: 74.0,
                child: Obx(() {
                  if (controller.isFloorMenuOpen.value ||
                      controller.isMapViewMenuOpen.value) {
                    return const SizedBox.shrink();
                  }
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
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: selectedVp == null
                        ? const SizedBox.shrink(
                            key: ValueKey('empty_viewpoint_card'),
                          )
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

              // 6. Subtle background scrim when any bottom menu is open (tapping closes menus)
              Positioned.fill(
                child: Obx(() {
                  final isOpen =
                      controller.isFloorMenuOpen.value ||
                      controller.isMapViewMenuOpen.value;
                  return IgnorePointer(
                    ignoring: !isOpen,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isOpen ? 1.0 : 0.0,
                      child: GestureDetector(
                        key: const Key('floor_menu_scrim'),
                        onTap: controller.closeAllBottomMenus,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.16),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              // 7. Anchored Floating Floor Selection Menu (opens upward above bottom bar)
              Positioned(
                left: 16.0,
                right: 16.0,
                bottom: 74.0,
                child: Obx(() {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    reverseDuration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.20),
                          end: Offset.zero,
                        ).animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: controller.isFloorMenuOpen.value
                        ? FloorSelectionMenu(
                            key: const ValueKey('floor_selection_menu'),
                            floors: controller.availableFloors,
                            activeFloorId: controller.floorId.value,
                            onSelectFloor: controller.switchFloor,
                            onClose: controller.closeFloorMenu,
                          )
                        : const SizedBox.shrink(
                            key: ValueKey('empty_floor_menu'),
                          ),
                  );
                }),
              ),

              // 8. Anchored Floating Map View Selection Menu (opens upward above bottom bar)
              Positioned(
                left: 16.0,
                right: 16.0,
                bottom: 74.0,
                child: Obx(() {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    reverseDuration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.20),
                          end: Offset.zero,
                        ).animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: controller.isMapViewMenuOpen.value
                        ? MapViewSelectionMenu(
                            key: const ValueKey('map_view_selection_menu'),
                            activeViewType: controller.selectedMapView.value,
                            onSelectMapView: controller.switchMapView,
                            onClose: controller.closeMapViewMenu,
                          )
                        : const SizedBox.shrink(
                            key: ValueKey('empty_map_view_menu'),
                          ),
                  );
                }),
              ),

              // 9. Persistent Bottom Navigation Bar (fixed above Android system inset)
              Positioned(
                left: 16.0,
                right: 16.0,
                bottom: 12.0,
                child: Obx(
                  () => FloorBottomBar(
                    margin: EdgeInsets.zero,
                    items: [
                      BottomNavItem(
                        key: const Key('floor_selection_bottom_button'),
                        icon: Icons.layers_rounded,
                        label: controller.landmarkName.value,
                        subtitle:controller.currentFloor.value.displayName,
                        isSelected: controller.isFloorMenuOpen.value,
                        onTap: controller.toggleFloorMenu,
                        semanticLabel:
                            'Choose ${controller.landmarkName.value} level',
                      ),
                    ],
                    trailing: Obx(
                      () => FloorProgressIndicator(
                        completedCount:
                            controller.currentFloorCompletedViewpoints,
                        totalCount: controller.currentFloorTotalViewpoints,
                        progressRatio: controller.currentFloorProgressRatio,
                        isCompleted: controller.isCurrentFloorComplete,
                        text: controller.currentFloorProgressText,
                        semanticLabel:
                            controller.currentFloorProgressSemanticLabel,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
  final bool isActive;
  final Color? activeColor;

  const _ToolbarButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.colors,
    this.isActive = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isActive
        ? (activeColor ?? colors.primary)
        : colors.foreground;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(9.0),
        child: Container(
          width: 38.0,
          height: 35.0,
          decoration: BoxDecoration(
            color: isActive
                ? (activeColor ?? colors.primary).withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9.0),
          ),
          child: Center(child: Icon(icon, size: 18.0, color: iconColor)),
        ),
      ),
    );
  }
}
