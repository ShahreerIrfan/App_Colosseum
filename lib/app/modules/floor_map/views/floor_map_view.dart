import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/theme_extensions.dart';
import '../controllers/floor_map_controller.dart';
import '../widgets/floor_plan_painter.dart';
import '../widgets/route_painter.dart';
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
            // 1. Dominant Interactive Floor Map Canvas (Anchored fixed position)
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: controller.transformationController,
                panEnabled: false,
                scaleEnabled: false,
                minScale: 0.8,
                maxScale: 3.5,
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

                            // Layer 2: Walking Route Path (User -> Selected Viewpoint)
                            Obx(
                              () => controller.routePoints.isNotEmpty
                                  ? CustomPaint(
                                      size: mapSize,
                                      painter: RoutePainter(
                                        normalizedPoints: controller.routePoints,
                                        routeColor: colors.primary,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),

                            // Layer 3: Animated User Indoor Location Puck
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

                            // Layer 4: Interactive Viewpoint Markers
                            Obx(() {
                              final selectedVp = controller.selectedViewpoint.value;
                              final isPlaying = controller.isPlayingAudio.value;

                              return Stack(
                                clipBehavior: Clip.none,
                                children: controller.viewpoints.map((vp) {
                                  final isSelected = selectedVp?.id == vp.id;
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

            // 4. Contextual Bottom Viewpoint Detail Card
            Positioned(
              left: 16.0,
              right: 16.0,
              bottom: 16.0,
              child: Obx(() {
                final selectedVp = controller.selectedViewpoint.value;
                if (selectedVp == null) return const SizedBox.shrink();

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.25),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: ViewpointDetailCard(
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
