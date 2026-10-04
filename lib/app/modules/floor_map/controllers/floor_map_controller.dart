import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/geodesic_utils.dart';
import '../../../data/models/itinerary_segment_model.dart';
import '../../../data/models/tour_navigation_state.dart';
import '../../../data/providers/colosseum_tour_data.dart';
import '../../../data/models/user_location_model.dart';
import '../../../data/models/user_orientation_state.dart';
import '../../../data/models/viewpoint_model.dart';
import '../../../data/services/compass_service.dart';
import '../../../data/services/gps_location_service.dart';
import '../../../data/services/tour_navigation_engine.dart';
import '../../../data/services/tts_service.dart';
import '../../../data/services/visited_viewpoints_service.dart';

/// Controller managing floor map state, camera transformations, viewpoints, and audio playback.
class FloorMapController extends GetxController {
  final TtsService ttsService;
  final TourNavigationEngine tourEngine;
  final CompassService compassService;
  final GpsLocationService gpsService;
  final VisitedViewpointsService visitedService;

  FloorMapController({
    TtsService? ttsService,
    TourNavigationEngine? tourEngine,
    CompassService? compassService,
    GpsLocationService? gpsService,
    VisitedViewpointsService? visitedService,
  })  : ttsService = ttsService ?? TtsService(),
        tourEngine = tourEngine ?? TourNavigationEngine(),
        compassService = compassService ?? CompassService(),
        gpsService = gpsService ?? GpsLocationService(),
        visitedService = visitedService ??
            (Get.isRegistered<VisitedViewpointsService>()
                ? Get.find<VisitedViewpointsService>()
                : Get.put(VisitedViewpointsService()));

  final landmarkName = 'Colosseum'.obs;
  final floorName = 'Underground (Hypogeum)'.obs;
  final floorId = 'floor_underground'.obs;

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

  /// Viewpoints for all 4 monumental levels (centralized in ColosseumTourData)
  static const List<ViewpointModel> undergroundViewpoints = ColosseumTourData.undergroundViewpoints;
  static const List<ViewpointModel> floor1Viewpoints = ColosseumTourData.level1Viewpoints;
  static const List<ViewpointModel> floor2Viewpoints = ColosseumTourData.level2Viewpoints;
  static const List<ViewpointModel> floor3Viewpoints = ColosseumTourData.level3Viewpoints;

  /// Architectural Guided Itinerary Segments for all 4 levels
  static const List<ItinerarySegmentModel> undergroundItinerary = ColosseumTourData.undergroundItinerary;
  static const List<ItinerarySegmentModel> level1Itinerary = ColosseumTourData.level1Itinerary;
  static const List<ItinerarySegmentModel> level2Itinerary = ColosseumTourData.level2Itinerary;
  static const List<ItinerarySegmentModel> level3Itinerary = ColosseumTourData.level3Itinerary;

  @override
  void onInit() {
    super.onInit();
    mapController = MapController();
    transformationController = TransformationController();

    // Parse navigation arguments if passed
    final args = Get.arguments;
    if (args is Map) {
      if (args.containsKey('landmarkName') && args['landmarkName'] != null) {
        landmarkName.value = args['landmarkName'].toString();
      }
      if (args.containsKey('floorName') && args['floorName'] != null) {
        floorName.value = args['floorName'].toString();
      }
      if (args.containsKey('floorId') && args['floorId'] != null) {
        floorId.value = args['floorId'].toString();
      }
    }

    // Initialize Text-to-Speech service, Tour Navigation Engine, Device Compass & GPS
    _initTts();
    _initTour();
    _initCompass();
    _initGps();

    // Load viewpoints according to selected floor
    _loadFloorData();
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
        _startAudioProgressTimer();
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
  void snapToTarget() {
    if (viewpoints.isEmpty) return;

    // 0. Cleanly stop any active audio from previous stop before snapping
    if (isPlayingAudio.value || ttsService.currentSpeechType != TtsSpeechType.none) {
      _stopAudioProgressTimer();
      isPlayingAudio.value = false;
      audioProgress.value = 0.0;
      ttsService.stop();
    }

    // 1. Freeze physical GPS drift so real sensor noise does not push user puck away
    gpsService.pauseDisplacement();
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
  void setSimulatedLocation(LatLng point) {
    // Cleanly stop any active audio when placing location
    if (isPlayingAudio.value || ttsService.currentSpeechType != TtsSpeechType.none) {
      _stopAudioProgressTimer();
      isPlayingAudio.value = false;
      audioProgress.value = 0.0;
      ttsService.stop();
    }

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
    final fid = floorId.value.toLowerCase();
    final List<ViewpointModel> currentViewpoints;
    final String activeFloorId;

    final hasCustomName = (Get.arguments is Map) && (Get.arguments as Map).containsKey('floorName');

    if (fid.contains('underground')) {
      if (!hasCustomName) floorName.value = 'Underground (Hypogeum)';
      currentViewpoints = undergroundViewpoints;
      activeFloorId = 'floor_underground';
    } else if (fid.contains('2')) {
      if (!hasCustomName) floorName.value = 'Floor 2';
      currentViewpoints = floor2Viewpoints;
      activeFloorId = 'floor_2';
    } else if (fid.contains('3')) {
      if (!hasCustomName) floorName.value = 'Floor 3';
      currentViewpoints = floor3Viewpoints;
      activeFloorId = 'floor_3';
    } else {
      if (!hasCustomName) floorName.value = 'Floor 1';
      currentViewpoints = floor1Viewpoints;
      activeFloorId = 'floor_1';
    }

    final storedVisited = visitedService.getVisitedForFloor(activeFloorId);
    final populatedViewpoints = currentViewpoints.map((vp) {
      return vp.copyWith(isVisited: storedVisited.contains(vp.id));
    }).toList();

    viewpoints.assignAll(populatedViewpoints);
    tourEngine.startTour(
      floorId: activeFloorId,
      viewpoints: populatedViewpoints,
      initialVisitedIds: storedVisited,
      isVoiceGuidanceEnabled: tourState.value.isVoiceGuidanceEnabled,
      isAutoPlayEnabled: tourState.value.isAutoPlayEnabled,
    );
    _refreshItinerarySegments();
  }

  /// Returns the architectural walking itinerary for the currently active floor.
  List<ItinerarySegmentModel> _getCurrentFloorItinerary() {
    final fid = floorId.value.toLowerCase();
    if (fid.contains('underground')) return undergroundItinerary;
    if (fid.contains('2')) return level2Itinerary;
    if (fid.contains('3')) return level3Itinerary;
    return level1Itinerary;
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

      final latLngs = <LatLng>[];
      for (int i = 0; i < rawPoints.length; i++) {
        if (i == 0) {
          final vp = viewpoints.firstWhereOrNull((v) => v.id == segment.fromId);
          latLngs.add(vp?.latLng ?? GeodesicUtils.canvasOffsetToLatLng(rawPoints[i]));
        } else if (i == rawPoints.length - 1) {
          final vp = viewpoints.firstWhereOrNull((v) => v.id == segment.toId);
          latLngs.add(vp?.latLng ?? GeodesicUtils.canvasOffsetToLatLng(rawPoints[i]));
        } else {
          latLngs.add(GeodesicUtils.canvasOffsetToLatLng(rawPoints[i]));
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
        mapController.move(colosseumCenter, defaultZoom);
      }
    } catch (_) {}

    transformationController.value = Matrix4.identity();
  }
}
