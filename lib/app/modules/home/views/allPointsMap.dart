// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/contain_circle_camera_constraint.dart';
import '../../../data/models/map_view_type.dart';
import '../controllers/home_controller.dart';
import '../widgets/landmark_markers_layer.dart';
import '../widgets/user_location_map_marker.dart';

class AllPointsMapView extends GetView<HomeController> {
  const AllPointsMapView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Stack(
            children: [
              // Map Viewport Container with rounded borders matching the wireframe
              Container(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.borderLg,
                  border: Border.all(color: colors.border, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: colors.foreground.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: FlutterMap(
                  mapController: controller.mapController,
                  options: MapOptions(
                    initialCenter: HomeController.colosseumCoordinates,
                    initialZoom: HomeController.defaultZoom,
                    minZoom: 13.0,
                    maxZoom: 18.5,
                    cameraConstraint: const ContainCircleCameraConstraint(
                      circleCenter: HomeController.colosseumCoordinates,
                      circleRadiusMeters: HomeController.zoneBoundaryRadiusMeters,
                    ),
                    onPositionChanged: controller.onPositionChanged,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    // Layer 1: Dynamic Base Map (Google Maps Standard vs Satellite)
                    Obx(() {
                      final isSatellite =
                          controller.selectedMapView.value == MapViewType.satellite;
                      return TileLayer(
                        key: ValueKey(controller.selectedMapView.value),
                        urlTemplate: isSatellite
                            ? 'https://mt{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}'
                            : 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                        subdomains: const ['0', '1', '2', '3'],
                        userAgentPackageName: 'com.example.colosseum_client',
                        maxZoom: 20,
                      );
                    }),

                    // Layer 2: 600-meter boundary circle centered on Colosseum
                    // Greenish when user is in the circle, reddish otherwise
                    Obx(() {
                      final inZone = controller.isUserInZone;
                      final circleColor = inZone
                          ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                          : colors.primary.withValues(alpha: 0.12);
                      final borderColor = inZone
                          ? const Color(0xFF2E7D32).withValues(alpha: 0.75)
                          : colors.primary.withValues(alpha: 0.75);

                      return CircleLayer(
                        key: const Key('colosseum_boundary_circle_layer'),
                        circles: [
                          CircleMarker(
                            key: const Key('colosseum_boundary_circle'),
                            point: HomeController.colosseumCoordinates,
                            radius: HomeController.zoneBoundaryRadiusMeters,
                            useRadiusInMeter: true,
                            color: circleColor,
                            borderColor: borderColor,
                            borderStrokeWidth: 2.0,
                          ),
                        ],
                      );
                    }),

                    // Layer 3: Classic Location Pins + Labels for Roman Monuments (All 5 Locations)
                    Obx(() {
                      if (!controller.isLandmarksVisible.value) {
                        return const SizedBox.shrink();
                      }
                      return LandmarkMarkersLayer(
                        markers: controller.landmarkMarkers,
                        selectedLandmarkId: controller.selectedLandmarkId.value,
                        currentZoom: controller.currentZoom.value,
                        onLandmarkTap: controller.selectLandmark,
                      );
                    }),

                    // Layer 4: Live User Location Marker (anchored at real-world coordinates)
                    Obx(() {
                      final user = controller.userLocation.value;
                      if (user == null) {
                        return const SizedBox.shrink();
                      }
                      return MarkerLayer(
                        key: const Key('user_location_layer'),
                        markers: [
                          Marker(
                            key: const Key('user_location_marker'),
                            point: user,
                            width: 44.0,
                            height: 44.0,
                            alignment: Alignment.center,
                            child: UserLocationMapMarker(
                              headingDegrees: controller.userHeading.value,
                              puckColor: const Color(0xFF00A6FF),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),

              // Top Warning Overlay: "you are not in the zone" banner when outside the 600m circle
              Positioned(
                top: 56,
                left: 12,
                right: 12,
                child: Obx(() {
                  if (controller.isUserInZone) {
                    return const SizedBox.shrink();
                  }
                  return Align(
                    alignment: Alignment.topCenter,
                    child: Material(
                      color: colors.card,
                      borderRadius: AppRadius.borderMd,
                      elevation: 2,
                      child: Container(
                        key: const Key('out_of_zone_banner'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.borderMd,
                          border: Border.all(
                            color: colors.destructive,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: colors.destructive,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'you are not in the zone',
                              style: textTheme.labelMedium?.copyWith(
                                color: colors.destructive,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),

              // Top Controls Overlay (Map View Toggle + Recenter on Colosseum)
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Toggle Map View (General vs Satellite)
                    Material(
                      color: colors.card,
                      borderRadius: AppRadius.borderMd,
                      elevation: 2,
                      child: InkWell(
                        key: const Key('home_toggle_map_view_button'),
                        onTap: controller.toggleMapView,
                        borderRadius: AppRadius.borderMd,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 8.0,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: AppRadius.borderMd,
                            border: Border.all(color: colors.border),
                          ),
                          child: Obx(
                            () => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  controller.selectedMapView.value ==
                                          MapViewType.satellite
                                      ? Icons.layers_rounded
                                      : Icons.satellite_alt_rounded,
                                  size: 18,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  controller.selectedMapView.value ==
                                          MapViewType.satellite
                                      ? 'General'
                                      : 'Satellite',
                                  style: textTheme.labelMedium?.copyWith(
                                    color: colors.foreground,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Recenter on Colosseum
                    Material(
                      color: colors.card,
                      borderRadius: AppRadius.borderMd,
                      elevation: 2,
                      child: InkWell(
                        key: const Key('home_recenter_button'),
                        onTap: controller.centerOnColosseum,
                        borderRadius: AppRadius.borderMd,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: AppRadius.borderMd,
                            border: Border.all(color: colors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.center_focus_strong_rounded,
                                size: 18,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Colosseum',
                                style: textTheme.labelMedium?.copyWith(
                                  color: colors.foreground,
                                  fontWeight: FontWeight.w600,
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
            ],
          ),
        ),
      ),
    );
  }
}

typedef AllPointsMap = AllPointsMapView;
