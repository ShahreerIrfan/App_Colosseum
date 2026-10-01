import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../data/models/tour_navigation_state.dart';
import '../controllers/floor_map_controller.dart';

/// Interactive Floating Tour Simulator overlay for testing GPS/Indoor location walking,
/// arrival dwell, TTS navigation, auto-play audio, mark-as-visited, and departure hysteresis.
class TourSimulatorPanel extends GetView<FloorMapController> {
  const TourSimulatorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    return Obx(() {
      final isExpanded = controller.isSimulatorExpanded.value;
      final isSimulating = controller.isSimulating.value;
      final isTapToMove = controller.isTapToMoveEnabled.value;
      final state = controller.tourState.value;

      if (!isExpanded) {
        // Collapsed Floating Button (Badge showing "Simulate Tour")
        return Material(
          color: colors.primary,
          elevation: 4.0,
          borderRadius: BorderRadius.circular(24.0),
          shadowColor: colors.primary.withValues(alpha: 0.4),
          child: InkWell(
            key: const Key('open_simulator_panel_button'),
            onTap: controller.toggleSimulatorExpanded,
            borderRadius: BorderRadius.circular(24.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSimulating
                        ? Icons.directions_walk_rounded
                        : Icons.smart_toy_rounded,
                    color: colors.primaryForeground,
                    size: 16.0,
                  ),
                  const SizedBox(width: 6.0),
                  Text(
                    isSimulating ? 'Walking Tour…' : 'Tour Simulator',
                    style: TextStyle(
                      color: colors.primaryForeground,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Expanded Control Panel
      return Container(
        width: 320.0,
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(
            color: colors.border,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 16.0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Title & Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5.0),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Icon(
                        Icons.smart_toy_rounded,
                        color: colors.primary,
                        size: 16.0,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      'Tour Walk Simulator',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  key: const Key('close_simulator_panel_button'),
                  onTap: controller.toggleSimulatorExpanded,
                  borderRadius: BorderRadius.circular(14.0),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.close_rounded,
                      color: colors.muted,
                      size: 18.0,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10.0),

            // Main Action 1: Auto-Walk Tour Play / Pause Button
            FilledButton.icon(
              key: const Key('toggle_autowalk_simulation_button'),
              onPressed: controller.toggleAutoWalkSimulation,
              icon: Icon(
                isSimulating ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 18.0,
                color: colors.primaryForeground,
              ),
              label: Text(
                isSimulating ? 'Pause Auto-Walk' : 'Auto-Walk Full Itinerary',
                style: TextStyle(
                  color: colors.primaryForeground,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: isSimulating ? Colors.orange.shade700 : colors.primary,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),

            const SizedBox(height: 8.0),

            // Speed & Tap-to-Move Controls
            Row(
              children: [
                // Speed Selector
                Expanded(
                  child: Container(
                    height: 34.0,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: colors.border.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: colors.border, width: 0.8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Speed:',
                          style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w600),
                        ),
                        Row(
                          children: [1.0, 2.0, 3.5].map((s) {
                            final isSel = (controller.simulationSpeed.value - s).abs() < 0.1;
                            return InkWell(
                              onTap: () => controller.setSimulationSpeed(s),
                              borderRadius: BorderRadius.circular(4.0),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                                padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
                                decoration: BoxDecoration(
                                  color: isSel ? colors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Text(
                                  '${s.toInt()}x',
                                  style: TextStyle(
                                    color: isSel ? Colors.white : colors.foreground,
                                    fontSize: 10.5,
                                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6.0),
                // Tap-to-Move Toggle
                InkWell(
                  key: const Key('toggle_tap_to_move_button'),
                  onTap: controller.toggleTapToMove,
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    height: 34.0,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: isTapToMove
                          ? colors.primary.withValues(alpha: 0.15)
                          : colors.border.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: isTapToMove ? colors.primary : colors.border,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 13.0,
                          color: isTapToMove ? colors.primary : colors.foreground,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          'Tap Map',
                          style: TextStyle(
                            color: isTapToMove ? colors.primary : colors.foreground,
                            fontSize: 11.0,
                            fontWeight: isTapToMove ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8.0),

            // Teleport to Viewpoint Quick Buttons
            const Text(
              'Teleport to Arrival Zone (<= 4m):',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.grey),
            ),
            const SizedBox(height: 4.0),
            Wrap(
              spacing: 4.0,
              runSpacing: 4.0,
              children: [
                _buildTeleportChip('ENTRY', () => controller.teleportToEntry(), colors),
                _buildTeleportChip('100', () => controller.teleportToStop('vp_100'), colors),
                _buildTeleportChip('101', () => controller.teleportToStop('vp_101'), colors),
                _buildTeleportChip('102', () => controller.teleportToStop('vp_102'), colors),
                _buildTeleportChip('103', () => controller.teleportToStop('vp_103'), colors),
                _buildTeleportChip('104', () => controller.teleportToStop('vp_104'), colors),
                _buildTeleportChip('105', () => controller.teleportToStop('vp_105'), colors),
                _buildTeleportChip('106', () => controller.teleportToStop('vp_106'), colors),
                _buildTeleportChip('EXIT', () => controller.teleportToExit(), colors),
              ],
            ),

            const SizedBox(height: 8.0),

            // Simulation Action Helper: If at viewpoint or visited, show quick Step Departure
            if (state.navigationStatus == TourNavigationStatus.arrived ||
                state.navigationStatus == TourNavigationStatus.viewpointAudioPlaying ||
                state.navigationStatus == TourNavigationStatus.waitingAtViewpoint ||
                state.navigationStatus == TourNavigationStatus.waitingForVisited ||
                state.navigationStatus == TourNavigationStatus.waitingForDeparture)
              OutlinedButton.icon(
                key: const Key('step_departure_button'),
                onPressed: controller.stepSimulatedDeparture,
                icon: const Icon(Icons.directions_walk_rounded, size: 15.0),
                label: const Text(
                  'Simulate Departure (Walk >= 7m away)',
                  style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),

            // Reset Tour Button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const Key('reset_tour_simulation_button'),
                onPressed: controller.resetTour,
                icon: const Icon(Icons.refresh_rounded, size: 14.0),
                label: const Text(
                  'Reset Tour',
                  style: TextStyle(fontSize: 11.0),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTeleportChip(String label, VoidCallback onTap, dynamic colors) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 3.5),
        decoration: BoxDecoration(
          color: colors.border.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(color: colors.border, width: 0.8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: colors.foreground,
          ),
        ),
      ),
    );
  }
}
