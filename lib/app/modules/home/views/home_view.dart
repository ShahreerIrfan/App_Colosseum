import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../data/models/map_view_type.dart';
import '../controllers/home_controller.dart';
import '../widgets/landmark_overlay_layer.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    // Pre-warm Flutter's memory image cache with the 5 transparent landmark PNG overlays
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LandmarkOverlayLayer.prewarm(context, controller.landmarkOverlays);
    });

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

                    // Layer 2: Reusable Geo-Anchored Landmark Ground Overlays (All 5 Monuments)
                    // Colosseum.png is directly clickable to navigate to floors.
                    Obx(() {
                      if (!controller.isLandmarksVisible.value) {
                        return const SizedBox.shrink();
                      }
                      return LandmarkOverlayLayer(
                        overlays: controller.landmarkOverlays,
                        currentZoom: controller.currentZoom.value,
                        isDebug: controller.isDebugLandmarks.value,
                      );
                    }),
                  ],
                ),
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
