import '../../../core/localization/tour_localizations.dart';
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/floor_definition.dart';
import '../../../data/models/landmark_marker_model.dart';
import '../../../data/models/landmark_overlay_model.dart';
import '../../../data/models/map_view_type.dart';
import '../../../data/models/user_orientation_state.dart';
import '../../../data/repositories/i_tour_repository.dart';
import '../../../data/repositories/tour_repository_impl.dart';
import '../../../data/services/compass_service.dart';
import '../../../data/services/gps_location_service.dart';
import '../../../data/services/offline_landmark_store.dart';
import '../../../data/services/tour_sync_service.dart';
import '../../../data/models/tour_bundle_model.dart';
import '../../../data/services/pedestrian_street_router.dart';
import '../../../data/services/tour_analytics_service.dart';
import '../../../routes/app_pages.dart';
import '../views/allPointsMap.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  late final MapController mapController;
  final ITourRepository tourRepository;
  final GpsLocationService gpsLocationService;
  final CompassService compassService;
  String ttsLocale = 'en-US';
  String tourLanguage = 'en';
  String? _outdoorAnalyticsSession;

  void _recordOutdoorEvent(String type, {String? landmark}) {
    final session = _outdoorAnalyticsSession;
    if (session == null) return;
    unawaited(TourAnalyticsService.instance.record(
      sessionId: session, type: type, tourKind: 'outdoor',
      language: tourLanguage, landmarkId: landmark,
    ));
  }

  void _finishOutdoorAnalyticsIfDone() {
    if (remainingTourLandmarks.isNotEmpty) return;
    _recordOutdoorEvent('tour_completed');
    _outdoorAnalyticsSession = null;
  }
  final lastBundleDownload = Rxn<DateTime>();
  final isDownloadingBundle = false.obs;
  final bundleDownloadMessage = RxnString();
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<UserOrientationState>? _compassSubscription;
  StreamSubscription<TourBundleModel>? _tourUpdates;
  TourSyncService? get _sync => Get.isRegistered<TourSyncService>() ? Get.find<TourSyncService>() : null;


  static const LatLng colosseumCoordinates = LatLng(41.890210, 12.492231);
  static const double defaultZoom = 16.5;

  /// Radius of the Colosseum archaeological boundary zone in meters.
  static const double zoneBoundaryRadiusMeters = 600.0;

  final currentZoom = defaultZoom.obs;

  /// Single source of truth for the 5 classic landmark pin markers.
  final landmarkMarkers = <LandmarkMarkerModel>[...LandmarkMarkerModel.all].obs;

  /// Currently selected landmark id (defaults to 'colosseum').
  final selectedLandmarkId = RxnString('colosseum');

  /// Single source of truth for the 5 calibrated landmark overlays (legacy / offline sync).
  final landmarkOverlays = <MapLandmarkOverlay>[...MapLandmarkOverlay.all].obs;

  /// Global toggle for landmark marker rendering.
  final isLandmarksVisible = true.obs;

  /// Debug mode toggle for developer alignment tools and visual bounds.
  final isDebugLandmarks = false.obs;

  /// Active base map view type (General vs Satellite).
  final selectedMapView = MapViewType.satellite.obs;

  /// Real-time user geographic location.
  final userLocation = Rxn<LatLng>();

  /// Real-time user device heading in degrees [0, 360).
  final userHeading = RxnDouble();

  /// Estimated GPS accuracy in meters.
  final locationAccuracy = 3.0.obs;

  /// Default initial user location when starting tour without GPS fix (Parco Celio).
  static const LatLng defaultTourStartLocation = LatLng(41.888500, 12.492500);

  /// Whether active tour navigation is currently enabled.
  final isTourActive = false.obs;

  /// IDs of landmarks that user has entered/visited.
  final visitedLandmarkIds = <String>{}.obs;

  /// IDs of landmarks that user has skipped.
  final skippedLandmarkIds = <String>{}.obs;

  /// IDs of landmarks that have already prompted the user upon proximity.
  final hasPromptedLandmarkIds = <String>{}.obs;

  /// Landmark currently within proximity threshold awaiting user action (Enter or Skip).
  final approachingLandmark = Rxn<LandmarkMarkerModel>();

  /// Remaining unvisited and unskipped landmarks in the tour.
  List<LandmarkMarkerModel> get remainingTourLandmarks {
    final visited = visitedLandmarkIds.toSet();
    final skipped = skippedLandmarkIds.toSet();
    return landmarkMarkers.where((m) {
      return !visited.contains(m.id) && !skipped.contains(m.id);
    }).toList();
  }

  final _pedestrianRouter = PedestrianStreetRouter.instance.obs;
  int _pedestrianRefreshGeneration = 0;

  /// Dynamically calculated planned itinerary route points following real streets and roads.
  List<LatLng> get currentTourRoutePoints => _buildOutdoorRoute();

  ({List<LatLng> points, List<String> instructions}) get currentTourRouteDetails {
    final instructions = <String>[];
    return (points: _buildOutdoorRoute(instructions: instructions), instructions: instructions);
  }

  List<LatLng> _buildOutdoorRoute({List<String>? instructions}) {
    if (!isTourActive.value) return const [];
    final start = userLocation.value ?? defaultTourStartLocation;
    final remaining = remainingTourLandmarks;
    if (remaining.isEmpty) return const [];

    return _pedestrianRouter.value.routeItinerary(start, remaining,
      firstLegInstructions: instructions);
  }

  /// Starts the interactive tour itinerary.
  void startTour() {
    if (_outdoorAnalyticsSession != null) _recordOutdoorEvent('tour_stopped');
    _outdoorAnalyticsSession = TourAnalyticsService.newId();
    _recordOutdoorEvent('tour_started');
    isTourActive.value = true;
    visitedLandmarkIds.clear();
    skippedLandmarkIds.clear();
    hasPromptedLandmarkIds.clear();
    approachingLandmark.value = null;
    final location = userLocation.value;
    if (location != null) checkProximityToLandmarks(location);
    try {
      mapController.move(location ?? defaultTourStartLocation, defaultZoom);
    } catch (_) {}
  }

  /// Stops/ends the interactive tour.
  void stopTour() {
    _recordOutdoorEvent('tour_stopped');
    _outdoorAnalyticsSession = null;
    isTourActive.value = false;
    approachingLandmark.value = null;
  }

  /// Toggles the tour state between started and stopped.
  void toggleTour() {
    if (isTourActive.value) {
      stopTour();
    } else {
      startTour();
    }
  }

  /// Returns the calibrated proximity detection threshold in meters for each landmark.
  ///
  /// For large monuments like the Colosseum (190m diameter), visitors reach the outer
  /// border/wall and ticket plazas at 90-130m from the geometric center.
  static double getProximityThresholdForLandmark(String landmarkId) {
    switch (landmarkId) {
      case 'colosseum':
        // Colosseum outer border is 85-100m from center; 115m reliably captures border without overlapping Arch (138m)
        return 115.0;
      case 'roman_forum':
        return 120.0;
      case 'temple_of_venus_and_rome':
        return 95.0;
      case 'ludus_magnus':
        return 80.0;
      case 'arch_of_constantine':
      default:
        return 70.0;
    }
  }

  /// Checks if the user is in proximity to any upcoming tour landmark border.
  void checkProximityToLandmarks(LatLng currentPos) {
    if (!isTourActive.value) return;

    // If currently prompting for a landmark, check if user walked far away from it without deciding
    if (approachingLandmark.value != null) {
      final currentLandmark = approachingLandmark.value!;
      final threshold = getProximityThresholdForLandmark(currentLandmark.id);
      final distance = Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        currentLandmark.latitude,
        currentLandmark.longitude,
      );
      if (distance > threshold * 1.5) {
        approachingLandmark.value = null;
        hasPromptedLandmarkIds.remove(currentLandmark.id);
      }
      return;
    }

    LandmarkMarkerModel? closestLandmark;
    var smallestDistance = double.infinity;

    for (final landmark in remainingTourLandmarks) {
      if (hasPromptedLandmarkIds.contains(landmark.id)) continue;

      final threshold = getProximityThresholdForLandmark(landmark.id);
      final distance = Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        landmark.latitude,
        landmark.longitude,
      );

      if (distance <= threshold && distance < smallestDistance) {
        smallestDistance = distance;
        closestLandmark = landmark;
      }
    }

    if (closestLandmark != null) {
      hasPromptedLandmarkIds.add(closestLandmark.id);
      approachingLandmark.value = closestLandmark;
    }
  }

  /// User action: Enters the approaching landmark.
  /// Directly navigates to the landmark's detailed view (FloorMapView),
  /// bypassing the intermediary levels selection view.
  void enterApproachingLandmark() {
    final landmark = approachingLandmark.value;
    if (landmark == null) return;
    visitedLandmarkIds.add(landmark.id);
    _recordOutdoorEvent('landmark_entered', landmark: landmark.id);
    _finishOutdoorAnalyticsIfDone();
    visitedLandmarkIds.refresh();
    approachingLandmark.value = null;
    unawaited(_enterSavedOrLive(landmark.id));
  }

  /// User action: Skips the approaching landmark and continues to next point.
  void skipApproachingLandmark() {
    final landmark = approachingLandmark.value;
    if (landmark == null) return;
    skippedLandmarkIds.add(landmark.id);
    _recordOutdoorEvent('landmark_skipped', landmark: landmark.id);
    _finishOutdoorAnalyticsIfDone();
    skippedLandmarkIds.refresh();
    approachingLandmark.value = null;
  }

  /// Metric distance from the user's current location to the Colosseum center in meters.
  double? get distanceToColosseumMeters {
    final user = userLocation.value;
    if (user == null) return null;
    return GpsLocationService.calculateDistanceToCenter(
      user.latitude,
      user.longitude,
    );
  }

  /// Whether the user is currently located inside the 600m Colosseum zone.
  bool get isUserInZone {
    final user = userLocation.value;
    if (user == null) return false;
    final center = colosseumCoordinates;
    return Geolocator.distanceBetween(user.latitude, user.longitude,
      center.latitude, center.longitude) <= zoneBoundaryRadiusMeters;
  }

  HomeController({
    ITourRepository? tourRepository,
    GpsLocationService? gpsLocationService,
    CompassService? compassService,
  })  : tourRepository = tourRepository ??
            (Get.isRegistered<ITourRepository>()
                ? Get.find<ITourRepository>()
                : TourRepositoryImpl()),
        gpsLocationService = gpsLocationService ?? GpsLocationService(),
        compassService = compassService ?? CompassService();

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments;
    if (arguments is Map && arguments['ttsLocale'] is String) {
      ttsLocale = arguments['ttsLocale'] as String;
    }
    if (arguments is Map && arguments['language'] is String) {
      tourLanguage = arguments['language'] as String;
    }
    unawaited(TourAnalyticsService.instance.flush());
    WidgetsBinding.instance.addObserver(this);
    mapController = MapController();
    final sync = _sync;
    if (sync != null) {
      _tourUpdates = sync.snapshots.listen(_applyTourSnapshot);
      final snapshot = sync.snapshotFor(tourLanguage);
      if (snapshot != null) _applyTourSnapshot(snapshot);
      unawaited(sync.activate(tourLanguage));
    } else {
      _initLandmarkMarkers();
      _initLandmarkOverlays();
      unawaited(_initPedestrianRoutes());
      _initFloors();
    }
    _initLocationTracking();
  }

  void _applyTourSnapshot(TourBundleModel snapshot) {
    if (isClosed || !identical(_sync?.snapshotFor(tourLanguage), snapshot)) return;
    landmarkMarkers.assignAll(snapshot.landmarkMarkers);
    _applyOverlays(snapshot.landmarks);
    _pedestrianRouter.value.initializeRoutes(snapshot.pedestrianRoutes ?? []);
    _pedestrianRouter.refresh();
    final ids = snapshot.landmarkMarkers.map((marker) => marker.id).toSet();
    if (!ids.contains(selectedLandmarkId.value)) selectedLandmarkId.value = null;
    if (approachingLandmark.value case final LandmarkMarkerModel approaching) {
      approachingLandmark.value = snapshot.landmarkMarkers.firstWhereOrNull(
        (marker) => marker.id == approaching.id,
      );
    }
    unawaited(tourRepository.getLastBundleDownload(lang: tourLanguage).then((date) {
      if (!isClosed) lastBundleDownload.value = date;
    }));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(TourAnalyticsService.instance.flush());
      if (_sync == null) refreshLandmarks();
    }
  }

  void _initFloors() {
    _loadRepositoryFloors();
  }

  Future<void> _loadRepositoryFloors() async {
    try {
      final floors = await tourRepository.getFloors(lang: tourLanguage);
      if (floors.isNotEmpty) {
        FloorDefinition.cacheFloors(floors);
      }
    } catch (_) {}
  }

  void _initLandmarkMarkers() {
    _loadRepositoryMarkers();
  }

  Future<void> _loadRepositoryMarkers() async {
    try {
      final markers = await tourRepository.getLandmarkMarkers(lang: tourLanguage);
      if (markers.isNotEmpty) {
        landmarkMarkers.assignAll(markers);
      }
      final liveMarkers = await tourRepository.getLandmarkMarkers(lang: tourLanguage, forceRefresh: true);
      if (liveMarkers.isNotEmpty) {
        landmarkMarkers.assignAll(liveMarkers);
      }
    } catch (_) {}
  }

  void _initLandmarkOverlays() {
    _loadRepositoryOverlays();
  }

  Future<void> _initPedestrianRoutes({bool forceRefresh = false}) async {
    final generation = ++_pedestrianRefreshGeneration;
    try {
      final result = forceRefresh ? await tourRepository.refreshTourBundle(
        lang: tourLanguage, maxAge: const Duration(hours: 24),
      ) : null;
      var routes = await tourRepository.getPedestrianRoutes(lang: tourLanguage);
      if ((result == TourSyncResult.unavailable || (result == null && routes.isEmpty)) &&
          Get.isRegistered<OfflineLandmarkStore>()) {
        try {
          final saved = await Get.find<OfflineLandmarkStore>().list(tourLanguage);
          final existing = routes.map((route) => route.waypoints.join('|')).toSet();
          routes = [...routes, for (final package in saved)
            for (final route in package.routes)
              if (existing.add(route.waypoints.join('|'))) route];
        } catch (_) {}
      }
      if (isClosed || generation != _pedestrianRefreshGeneration) return;
      _pedestrianRouter.value.initializeRoutes(routes);
      _pedestrianRouter.refresh();
      final downloadedAt = await tourRepository.getLastBundleDownload(lang: tourLanguage);
      if (!isClosed && generation == _pedestrianRefreshGeneration) {
        lastBundleDownload.value = downloadedAt;
      }
    } catch (_) {}
  }

  Future<void> downloadTourBundle() async {
    if (isDownloadingBundle.value) return;
    isDownloadingBundle.value = true;
    bundleDownloadMessage.value = null;
    try {
      final result = await (_sync?.check(force: true)
          ?? tourRepository.refreshTourBundle(lang: tourLanguage, force: true));
      if (isClosed) return;
      if (result == TourSyncResult.unavailable) {
        bundleDownloadMessage.value = 'Download failed. Your saved tour is still available.'.tourText;
        return;
      }
      if (_sync != null) {
        lastBundleDownload.value = await tourRepository.getLastBundleDownload(lang: tourLanguage);
        if (!isClosed) bundleDownloadMessage.value = 'Tour downloaded.'.tourText;
        return;
      }
      final markers = await tourRepository.getLandmarkMarkers(lang: tourLanguage);
      final overlays = await tourRepository.getLandmarkOverlays();
      if (isClosed) return;
      landmarkMarkers.assignAll(markers);
      _applyOverlays(overlays);
      await _initPedestrianRoutes();
      if (!isClosed) bundleDownloadMessage.value = 'Tour downloaded.'.tourText;
    } catch (_) {
      if (!isClosed) bundleDownloadMessage.value = 'Unable to refresh the tour.'.tourText;
    } finally {
      if (!isClosed) isDownloadingBundle.value = false;
    }
  }

  Future<void> _loadRepositoryOverlays() async {
    try {
      final overlays = await tourRepository.getLandmarkOverlays();
      if (overlays.isNotEmpty) {
        _applyOverlays(overlays);
      }
      final liveOverlays = await tourRepository.getLandmarkOverlays(forceRefresh: true);
      if (liveOverlays.isNotEmpty) {
        _applyOverlays(liveOverlays);
      }
    } catch (_) {}
  }

  void _applyOverlays(List<MapLandmarkOverlay> list) {
    final overlays = list.map((overlay) {
      if (overlay.id == 'colosseum') {
        return overlay.copyWith(
          onTap: onColosseumTapped,
        );
      }
      return overlay;
    }).toList();
    landmarkOverlays.assignAll(overlays);
  }

  /// Navigates from landing screen to AllPointsMap view.
  void navigateToAllPointsMap() {
    if (Get.routeTree.routes.any((route) => route.name == Routes.allPointsMap)) {
      Get.toNamed(Routes.allPointsMap);
    } else {
      Get.to(() => const AllPointsMapView());
    }
  }

  /// Navigates directly to the landmark's detailed view (FloorMapView),
  /// bypassing the intermediary levels selection view.
  void navigateToLandmarkDetails(String landmarkId, {OfflineLandmark? offline}) {
    final snapshot = _sync?.snapshotFor(tourLanguage);
    final normalizedId = offline?.landmark.id ??
        (snapshot != null ? landmarkId : FloorDefinition.normalizeLandmarkId(landmarkId));
    final liveFloor = snapshot?.floors.firstWhereOrNull((floor) => floor.landmarkId == normalizedId);
    if (offline == null && snapshot != null && liveFloor == null) {
      Get.snackbar('Landmark unavailable'.tourText, 'No published floors are available.'.tourText);
      return;
    }
    selectedLandmarkId.value = normalizedId;
    final name = offline?.landmark.name
        ?? landmarkMarkers.firstWhereOrNull((marker) => marker.id == normalizedId)?.name
        ?? FloorDefinition.landmarkNameFor(normalizedId);
    final initialFloor = offline?.floors.first ?? liveFloor ?? FloorDefinition.initialFloorForLandmark(normalizedId);
    if (Get.routeTree.routes.any((route) => route.name == Routes.floorMap)) {
      Get.toNamed(
        Routes.floorMap,
        arguments: {
          'landmarkId': normalizedId,
          'landmarkName': name,
          'floorId': initialFloor.id,
          'floorName': initialFloor.displayName,
          'offlineLandmark': ?offline,
        },
      );
    }
  }

  Future<void> _enterSavedOrLive(String landmarkId) async {
    OfflineLandmark? saved;
    if (Get.isRegistered<OfflineLandmarkStore>()) {
      try {
        saved = await Get.find<OfflineLandmarkStore>().get(landmarkId, tourLanguage);
      } catch (_) {}
    }
    if (!isClosed) navigateToLandmarkDetails(landmarkId, offline: saved);
  }

  /// Navigation triggered when tapping on the Colosseum ground overlay image.
  void onColosseumTapped() {
    navigateToLandmarkDetails('colosseum');
  }

  /// Selects a landmark marker and activates its highlighted state.
  /// Directly forwards to the landmark's detailed view (FloorMapView).
  void selectLandmark(String landmarkId) {
    selectedLandmarkId.value = landmarkId;
    navigateToLandmarkDetails(landmarkId);
  }

  /// Updates properties of a specific landmark marker in the reactive list.
  void updateLandmarkMarker(LandmarkMarkerModel updated) {
    final index = landmarkMarkers.indexWhere((m) => m.id == updated.id);
    if (index != -1) {
      landmarkMarkers[index] = updated;
    }
  }

  void onPositionChanged(MapCamera camera, bool hasGesture) {
    currentZoom.value = camera.zoom;
  }

  /// Manually or automatically re-fetches live landmark markers, overlays, and floors from the remote database
  /// and updates local Hive storage.
  Future<void> refreshLandmarks() async {
    if (_sync case final TourSyncService sync) {
      await sync.check();
      return;
    }
    await _initPedestrianRoutes(forceRefresh: true);
    try {
      final liveMarkers = await tourRepository.getLandmarkMarkers(lang: tourLanguage,
        forceRefresh: tourLanguage == 'en');
      landmarkMarkers.assignAll(liveMarkers);
      final liveOverlays = await tourRepository.getLandmarkOverlays(forceRefresh: true);
      _applyOverlays(liveOverlays);
      final liveFloors = await tourRepository.getFloors(lang: tourLanguage,
        forceRefresh: tourLanguage == 'en');
      for (final floor in liveFloors) {
        tourRepository.getViewpointsByFloor(floor.id, forceRefresh: true, lang: tourLanguage);
      }
    } catch (_) {}
  }

  void centerOnColosseum() {
    selectedLandmarkId.value = 'colosseum';
    try {
      mapController.move(colosseumCoordinates, defaultZoom);
    } catch (_) {
      // MapController is only attached when FlutterMap is rendered
    }
    refreshLandmarks();
  }

  /// Toggles visibility of all landmark ground overlays.
  void toggleLandmarksVisibility() {
    isLandmarksVisible.toggle();
  }

  /// Toggles debug overlay outlines and center calibration labels.
  void toggleDebugLandmarks() {
    isDebugLandmarks.toggle();
  }

  /// Updates calibration parameters of a specific landmark overlay.
  void updateLandmarkOverlay(MapLandmarkOverlay updated) {
    final index = landmarkOverlays.indexWhere((o) => o.id == updated.id);
    if (index != -1) {
      landmarkOverlays[index] = updated;
    }
  }

  /// Switches base map between General and Satellite view.
  void switchMapView(MapViewType type) {
    selectedMapView.value = type;
  }

  /// Toggles base map view between General and Satellite.
  void toggleMapView() {
    selectedMapView.value = selectedMapView.value == MapViewType.general
        ? MapViewType.satellite
        : MapViewType.general;
  }

  void _initLocationTracking() {
    try {
      _compassSubscription = compassService.orientationStream.listen((state) {
        if (state.headingDegrees != null) {
          userHeading.value = state.headingDegrees;
        }
      });
      compassService.startListening();
    } catch (_) {}

    try {
      Geolocator.isLocationServiceEnabled().then((enabled) {
        if (enabled) {
          gpsLocationService.checkAndRequestPermissions().then((granted) {
            if (granted) {
              _positionSubscription = Geolocator.getPositionStream(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.bestForNavigation,
                  distanceFilter: 2,
                ),
              ).listen(
                (pos) {
                  final posLatLng = LatLng(pos.latitude, pos.longitude);
                  userLocation.value = posLatLng;
                  locationAccuracy.value = pos.accuracy;
                  if (isTourActive.value) {
                    checkProximityToLandmarks(posLatLng);
                  }
                },
                onError: (_) {},
              );
            }
          }).catchError((_) {});
        }
      }).catchError((_) {});
    } catch (_) {}
  }

  /// Sets or updates the user's geographic location (for live tracking or unit testing).
  void setUserLocation(LatLng? location, {double? heading, double? accuracy}) {
    userLocation.value = location;
    if (heading != null) userHeading.value = heading;
    if (accuracy != null) locationAccuracy.value = accuracy;
    if (location != null && isTourActive.value) {
      checkProximityToLandmarks(location);
    }
  }

  @override
  void onClose() {
    _recordOutdoorEvent('tour_stopped');
    _outdoorAnalyticsSession = null;
    _pedestrianRefreshGeneration++;
    WidgetsBinding.instance.removeObserver(this);
    _tourUpdates?.cancel();
    _positionSubscription?.cancel();
    _compassSubscription?.cancel();
    compassService.stopListening();
    mapController.dispose();
    super.onClose();
  }
}
