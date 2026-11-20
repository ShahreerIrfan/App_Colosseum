// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/tour_localizations.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/contain_circle_camera_constraint.dart';
import '../../../data/models/floor_definition.dart';
import '../../../data/models/map_view_type.dart';
import '../../../data/services/offline_landmark_store.dart';
import '../../../data/services/pedestrian_navigation_engine.dart';
import '../../../data/services/tour_analytics_service.dart';
import '../../../routes/app_pages.dart';
import '../controllers/home_controller.dart';
import '../widgets/landmark_markers_layer.dart';
import '../widgets/landmark_detail_card.dart';
import '../widgets/landmark_download_dialog.dart';
import '../widgets/user_location_map_marker.dart';

class AllPointsMapView extends GetView<HomeController> {
  const AllPointsMapView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    // Pre-cache landmark logo images for smooth and instant map marker rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        LandmarkMarkersLayer.prewarm(context, controller.landmarkMarkers);
      }
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

                    // Layer 2: Park boundary
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

                    // Layer 3: Tour Itinerary Route Polyline
                    Obx(() {
                      if (!controller.isTourActive.value) {
                        return const SizedBox.shrink();
                      }
                      final points = controller.currentTourRoutePoints;
                      if (points.length < 2) {
                        return const SizedBox.shrink();
                      }
                      return PolylineLayer(
                        key: const Key('tour_route_layer'),
                        polylines: [
                          Polyline(
                            points: points,
                            strokeWidth: 4.5,
                            color: colors.primary,
                            borderColor: colors.card,
                            borderStrokeWidth: 1.5,
                            strokeCap: StrokeCap.round,
                            strokeJoin: StrokeJoin.round,
                          ),
                        ],
                      );
                    }),

                    // Layer 3b: Landmark Walking Directions Polyline
                    Obx(() {
                      final points = controller.landmarkDirectionsRoute;
                      if (points.length < 2) {
                        return const SizedBox.shrink();
                      }
                      return PolylineLayer(
                        key: const Key('landmark_directions_route_layer'),
                        polylines: [
                          Polyline(
                            points: points,
                            strokeWidth: 4.5,
                            color: colors.primary,
                            borderColor: colors.card,
                            borderStrokeWidth: 1.5,
                            strokeCap: StrokeCap.round,
                            strokeJoin: StrokeJoin.round,
                          ),
                        ],
                      );
                    }),

                    // Layer 4: Landmark Logo Image Badges from assets/logo (All 5 Locations)
                    Obx(() {
                      if (!controller.isLandmarksVisible.value) {
                        return const SizedBox.shrink();
                      }
                      return LandmarkMarkersLayer(
                        markers: controller.landmarkMarkers,
                        selectedLandmarkId: controller.selectedLandmarkId.value,
                        currentZoom: controller.currentZoom.value,
                        onLandmarkTap: (id) => _showLandmarkActions(context, id),
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
                              controller.userLocation.value == null
                                  ? 'GPS location unavailable'.tourText
                                  : 'you are not in the zone',
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

              // Turn-by-Turn Outdoor Walking Navigation Banner
              Positioned(
                top: 64,
                left: 12,
                right: 12,
                child: Obx(() {
                  final navStatus = controller.pedestrianNavStatus.value;
                  final isNavigating = controller.pedestrianNavEngine.isNavigating;
                  if (!isNavigating || navStatus.instruction.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final target = navStatus.targetLandmark;
                  final totalDistMeters = navStatus.totalRemainingDistanceMeters.round();
                  final isMuted = controller.isVoiceGuidanceMuted.value;

                  return Center(
                    child: Material(
                      elevation: 4,
                      color: colors.card,
                      borderRadius: AppRadius.borderLg,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.borderLg,
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.15),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Maneuver Icon
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.1),
                                borderRadius: AppRadius.borderMd,
                              ),
                              child: Icon(
                                _getManeuverIcon(navStatus.maneuver),
                                color: colors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Direction Instruction & Destination Target
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    navStatus.instruction,
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
                                    target != null
                                        ? '${target.name} • ${totalDistMeters}m'
                                        : '${navStatus.distanceToNextTurnMeters.round()}m ahead',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.mutedForeground,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // Voice Guidance Mute / Unmute Button
                            IconButton(
                              icon: Icon(
                                isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                color: isMuted ? colors.mutedForeground : colors.primary,
                                size: 20,
                              ),
                              onPressed: controller.toggleVoiceGuidance,
                              tooltip: isMuted ? 'Unmute Voice' : 'Mute Voice',
                              visualDensity: VisualDensity.compact,
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
                                      : 'Satellite'.tourText,
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

              Positioned(
                top: 12,
                left: 12,
                child: Material(
                  color: colors.card,
                  borderRadius: AppRadius.borderMd,
                  child: IconButton(
                    tooltip: 'Offline tour downloads'.tourText,
                    icon: const Icon(Icons.sync),
                    onPressed: () => _showTourDownloads(context),
                  ),
                ),
              ),

              // Bottom Tour Action / Arrival Overlay
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Obx(() {
                  final activeLandmark = controller.activeLandmarkForCard.value;
                  if (controller.isLandmarkCardVisible.value && activeLandmark != null) {
                    final userPos = controller.userLocation.value;
                    final distance = userPos != null
                        ? const Distance().as(LengthUnit.Meter, userPos, activeLandmark.coordinates)
                        : null;
                    final onboarding = activeLandmark.onboardingModel;
                    return KeyedSubtree(
                      key: ValueKey('landmark_card_${activeLandmark.id}'),
                      child: LandmarkDetailCard(
                        key: const Key('landmark_arrival_popup'),
                        landmark: activeLandmark,
                        onboarding: onboarding,
                        isPlaying: controller.isLandmarkAudioPlaying.value,
                        isCollapsed: controller.isLandmarkCardCollapsed.value,
                        progress: controller.landmarkAudioProgress.value,
                        distanceMeters: distance,
                        onToggleAudio: controller.toggleLandmarkAudio,
                        onToggleCollapse: controller.toggleLandmarkCardCollapse,
                        onClose: controller.dismissLandmarkCard,
                        onEnterMonument: controller.enterLandmarkFromCard,
                        onSkip: controller.skipApproachingLandmark,
                        onDirections: () => controller.getDirectionsToLandmark(activeLandmark),
                      ),
                    );
                  }

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.15),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          )),
                          child: child,
                        ),
                      );
                    },
                    child: controller.isTourActive.value
                        ? KeyedSubtree(
                            key: const ValueKey('active_tour_bar'),
                            child: _buildActiveTourBar(context),
                          )
                        : KeyedSubtree(
                            key: const ValueKey('start_tour_button'),
                            child: _buildStartTourButton(context),
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

  OfflineLandmarkStore get _offlineStore => Get.isRegistered<OfflineLandmarkStore>()
      ? Get.find<OfflineLandmarkStore>() : OfflineLandmarkStore();

  Future<void> _showLandmarkActions(BuildContext context, String id) async {
    controller.selectedLandmarkId.value = id;
    final marker = controller.landmarkMarkers.firstWhereOrNull((m) => m.id == id);
    if (marker != null) {
      controller.showLandmarkOnboarding(marker, autoTriggered: false, autoPlayAudio: false);
      return;
    }
    final overlay = controller.landmarkOverlays.firstWhereOrNull((o) => o.id == id);
    final name = overlay?.name ?? FloorDefinition.landmarkNameFor(id);
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => LandmarkDownloadDialog(
        landmarkId: id,
        name: name,
        category: marker?.category,
        imagePath: marker?.imagePath ?? overlay?.assetPath,
        thumbnailUrl: marker?.thumbnailUrl ?? overlay?.thumbnailUrl,
        description: overlay?.description,
        language: controller.tourLanguage,
        voiceLocale: controller.ttsLocale,
        store: _offlineStore,
        onEnter: (package) => controller.navigateToLandmarkDetails(id, offline: package),
      ),
    );
  }

  Future<void> _showSavedLandmarks(BuildContext context) async {
    final package = await showDialog<OfflineLandmark>(
      context: context,
      builder: (context) => SavedLandmarkDownloads(language: controller.tourLanguage, store: _offlineStore),
    );
    if (package != null && context.mounted) {
      controller.navigateToLandmarkDetails(package.landmark.id, offline: package);
    }
  }

  Future<void> _showTourDownloads(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Obx(() {
          final downloaded = controller.lastBundleDownload.value?.toLocal();
          final busy = controller.isDownloadingBundle.value;
          final message = controller.bundleDownloadMessage.value;
          final formatter = MaterialLocalizations.of(sheetContext);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Offline tour'.tourText, style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(downloaded == null
                  ? 'No recorded download yet.'.tourText
                  : 'Last download: {time}'.tourTextWith({
                    'time': '${formatter.formatMediumDate(downloaded)} '
                        '${formatter.formatTimeOfDay(TimeOfDay.fromDateTime(downloaded))}',
                  })),
              Text('Downloads include tour content. Map tiles and device voices are separate.'.tourText),
              if (message != null) Text(message, semanticsLabel: message),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: busy ? null : controller.downloadTourBundle,
                child: Text(busy ? 'Downloading…'.tourText : 'Download latest tour'.tourText),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _showSavedLandmarks(context);
                },
                child: Text('Downloaded landmarks'.tourText),
              ),
              TextButton(
                onPressed: () => _showAnalyticsPrivacy(sheetContext),
                child: Text('Tour analytics privacy'.tourText),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Get.offAllNamed(Routes.language);
                },
                child: Text('Change language'.tourText),
              ),
            ],
          );
        }),
      ),
    ),
  );

  Future<void> _showAnalyticsPrivacy(BuildContext context) async {
    final analytics = TourAnalyticsService.instance;
    final initial = await analytics.consent;
    final policy = Uri.tryParse(const String.fromEnvironment('COLOSSEUM_PRIVACY_URL'));
    final hasPolicy = policy != null && policy.scheme == 'https' && policy.host.isNotEmpty;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var allowed = initial;
        return StatefulBuilder(builder: (context, setState) => AlertDialog(
          title: Text('Tour analytics'.tourText),
          content: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Optionally share tour activity, such as stops visited and narration completion. Analytics uses a random identifier and does not collect GPS coordinates or your name. Sent events expire after 90 days. Turning this off clears unsent events.'.tourText),
              if (hasPolicy)
                TextButton(
                  onPressed: () async {
                    var opened = false;
                    try {
                      opened = await launchUrl(policy, mode: LaunchMode.externalApplication);
                    } catch (_) {
                      // The offline disclosure remains visible when no browser is available.
                    }
                    if (!opened && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not open the privacy notice.'.tourText)),
                      );
                    }
                  },
                  child: Text('Read the privacy notice'.tourText),
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Share tour activity'.tourText),
                value: allowed,
                onChanged: (value) => setState(() => allowed = value),
              ),
            ],
          )),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('Cancel'.tourText)),
            FilledButton(
              onPressed: () async {
                await analytics.setConsent(allowed);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: Text('Save'.tourText),
            ),
          ],
        ));
      },
    );
  }

  Widget _buildStartTourButton(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: colors.primary,
        borderRadius: BorderRadius.circular(28),
        elevation: 4,
        shadowColor: colors.primary.withValues(alpha: 0.4),
        child: InkWell(
          key: const Key('map_start_tour_button'),
          onTap: controller.startTour,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 14.0,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colors.primaryForeground.withValues(alpha: 0.25),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.route_rounded,
                  size: 20,
                  color: colors.primaryForeground,
                ),
                const SizedBox(width: 8),
                Text(
                  'Show Itinerary'.tourText,
                  style: textTheme.labelLarge?.copyWith(
                    color: colors.primaryForeground,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTourBar(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final remaining = controller.remainingTourLandmarks;

    return Material(
      key: const Key('map_active_tour_bar'),
      color: colors.card,
      borderRadius: AppRadius.borderLg,
      elevation: 4,
      shadowColor: colors.foreground.withValues(alpha: 0.1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: AppRadius.borderLg,
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_walk_rounded,
                size: 20,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    remaining.isNotEmpty
                        ? 'Next: {place}'.tourTextWith({'place': remaining.first.name})
                        : 'Tour Complete',
                    style: textTheme.labelLarge?.copyWith(
                      color: colors.foreground,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    remaining.isNotEmpty
                        ? (remaining.length == 1 ? '{count} landmark remaining' : '{count} landmarks remaining')
                        .tourTextWith({'count': remaining.length})
                        : 'All landmarks visited or skipped',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.mutedForeground,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: colors.destructive.withValues(alpha: 0.1),
              borderRadius: AppRadius.borderMd,
              child: InkWell(
                key: const Key('map_end_tour_button'),
                onTap: controller.stopTour,
                borderRadius: AppRadius.borderMd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 6.0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.stop_circle_outlined,
                        size: 16,
                        color: colors.destructive,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'End Tour'.tourText,
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.destructive,
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
    );
  }
  IconData _getManeuverIcon(PedestrianManeuverType maneuver) {
    switch (maneuver) {
      case PedestrianManeuverType.slightRight:
      case PedestrianManeuverType.turnRight:
        return Icons.turn_right_rounded;
      case PedestrianManeuverType.sharpRight:
        return Icons.u_turn_right_rounded;
      case PedestrianManeuverType.slightLeft:
      case PedestrianManeuverType.turnLeft:
        return Icons.turn_left_rounded;
      case PedestrianManeuverType.sharpLeft:
        return Icons.u_turn_left_rounded;
      case PedestrianManeuverType.uTurn:
        return Icons.u_turn_right_rounded;
      case PedestrianManeuverType.arrived:
        return Icons.check_circle_rounded;
      case PedestrianManeuverType.straight:
        return Icons.straight_rounded;
    }
  }
}

typedef AllPointsMap = AllPointsMapView;
