import '../../../core/localization/tour_localizations.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/geodesic_utils.dart';
import '../../../data/models/floor_definition.dart';
import '../../../data/models/floor_transition_portal.dart';
import '../../../data/models/tour_bundle_model.dart';
import '../../../data/models/itinerary_segment_model.dart';
import '../../../data/models/map_view_type.dart';
import '../../../data/models/tour_navigation_state.dart';
import '../../../data/models/user_location_model.dart';
import '../../../data/models/user_orientation_state.dart';
import '../../../data/models/viewpoint_model.dart';
import '../../../data/repositories/i_tour_repository.dart';
import '../../../data/repositories/tour_repository_impl.dart';
import '../../../data/services/compass_service.dart';
import '../../../data/services/floor_detection_engine.dart';
import '../../../data/services/gps_location_service.dart';
import '../../../data/services/offline_landmark_store.dart';
import '../../../data/services/tour_sync_service.dart';
import '../../../data/services/tour_navigation_engine.dart';
import '../../../data/services/tour_analytics_service.dart';
import '../../../data/services/tts_service.dart';
import '../../../data/services/visited_viewpoints_service.dart';
import '../../home/controllers/home_controller.dart';

/// Controller managing floor map state, camera transformations, viewpoints, and audio playback.
class FloorMapController extends GetxController with WidgetsBindingObserver {
  final TtsService ttsService;
  final TourNavigationEngine tourEngine;
  final CompassService compassService;
  final GpsLocationService gpsService;
  final VisitedViewpointsService visitedService;
  final ITourRepository tourRepository;
  final bool? enablePeriodicSync;
  OfflineLandmark? offlineLandmark;
  final liveFloorUnavailable = false.obs;
  StreamSubscription<TourBundleModel>? _tourUpdates;
  TourSyncService? get _sync => Get.isRegistered<TourSyncService>() ? Get.find<TourSyncService>() : null;
  String? _floorAnalyticsSession;
  FloorDefinition? _analyticsFloor;
  String? _trackedNarration;
  final narrationError = RxnString();
  static const _narrationUnavailable =
      'Narration is unavailable. You can still read the guide.';
  String get _tourLanguage => offlineLandmark?.language ??
      (Get.isRegistered<HomeController>() ? Get.find<HomeController>().tourLanguage : 'en');

  bool _canNarrate(ViewpointModel viewpoint) {
    if (viewpoint.description.trim().isNotEmpty &&
        (viewpoint.narrationLanguage ?? 'en') == _tourLanguage) {
      return true;
    }
    narrationError.value = _narrationUnavailable;
    isPlayingAudio.value = false;
    isCardCollapsed.value = false;
    tourEngine.onUserStopOrCloseAudio();
    return false;
  }
  bool _hasFloorTourActivity = false;

  void _recordFloorEvent(String type, {String? viewpoint}) {
    final session = _floorAnalyticsSession;
    final floor = _analyticsFloor;
    if (session == null || floor == null) return;
    unawaited(TourAnalyticsService.instance.record(
      sessionId: session, type: type, tourKind: 'floor',
      language: Get.isRegistered<HomeController>() ? Get.find<HomeController>().tourLanguage : 'en',
      landmarkId: floor.landmarkId, floorId: floor.id, viewpointId: viewpoint,
    ));
  }

  void _startFloorAnalytics(FloorDefinition floor) {
    _recordFloorEvent('tour_stopped');
    _floorAnalyticsSession = TourAnalyticsService.newId();
    _analyticsFloor = floor;
    _trackedNarration = null;
    _hasFloorTourActivity = false;
    _recordFloorEvent('tour_started');
  }

  bool get needsCompassForAutoPlay {
    final state = tourState.value;
    if (!state.isAutoPlayEnabled || state.reachedViewpointId == state.navigationTargetId) {
      return false;
    }
    final target = viewpoints.firstWhereOrNull((vp) => vp.id == state.navigationTargetId);
    final distance = state.distanceToTarget;
    final heading = _navigationHeading(userOrientation.value);
    return target?.targetGazeHeadingDegrees != null && distance != null &&
        distance <= (target?.triggerRadiusMeters ?? tourEngine.config.arrivalRadiusMeters) &&
        (heading == null || !heading.isFinite);
  }

  bool get isPeriodicSyncEnabled {
    if (enablePeriodicSync != null) return enablePeriodicSync!;
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        return false;
      }
    } catch (_) {}
    return true;
  }

  FloorMapController({
    TtsService? ttsService,
    TourNavigationEngine? tourEngine,
    CompassService? compassService,
    GpsLocationService? gpsService,
    VisitedViewpointsService? visitedService,
    ITourRepository? tourRepository,
    this.enablePeriodicSync,
  })  : ttsService = ttsService ?? TtsService(),
        tourEngine = tourEngine ?? TourNavigationEngine(),
        compassService = compassService ?? CompassService(),
        gpsService = gpsService ?? GpsLocationService(),
        visitedService = visitedService ??
            (Get.isRegistered<VisitedViewpointsService>()
                ? Get.find<VisitedViewpointsService>()
                : Get.put(VisitedViewpointsService())),
        tourRepository = tourRepository ??
            (Get.isRegistered<ITourRepository>()
                ? Get.find<ITourRepository>()
                : TourRepositoryImpl());

  final landmarkId = 'colosseum'.obs;
  final landmarkName = 'Colosseum'.obs;
  final floorName = 'Underground (Hypogeum)'.obs;
  final floorId = 'floor_underground'.obs;

  /// Single source of truth floor definition
  final currentFloor = FloorDefinition.underground.obs;

  /// Dynamically resolved center coordinates and zoom for current landmark and floor
  LatLng get activeCenter => currentFloor.value.center;
  double get activeZoom => currentFloor.value.defaultZoom;

  /// List of monumental floors loaded dynamically from repository
  final availableFloors = <FloorDefinition>[...FloorDefinition.floorsForLandmark('colosseum')].obs;

  /// Single source of truth for the base map view presentation (General vs Satellite).
  final selectedMapView = MapViewType.satellite.obs;

  /// Whether the floating floor selection menu is open
  final isFloorMenuOpen = false.obs;

  /// Whether the floating map view selection menu is open
  final isMapViewMenuOpen = false.obs;

  /// Non-blocking flag for satellite tile loading error
  final hasSatelliteError = false.obs;

  /// Guard to prevent rapid re-entrant floor switches
  final isFloorSwitching = false.obs;

  /// Automatic floor detection engine and undo state
  final isAutoFloorDetectionEnabled = true.obs;
  late final FloorDetectionEngine floorDetectionEngine;
  final showAutoFloorSwitchBanner = false.obs;
  final autoSwitchBannerFloorName = ''.obs;
  FloorDefinition? _previousFloorBeforeAutoSwitch;
  @visibleForTesting
  FloorDefinition? get previousFloorBeforeAutoSwitch => _previousFloorBeforeAutoSwitch;
  @visibleForTesting
  set previousFloorBeforeAutoSwitch(FloorDefinition? value) => _previousFloorBeforeAutoSwitch = value;

  void toggleAutoFloorDetection() {
    isAutoFloorDetectionEnabled.toggle();
    floorDetectionEngine.isEnabled = isAutoFloorDetectionEnabled.value;
  }

  /// Per-floor saved camera states

  /// Physical floor ID where user is physically detected or anchored
  final physicalFloorId = 'floor_underground'.obs;

  /// Whether user is currently viewing a different floor than their physical location
  bool get isViewingDifferentFloor =>
      isUserInLocation.value && physicalFloorId.value != currentFloor.value.id;

  String get physicalFloorName =>
      (offlineLandmark?.floors.firstWhereOrNull((floor) => floor.id == physicalFloorId.value)
          ?? FloorDefinition.fromId(physicalFloorId.value)).displayName;

  String get currentFloorShortName => currentFloor.value.shortName;

  /// User-facing display name of the active map view mode.
  String get currentMapViewDisplayName => selectedMapView.value.displayName;

  /// Short display label for bottom bar action button.
  String get currentMapViewShortName => selectedMapView.value.shortName;

  /// Total number of viewpoints on the currently selected floor.
  int get currentFloorTotalViewpoints => viewpoints.length;

  /// Number of completed (visited) viewpoints on the currently selected floor only.
  int get currentFloorCompletedViewpoints =>
      viewpoints.where((vp) => vp.isVisited).length;

  /// Completion ratio (0.0 to 1.0) on the currently selected floor.
  double get currentFloorProgressRatio {
    if (viewpoints.isEmpty) return 0.0;
    return (currentFloorCompletedViewpoints / currentFloorTotalViewpoints)
        .clamp(0.0, 1.0);
  }

  /// Whether all viewpoints on the currently selected floor are completed.
  bool get isCurrentFloorComplete =>
      viewpoints.isNotEmpty &&
      currentFloorCompletedViewpoints == currentFloorTotalViewpoints;

  /// Live user-facing formatted progress label: "Completed: 2/7" or "✓ Completed 7/7".
  String get currentFloorProgressText {
    if (viewpoints.isEmpty) return 'No viewpoints'.tourText;
    if (isCurrentFloorComplete) {
      return '✓ Completed {done}/{total}'.tourTextWith({'done': currentFloorCompletedViewpoints, 'total': currentFloorTotalViewpoints});
    }
    return 'Completed: {done}/{total}'.tourTextWith({'done': currentFloorCompletedViewpoints, 'total': currentFloorTotalViewpoints});
  }

  /// Accessibility semantic description for current floor progress.
  String get currentFloorProgressSemanticLabel {
    if (viewpoints.isEmpty) {
      return 'No viewpoints on ${currentFloor.value.displayName}';
    }
    if (isCurrentFloorComplete) {
      return 'All $currentFloorTotalViewpoints viewpoints completed on ${currentFloor.value.displayName}';
    }
    return '$currentFloorCompletedViewpoints of $currentFloorTotalViewpoints viewpoints completed on ${currentFloor.value.displayName}';
  }

  /// Session-cached last viewed floor ID
  static String? lastViewedFloorId;

  /// Session-cached last viewed map view mode
  static MapViewType? lastViewedMapView;

  late final MapController mapController;
  late final TransformationController transformationController;

  static const LatLng colosseumCenter = LatLng(41.890210, 12.492231);
  static const double defaultZoom = 18.6;
  static const double minZoom = 17.0;
  static const double maxZoom = 21.0;

  final currentZoom = defaultZoom.obs;

  /// Reactive indoor guided tour state machine
  final tourState = const TourNavigationState().obs;

  /// Whether the user is currently physically located inside the Colosseum boundary
  final isUserInLocation = false.obs;

  /// Whether the app is in Local Ground Field-Test (Playground) Mode
  final isPlaygroundMode = false.obs;

  /// User's real-time indoor location beacon on this floor (null when outside location)
  final userLocation = Rxn<UserLocationModel>();

  StreamSubscription<GpsLocationResult>? _gpsSubscription;

  /// User's live device orientation and compass heading state
  final userOrientation = const UserOrientationState().obs;

  StreamSubscription<UserOrientationState>? _compassSubscription;

  /// Observable list of architectural viewpoints / audio stops
  final viewpoints = <ViewpointModel>[].obs;

  /// Currently selected / active viewpoint (null when none selected)
  final selectedViewpoint = Rxn<ViewpointModel>();

  /// Audio guide playing state
  final isPlayingAudio = false.obs;

  /// Audio narration progress (0.0 to 1.0)
  final audioProgress = 0.0.obs;

  /// Whether the bottom detail card is collapsed to show maximum map area
  final isCardCollapsed = false.obs;

  /// Architectural Guided Itinerary Segments for the current floor
  final itinerarySegments = <ItinerarySegmentModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    mapController = MapController();
    transformationController = TransformationController();

    // Parse navigation arguments if passed
    final args = Get.arguments;
    if (args is Map) {
      if (args['offlineLandmark'] case final OfflineLandmark package) {
        offlineLandmark = package;
        if (Get.isRegistered<OfflineLandmarkStore>()) Get.find<OfflineLandmarkStore>().pin(package);
        availableFloors.assignAll(package.floors);
        gpsService.useOfflineLandmark(package.landmark);
      }
      if (args.containsKey('landmarkId') && args['landmarkId'] != null) {
        final id = args['landmarkId'].toString();
        landmarkId.value = offlineLandmark?.landmark.id
            ?? (_sync != null ? id : FloorDefinition.normalizeLandmarkId(id));
      }
      if (args.containsKey('landmarkName') && args['landmarkName'] != null) {
        landmarkName.value = args['landmarkName'].toString();
      } else {
        landmarkName.value = FloorDefinition.landmarkNameFor(landmarkId.value);
      }
      if (args.containsKey('floorId') && args['floorId'] != null) {
        final id = args['floorId'].toString();
        final def = (offlineLandmark?.floors ?? _sync?.snapshotFor(_tourLanguage)?.floors)
                ?.firstWhereOrNull((floor) => floor.id == id)
            ?? FloorDefinition.fromId(id);
        currentFloor.value = def;
        floorId.value = def.id;
        physicalFloorId.value = def.id;
        floorName.value = def.displayName;
        if (landmarkId.value.isEmpty || (landmarkId.value == 'colosseum' && def.landmarkId != 'colosseum')) {
          landmarkId.value = def.landmarkId;
          landmarkName.value = def.landmarkName;
        }
      } else {
        final def = (offlineLandmark?.floors ?? _sync?.snapshotFor(_tourLanguage)?.floors)
                ?.firstWhereOrNull((floor) => floor.landmarkId == landmarkId.value)
            ?? FloorDefinition.initialFloorForLandmark(landmarkId.value, availableFloors);
        currentFloor.value = def;
        floorId.value = def.id;
        physicalFloorId.value = def.id;
        floorName.value = def.displayName;
      }
      if (args.containsKey('floorName') && args['floorName'] != null) {
        floorName.value = args['floorName'].toString();
      }
    } else {
      final targetFloorId = floorId.value.isNotEmpty ? floorId.value : 'floor_underground';
      final def = (offlineLandmark?.floors ?? _sync?.snapshotFor(_tourLanguage)?.floors)
              ?.firstWhereOrNull((floor) => floor.id == targetFloorId)
          ?? FloorDefinition.fromId(targetFloorId);
      currentFloor.value = def;
      floorId.value = def.id;
      physicalFloorId.value = def.id;
      floorName.value = def.displayName;
      landmarkId.value = def.landmarkId;
      landmarkName.value = def.landmarkName;
    }

    // Initialize Text-to-Speech service, Tour Navigation Engine, Device Compass & GPS
    _initTts();
    _initTour();
    _initFloorDetectionEngine();
    _initCompass();
    _initGps();

    // Load viewpoints according to selected floor
    _loadFloorData();
    final sync = _sync;
    if (offlineLandmark != null) return;
    if (sync == null) {
      _loadAvailableFloors(forceRefresh: true);
    } else {
      _tourUpdates = sync.snapshots.listen(_applyTourSnapshot);
      final snapshot = sync.snapshotFor(_tourLanguage);
      if (snapshot != null) _applyTourSnapshot(snapshot);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(TourAnalyticsService.instance.flush());
      if (_sync == null) {
        _loadAvailableFloors(forceRefresh: true);
        _loadRepositoryFloorData(currentFloor.value.id, forceRefresh: true);
      }
    }
  }

  int _currentSpeechStartOffset = 0;
  int _lastSpokenCharIndex = 0;
  Timer? _audioProgressTimer;
  DateTime? _narrationStartTime;
  static const double _estimatedCharsPerSecond = 14.5;

  void _startAudioProgressTimer() {
    _audioProgressTimer?.cancel();
    _narrationStartTime = DateTime.now();
    _audioProgressTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final vp = selectedViewpoint.value;
      if (vp == null || vp.description.isEmpty || !isPlayingAudio.value) {
        _stopAudioProgressTimer();
        return;
      }
      if (_narrationStartTime != null) {
        final elapsedSeconds =
            DateTime.now().difference(_narrationStartTime!).inMilliseconds / 1000.0;
        final estimatedChars = (_currentSpeechStartOffset +
                (elapsedSeconds * _estimatedCharsPerSecond))
            .round()
            .clamp(0, vp.description.length);
        if (estimatedChars > _lastSpokenCharIndex) {
          _lastSpokenCharIndex = estimatedChars;
          audioProgress.value =
              (_lastSpokenCharIndex / vp.description.length).clamp(0.0, 1.0);
        }
      }
    });
  }

  void _stopAudioProgressTimer() {
    _audioProgressTimer?.cancel();
    _audioProgressTimer = null;
    _narrationStartTime = null;
  }

  void _initTts() {
    final preferredLocale = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>().ttsLocale
        : 'en-US';
    final savedLanguage = offlineLandmark?.language;
    final locale = savedLanguage != null &&
            preferredLocale.split(RegExp('[-_]')).first.toLowerCase() != savedLanguage
        ? savedLanguage
        : preferredLocale;
    ttsService.init(languageCode: locale, offlineOnly: savedLanguage != null);
    ttsService.onError = (error) {
      _stopAudioProgressTimer();
      isPlayingAudio.value = false;
      narrationError.value = error is OfflineVoiceUnavailable
          ? Platform.isIOS
              ? 'Install a voice for this language in Settings → Accessibility → Spoken Content → Voices. You can read the tour without it.'
              : 'Install an offline voice for this language in your phone’s text-to-speech settings. You can read the tour without it.'
          : _narrationUnavailable;
      isCardCollapsed.value = false;
      _trackedNarration = null;
      tourEngine.onUserStopOrCloseAudio();
    };
    ttsService.onStart = () {
      isPlayingAudio.value = true;
      if (ttsService.currentSpeechType == TtsSpeechType.narration) {
        narrationError.value = null;
        final id = selectedViewpoint.value?.id;
        if (id != null && id != _trackedNarration) {
          _trackedNarration = id;
          _hasFloorTourActivity = true;
          _recordFloorEvent('narration_started', viewpoint: id);
        }
        if (_audioProgressTimer == null) {
          _startAudioProgressTimer();
        }
      }
    };
    ttsService.onNarrationComplete = () {
      _stopAudioProgressTimer();
      _currentSpeechStartOffset = 0;
      _lastSpokenCharIndex = 0;
      isPlayingAudio.value = false;
      audioProgress.value = 0.0;
      final previousVisits = tourEngine.state.visitedIds;
      final narration = _trackedNarration;
      if (narration != null) _recordFloorEvent('narration_completed', viewpoint: narration);
      _trackedNarration = null;
      tourEngine.onAudioCompleted();
      for (final id in tourEngine.state.visitedIds.difference(previousVisits)) {
        unawaited(visitedService.markVisited(id));
        _recordFloorEvent('viewpoint_visited', viewpoint: id);
      }
    };
    ttsService.onStop = () {
      _stopAudioProgressTimer();
      isPlayingAudio.value = false;
    };
    ttsService.onPause = () {
      _stopAudioProgressTimer();
      isPlayingAudio.value = false;
    };
    ttsService.onProgress = (start, end, word) {
      final vp = selectedViewpoint.value;
      if (vp != null && vp.description.isNotEmpty) {
        final calculatedIndex = (_currentSpeechStartOffset + end).clamp(0, vp.description.length);
        if (calculatedIndex > _lastSpokenCharIndex) {
          _lastSpokenCharIndex = calculatedIndex;
          audioProgress.value = (_lastSpokenCharIndex / vp.description.length).clamp(0.0, 1.0);
        }
      }
    };
  }

  void _initTour() {
    tourEngine.onSpeakInstruction = (text, {onDone}) {
      ttsService.speakInstruction(text, onDone: onDone);
    };

    tourEngine.onAutoPlayViewpoint = (viewpoint) {
      selectedViewpoint.value = viewpoint;
      isCardCollapsed.value = false;
      if (!_canNarrate(viewpoint)) return;
      isPlayingAudio.value = true;
      _currentSpeechStartOffset = 0;
      _lastSpokenCharIndex = 0;
      audioProgress.value = 0.0;
      ttsService.speakNarration(viewpoint.description);
    };

    tourEngine.onStateChanged = (state) {
      final prevReachedId = tourState.value.reachedViewpointId;
      tourState.value = state;
      if (!state.isExplicitlyClosed &&
          state.reachedViewpointId != null &&
          state.reachedViewpointId != prevReachedId &&
          (state.navigationStatus == TourNavigationStatus.arrived ||
              state.navigationStatus == TourNavigationStatus.viewpointAudioPlaying ||
              state.navigationStatus == TourNavigationStatus.waitingAtViewpoint)) {
        final reachedVp =
            viewpoints.firstWhereOrNull((vp) => vp.id == state.reachedViewpointId);
        if (reachedVp != null) {
          selectedViewpoint.value = reachedVp;
          isCardCollapsed.value = false;
        }
      }
      if (_hasFloorTourActivity && state.navigationStatus == TourNavigationStatus.itineraryComplete) {
        _recordFloorEvent('tour_completed');
        _floorAnalyticsSession = null;
      }

      // Sync visited status across local viewpoints
      bool changed = false;
      for (int i = 0; i < viewpoints.length; i++) {
        final isVisited = state.visitedIds.contains(viewpoints[i].id);
        if (viewpoints[i].isVisited != isVisited) {
          viewpoints[i] = viewpoints[i].copyWith(isVisited: isVisited);
          changed = true;
        }
      }

      if (changed && selectedViewpoint.value != null) {
        final updatedSelected = viewpoints
            .firstWhereOrNull((vp) => vp.id == selectedViewpoint.value!.id);
        if (updatedSelected != null) {
          selectedViewpoint.value = updatedSelected;
        }
      }

      if (changed) {
        viewpoints.refresh();
      }

      _refreshItinerarySegments();
    };
  }

  void _initFloorDetectionEngine() {
    floorDetectionEngine = FloorDetectionEngine(
      currentFloorId: currentFloor.value.id,
      availableFloors: availableFloors,
      isEnabled: isAutoFloorDetectionEnabled.value,
    );
    floorDetectionEngine.onFloorTransitionDetected = (candidate) {
      if (!isAutoFloorDetectionEnabled.value) return;
      _handleAutoFloorTransition(candidate);
    };
  }

  void _handleAutoFloorTransition(FloorTransitionCandidate candidate) {
    if (isFloorSwitching.value) return;
    _previousFloorBeforeAutoSwitch = currentFloor.value;
    autoSwitchBannerFloorName.value = candidate.targetFloor.displayName;
    showAutoFloorSwitchBanner.value = true;

    // Smoothly switch floor to detected floor
    switchFloor(candidate.targetFloor.id);
  }

  Future<void> undoAutoFloorSwitch() async {
    showAutoFloorSwitchBanner.value = false;
    autoSwitchBannerFloorName.value = '';
    if (_previousFloorBeforeAutoSwitch != null) {
      final prev = _previousFloorBeforeAutoSwitch!;
      final current = currentFloor.value;
      _previousFloorBeforeAutoSwitch = null;

      // Arm 90s cooldown between these two floors so it won't bounce back immediately
      floorDetectionEngine.armCooldown(prev.id, current.id, duration: const Duration(seconds: 90));

      // Revert back to previous floor
      await switchFloor(prev.id);
    }
  }

  void dismissAutoFloorSwitchBanner() {
    showAutoFloorSwitchBanner.value = false;
    autoSwitchBannerFloorName.value = '';
  }

  void onStaircasePortalTapped(FloorTransitionPortal portal) {
    final targetFloor = availableFloors.where((f) => f.id == portal.toFloorId).firstOrNull ??
        FloorDefinition.fromId(portal.toFloorId);
    final targetName = targetFloor.displayName.isNotEmpty
        ? targetFloor.displayName
        : (portal.toFloorId == 'floor_1' ? 'Level 1' : portal.toFloorId);

    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.rawSnackbar(
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      borderRadius: 24,
      duration: const Duration(seconds: 4),
      animationDuration: const Duration(milliseconds: 320),
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      messageText: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFAB0D0C).withValues(alpha: 0.22),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Subtle Colosseum watermark on top-right
            Positioned(
              right: -8,
              top: 6,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.10,
                  child: Image.asset(
                    'assets/logo/Colosseum.png',
                    width: 110,
                    height: 82,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top maroon header accent strip with centered handle pill
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFAB0D0C), Color(0xFFDD1110), Color(0xFFAB0D0C)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 34,
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBF5).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left Staircase Icon Badge
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBE7E6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFDD1110).withValues(alpha: 0.18),
                            width: 1.0,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.stairs_rounded,
                            color: Color(0xFFDD1110),
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Center Title & Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              portal.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFAB0D0C),
                                fontSize: 16.0,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Connects to $targetName. Tap SWITCH to change floor.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF5A5550),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Vertical divider
                      Container(
                        width: 1.0,
                        height: 44,
                        color: const Color(0xFFE5DAD0),
                      ),
                      const SizedBox(width: 10),
                      // Right SWITCH CTA Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (Get.isSnackbarOpen) {
                              Get.closeCurrentSnackbar();
                            }
                            switchFloor(targetFloor.id);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFDD1110), Color(0xFFAB0D0C)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFAB0D0C).withValues(alpha: 0.28),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.swap_horiz_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'SWITCH',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.0,
                                    letterSpacing: 0.4,
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
          ],
        ),
      ),
    );
  }

  void _initCompass() {
    compassService.setMapNorthOffset(0.0);
    userOrientation.value = compassService.currentState;
    _compassSubscription = compassService.orientationStream.listen(updateOrientation);
    compassService.startListening();
  }

  double? _navigationHeading(UserOrientationState state) =>
      state.isAvailable && !state.isCalibrating ? state.headingDegrees : null;

  /// Whether physical ground walking displacement is paused in field test mode (allows relocating without moving the map puck)
  final isDisplacementPaused = false.obs;

  void _initGps() {
    isUserInLocation.value = gpsService.currentResult.isInLocation;
    isPlaygroundMode.value = gpsService.isPlaygroundMode;
    isDisplacementPaused.value = gpsService.isDisplacementPaused;
    userLocation.value = gpsService.currentResult.userLocation;

    _gpsSubscription = gpsService.locationStream.listen((result) {
      isUserInLocation.value = result.isInLocation;
      isPlaygroundMode.value = result.isPlaygroundMode;
      isDisplacementPaused.value = result.isDisplacementPaused;
      if (result.isInLocation && result.userLocation != null) {
        final heading = _navigationHeading(userOrientation.value);
        final loc = result.userLocation!.copyWith(
          headingDegrees: heading, clearHeading: heading == null,
        );
        userLocation.value = loc;
        tourEngine.updateLocation(loc);
        floorDetectionEngine.updateLocation(
          canvasOffset: Offset(loc.normalizedX, loc.normalizedY),
          latLng: loc.latLng,
          accuracyMeters: loc.accuracyMeters,
        );
      } else {
        userLocation.value = null;
      }
    });
    gpsService.startTracking(floorId: floorId.value);
  }

  /// Toggles between Colosseum Geofence Mode and Local Playground Field Test Mode.
  void togglePlaygroundMode() {
    final nextMode = isPlaygroundMode.value
        ? GpsTrackingMode.colosseumGeofence
        : GpsTrackingMode.localPlayground;
    gpsService.setTrackingMode(nextMode, floorId: floorId.value);
    isPlaygroundMode.value = gpsService.isPlaygroundMode;
    isDisplacementPaused.value = gpsService.isDisplacementPaused;
    isUserInLocation.value = gpsService.currentResult.isInLocation;
    userLocation.value = gpsService.currentResult.userLocation;
    if (isUserInLocation.value && userLocation.value != null) {
      tourEngine.updateLocation(userLocation.value!, isSimulated: true);
    }
  }

  /// Toggles pause/resume of physical ground walking displacement in field test mode.
  void togglePauseDisplacement() {
    if (isDisplacementPaused.value) {
      gpsService.resumeDisplacement();
    } else {
      gpsService.pauseDisplacement();
    }
    isDisplacementPaused.value = gpsService.isDisplacementPaused;
  }

  /// Pauses physical walking displacement to allow relocating.
  void pauseDisplacement() {
    gpsService.pauseDisplacement();
    isDisplacementPaused.value = true;
  }

  /// Resumes physical walking displacement from current physical position anchored to last stop.
  void resumeDisplacement() {
    gpsService.resumeDisplacement();
    isDisplacementPaused.value = false;
  }

  /// Snaps user location anchor to the target viewpoint with smart sequential advance for developer testing.
  Future<void> snapToTarget() async {
    if (viewpoints.isEmpty) return;

    // 0. Cleanly stop any active audio from previous stop before snapping
    _stopAudioProgressTimer();
    isPlayingAudio.value = false;
    audioProgress.value = 0.0;
    await ttsService.stop();

    // 1. Freeze physical GPS drift so real sensor noise does not push user puck away
    isDisplacementPaused.value = true;
    isPlaygroundMode.value = true;

    // 2. Determine which viewpoint to snap to:
    final currentTargetId = tourState.value.navigationTargetId;
    final reachedId = tourState.value.reachedViewpointId;
    final selectedVp = selectedViewpoint.value;

    ViewpointModel? targetVp;

    // Priority A: If developer tapped/selected a viewpoint that differs from current reached stop, snap to selected:
    if (selectedVp != null && selectedVp.id != reachedId) {
      targetVp = selectedVp;
    }
    // Priority B: If already at the current target stop, advance to the NEXT sequential stop:
    else if (reachedId != null && reachedId == currentTargetId) {
      final currentIndex = viewpoints.indexWhere((v) => v.id == reachedId);
      if (currentIndex != -1 && currentIndex + 1 < viewpoints.length) {
        targetVp = viewpoints[currentIndex + 1];
      } else {
        targetVp = viewpoints.first;
      }
    }
    // Priority C: Otherwise, snap to current navigation target (or first viewpoint):
    else if (currentTargetId != null) {
      targetVp = viewpoints.firstWhereOrNull((v) => v.id == currentTargetId);
    }
    targetVp ??= viewpoints.first;

    // 3. Update tour engine navigation target to this viewpoint
    tourEngine.setNavigationTarget(targetVp.id);

    // 4. Update GPS service and local reactive coordinates
    final canvasOffset = Offset(targetVp.normalizedX, targetVp.normalizedY);
    gpsService.snapToCanvasOffset(
      canvasOffset,
      floorId: floorId.value,
      latLng: targetVp.latLng,
    );
    gpsService.pauseDisplacement();

    final snappedLoc = UserLocationModel(
      floorId: floorId.value,
      normalizedX: targetVp.normalizedX,
      normalizedY: targetVp.normalizedY,
      latitude: targetVp.latLng.latitude,
      longitude: targetVp.latLng.longitude,
      headingDegrees: userOrientation.value.headingDegrees,
      accuracyMeters: 1.5,
      timestamp: DateTime.now(),
    );

    isUserInLocation.value = true;
    userLocation.value = snappedLoc;
    selectedViewpoint.value = targetVp;

    // 5. Update engine location to trigger instant arrival and audio narration
    tourEngine.updateLocation(snappedLoc, isSimulated: true);
    floorDetectionEngine.updateLocation(
      canvasOffset: Offset(snappedLoc.normalizedX, snappedLoc.normalizedY),
      latLng: snappedLoc.latLng,
      accuracyMeters: snappedLoc.accuracyMeters,
    );
  }

  /// Sets a simulated user location from a tapped geographic coordinate on the satellite map (FoodPanda / Uber style).
  Future<void> setSimulatedLocation(LatLng point) async {
    // Cleanly stop any active audio when placing location
    _stopAudioProgressTimer();
    isPlayingAudio.value = false;
    audioProgress.value = 0.0;
    await ttsService.stop();

    final canvasOffset = GeodesicUtils.latLngToCanvasOffset(point);
    // Pause any live physical GPS drift while manually placing position
    gpsService.pauseDisplacement();
    isDisplacementPaused.value = true;
    isPlaygroundMode.value = true;

    gpsService.snapToCanvasOffset(
      canvasOffset,
      floorId: floorId.value,
      latLng: point,
    );

    final simulatedLoc = UserLocationModel(
      floorId: floorId.value,
      normalizedX: canvasOffset.dx,
      normalizedY: canvasOffset.dy,
      latitude: point.latitude,
      longitude: point.longitude,
      headingDegrees: userOrientation.value.headingDegrees,
      accuracyMeters: 1.5,
      timestamp: DateTime.now(),
    );

    isUserInLocation.value = true;
    userLocation.value = simulatedLoc;
    tourEngine.updateLocation(simulatedLoc, isSimulated: true);
    floorDetectionEngine.updateLocation(
      canvasOffset: Offset(simulatedLoc.normalizedX, simulatedLoc.normalizedY),
      latLng: simulatedLoc.latLng,
      accuracyMeters: simulatedLoc.accuracyMeters,
    );
  }

  /// Resets the local playground reference origin to current GPS location.
  void resetPlaygroundOrigin() {
    gpsService.resetPlaygroundOrigin();
    isDisplacementPaused.value = false;
  }

  void _loadFloorData() {
    final fid = floorId.value;
    final def = offlineLandmark == null && _sync == null
        ? FloorDefinition.fromId(fid) : currentFloor.value;

    currentFloor.value = def;
    floorId.value = def.id;
    if (landmarkId.value.isEmpty || (landmarkId.value == 'colosseum' && def.landmarkId != 'colosseum')) {
      landmarkId.value = def.landmarkId;
    }

    final hasCustomName = (Get.arguments is Map) && (Get.arguments as Map).containsKey('floorName');
    if (!hasCustomName) {
      floorName.value = def.displayName;
    }
    lastViewedFloorId = def.id;

    final storedVisited = visitedService.getVisitedForFloor(
        def.id, def.viewpoints.map((v) => v.id));
    final populatedViewpoints = def.viewpoints.map((vp) {
      return vp.copyWith(isVisited: storedVisited.contains(vp.id));
    }).toList();

    viewpoints.assignAll(populatedViewpoints);
    _startFloorAnalytics(def);
    tourEngine.startTour(
      floorId: def.id,
      landmarkName: landmarkName.value,
      floorName: def.displayName,
      viewpoints: populatedViewpoints,
      initialVisitedIds: storedVisited,
      isVoiceGuidanceEnabled: tourState.value.isVoiceGuidanceEnabled,
      isAutoPlayEnabled: tourState.value.isAutoPlayEnabled,
    );
    _refreshItinerarySegments();
    _loadRepositoryFloorData(def.id, forceRefresh: true);
  }

  int _viewpointRefreshGeneration = 0;

  Future<void> _loadRepositoryFloorData(String targetFloorId, {bool forceRefresh = false}) async {
    if (offlineLandmark != null || _sync != null) return;
    final generation = ++_viewpointRefreshGeneration;
    try {
      if (forceRefresh && isPeriodicSyncEnabled) {
        await tourRepository.refreshTourBundle(lang: _tourLanguage,
          maxAge: const Duration(hours: 24));
      }
      final liveViewpoints = await tourRepository.getViewpointsByFloor(
        targetFloorId,
        forceRefresh: forceRefresh,
        lang: _tourLanguage,
      );
      final cachedFloor = await tourRepository.getFloorById(targetFloorId, lang: _tourLanguage);
      if (generation != _viewpointRefreshGeneration ||
          targetFloorId != currentFloor.value.id) {
        return;
      }

      _applyFloorContent(cachedFloor ?? currentFloor.value, liveViewpoints);
    } catch (_) {
      // Keep the current floor intact if the refresh fails.
    }
  }

  void _applyTourSnapshot(TourBundleModel snapshot) {
    if (isClosed || !identical(_sync?.snapshotFor(_tourLanguage), snapshot)) return;
    final landmark = snapshot.landmarks.firstWhereOrNull((item) => item.id == landmarkId.value);
    final floors = landmark == null ? <FloorDefinition>[] :
        snapshot.floors.where((floor) => floor.landmarkId == landmark.id).toList();
    availableFloors.assignAll(floors);
    if (isFloorSwitching.value) return;
    if (landmark != null) landmarkName.value = landmark.name;
    final floor = floors.firstWhereOrNull((item) => item.id == floorId.value);
    if (floor == null) {
      liveFloorUnavailable.value = true;
      if (floors.isEmpty) closeAllBottomMenus();
      _applyFloorContent(currentFloor.value.copyWith(viewpoints: [], itinerary: []), []);
      return;
    }
    liveFloorUnavailable.value = false;
    _applyFloorContent(floor, floor.viewpoints);
  }

  void _applyFloorContent(FloorDefinition floor, List<ViewpointModel> liveViewpoints) {
    final ids = liveViewpoints.map((viewpoint) => viewpoint.id).toSet();
    final storedVisited = visitedService.getVisitedForFloor(floor.id, ids);
    final updated = liveViewpoints.map((viewpoint) {
      return viewpoint.copyWith(isVisited: storedVisited.contains(viewpoint.id));
    }).toList();

    final selected = selectedViewpoint.value;
    final activeAudio = tourEngine.state.activeAudioViewpointId;
    if ((selected != null && !ids.contains(selected.id)) ||
        (activeAudio != null && !ids.contains(activeAudio))) {
      _stopAudioProgressTimer();
      _currentSpeechStartOffset = 0;
      _lastSpokenCharIndex = 0;
      isPlayingAudio.value = false;
      audioProgress.value = 0.0;
      unawaited(ttsService.stop());
    }

    viewpoints.assignAll(updated);
    selectedViewpoint.value =
        updated.firstWhereOrNull((viewpoint) => viewpoint.id == selected?.id);
    currentFloor.value = floor.copyWith(viewpoints: updated);
    floorName.value = floor.displayName;
    compassService.setMapNorthOffset(0.0);
    if (physicalFloorId.value == 'floor_underground' || physicalFloorId.value == floor.id) {
      physicalFloorId.value = floor.id;
    }

    final idx = availableFloors.indexWhere((item) => item.id == floor.id);
    if (idx != -1) availableFloors[idx] = currentFloor.value;

    tourEngine.updateViewpoints(updated);
    _refreshItinerarySegments();
  }

  Future<void> _loadAvailableFloors({bool forceRefresh = false}) async {
    if (offlineLandmark != null) return;
    final cached = FloorDefinition.floorsForLandmark(landmarkId.value);
    if (cached.isNotEmpty) {
      availableFloors.assignAll(cached);
      _syncAvailableFloorsWithCurrent();
    }
    try {
      final loadedFloors = await tourRepository.getFloors(lang: _tourLanguage,
        forceRefresh: forceRefresh && _tourLanguage == 'en');
      if (loadedFloors.isNotEmpty) {
        final matching = FloorDefinition.floorsForLandmark(landmarkId.value, loadedFloors);
        if (matching.isNotEmpty) {
          availableFloors.assignAll(matching);
          _syncAvailableFloorsWithCurrent();
        }
      }
    } catch (_) {}
  }

  void _syncAvailableFloorsWithCurrent() {
    final idx = availableFloors.indexWhere((f) => f.id == currentFloor.value.id);
    if (idx != -1 && currentFloor.value.viewpoints.isNotEmpty) {
      availableFloors[idx] = currentFloor.value;
    }
  }

  /// Returns the architectural walking itinerary for the currently active floor.
  List<ItinerarySegmentModel> _getCurrentFloorItinerary() {
    final stops = viewpoints.map((viewpoint) => viewpoint.id).toSet()
      ..addAll(['ENTRY', 'EXIT']);
    return currentFloor.value.itinerary.where((segment) =>
        stops.contains(segment.fromId) && stops.contains(segment.toId)).toList();
  }

  /// Recalculates completed and active status on itinerary walking segments.
  void _refreshItinerarySegments() {
    final itinerary = _getCurrentFloorItinerary();
    final currentTarget = tourState.value.navigationTargetId;
    final visited = tourState.value.visitedIds;

    final updated = itinerary.map((segment) {
      final isCompleted = visited.contains(segment.toId) ||
          (viewpoints.firstWhereOrNull((vp) => vp.id == segment.toId)?.isVisited ?? false);

      final isActive = segment.toId == currentTarget;

      return segment.copyWith(
        isCompleted: isCompleted,
        isActive: isActive,
      );
    }).toList();
    itinerarySegments.assignAll(updated);
  }

  /// Updates indoor user position and evaluates tour proximity state machine.
  void updateUserLocation(UserLocationModel? location) {
    if (location != null) {
      isUserInLocation.value = true;
      userLocation.value = location;
      tourEngine.updateLocation(location);
      floorDetectionEngine.updateLocation(
        canvasOffset: Offset(location.normalizedX, location.normalizedY),
        latLng: location.latLng,
        accuracyMeters: location.accuracyMeters,
      );
    } else {
      isUserInLocation.value = false;
      userLocation.value = null;
    }
  }

  @override
  void onClose() {
    _recordFloorEvent('tour_stopped');
    _floorAnalyticsSession = null;
    _viewpointRefreshGeneration++;
    WidgetsBinding.instance.removeObserver(this);
    _tourUpdates?.cancel();
    if (offlineLandmark case final OfflineLandmark package) {
      if (Get.isRegistered<OfflineLandmarkStore>()) Get.find<OfflineLandmarkStore>().unpin(package);
    }
    _stopAudioProgressTimer();
    tourEngine.dispose();
    _gpsSubscription?.cancel();
    gpsService.dispose();
    _compassSubscription?.cancel();
    compassService.dispose();
    ttsService.dispose();
    mapController.dispose();
    transformationController.dispose();
    super.onClose();
  }

  /// Feeds simulated mock GPS position (useful for unit tests and Fake GPS simulation).
  void updateGpsPosition(
    double latitude,
    double longitude, {
    double accuracy = 2.0,
  }) {
    gpsService.setMockPosition(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      floorId: floorId.value,
    );
    isUserInLocation.value = gpsService.currentResult.isInLocation;
    if (gpsService.currentResult.isInLocation &&
        gpsService.currentResult.userLocation != null) {
      final loc = gpsService.currentResult.userLocation!.copyWith(
        headingDegrees: userOrientation.value.headingDegrees,
      );
      userLocation.value = loc;
      tourEngine.updateLocation(loc);
    } else {
      userLocation.value = null;
    }
  }

  /// Manually feeds a simulated mock compass heading (useful for unit tests and walking simulations).
  void updateHeading(double? headingDegrees, {double? accuracy}) {
    compassService.setMockHeading(headingDegrees, accuracy: accuracy);
    updateOrientation(compassService.currentState);
  }

  /// Manually updates complete user orientation state.
  void updateOrientation(UserOrientationState state) {
    userOrientation.value = state;
    if (isUserInLocation.value && userLocation.value != null) {
      final displayHeading = state.headingDegrees ?? state.mapHeadingDegrees;
      userLocation.value = userLocation.value!.copyWith(
        headingDegrees: displayHeading, clearHeading: displayHeading == null,
      );
      tourEngine.updateHeading(_navigationHeading(state));
    }
  }

  /// Selects a viewpoint, opens its detail card, and highlights marker.
  void selectViewpoint(ViewpointModel viewpoint) {
    narrationError.value = null;
    final previous = selectedViewpoint.value;
    selectedViewpoint.value = viewpoint;
    tourEngine.selectViewpoint(viewpoint.id);

    // When choosing another viewpoint, automatically pause / stop TTS playback and reset bookmark
    if (previous?.id != viewpoint.id) {
      _stopAudioProgressTimer();
      _currentSpeechStartOffset = 0;
      _lastSpokenCharIndex = 0;
      audioProgress.value = 0.0;
      if (isPlayingAudio.value) {
        isPlayingAudio.value = false;
        ttsService.stop();
      }
    }
  }

  /// Toggles collapsed / expanded presentation for the bottom detail card.
  void toggleCardCollapse() {
    isCardCollapsed.toggle();
  }

  /// Expands bottom detail card to show full description and media.
  void expandCard() {
    isCardCollapsed.value = false;
  }

  /// Collapses bottom detail card to maximize map visibility.
  void collapseCard() {
    isCardCollapsed.value = true;
  }

  /// Deselects active viewpoint and closes detail card.
  void deselectViewpoint() {
    _stopAudioProgressTimer();
    _currentSpeechStartOffset = 0;
    _lastSpokenCharIndex = 0;
    selectedViewpoint.value = null;
    isCardCollapsed.value = false;
    isPlayingAudio.value = false;
    audioProgress.value = 0.0;
    ttsService.stop();
    tourEngine.deselectViewpoint();
    tourEngine.onUserStopOrCloseAudio();
  }

  /// Toggles the visited status for a viewpoint (defaults to currently selected viewpoint).
  void toggleVisited([String? viewpointId]) {
    final targetId = viewpointId ?? selectedViewpoint.value?.id;
    if (targetId == null) return;

    final index = viewpoints.indexWhere((vp) => vp.id == targetId);
    if (index != -1) {
      final current = viewpoints[index];
      if (current.isVisited) {
        tourEngine.unmarkVisited(targetId);
        visitedService.unmarkVisited(targetId);
      } else {
        _hasFloorTourActivity = true;
        _recordFloorEvent('viewpoint_visited', viewpoint: targetId);
        tourEngine.markVisited(targetId);
        visitedService.markVisited(targetId);
      }
    }
  }

  /// Explicitly skips a viewpoint in the guided tour.
  void skipViewpoint([String? viewpointId]) {
    final targetId = viewpointId ?? tourState.value.navigationTargetId;
    if (targetId != null) {
      if (viewpoints.any((viewpoint) => viewpoint.id == targetId)) {
        _hasFloorTourActivity = true;
        _recordFloorEvent('viewpoint_skipped', viewpoint: targetId);
      }
      tourEngine.skipViewpoint(targetId);
      _refreshItinerarySegments();
    }
  }

  /// Toggles voice guidance announcements.
  void toggleVoiceGuidance([bool? enabled]) {
    final newVal = enabled ?? !tourState.value.isVoiceGuidanceEnabled;
    tourEngine.toggleVoiceGuidance(newVal);
  }

  /// Toggles automatic viewpoint audio playback upon arrival.
  void toggleAutoPlay([bool? enabled]) {
    final newVal = enabled ?? !tourState.value.isAutoPlayEnabled;
    tourEngine.toggleAutoPlay(newVal);
  }

  /// Resets the full tour to the beginning.
  void resetTour() {
    _stopAudioProgressTimer();
    _currentSpeechStartOffset = 0;
    _lastSpokenCharIndex = 0;
    tourEngine.resetTour();
    visitedService.clearFloor(floorId.value);
    for (int i = 0; i < viewpoints.length; i++) {
      viewpoints[i] = viewpoints[i].copyWith(isVisited: false);
    }
    viewpoints.refresh();
    selectedViewpoint.value = null;
    isPlayingAudio.value = false;
    audioProgress.value = 0.0;
    ttsService.stop();
    _refreshItinerarySegments();
  }

  /// Toggles audio guide speech playback for the active viewpoint with smart resume.
  void toggleAudio() async {
    if (isPlayingAudio.value) {
      _stopAudioProgressTimer();
      isPlayingAudio.value = false;
      tourEngine.onUserPauseAudio();
      await ttsService.stop();
    } else {
      final vp = selectedViewpoint.value;
      if (vp != null && _canNarrate(vp)) {
        isPlayingAudio.value = true;
        tourEngine.onUserResumeAudio();

        // Resume from bookmarked character offset if paused midway
        if (_lastSpokenCharIndex > 0 && _lastSpokenCharIndex < vp.description.length) {
          int resumeIndex = _lastSpokenCharIndex;
          if (resumeIndex < vp.description.length && vp.description[resumeIndex] != ' ') {
            final lastSpace = vp.description.lastIndexOf(' ', resumeIndex);
            if (lastSpace != -1 && lastSpace >= _currentSpeechStartOffset) {
              resumeIndex = lastSpace + 1;
            }
          }
          _currentSpeechStartOffset = resumeIndex;
          final remainingText = vp.description.substring(_currentSpeechStartOffset);
          _startAudioProgressTimer();
          await ttsService.speakNarration(remainingText);
        } else {
          _currentSpeechStartOffset = 0;
          _lastSpokenCharIndex = 0;
          _startAudioProgressTimer();
          await ttsService.speakNarration(vp.description);
        }
      }
    }
  }

  /// Gets the live effective heading in degrees from compass or user location.
  double? get effectiveHeading =>
      userOrientation.value.headingDegrees ??
      userOrientation.value.mapHeadingDegrees ??
      userLocation.value?.headingDegrees;

  /// Handles camera movement changes on the satellite map.
  void onPositionChanged(MapCamera camera, bool hasGesture) {
    currentZoom.value = camera.zoom;
  }

  /// Centers the satellite map view on a specific viewpoint.
  void animateToViewpoint(ViewpointModel vp) {
    selectViewpoint(vp);
    try {
      mapController.move(vp.latLng, mapController.camera.zoom);
    } catch (_) {}
  }

  /// Builds geo-located polylines for the walking tour itinerary on Google Satellite View.
  List<Polyline> buildItineraryPolylines(AppColors colors) {
    final polylines = <Polyline>[];

    for (final segment in itinerarySegments) {
      final rawPoints = segment.points;
      if (rawPoints.isEmpty) continue;

      final fromVp = viewpoints.firstWhereOrNull((v) => v.id == segment.fromId);
      final toVp = viewpoints.firstWhereOrNull((v) => v.id == segment.toId);
      final latLngs = <LatLng>[];
      for (int i = 0; i < rawPoints.length; i++) {
        final pt = rawPoints[i];
        if (i == 0 && fromVp != null) {
          latLngs.add(fromVp.latLng);
        } else if (i == rawPoints.length - 1 && toVp != null) {
          latLngs.add(toVp.latLng);
        } else if (segment.usesGpsCoordinates || (pt.dx > 1.0 && pt.dy > 1.0)) {
          // Explicit GPS waypoint along authentic historical route
          latLngs.add(LatLng(pt.dx, pt.dy));
        } else if (fromVp != null && toVp != null && rawPoints.length > 2) {
          // Interpolate between the actual landmark viewpoints
          final fraction = i / (rawPoints.length - 1);
          final lat = fromVp.latLng.latitude +
              (toVp.latLng.latitude - fromVp.latLng.latitude) * fraction;
          final lng = fromVp.latLng.longitude +
              (toVp.latLng.longitude - fromVp.latLng.longitude) * fraction;
          latLngs.add(LatLng(lat, lng));
        } else {
          latLngs.add(GeodesicUtils.canvasOffsetToLatLng(
            rawPoints[i],
            centerLat: currentFloor.value.center.latitude,
            centerLng: currentFloor.value.center.longitude,
          ));
        }
      }

      final Color color;
      final double strokeWidth;
      if (segment.isCompleted) {
        color = const Color(0xFF10B981); // Emerald green for visited legs
        strokeWidth = 4.2;
      } else if (segment.isActive) {
        color = colors.primary; // Active targeted leg
        strokeWidth = 4.8;
      } else {
        color = colors.primary.withValues(alpha: 0.38); // Upcoming legs
        strokeWidth = 3.2;
      }

      polylines.add(
        Polyline(
          points: latLngs,
          strokeWidth: strokeWidth,
          color: color,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
    }

    return polylines;
  }

  /// Zoom In helper for floating map controls.
  void zoomIn() {
    try {
      final targetZoom = (mapController.camera.zoom + 0.6).clamp(minZoom, maxZoom);
      mapController.move(mapController.camera.center, targetZoom);
    } catch (_) {}

    final currentScale = transformationController.value.getMaxScaleOnAxis();
    if (currentScale < 3.2) {
      final targetScale = currentScale * 1.25;
      transformationController.value = Matrix4.diagonal3Values(
        targetScale,
        targetScale,
        1.0,
      );
    }
  }

  /// Zoom Out helper for floating map controls.
  void zoomOut() {
    try {
      final targetZoom = (mapController.camera.zoom - 0.6).clamp(minZoom, maxZoom);
      mapController.move(mapController.camera.center, targetZoom);
    } catch (_) {}

    final currentScale = transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 0.85) {
      final targetScale = currentScale * 0.8;
      transformationController.value = Matrix4.diagonal3Values(
        targetScale,
        targetScale,
        1.0,
      );
    }
  }

  /// Recenter floor map to default scale and origin.
  void recenter() {
    try {
      if (isUserInLocation.value && userLocation.value != null) {
        mapController.move(userLocation.value!.latLng, defaultZoom);
      } else {
        mapController.move(activeCenter, activeZoom);
      }
    } catch (_) {}

    transformationController.value = Matrix4.identity();
  }

  /// Toggles visibility of the floating floor selection menu.
  void toggleFloorMenu() {
    if (isFloorMenuOpen.value) {
      closeFloorMenu();
    } else {
      openFloorMenu();
    }
  }

  /// Opens the floating floor selection menu and closes any other bottom menu.
  void openFloorMenu() {
    isMapViewMenuOpen.value = false;
    isFloorMenuOpen.value = true;
  }

  /// Closes the floating floor selection menu.
  void closeFloorMenu() {
    isFloorMenuOpen.value = false;
  }

  /// Toggles visibility of the floating map view selection menu.
  void toggleMapViewMenu() {
    if (isMapViewMenuOpen.value) {
      closeMapViewMenu();
    } else {
      openMapViewMenu();
    }
  }

  /// Opens the floating map view selection menu and closes any other bottom menu.
  void openMapViewMenu() {
    isFloorMenuOpen.value = false;
    isMapViewMenuOpen.value = true;
  }

  /// Closes the floating map view selection menu.
  void closeMapViewMenu() {
    isMapViewMenuOpen.value = false;
  }

  /// Closes all anchored bottom menus (floor menu, map view menu).
  void closeAllBottomMenus() {
    isFloorMenuOpen.value = false;
    isMapViewMenuOpen.value = false;
  }

  /// Centralized action to switch base map view between General and Satellite.
  ///
  /// Strictly preserves:
  /// - Current floor context and geometry
  /// - Viewpoints and visited progress
  /// - Itinerary route and navigation target
  /// - Active viewpoint card selection
  /// - Audio narration playback and bookmark position
  /// - Active TTS navigation guidance
  /// - User location and compass heading
  /// - Camera zoom and pan coordinates
  void switchMapView(MapViewType type) {
    if (selectedMapView.value == type) {
      closeMapViewMenu();
      return;
    }

    closeMapViewMenu();
    selectedMapView.value = type;
    lastViewedMapView = type;
  }

  /// Directly toggles base map view between Satellite and General.
  void toggleMapView() {
    final nextView = selectedMapView.value == MapViewType.satellite
        ? MapViewType.general
        : MapViewType.satellite;
    switchMapView(nextView);
  }

  /// Non-blocking callback when satellite tiles encounter fetch failure.
  void onSatelliteTileError() {
    hasSatelliteError.value = true;
  }

  /// Centralized floor switching action coordinating:
  /// 1. Close floor menu
  /// 2. Stop/pause old-floor audio narration and speech timers
  /// 3. Pause old-floor navigation
  /// 4. Clear selected old-floor viewpoint card
  /// 5. Save old floor camera state
  /// 6. Update selectedFloorId & single source of truth
  /// 7. Load target floor configuration
  /// 8. Load target floor map & architectural geometry
  /// 9. Load target viewpoints
  /// 10. Load target itinerary
  /// 11. Load target calibration
  /// 12. Restore/default target floor camera
  /// 13. Restore target floor visited progress
  /// 14. Update header
  /// 15. Reevaluate location rendering
  Future<void> switchFloor(String targetFloorId) async {
    if (isFloorSwitching.value) return;

    final savedFloor = availableFloors.firstWhereOrNull((floor) => floor.id == targetFloorId);
    if ((offlineLandmark != null || _sync != null) && savedFloor == null) return;
    final targetDef = savedFloor ?? FloorDefinition.fromId(targetFloorId);

    // If user selected the already active floor, close menu and do nothing destructive
    if (targetDef.id == currentFloor.value.id) {
      closeFloorMenu();
      return;
    }

    isFloorSwitching.value = true;

    // 1. Close floor menu
    closeFloorMenu();

    // 2. Stop/pause old-floor audio narration and progress timers
    _stopAudioProgressTimer();
    _currentSpeechStartOffset = 0;
    _lastSpokenCharIndex = 0;
    isPlayingAudio.value = false;
    audioProgress.value = 0.0;
    await ttsService.stop();

    // 3. Pause old-floor navigation guidance
    tourEngine.onUserStopOrCloseAudio();

    // 4. Clear selected old-floor viewpoint card
    selectedViewpoint.value = null;
    isCardCollapsed.value = false;
    narrationError.value = null;

    // 6. Update single source of truth floor state
    currentFloor.value = targetDef;
    floorId.value = targetDef.id;
    physicalFloorId.value = targetDef.id;
    compassService.setMapNorthOffset(0.0);
    floorName.value = targetDef.displayName;
    landmarkId.value = targetDef.landmarkId;
    if (offlineLandmark case final OfflineLandmark package) {
      landmarkName.value = package.landmark.name;
    } else if (Get.isRegistered<HomeController>()) {
      final markers = Get.find<HomeController>().landmarkMarkers;
      landmarkName.value = markers.firstWhereOrNull((marker) => marker.id == targetDef.landmarkId)?.name
          ?? targetDef.landmarkName;
    } else {
      landmarkName.value = targetDef.landmarkName;
    }
    lastViewedFloorId = targetDef.id;

    // 7, 8, 9, 10, 11, 13. Load target floor configuration, viewpoints, route, visited progress
    final storedVisited = visitedService.getVisitedForFloor(targetDef.id);
    final populatedViewpoints = targetDef.viewpoints.map((vp) {
      return vp.copyWith(isVisited: storedVisited.contains(vp.id));
    }).toList();

    viewpoints.assignAll(populatedViewpoints);

    _startFloorAnalytics(targetDef);
    tourEngine.startTour(
      floorId: targetDef.id,
      landmarkName: landmarkName.value,
      floorName: targetDef.displayName,
      viewpoints: populatedViewpoints,
      initialVisitedIds: storedVisited,
      isVoiceGuidanceEnabled: tourState.value.isVoiceGuidanceEnabled,
      isAutoPlayEnabled: tourState.value.isAutoPlayEnabled,
    );

    _refreshItinerarySegments();
    _loadRepositoryFloorData(targetDef.id, forceRefresh: true);

    try {
      mapController.move(targetDef.center, targetDef.defaultZoom);
    } catch (_) {}

    // Update GPS service tracking floor calibration
    gpsService.startTracking(floorId: targetDef.id);

    // Sync floor context to auto-detection engine
    floorDetectionEngine.setFloorContext(
      currentFloorId: targetDef.id,
      availableFloors: availableFloors,
    );

    // Subtle safety buffer to disable repeated rapid switching
    await Future<void>.delayed(const Duration(milliseconds: 150));
    isFloorSwitching.value = false;
    final snapshot = offlineLandmark == null ? _sync?.snapshotFor(_tourLanguage) : null;
    if (snapshot != null) _applyTourSnapshot(snapshot);
  }

  /// Builds architectural visual geometry polylines for the active floor level.
  List<Polyline> buildFloorArchitecturalPolylines(AppColors colors) {
    return const [];
  }
}
