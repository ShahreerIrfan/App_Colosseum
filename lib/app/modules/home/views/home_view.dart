import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../routes/app_pages.dart';
import '../controllers/home_controller.dart';
import '../widgets/map_marker_widget.dart';

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
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    // Base Map: Crisp Google Maps standard tiles
                    TileLayer(
                      urlTemplate:
                          'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                      subdomains: const ['0', '1', '2', '3'],
                      userAgentPackageName: 'com.example.colosseum_client',
                      maxZoom: 20,
                    ),

                    // Exact Colosseum Center UI Map Marker
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: HomeController.colosseumCoordinates,
                          width: 120,
                          height: 100,
                          alignment: Alignment.topCenter,
                          child: MapMarkerWidget(
                            label: 'Colosseum',
                            number: '1',
                            onTap: () => Get.toNamed(
                              Routes.floors,
                              arguments: {'landmarkName': 'Colosseum'},
                            ),
                          ),
                        ),
                      ],
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
            ],
          ),
        ),
      ),
    );
  }
}

