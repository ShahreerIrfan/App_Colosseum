import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/theme_extensions.dart';
import '../controllers/home_controller.dart';
import '../widgets/poi_marker_widget.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

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
                    onPositionChanged: controller.onPositionChanged,
                    onTap: (_, point) => controller.onMapTap(point),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    // Base Map: Crisp Google Maps standard tiles
                    TileLayer(
                      urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                      subdomains: const ['0', '1', '2', '3'],
                      userAgentPackageName: 'com.example.colosseum_client',
                      maxZoom: 20,
                    ),

                    // Georeferenced Architectural Ground Overlay (Direct transparent PNG over Google Map)
                    Obx(
                      () => OverlayImageLayer(
                        overlayImages: controller.landmarks
                            .where(
                              (poi) =>
                                  poi.bounds != null &&
                                  poi.overlayAssetPath != null &&
                                  controller.isOverlayActive(poi),
                            )
                            .map(
                              (poi) => OverlayImage(
                                bounds: poi.bounds!,
                                imageProvider: AssetImage(
                                  poi.overlayAssetPath!,
                                ),
                                opacity: 1.0,
                                gaplessPlayback: true,
                              ),
                            )
                            .toList(),
                      ),
                    ),

                    // Layer 3: POI Markers (For far-zoom discovery or point landmarks)
                    Obx(
                      () => MarkerLayer(
                        markers: controller.landmarks
                            .where((poi) => controller.isMarkerVisible(poi))
                            .map((poi) {
                              final isSelected =
                                  controller.selectedPoi.value?.id == poi.id;
                              return Marker(
                                point: LatLng(poi.latitude, poi.longitude),
                                width: 140,
                                height: 140,
                                alignment: Alignment.topCenter,
                                child: PoiMarkerWidget(
                                  poi: poi,
                                  isSelected: isSelected,
                                  currentZoom: controller.currentZoom.value,
                                  onTap: () => controller.selectPoi(poi),
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Top Controls Overlay (Recenter on Colosseum)
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: colors.card,
                  borderRadius: AppRadius.borderMd,
                  elevation: 2,
                  child: InkWell(
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
              ),

              // Bottom Selected POI Info Card Overlay
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Obx(() {
                  final poi = controller.selectedPoi.value;
                  if (poi == null) return const SizedBox.shrink();

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: AppRadius.borderLg,
                      border: Border.all(color: colors.primary, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: colors.foreground.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: Image.asset(
                                poi.assetPath,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    poi.name,
                                    style: textTheme.titleMedium?.copyWith(
                                      color: colors.foreground,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (poi.description.isNotEmpty)
                                    Text(
                                      poi.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colors.mutedForeground,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              color: colors.mutedForeground,
                              onPressed: controller.clearSelection,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
