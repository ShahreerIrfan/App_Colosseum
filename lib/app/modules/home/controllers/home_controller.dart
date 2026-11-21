import '../../../core/localization/tour_localizations.dart';
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/floor_definition.dart';
import '../../../data/models/landmark_marker_model.dart';
import '../../../data/models/landmark_onboarding_model.dart';
import '../../../data/models/landmark_overlay_model.dart';
import '../../../data/models/map_view_type.dart';
import '../../../data/models/user_orientation_state.dart';
import '../../../data/repositories/i_tour_repository.dart';
import '../../../data/repositories/tour_repository_impl.dart';
import '../../../data/services/compass_service.dart';
import '../../../data/services/gps_location_service.dart';
import '../../../data/services/offline_landmark_store.dart';
import '../../../data/services/pedestrian_navigation_engine.dart';
import '../../../data/services/tour_sync_service.dart';
import '../../../data/models/tour_bundle_model.dart';
import '../../../data/services/pedestrian_street_router.dart';
import '../../../data/services/tour_analytics_service.dart';
import '../../../data/services/tts_service.dart';
import '../../../routes/app_pages.dart';
import '../views/allPointsMap.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  late final MapController mapController;
  final ITourRepository tourRepository;
  final GpsLocationService gpsLocationService;
  final CompassService compassService;
  final TtsService ttsService;
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

  /// Currently active landmark displayed in the LandmarkDetailCard (if visible).
  final activeLandmarkForCard = Rxn<LandmarkMarkerModel>();

  /// Whether the LandmarkDetailCard bottom card is currently visible.
  final isLandmarkCardVisible = false.obs;

  /// Whether the LandmarkDetailCard is collapsed to mini-player mode.
  final isLandmarkCardCollapsed = false.obs;

  /// Whether audio briefing for active landmark is currently playing.
  final isLandmarkAudioPlaying = false.obs;

  /// Playback progress of landmark welcome narration (0.0 to 1.0).
  final landmarkAudioProgress = 0.0.obs;

  /// Set of landmark IDs dismissed by the user to avoid immediate re-prompting.
  final _dismissedProximityLandmarkIds = <String>{}.obs;

  /// Active route points for walking directions to a specific landmark gate.
  final landmarkDirectionsRoute = <LatLng>[].obs;

  /// Turn-by-turn navigation engine for outdoor walking routes.
  late final PedestrianNavigationEngine pedestrianNavEngine;
  final pedestrianNavStatus = const PedestrianNavStatus().obs;
  final isVoiceGuidanceMuted = false.obs;

  void toggleVoiceGuidance() {
    isVoiceGuidanceMuted.toggle();
    ttsService.isVoiceGuidanceMuted = isVoiceGuidanceMuted.value;
    if (!isVoiceGuidanceMuted.value && pedestrianNavEngine.isNavigating) {
      pedestrianNavEngine.speakCurrentInstruction();
    }
  }

  /// Speaks the active pedestrian navigation instruction on demand.
  void speakCurrentNavInstruction() {
    if (!isVoiceGuidanceMuted.value && pedestrianNavEngine.isNavigating) {
      pedestrianNavEngine.speakCurrentInstruction();
    }
  }

  /// Whether [landmarkId] is currently excluded from the itinerary plan.
  bool isLandmarkExcluded(String landmarkId) {
    return skippedLandmarkIds.contains(landmarkId);
  }

  /// Toggles whether [landmarkId] is included in or excluded from the outdoor itinerary.
  void toggleLandmarkInclusion(String landmarkId) {
    if (skippedLandmarkIds.contains(landmarkId)) {
      skippedLandmarkIds.remove(landmarkId);
    } else {
      if (remainingTourLandmarks.length <= 1) {
        Get.snackbar(
          'Itinerary'.tourText,
          'At least one landmark must stay in the itinerary.',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
        return;
      }
      skippedLandmarkIds.add(landmarkId);
    }
    skippedLandmarkIds.refresh();
    if (isTourActive.value) {
      _armNextTourNavigation();
    }
  }

  Timer? _landmarkAudioProgressTimer;
  DateTime? _landmarkNarrationStartTime;
  int _landmarkSpeechStartOffset = 0;
  int _landmarkLastSpokenCharIndex = 0;
  static const double _estimatedCharsPerSecond = 14.5;

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
    dismissLandmarkCard();
    if (_outdoorAnalyticsSession != null) _recordOutdoorEvent('tour_stopped');
    _outdoorAnalyticsSession = TourAnalyticsService.newId();
    _recordOutdoorEvent('tour_started');
    isTourActive.value = true;
    visitedLandmarkIds.clear();
    hasPromptedLandmarkIds.clear();
    approachingLandmark.value = null;

    final location = userLocation.value;
    // When the user starts/views the itinerary, display the pedestrian route over the map.
    // Do NOT immediately pop up a landmark modal; if the user is already inside proximity
    // of a landmark at the start, mark it as prompted so it doesn't interrupt the itinerary view.
    if (location != null) {
      for (final landmark in remainingTourLandmarks) {
        final threshold = getProximityThresholdForLandmark(landmark.id);
        final distance = Geolocator.distanceBetween(
          location.latitude,
          location.longitude,
          landmark.latitude,
          landmark.longitude,
        );
        if (distance <= threshold) {
          hasPromptedLandmarkIds.add(landmark.id);
        }
      }
    }

    try {
      mapController.move(location ?? defaultTourStartLocation, defaultZoom);
    } catch (_) {}
    _armNextTourNavigation();
  }

  /// Arms turn-by-turn pedestrian navigation toward the next landmark in the tour.
  void _armNextTourNavigation({bool announceImmediately = true}) {
    if (!isTourActive.value) return;
    final start = userLocation.value ?? defaultTourStartLocation;
    final ordered = _pedestrianRouter.value.orderLandmarksForItinerary(
      start,
      remainingTourLandmarks,
    );
    final next = ordered.firstOrNull;
    if (next != null) {
      final route = _pedestrianRouter.value.routeBetween(start, next.coordinates);
      if (route.isNotEmpty) {
        pedestrianNavEngine.startNavigation(
          route: route,
          destination: next,
          announceImmediately: announceImmediately,
          totalStops: ordered.length,
        );
      }
    } else {
      pedestrianNavEngine.stopNavigation();
    }
    _pedestrianRouter.refresh();
  }

  /// Dynamically re-evaluates which landmark is closest as the user's location moves,
  /// re-arming the route and voice target if another landmark is now closer or user moved off-route.
  void _reevaluateActiveTourNavigation(LatLng currentPos) {
    if (!isTourActive.value) return;
    final ordered = _pedestrianRouter.value.orderLandmarksForItinerary(
      currentPos,
      remainingTourLandmarks,
    );
    final closest = ordered.firstOrNull;
    if (closest == null) {
      pedestrianNavEngine.stopNavigation();
      return;
    }

    final currentTargetId = pedestrianNavStatus.value.targetLandmark?.id;
    final targetChanged = !pedestrianNavEngine.isNavigating || currentTargetId != closest.id;
    if (targetChanged || _isOffActiveRoute(currentPos)) {
      _armNextTourNavigation(announceImmediately: targetChanged);
    } else {
      pedestrianNavEngine.updatePosition(currentPos);
      _pedestrianRouter.refresh();
    }
  }

  bool _isOffActiveRoute(LatLng currentPos) {
    final pts = pedestrianNavEngine.routePoints;
    if (pts.isEmpty) return true;
    var minDist = double.infinity;
    for (final pt in pts) {
      final d = Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        pt.latitude,
        pt.longitude,
      );
      if (d < minDist) minDist = d;
    }
    return minDist > 25.0;
  }

  void _initPedestrianNav() {
    pedestrianNavEngine = PedestrianNavigationEngine(ttsService: ttsService);
    pedestrianNavEngine.onStatusChanged = (status) {
      pedestrianNavStatus.value = status;
    };
    pedestrianNavEngine.onArrival = () {
      final target = pedestrianNavStatus.value.targetLandmark;
      if (target != null && !hasPromptedLandmarkIds.contains(target.id)) {
        hasPromptedLandmarkIds.add(target.id);
        approachingLandmark.value = target;
        showLandmarkOnboarding(target, autoTriggered: true, autoPlayAudio: true);
      }
    };
  }

  /// Stops/ends the interactive tour.
  void stopTour() {
    _recordOutdoorEvent('tour_stopped');
    _outdoorAnalyticsSession = null;
    isTourActive.value = false;
    approachingLandmark.value = null;
    pedestrianNavEngine.stopNavigation();
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
        if (activeLandmarkForCard.value?.id == currentLandmark.id) {
          dismissLandmarkCard();
        }
      }
      return;
    }

    // Reset prompted landmarks if user moved away so they can be re-prompted upon re-approach
    if (hasPromptedLandmarkIds.isNotEmpty) {
      final toUnprompt = <String>[];
      for (final id in hasPromptedLandmarkIds) {
        final landmark = landmarkMarkers.firstWhereOrNull((m) => m.id == id);
        if (landmark != null) {
          final threshold = getProximityThresholdForLandmark(id);
          final dist = Geolocator.distanceBetween(
            currentPos.latitude,
            currentPos.longitude,
            landmark.latitude,
            landmark.longitude,
          );
          if (dist > threshold * 1.4) {
            toUnprompt.add(id);
          }
        }
      }
      hasPromptedLandmarkIds.removeAll(toUnprompt);
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
      showLandmarkOnboarding(closestLandmark, autoTriggered: true, autoPlayAudio: true);
    }
  }

  /// User action: Enters the approaching landmark.
  /// Directly navigates to the landmark's detailed view (FloorMapView).
  void enterApproachingLandmark() {
    enterLandmarkFromCard();
  }

  /// User action: Skips the approaching landmark and continues to next point.
  void skipApproachingLandmark() {
    final landmark = approachingLandmark.value ?? activeLandmarkForCard.value;
    if (landmark != null) {
      if (isTourActive.value) {
        skippedLandmarkIds.add(landmark.id);
        _recordOutdoorEvent('landmark_skipped', landmark: landmark.id);
        _finishOutdoorAnalyticsIfDone();
        skippedLandmarkIds.refresh();
        _armNextTourNavigation();
      }
      _dismissedProximityLandmarkIds.add(landmark.id);
    }
    approachingLandmark.value = null;
    dismissLandmarkCard();
  }

  /// Returns the calibrated physical outer radius of a monument in meters.
  static double getLandmarkOuterRadius(String landmarkId) {
    switch (landmarkId.toLowerCase().trim()) {
      case 'colosseum':
      case 'colosseo':
        return 65.0;
      case 'arch_of_constantine':
      case 'arco_di_costantino':
        return 18.0;
      case 'ludus_magnus':
        return 35.0;
      case 'temple_venus_rome':
      case 'temple_of_venus_and_rome':
      case 'tempio_di_venere_e_roma':
        return 55.0;
      case 'roman_forum':
      case 'foro_romano':
        return 50.0;
      default:
        return 40.0;
    }
  }

  /// Evaluates exterior proximity to landmarks when active tour is not navigating.
  /// Triggers LandmarkDetailCard when user is in the 5m - 10m exterior buffer of the monument wall.
  void evaluateLandmarkProximity(LatLng userPos) {
    if (isTourActive.value) return;

    // Active card departure check with hysteresis
    if (isLandmarkCardVisible.value && activeLandmarkForCard.value != null) {
      final currentLandmark = activeLandmarkForCard.value!;
      final radius = getLandmarkOuterRadius(currentLandmark.id);
      final distance = const Distance().as(LengthUnit.Meter, userPos, currentLandmark.coordinates);

      // Auto-dismiss if user walked well past the entrance buffer (radius + 25m)
      if (distance > radius + 25.0) {
        dismissLandmarkCard();
      }
      return;
    }

    // Check entrance approach buffer for each monument
    for (final landmark in landmarkMarkers) {
      if (_dismissedProximityLandmarkIds.contains(landmark.id)) continue;

      final distance = const Distance().as(LengthUnit.Meter, userPos, landmark.coordinates);
      final outerRadius = getLandmarkOuterRadius(landmark.id);
      final bufferMax = outerRadius + 10.0; // 10m outer boundary
      final bufferMin = outerRadius; // Outer monument perimeter

      // User is within the 5-10m exterior entrance zone
      if (distance >= (bufferMin - 2.0) && distance <= bufferMax) {
        approachingLandmark.value = landmark;
        showLandmarkOnboarding(landmark, autoTriggered: true, autoPlayAudio: true);
        break;
      }
    }
  }

  /// Displays the rich onboarding & orientation card for a landmark.
  void showLandmarkOnboarding(
    LandmarkMarkerModel landmark, {
    bool autoTriggered = false,
    bool autoPlayAudio = false,
  }) {
    if (activeLandmarkForCard.value?.id != landmark.id) {
      _stopLandmarkAudioTimer();
      _landmarkSpeechStartOffset = 0;
      _landmarkLastSpokenCharIndex = 0;
      landmarkAudioProgress.value = 0.0;
      if (isLandmarkAudioPlaying.value) {
        isLandmarkAudioPlaying.value = false;
        ttsService.stop();
      }
      landmarkDirectionsRoute.clear();
    }

    activeLandmarkForCard.value = landmark;
    selectedLandmarkId.value = landmark.id;
    isLandmarkCardVisible.value = true;
    isLandmarkCardCollapsed.value = false;

    if (autoPlayAudio) {
      playLandmarkAudio();
    }
  }

  /// Dismisses the landmark onboarding card and stops any active narration.
  void dismissLandmarkCard() {
    _stopLandmarkAudioTimer();
    _landmarkSpeechStartOffset = 0;
    _landmarkLastSpokenCharIndex = 0;
    landmarkAudioProgress.value = 0.0;
    if (isLandmarkAudioPlaying.value) {
      isLandmarkAudioPlaying.value = false;
      ttsService.stop();
    }
    if (activeLandmarkForCard.value != null) {
      _dismissedProximityLandmarkIds.add(activeLandmarkForCard.value!.id);
    }
    isLandmarkCardVisible.value = false;
    activeLandmarkForCard.value = null;
    approachingLandmark.value = null;
    isLandmarkCardCollapsed.value = false;
    landmarkDirectionsRoute.clear();
    if (isTourActive.value) {
      _armNextTourNavigation();
    }
  }

  /// Toggles collapsed (mini-player) and expanded card presentation.
  void toggleLandmarkCardCollapse() {
    isLandmarkCardCollapsed.toggle();
  }

  /// Plays or resumes audio briefing for the currently active landmark.
  Future<void> playLandmarkAudio() async {
    final landmark = activeLandmarkForCard.value;
    if (landmark == null) return;
    final onboarding = landmark.onboardingModel;
    final text = onboarding.audioIntroText;
    if (text.isEmpty) return;

    isLandmarkAudioPlaying.value = true;
    _startLandmarkAudioProgressTimer(text);
    await ttsService.speakNarration(text);
  }

  /// Toggles landmark audio playback between playing and paused with position bookmarking.
  void toggleLandmarkAudio() async {
    if (isLandmarkAudioPlaying.value) {
      _stopLandmarkAudioTimer();
      isLandmarkAudioPlaying.value = false;
      await ttsService.stop();
    } else {
      final landmark = activeLandmarkForCard.value;
      if (landmark == null) return;
      final onboarding = LandmarkOnboardingModel.forLandmark(
        landmark.id,
        language: tourLanguage,
      );
      final text = onboarding.audioIntroText;
      if (text.isEmpty) return;

      isLandmarkAudioPlaying.value = true;

      if (_landmarkLastSpokenCharIndex > 0 &&
          _landmarkLastSpokenCharIndex < text.length) {
        int resumeIndex = _landmarkLastSpokenCharIndex;
        if (resumeIndex < text.length && text[resumeIndex] != ' ') {
          final lastSpace = text.lastIndexOf(' ', resumeIndex);
          if (lastSpace != -1 && lastSpace >= _landmarkSpeechStartOffset) {
            resumeIndex = lastSpace + 1;
          }
        }
        _landmarkSpeechStartOffset = resumeIndex;
        final remainingText = text.substring(_landmarkSpeechStartOffset);
        _startLandmarkAudioProgressTimer(text);
        await ttsService.speakNarration(remainingText);
      } else {
        _landmarkSpeechStartOffset = 0;
        _landmarkLastSpokenCharIndex = 0;
        _startLandmarkAudioProgressTimer(text);
        await ttsService.speakNarration(text);
      }
    }
  }

  void _startLandmarkAudioProgressTimer(String fullText) {
    _landmarkAudioProgressTimer?.cancel();
    _landmarkNarrationStartTime = DateTime.now();
    _landmarkAudioProgressTimer =
        Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!isLandmarkAudioPlaying.value || activeLandmarkForCard.value == null) {
        _stopLandmarkAudioTimer();
        return;
      }
      if (_landmarkNarrationStartTime != null) {
        final elapsedSeconds = DateTime.now()
                .difference(_landmarkNarrationStartTime!)
                .inMilliseconds /
            1000.0;
        final estimatedChars = (_landmarkSpeechStartOffset +
                (elapsedSeconds * _estimatedCharsPerSecond))
            .round()
            .clamp(0, fullText.length);
        _landmarkLastSpokenCharIndex = estimatedChars;
        landmarkAudioProgress.value = fullText.isNotEmpty
            ? (estimatedChars / fullText.length).clamp(0.0, 1.0)
            : 0.0;
      }
    });
  }

  void _stopLandmarkAudioTimer() {
    _landmarkAudioProgressTimer?.cancel();
    _landmarkAudioProgressTimer = null;
    _landmarkNarrationStartTime = null;
  }

  /// Action from LandmarkDetailCard: transitions into interior floor map.
  void enterLandmarkFromCard() {
    final landmark = activeLandmarkForCard.value ?? approachingLandmark.value;
    if (landmark == null) return;
    final id = landmark.id;
    if (isTourActive.value) {
      visitedLandmarkIds.add(id);
      _recordOutdoorEvent('landmark_entered', landmark: id);
      _finishOutdoorAnalyticsIfDone();
      visitedLandmarkIds.refresh();
      approachingLandmark.value = null;
    }
    dismissLandmarkCard();
    unawaited(_enterSavedOrLive(id));
  }

  /// Calculates and displays pedestrian street walking route to the landmark gate,
  /// and minimizes (collapses) the card so the user can clearly see the map and route.
  void getDirectionsToLandmark(LandmarkMarkerModel landmark) {
    final start = userLocation.value ?? defaultTourStartLocation;
    final route = _pedestrianRouter.value.routeBetween(start, landmark.coordinates);
    landmarkDirectionsRoute.assignAll(route);
    if (route.isNotEmpty) {
      pedestrianNavEngine.startNavigation(route: route, destination: landmark);
    }
    isLandmarkCardCollapsed.value = true;
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
    TtsService? ttsService,
  })  : tourRepository = tourRepository ??
            (Get.isRegistered<ITourRepository>()
                ? Get.find<ITourRepository>()
                : TourRepositoryImpl()),
        gpsLocationService = gpsLocationService ?? GpsLocationService(),
        compassService = compassService ?? CompassService(),
        ttsService = ttsService ??
            (Get.isRegistered<TtsService>()
                ? Get.find<TtsService>()
                : TtsService());

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
    _initTts();
    PedestrianStreetRouter.ensureInitialized();
    _initPedestrianNav();
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

  void _initTts() {
    ttsService.init(languageCode: ttsLocale);
    ttsService.onNarrationComplete = () {
      _stopLandmarkAudioTimer();
      _landmarkSpeechStartOffset = 0;
      _landmarkLastSpokenCharIndex = 0;
      isLandmarkAudioPlaying.value = false;
      landmarkAudioProgress.value = 0.0;
    };
    ttsService.onError = (_) {
      _stopLandmarkAudioTimer();
      isLandmarkAudioPlaying.value = false;
    };
  }

  void _applyTourSnapshot(TourBundleModel snapshot) {
    if (isClosed || !identical(_sync?.snapshotFor(tourLanguage), snapshot)) return;
    landmarkMarkers.assignAll(snapshot.landmarkMarkers);
    _applyOverlays(snapshot.landmarks);
    PedestrianStreetRouter.ensureInitialized();
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
      if (forceRefresh) {
        await tourRepository.refreshTourBundle(
          lang: tourLanguage, maxAge: const Duration(hours: 24),
        );
      }
      if (isClosed || generation != _pedestrianRefreshGeneration) return;
      PedestrianStreetRouter.ensureInitialized();
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

  Timer? _locationPollTimer;
  bool _isPollingLocation = false;

  void _handleLivePosition(Position pos) {
    final posLatLng = LatLng(pos.latitude, pos.longitude);
    userLocation.value = posLatLng;
    locationAccuracy.value = pos.accuracy;
    if (isTourActive.value) {
      _reevaluateActiveTourNavigation(posLatLng);
      checkProximityToLandmarks(posLatLng);
    } else {
      if (pedestrianNavEngine.isNavigating) {
        pedestrianNavEngine.updatePosition(posLatLng);
      }
      evaluateLandmarkProximity(posLatLng);
    }
  }

  LocationSettings _buildHomeLocationSettings() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        intervalDuration: const Duration(milliseconds: 1000),
        distanceFilter: 0,
        forceLocationManager: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );
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
            if (granted && !isClosed) {
              final settings = _buildHomeLocationSettings();
              _positionSubscription = Geolocator.getPositionStream(
                locationSettings: settings,
              ).listen(
                _handleLivePosition,
                onError: (_) {},
              );
              if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
                _locationPollTimer?.cancel();
                _locationPollTimer = Timer.periodic(
                  const Duration(seconds: 1),
                  (_) async {
                    if (isClosed || _isPollingLocation) return;
                    _isPollingLocation = true;
                    try {
                      final pos = await Geolocator.getCurrentPosition(
                        locationSettings: settings,
                      );
                      if (!isClosed) _handleLivePosition(pos);
                    } catch (_) {
                    } finally {
                      _isPollingLocation = false;
                    }
                  },
                );
              }
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
    if (location != null) {
      if (isTourActive.value) {
        _reevaluateActiveTourNavigation(location);
        checkProximityToLandmarks(location);
      } else {
        if (pedestrianNavEngine.isNavigating) {
          pedestrianNavEngine.updatePosition(location);
        }
        evaluateLandmarkProximity(location);
      }
    }
  }

  @override
  void onClose() {
    _recordOutdoorEvent('tour_stopped');
    _outdoorAnalyticsSession = null;
    _pedestrianRefreshGeneration++;
    _stopLandmarkAudioTimer();
    pedestrianNavEngine.stopNavigation();
    ttsService.stop();
    WidgetsBinding.instance.removeObserver(this);
    _tourUpdates?.cancel();
    _locationPollTimer?.cancel();
    _positionSubscription?.cancel();
    _compassSubscription?.cancel();
    compassService.stopListening();
    mapController.dispose();
    super.onClose();
  }
}
