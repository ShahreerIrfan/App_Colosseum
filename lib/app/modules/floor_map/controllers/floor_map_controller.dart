import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/geodesic_utils.dart';
import '../../../data/models/floor_definition.dart';
import '../../../data/models/itinerary_segment_model.dart';
import '../../../data/models/map_view_type.dart';
import '../../../data/models/tour_navigation_state.dart';
import '../../../data/models/user_location_model.dart';
import '../../../data/models/user_orientation_state.dart';
import '../../../data/models/viewpoint_model.dart';
import '../../../data/repositories/i_tour_repository.dart';
import '../../../data/repositories/tour_repository_impl.dart';
import '../../../data/services/compass_service.dart';
import '../../../data/services/gps_location_service.dart';
import '../../../data/services/tour_navigation_engine.dart';
import '../../../data/services/tts_service.dart';
import '../../../data/services/visited_viewpoints_service.dart';

/// Saved camera position and zoom state for a specific floor.
class FloorCameraState {
  final LatLng center;
  final double zoom;
  const FloorCameraState({required this.center, required this.zoom});
}

/// Controller managing floor map state, camera transformations, viewpoints, and audio playback.
class FloorMapController extends GetxController with WidgetsBindingObserver {
  final TtsService ttsService;
  final TourNavigationEngine tourEngine;
  final CompassService compassService;
  final GpsLocationService gpsService;
  final VisitedViewpointsService visitedService;
  final ITourRepository tourRepository;
  final bool? enablePeriodicSync;

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

  /// Per-floor saved camera states
  final Map<String, FloorCameraState> _savedCameraStates = <String, FloorCameraState>{};

  /// Physical floor ID where user is physically detected or anchored
  final physicalFloorId = 'floor_underground'.obs;

  /// Whether user is currently viewing a different floor than their physical location
  bool get isViewingDifferentFloor =>
      isUserInLocation.value && physicalFloorId.value != currentFloor.value.id;

  String get physicalFloorName =>
      FloorDefinition.fromId(physicalFloorId.value).displayName;

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
    if (viewpoints.isEmpty) return 'No viewpoints';
    if (isCurrentFloorComplete) {
      return '✓ Completed $currentFloorCompletedViewpoints/$currentFloorTotalViewpoints';
    }
    return 'Completed: $currentFloorCompletedViewpoints/$currentFloorTotalViewpoints';
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
      if (args.containsKey('landmarkId') && args['landmarkId'] != null) {
        landmarkId.value = FloorDefinition.normalizeLandmarkId(args['landmarkId'].toString());
      }
      if (args.containsKey('landmarkName') && args['landmarkName'] != null) {
        landmarkName.value = args['landmarkName'].toString();
      } else {
        landmarkName.value = FloorDefinition.landmarkNameFor(landmarkId.value);
      }
      if (args.containsKey('floorId') && args['floorId'] != null) {
        final def = FloorDefinition.fromId(args['floorId'].toString());
        currentFloor.value = def;
        floorId.value = def.id;
        floorName.value = def.displayName;
        if (landmarkId.value.isEmpty || (landmarkId.value == 'colosseum' && def.landmarkId != 'colosseum')) {
          landmarkId.value = def.landmarkId;
          landmarkName.value = def.landmarkName;
        }
      }
      if (args.containsKey('floorName') && args['floorName'] != null) {
        floorName.value = args['floorName'].toString();
      }
    } else if (floorId.value != 'floor_underground') {
      final def = FloorDefinition.fromId(floorId.value);
      currentFloor.value = def;
      floorId.value = def.id;
      floorName.value = def.displayName;
      landmarkId.value = def.landmarkId;
      landmarkName.value = def.landmarkName;
    }

    // Initialize Text-to-Speech service, Tour Navigation Engine, Device Compass & GPS
    _initTts();
    _initTour();
    _initCompass();
    _initGps();

    // Load viewpoints according to selected floor
    _loadFloorData();
    _loadAvailableFloors(forceRefresh: true);
    _startPeriodicFloorSync();
  }

  Timer? _periodicFloorSyncTimer;

  void _startPeriodicFloorSync() {
    if (!isPeriodicSyncEnabled) return;
    _periodicFloorSyncTimer?.cancel();
    _periodicFloorSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _loadAvailableFloors(forceRefresh: true);
      _loadRepositoryFloorData(currentFloor.value.id, forceRefresh: true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAvailableFloors(forceRefresh: true);
      _loadRepositoryFloorData(currentFloor.value.id, forceRefresh: true);
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
    ttsService.init();
    ttsService.onStart = () {
      isPlayingAudio.value = true;
      if (ttsService.currentSpeechType == TtsSpeechType.narration) {
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
      tourEngine.onAudioCompleted();
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
      isCardCollapsed.value = true; // Auto-play starts in collapsed mini-player
      isPlayingAudio.value = true;
      _currentSpeechStartOffset = 0;
      _lastSpokenCharIndex = 0;
      audioProgress.value = 0.0;
      if (viewpoint.description.isNotEmpty) {
        ttsService.speakNarration(viewpoint.description);
      }
    };

    tourEngine.onStateChanged = (state) {
      tourState.value = state;

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

  void _initCompass() {
    userOrientation.value = compassService.currentState;
    _compassSubscription = compassService.orientationStream.listen((state) {
      userOrientation.value = state;
      if (isUserInLocation.value && userLocation.value != null) {
        userLocation.value = userLocation.value!.copyWith(
          headingDegrees: state.mapHeadingDegrees ?? state.headingDegrees,
        );
      }
    });
    compassService.startListening();
  }

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
        final loc = result.userLocation!.copyWith(
          headingDegrees: userOrientation.value.headingDegrees,
        );
        userLocation.value = loc;
        tourEngine.updateLocation(loc);
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
    gpsService.snapToCanvasOffset(canvasOffset, floorId: floorId.value);
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

    gpsService.snapToCanvasOffset(canvasOffset, floorId: floorId.value);

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
  }

  /// Resets the local playground reference origin to current GPS location.
  void resetPlaygroundOrigin() {
    gpsService.resetPlaygroundOrigin();
    isDisplacementPaused.value = false;
  }

  void _loadFloorData() {
    final fid = floorId.value;
    final FloorDefinition def = FloorDefinition.fromId(fid);

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

  Future<void> _loadRepositoryFloorData(String targetFloorId, {bool forceRefresh = false}) async {
    try {
      final liveViewpoints = await tourRepository.getViewpointsByFloor(
        targetFloorId,
        forceRefresh: forceRefresh,
      );

      if (targetFloorId == currentFloor.value.id && liveViewpoints.isNotEmpty) {
        final storedVisited = visitedService.getVisitedForFloor(
            targetFloorId, liveViewpoints.map((v) => v.id));
        final populatedViewpoints = liveViewpoints.map((vp) {
          return vp.copyWith(isVisited: storedVisited.contains(vp.id));
        }).toList();

        viewpoints.assignAll(populatedViewpoints);
        currentFloor.value = currentFloor.value.copyWith(viewpoints: populatedViewpoints);

        final idx = availableFloors.indexWhere((f) => f.id == targetFloorId);
        if (idx != -1) {
          availableFloors[idx] = currentFloor.value;
        }

        tourEngine.updateViewpoints(populatedViewpoints);
        _refreshItinerarySegments();
        return;
      }

      final repoFloor = await tourRepository.getFloorById(targetFloorId);
      if (repoFloor != null && repoFloor.id == currentFloor.value.id) {
        currentFloor.value = repoFloor;
        final storedVisited = visitedService.getVisitedForFloor(
            repoFloor.id, repoFloor.viewpoints.map((v) => v.id));
        final populatedViewpoints = repoFloor.viewpoints.map((vp) {
          return vp.copyWith(isVisited: storedVisited.contains(vp.id));
        }).toList();
        viewpoints.assignAll(populatedViewpoints);
        tourEngine.updateViewpoints(populatedViewpoints);
        _refreshItinerarySegments();

        // Synchronize availableFloors with the fully populated floor
        final idx = availableFloors.indexWhere((f) => f.id == repoFloor.id);
        if (idx != -1) {
          availableFloors[idx] = repoFloor;
        }
      }
    } catch (_) {}
  }

  Future<void> _loadAvailableFloors({bool forceRefresh = false}) async {
    final cached = FloorDefinition.floorsForLandmark(landmarkId.value);
    if (cached.isNotEmpty) {
      availableFloors.assignAll(cached);
      _syncAvailableFloorsWithCurrent();
    }
    try {
      final loadedFloors = await tourRepository.getFloors(forceRefresh: forceRefresh);
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
    return currentFloor.value.itinerary;
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
    } else {
      isUserInLocation.value = false;
      userLocation.value = null;
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _periodicFloorSyncTimer?.cancel();
    _stopAudioProgressTimer();
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
    userOrientation.value = compassService.currentState;
    if (isUserInLocation.value && userLocation.value != null) {
      userLocation.value = userLocation.value!.copyWith(
        headingDegrees: compassService.currentState.mapHeadingDegrees ??
            compassService.currentState.headingDegrees,
      );
    }
  }

  /// Manually updates complete user orientation state.
  void updateOrientation(UserOrientationState state) {
    userOrientation.value = state;
    if (isUserInLocation.value && userLocation.value != null) {
      userLocation.value = userLocation.value!.copyWith(
        headingDegrees: state.mapHeadingDegrees ?? state.headingDegrees,
      );
    }
  }

  /// Selects a viewpoint, opens its detail card, and highlights marker.
  void selectViewpoint(ViewpointModel viewpoint) {
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
        tourEngine.markVisited(targetId);
        visitedService.markVisited(targetId);
      }
    }
  }

  /// Explicitly skips a viewpoint in the guided tour.
  void skipViewpoint([String? viewpointId]) {
    final targetId = viewpointId ?? tourState.value.navigationTargetId;
    if (targetId != null) {
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
      if (vp != null && vp.description.isNotEmpty) {
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
      userOrientation.value.mapHeadingDegrees ??
      userOrientation.value.headingDegrees ??
      userLocation.value?.headingDegrees;

  /// Handles camera movement changes on the satellite map.
  void onPositionChanged(MapCamera camera, bool hasGesture) {
    currentZoom.value = camera.zoom;
    if (hasGesture) {
      _savedCameraStates[currentFloor.value.id] = FloorCameraState(
        center: camera.center,
        zoom: camera.zoom,
      );
    }
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
        } else if (pt.dx > 1.0 && pt.dy > 1.0) {
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

    final targetDef = FloorDefinition.fromId(targetFloorId);

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

    // 5. Save old floor camera state
    try {
      _savedCameraStates[currentFloor.value.id] = FloorCameraState(
        center: mapController.camera.center,
        zoom: mapController.camera.zoom,
      );
    } catch (_) {}

    // 6. Update single source of truth floor state
    currentFloor.value = targetDef;
    floorId.value = targetDef.id;
    floorName.value = targetDef.displayName;
    landmarkId.value = targetDef.landmarkId;
    landmarkName.value = targetDef.landmarkName;
    lastViewedFloorId = targetDef.id;

    // 7, 8, 9, 10, 11, 13. Load target floor configuration, viewpoints, route, visited progress
    final storedVisited = visitedService.getVisitedForFloor(targetDef.id);
    final populatedViewpoints = targetDef.viewpoints.map((vp) {
      return vp.copyWith(isVisited: storedVisited.contains(vp.id));
    }).toList();

    viewpoints.assignAll(populatedViewpoints);

    tourEngine.startTour(
      floorId: targetDef.id,
      landmarkName: targetDef.landmarkName,
      floorName: targetDef.displayName,
      viewpoints: populatedViewpoints,
      initialVisitedIds: storedVisited,
      isVoiceGuidanceEnabled: tourState.value.isVoiceGuidanceEnabled,
      isAutoPlayEnabled: tourState.value.isAutoPlayEnabled,
    );

    _refreshItinerarySegments();
    _loadRepositoryFloorData(targetDef.id, forceRefresh: true);

    // 12. Restore or default target floor camera
    if (_savedCameraStates.containsKey(targetDef.id)) {
      final saved = _savedCameraStates[targetDef.id]!;
      try {
        mapController.move(saved.center, saved.zoom);
      } catch (_) {}
    } else {
      try {
        mapController.move(targetDef.center, targetDef.defaultZoom);
      } catch (_) {}
    }

    // Update GPS service tracking floor calibration
    gpsService.startTracking(floorId: targetDef.id);

    // Subtle safety buffer to disable repeated rapid switching
    await Future<void>.delayed(const Duration(milliseconds: 150));
    isFloorSwitching.value = false;
  }

  /// Builds architectural visual geometry polylines for the active floor level.
  List<Polyline> buildFloorArchitecturalPolylines(AppColors colors) {
    return const [];
  }
}
