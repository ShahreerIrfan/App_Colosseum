import '../../core/localization/tour_localizations.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show Offset;
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/floor_definition.dart';
import '../models/tour_navigation_state.dart';
import '../models/user_location_model.dart';
import '../models/viewpoint_model.dart';

/// Centralized state machine engine managing location-aware indoor tour guidance,
/// proximity detection, arrival dwell, departure hysteresis, audio auto-play, and user overrides.
class TourNavigationEngine {
  final TourConfig defaultConfig;
  TourConfig get config => defaultConfig;

  TourNavigationState _state = const TourNavigationState();
  TourNavigationState get state => _state;

  List<ViewpointModel> _viewpoints = [];
  List<ViewpointModel> get viewpoints => List.unmodifiable(_viewpoints);

  Offset? _entryLocation;
  Offset? _exitLocation;
  bool get _hasExit => _exitLocation != null;
  bool _canReevaluateHeading = false;
  final Set<String> _announcedApproachViewpointIds = <String>{};
  Timer? _arrivalDwellTimer;

  void _cancelArrivalDwellTimer() {
    _arrivalDwellTimer?.cancel();
    _arrivalDwellTimer = null;
  }

  void _scheduleArrivalDwellTimer(Offset userOffset) {
    _cancelArrivalDwellTimer();
    _arrivalDwellTimer = Timer(config.arrivalDwellDuration, () {
      _arrivalDwellTimer = null;
      if (_state.navigationStatus == TourNavigationStatus.arrivalPending &&
          _state.userLocation != null) {
        final latestOffset = Offset(
          _state.userLocation!.normalizedX,
          _state.userLocation!.normalizedY,
        );
        _evaluateTargetProximity(latestOffset, DateTime.now(), useLiveTimer: false);
      }
    });
  }

  /// Releases any pending dwell timers.
  void dispose() {
    _cancelArrivalDwellTimer();
  }

  /// Callbacks for engine events
  void Function(String text, {VoidCallback? onDone})? onSpeakInstruction;
  void Function(ViewpointModel viewpoint)? onAutoPlayViewpoint;
  void Function(TourNavigationState state)? onStateChanged;

  TourNavigationEngine({
    TourConfig? config,
    this.onSpeakInstruction,
    this.onAutoPlayViewpoint,
    this.onStateChanged,
  }) : defaultConfig = config ?? const TourConfig();

  /// Initializes or starts the guided tour on a specific floor.
  void startTour({
    required String floorId,
    required List<ViewpointModel> viewpoints,
    String? landmarkName,
    String? floorName,
    Offset? entryLocation,
    Offset? exitLocation,
    bool isVoiceGuidanceEnabled = true,
    bool isAutoPlayEnabled = true,
    Set<String>? initialVisitedIds,
  }) {
    _viewpoints = List.from(viewpoints);
    _entryLocation = entryLocation;
    _exitLocation = exitLocation;
    _canReevaluateHeading = false;
    _announcedApproachViewpointIds.clear();
    _cancelArrivalDwellTimer();

    // Sort viewpoints by order if present
    _orderViewpoints();

    final initialVisited = initialVisitedIds != null
        ? Set<String>.from(initialVisitedIds)
        : <String>{};

    for (int i = 0; i < _viewpoints.length; i++) {
      if (initialVisited.contains(_viewpoints[i].id)) {
        _viewpoints[i] = _viewpoints[i].copyWith(isVisited: true);
      }
    }

    final firstUnvisited = _findNextItineraryTarget(initialVisited, const <String>{});
    final effectiveFirstTarget = firstUnvisited ??
        (_viewpoints.isNotEmpty
            ? _viewpoints.first.id
            : (_hasExit ? 'EXIT' : null));

    final resolvedFloor = FloorDefinition.fromId(floorId);
    final effectiveLandmarkName = landmarkName ?? resolvedFloor.landmarkName;
    final effectiveFloorName = floorName ?? resolvedFloor.displayName;

    _state = TourNavigationState(
      itineraryId: '${floorId}_tour',
      activeFloorId: floorId,
      landmarkName: effectiveLandmarkName,
      floorName: effectiveFloorName,
      navigationTargetId: effectiveFirstTarget,
      previousTargetId: null,
      armedAutoPlayViewpointId: effectiveFirstTarget,
      navigationStatus: initialVisited.length >= _viewpoints.length && _viewpoints.isNotEmpty
          ? TourNavigationStatus.itineraryComplete
          : TourNavigationStatus.navigating,
      isVoiceGuidanceEnabled: isVoiceGuidanceEnabled,
      isAutoPlayEnabled: isAutoPlayEnabled,
      visitedIds: initialVisited,
      skippedIds: <String>{},
      autoPlayedViewpointIds: <String>{},
    );

    _notifyState();

    if (isVoiceGuidanceEnabled && _viewpoints.isNotEmpty && effectiveFirstTarget != null && effectiveFirstTarget != 'EXIT') {
      final firstVp = _viewpoints.where((vp) => vp.id == effectiveFirstTarget).firstOrNull;
      if (firstVp != null) {
        _speakInitialGreeting(firstVp);
      }
    }
  }

  void _orderViewpoints() {
    _viewpoints.sort((a, b) => a.order.compareTo(b.order));
  }

  /// Dynamically updates the viewpoints on the active tour from live sync
  /// while preserving current navigation progress, visited status, and targets.
  void updateViewpoints(List<ViewpointModel> newViewpoints) {
    final wasEmpty = _viewpoints.isEmpty;
    _viewpoints = List.from(newViewpoints);
    _orderViewpoints();

    for (int i = 0; i < _viewpoints.length; i++) {
      if (_state.visitedIds.contains(_viewpoints[i].id)) {
        _viewpoints[i] = _viewpoints[i].copyWith(isVisited: true);
      }
    }

    final availableIds = _viewpoints.map((vp) => vp.id).toSet();
    bool wasRemoved(String? id) => id != null &&
        id != 'ENTRY' && id != 'EXIT' && !availableIds.contains(id);
    final activeAudioRemoved = wasRemoved(_state.activeAudioViewpointId);
    final previousRemoved = wasRemoved(_state.previousTargetId);
    if (previousRemoved) {
      _state = _state.copyWith(previousTargetId: () => null, distanceFromPrevious: () => null);
    }
    if (wasRemoved(_state.selectedViewpointId)) {
      _state = _state.copyWith(selectedViewpointId: () => null);
    }
    if (wasRemoved(_state.reachedViewpointId)) {
      _state = _state.copyWith(reachedViewpointId: () => null);
    }
    if (activeAudioRemoved) {
      _state = _state.copyWith(activeAudioViewpointId: () => null);
    }
    if (wasRemoved(_state.navigationTargetId) ||
        (_state.navigationTargetId == 'EXIT' && !_hasExit) ||
        (wasEmpty && _state.navigationTargetId == null && _viewpoints.isNotEmpty)) {
      final nextTarget = _findNextItineraryTarget(_state.visitedIds, _state.skippedIds);
      _state = _state.copyWith(
        navigationTargetId: () => nextTarget,
        armedAutoPlayViewpointId: () => nextTarget,
        previousTargetId: () => null,
        arrivalDwellStartedAt: () => null,
        distanceToTarget: () => null,
        distanceFromPrevious: () => null,
        navigationStatus: nextTarget == null
            ? TourNavigationStatus.itineraryComplete
            : TourNavigationStatus.navigating,
      );
    } else if (activeAudioRemoved ||
        (previousRemoved && _state.navigationStatus == TourNavigationStatus.waitingForDeparture)) {
      _state = _state.copyWith(
        armedAutoPlayViewpointId: () => _state.navigationTargetId,
        navigationStatus: _state.navigationTargetId == null
            ? TourNavigationStatus.itineraryComplete
            : TourNavigationStatus.navigating,
      );
    }
    _notifyState();
  }

  void _speakInitialGreeting(ViewpointModel firstVp) {
    final landmark = _state.landmarkName;
    final isColosseum = landmark.toLowerCase() == 'colosseum';
    if (isColosseum) {
      _speakThrottled(
        'Begin the {floor} tour. Proceed toward Viewpoint {number}.'.tourTextWith({'floor': _localizedFloorName, 'number': firstVp.order}),
      );
    } else {
      final formattedLandmark = landmark.toLowerCase().startsWith('the ')
          ? landmark
          : 'the $landmark';
      final titleSuffix = firstVp.title.isNotEmpty ? ': ${firstVp.title}' : '';
      _speakThrottled(
        'Welcome to {place}. Proceed to Viewpoint {number}{title}.'.tourTextWith({
          'place': TourLocalizations.currentLanguage == 'en' ? formattedLandmark : landmark,
          'number': firstVp.order,
          'title': titleSuffix,
        }),
      );
    }
  }

  String get _localizedFloorName =>
      TourLocalizations.currentLanguage != 'en' && _state.floorName != null
          ? _state.floorName! : _getFloorTourName(_state.activeFloorId);

  String _getFloorTourName(String? floorId) {
    if (floorId == null) return _state.landmarkName;
    if (floorId.contains('underground')) return 'Underground';
    if (floorId.contains('1')) return 'Level 1';
    if (floorId.contains('2')) return 'Level 2';
    if (floorId.contains('3')) return 'Level 3';
    return _state.floorName ?? _state.landmarkName;
  }

  /// Calculates real-world metric physical distance between two normalized floor offsets.
  double calculateMetricDistance(Offset p1, Offset p2) {
    final dx = (p2.dx - p1.dx) * config.arenaWidthMeters;
    final dy = (p2.dy - p1.dy) * config.arenaHeightMeters;
    return math.sqrt(dx * dx + dy * dy);
  }

  double _distanceToViewpoint(Offset offset, ViewpointModel viewpoint) {
    final location = _state.userLocation;
    if (location?.latitude != null && location?.longitude != null &&
        viewpoint.hasGeographicPosition) {
      return const Distance(roundResult: false).as(
        LengthUnit.Meter, location!.latLng, viewpoint.latLng,
      );
    }
    return calculateMetricDistance(
      offset, Offset(viewpoint.normalizedX, viewpoint.normalizedY),
    );
  }

  /// Recheck a heading-gated stop using the last accepted, fresh GPS fix.
  void updateHeading(double? heading, {DateTime? now}) {
    final location = _state.userLocation;
    final timestamp = location?.timestamp;
    final time = now ?? DateTime.now();
    if (!_canReevaluateHeading || location == null || timestamp == null ||
        !_viewpoints.any((vp) => vp.id == _state.navigationTargetId &&
            vp.targetGazeHeadingDegrees != null)) {
      return;
    }
    if (time.difference(timestamp) > config.maxLocationAge) {
      _canReevaluateHeading = false;
      _state = _state.copyWith(arrivalDwellStartedAt: () => null);
      return;
    }
    _state = _state.copyWith(userLocation: () => location.copyWith(
      headingDegrees: heading, clearHeading: heading == null,
    ));
    _evaluateTargetProximity(
      Offset(location.normalizedX, location.normalizedY), time,
    );
  }

  /// Evaluates an incoming indoor location beacon and advances navigation state.
  /// If [isSimulated] is true (e.g. developer map tap or snap stop), jump detection and dwell
  /// timers are bypassed so arrival and auto-play trigger immediately.
  void updateLocation(
    UserLocationModel location, {
    DateTime? now,
    bool isSimulated = false,
  }) {
    final currentTime = now ?? location.timestamp ?? DateTime.now();
    _canReevaluateHeading = false;

    // 1. Floor Validation Check
    if (location.floorId != _state.activeFloorId) {
      // Location update belongs to another floor, ignore proximity
      return;
    }

    // 2. Location Staleness Check
    if (!isSimulated && location.timestamp != null) {
      final age = currentTime.difference(location.timestamp!);
      if (age > config.maxLocationAge) {
        // Discard stale location
        return;
      }
    }

    // 3. Accuracy / Quality Check
    if (!isSimulated && location.accuracyMeters > config.maxAcceptableAccuracyMeters) {
      _state = _state.copyWith(
        isLocationUncertain: true,
        navigationStatus: TourNavigationStatus.locationUncertain,
        userLocation: () => location,
      );
      _notifyState();
      return;
    }

    // Recover from locationUncertain if accuracy is now acceptable
    if (_state.isLocationUncertain) {
      _state = _state.copyWith(isLocationUncertain: false);
    }

    // Adaptive Exponential Moving Average (EMA) smoothing for indoor positioning
    UserLocationModel effectiveLocation = location;
    if (!isSimulated &&
        _state.userLocation != null &&
        _state.userLocation!.floorId == location.floorId) {
      final prev = _state.userLocation!;
      // Dynamic smoothing weight: higher responsiveness when accuracy is good, stronger damping when accuracy is noisy
      final alpha = (15.0 / location.accuracyMeters.clamp(5.0, 60.0)).clamp(0.25, 0.85);
      final smoothedX = prev.normalizedX * (1 - alpha) + location.normalizedX * alpha;
      final smoothedY = prev.normalizedY * (1 - alpha) + location.normalizedY * alpha;

      double? smoothedLat;
      double? smoothedLng;
      if (prev.latitude != null && location.latitude != null &&
          prev.longitude != null && location.longitude != null) {
        smoothedLat = prev.latitude! * (1 - alpha) + location.latitude! * alpha;
        smoothedLng = prev.longitude! * (1 - alpha) + location.longitude! * alpha;
      }

      effectiveLocation = location.copyWith(
        normalizedX: smoothedX,
        normalizedY: smoothedY,
        latitude: smoothedLat,
        longitude: smoothedLng,
      );
    }

    // 4. Sudden Impossible Jump Detection
    if (!isSimulated && _state.userLocation != null) {
      final prevOffset = Offset(
        _state.userLocation!.normalizedX,
        _state.userLocation!.normalizedY,
      );
      final newOffset = Offset(effectiveLocation.normalizedX, effectiveLocation.normalizedY);
      final previous = _state.userLocation!;
      final jumpDist = previous.latitude != null && previous.longitude != null &&
              effectiveLocation.latitude != null && effectiveLocation.longitude != null
          ? const Distance(roundResult: false).as(
              LengthUnit.Meter, previous.latLng, effectiveLocation.latLng,
            )
          : calculateMetricDistance(prevOffset, newOffset);

      if (jumpDist > config.maxJumpDistanceMeters) {
        // Mark jump suspicious; invalidate pending arrival dwell
        _state = _state.copyWith(
          userLocation: () => effectiveLocation,
          arrivalDwellStartedAt: () => null,
        );
        _notifyState();
        return;
      }
    }

    // Record user location
    _state = _state.copyWith(userLocation: () => effectiveLocation);
    _canReevaluateHeading = !isSimulated;

    final userOffset = Offset(effectiveLocation.normalizedX, effectiveLocation.normalizedY);

    // 5. Evaluate Departure from Previous Stop (Hysteresis)
    // When isSimulated is true (developer snap / manual placement), skip departure instruction
    // to prevent collision with immediate arrival instruction on the same tick.
    if (!isSimulated) {
      _evaluateDeparture(userOffset, currentTime);
    }

    // 6. Evaluate Target Proximity & Arrival
    _evaluateTargetProximity(
      userOffset,
      currentTime,
      isSimulated: isSimulated,
      useLiveTimer: now == null && !isSimulated,
    );
  }

  void _evaluateDeparture(Offset userOffset, DateTime currentTime) {
    if (_state.previousTargetId == null) return;

    double? distFromPrev;
    if (_state.previousTargetId == 'ENTRY') {
      final entry = _entryLocation;
      if (entry != null) distFromPrev = calculateMetricDistance(userOffset, entry);
    } else {
      final prevVp = _viewpoints
          .where((vp) => vp.id == _state.previousTargetId)
          .firstOrNull;
      if (prevVp != null) {
        distFromPrev = _distanceToViewpoint(userOffset, prevVp);
      }
    }

    if (distFromPrev != null) {
      _state = _state.copyWith(
        distanceFromPrevious: () => distFromPrev,
      );

      // Check if visitor was waiting for departure after marking visited
      if (_state.navigationStatus == TourNavigationStatus.waitingForDeparture ||
          (_state.previousTargetId != null &&
              _state.visitedIds.contains(_state.previousTargetId) &&
              _state.armedAutoPlayViewpointId == null &&
              _state.navigationTargetId != null &&
              _state.navigationTargetId != 'EXIT')) {
        final previousViewpoint =
            _viewpoints.where((vp) => vp.id == _state.previousTargetId).firstOrNull;
        final departureRadius = math.max(
          config.departureRadiusMeters,
          (previousViewpoint?.triggerRadiusMeters ?? config.arrivalRadiusMeters) + 0.5,
        );
        if (distFromPrev >= departureRadius) {
          // Confirmed physical departure!
          final nextTargetId = _state.navigationTargetId;
          _state = _state.copyWith(
            navigationStatus: TourNavigationStatus.navigating,
            armedAutoPlayViewpointId: () => nextTargetId,
          );

          final nextVp = _viewpoints
              .where((vp) => vp.id == nextTargetId)
              .firstOrNull;

          if (_state.isVoiceGuidanceEnabled &&
              _state.activeAudioViewpointId == null) {
            if (nextVp != null) {
              _speakThrottled(
                'Next, proceed toward Viewpoint {number}.'.tourTextWith({'number': nextVp.order}),
              );
            } else if (nextTargetId == 'EXIT') {
              _speakThrottled('Proceed toward the Exit portal.'.tourText);
            }
          }
        }
      }
    }
  }

  void _evaluateTargetProximity(
    Offset userOffset,
    DateTime currentTime, {
    bool isSimulated = false,
    bool useLiveTimer = true,
  }) {
    if (_state.navigationTargetId == null) return;

    // Handle EXIT Portal Target
    if (_state.navigationTargetId == 'EXIT') {
      if (_hasExit) {
        final distToExit = calculateMetricDistance(userOffset, _exitLocation!);
        _state = _state.copyWith(distanceToTarget: () => distToExit);

        final isExitDwellConfirmed = isSimulated ||
            (_state.arrivalDwellStartedAt != null &&
                currentTime.difference(_state.arrivalDwellStartedAt!) >=
                    config.arrivalDwellDuration);

        if (distToExit <= config.arrivalRadiusMeters) {
          if (!isExitDwellConfirmed && _state.arrivalDwellStartedAt == null) {
            _state = _state.copyWith(
              arrivalDwellStartedAt: () => currentTime,
              navigationStatus: TourNavigationStatus.arrivalPending,
            );
            if (useLiveTimer) {
              _scheduleArrivalDwellTimer(userOffset);
            }
          } else if (isExitDwellConfirmed) {
            _cancelArrivalDwellTimer();
            if (_state.navigationStatus != TourNavigationStatus.itineraryComplete) {
              _state = _state.copyWith(
                navigationStatus: TourNavigationStatus.itineraryComplete,
                reachedViewpointId: () => 'EXIT',
                arrivalDwellStartedAt: () => null,
              );
              if (_state.isVoiceGuidanceEnabled) {
                final isColosseum =
                    _state.landmarkName.toLowerCase() == 'colosseum';
                if (isColosseum) {
                  _speakThrottled(
                    'You have completed the {place} itinerary. The exit is here.'.tourTextWith({'place': _localizedFloorName}),
                  );
                } else {
                  _speakThrottled(
                    'You have completed the {place} itinerary. The exit is here.'.tourTextWith({'place': _state.landmarkName}),
                  );
                }
              }
            }
          }
        } else {
          _state = _state.copyWith(arrivalDwellStartedAt: () => null);
        }
      }
      _notifyState();
      return;
    }

    // Handle Viewpoint Target
    final targetVp = _viewpoints
        .where((vp) => vp.id == _state.navigationTargetId)
        .firstOrNull;
    if (targetVp == null) {
      _notifyState();
      return;
    }

    final distToTarget = _distanceToViewpoint(userOffset, targetVp);
    final configuredRadius = targetVp.triggerRadiusMeters;
    final arrivalRadius = configuredRadius != null && configuredRadius.isFinite && configuredRadius > 0
        ? configuredRadius : config.arrivalRadiusMeters;
    final approachRadius = math.max(config.approachRadiusMeters, arrivalRadius);

    _state = _state.copyWith(distanceToTarget: () => distToTarget);

    // Active viewpoint narration or already arrived / exploring states
    final isAtOrExploring = _state.navigationStatus == TourNavigationStatus.arrived ||
        _state.navigationStatus == TourNavigationStatus.viewpointAudioPlaying ||
        _state.navigationStatus == TourNavigationStatus.waitingAtViewpoint ||
        _state.navigationStatus == TourNavigationStatus.waitingForVisited ||
        _state.navigationStatus == TourNavigationStatus.waitingForDeparture;

    if (isAtOrExploring && _state.reachedViewpointId == targetVp.id) {
      _notifyState();
      return;
    }

    // 1. Outside Approach Radius with 2m Hysteresis (> approachRadius + 2m)
    if (distToTarget > approachRadius + 2.0) {
      if (_state.navigationStatus == TourNavigationStatus.approaching ||
          _state.navigationStatus == TourNavigationStatus.arrivalPending) {
        _cancelArrivalDwellTimer();
        _state = _state.copyWith(
          arrivalDwellStartedAt: () => null,
          navigationStatus: TourNavigationStatus.navigating,
        );
      }
    }
    // 2. Inside Approach Radius (arrivalRadius < dist <= approachRadius)
    else if (distToTarget > arrivalRadius && distToTarget <= approachRadius) {
      _cancelArrivalDwellTimer();
      _state = _state.copyWith(arrivalDwellStartedAt: () => null);
      if (_state.navigationStatus != TourNavigationStatus.approaching &&
          !isAtOrExploring) {
        _state = _state.copyWith(
          navigationStatus: TourNavigationStatus.approaching,
        );
        if (_state.isVoiceGuidanceEnabled &&
            _state.activeAudioViewpointId == null &&
            !_announcedApproachViewpointIds.contains(targetVp.id)) {
          _announcedApproachViewpointIds.add(targetVp.id);
          _speakThrottled('Viewpoint {number} is ahead.'.tourTextWith({'number': targetVp.order}));
        }
      }
    }
    // 3. Inside Arrival Radius (<= arrivalRadius) -> Dwell Verification
    else if (distToTarget <= arrivalRadius) {
      final targetHeading = targetVp.targetGazeHeadingDegrees;
      final heading = _state.userLocation?.headingDegrees;
      if (targetHeading != null &&
          (heading == null || !heading.isFinite || !targetHeading.isFinite ||
           ((heading - targetHeading + 180) % 360 - 180).abs() > config.headingToleranceDegrees)) {
        _state = _state.copyWith(arrivalDwellStartedAt: () => null);
        _notifyState();
        return;
      }
      final isDwellSatisfied = isSimulated ||
          (_state.arrivalDwellStartedAt != null &&
              currentTime.difference(_state.arrivalDwellStartedAt!) >=
                  config.arrivalDwellDuration);

      if (!isDwellSatisfied && _state.arrivalDwellStartedAt == null) {
        _state = _state.copyWith(
          arrivalDwellStartedAt: () => currentTime,
          navigationStatus: TourNavigationStatus.arrivalPending,
        );
        if (useLiveTimer) {
          _scheduleArrivalDwellTimer(userOffset);
        }
      } else if (isDwellSatisfied) {
        // ARRIVAL CONFIRMED!
        _cancelArrivalDwellTimer();
        _announcedApproachViewpointIds.add(targetVp.id);
        _state = _state.copyWith(
          navigationStatus: TourNavigationStatus.arrived,
          reachedViewpointId: () => targetVp.id,
          arrivalDwellStartedAt: () => null,
          isExplicitlyClosed: false,
          pausedByUser: false,
        );

        // Auto-play eligibility: completely decoupled from visitedIds!
        // Viewpoints will auto-play as long as auto-play is enabled and this stop hasn't already auto-played in this session.
        final isEligibleForAutoPlay = _state.isAutoPlayEnabled &&
            !_state.autoPlayedViewpointIds.contains(targetVp.id) &&
            !_state.skippedIds.contains(targetVp.id);

        if (_state.isVoiceGuidanceEnabled) {
          _speakThrottled(
            'You have arrived at Viewpoint {number}.'.tourTextWith({'number': targetVp.order}),
            onDone: () {
              if (_state.navigationTargetId != targetVp.id ||
                  _state.reachedViewpointId != targetVp.id) {
                return;
              }
              if (isEligibleForAutoPlay) {
                _triggerAutoPlay(targetVp);
              } else {
                _state = _state.copyWith(
                  navigationStatus: TourNavigationStatus.waitingAtViewpoint,
                );
                _notifyState();
              }
            },
          );
        } else {
          if (isEligibleForAutoPlay) {
            _triggerAutoPlay(targetVp);
          } else {
            _state = _state.copyWith(
              navigationStatus: TourNavigationStatus.waitingAtViewpoint,
            );
          }
        }
      }
    }

    _notifyState();
  }

  void _triggerAutoPlay(ViewpointModel targetVp) {
    final updatedAutoPlayed = Set<String>.from(_state.autoPlayedViewpointIds)
      ..add(targetVp.id);

    _state = _state.copyWith(
      armedAutoPlayViewpointId: () => null, // Disarm current stop
      autoPlayedViewpointIds: updatedAutoPlayed,
      activeAudioViewpointId: () => targetVp.id,
      selectedViewpointId: () => targetVp.id,
      navigationStatus: TourNavigationStatus.viewpointAudioPlaying,
      pausedByUser: false,
      pausedBySystem: false,
      isExplicitlyClosed: false,
    );

    _notifyState();
    onAutoPlayViewpoint?.call(targetVp);
  }

  /// Explicit user action or auto-completion: Marks a viewpoint as visited and advances navigation.
  void markVisited(String viewpointId) {
    _announcedApproachViewpointIds.add(viewpointId);
    final updatedVisited = Set<String>.from(_state.visitedIds)..add(viewpointId);
    
    // Update local viewpoint copy
    final index = _viewpoints.indexWhere((vp) => vp.id == viewpointId);
    if (index != -1) {
      _viewpoints[index] = _viewpoints[index].copyWith(isVisited: true);
    }

    String? nextTargetId = _state.navigationTargetId;
    String? prevTargetId = _state.previousTargetId;

    if (_state.navigationTargetId == viewpointId) {
      prevTargetId = viewpointId;
      // Advance target to the next unvisited and unskipped stop
      nextTargetId = _findNextItineraryTarget(updatedVisited, _state.skippedIds);
    }

    final isAudioPlaying = _state.activeAudioViewpointId == viewpointId &&
        _state.navigationStatus == TourNavigationStatus.viewpointAudioPlaying;

    final isTourComplete = nextTargetId == null;

    _state = _state.copyWith(
      visitedIds: updatedVisited,
      previousTargetId: () => prevTargetId,
      navigationTargetId: () => nextTargetId,
      // Auto-arm next target so user walking to it automatically triggers
      armedAutoPlayViewpointId: () => nextTargetId,
      isExplicitlyClosed: false,
      pausedByUser: false,
      navigationStatus: isAudioPlaying
          ? TourNavigationStatus.viewpointAudioPlaying
          : (isTourComplete
              ? TourNavigationStatus.itineraryComplete
              : TourNavigationStatus.navigating),
    );

    _notifyState();

    // Speak immediate next navigation direction
    if (_state.isVoiceGuidanceEnabled && !isAudioPlaying) {
      if (nextTargetId == null) {
        final isColosseum = _state.landmarkName.toLowerCase() == 'colosseum';
        if (isColosseum) {
          _speakThrottled(
              'You have completed the {place} tour.'.tourTextWith({'place': _localizedFloorName}));
        } else {
          final floorLabel = _state.floorName ?? _state.activeFloorId;
          _speakThrottled(
              'You have completed the {place} tour.'.tourTextWith({'place': '${_state.landmarkName}: $floorLabel'}));
        }
      } else if (nextTargetId == 'EXIT') {
        _speakThrottled('Proceed toward the Exit portal.'.tourText);
      } else {
        final nextVp = _viewpoints
            .where((vp) => vp.id == nextTargetId)
            .firstOrNull;
        if (nextVp != null) {
          _speakThrottled('Next, proceed toward Viewpoint {number}.'.tourTextWith({'number': nextVp.order}));
        }
      }
    }
  }

  /// Explicit user action: Unmarks a viewpoint as visited.
  void unmarkVisited(String viewpointId) {
    _announcedApproachViewpointIds.remove(viewpointId);
    final updatedVisited = Set<String>.from(_state.visitedIds)..remove(viewpointId);

    // Update local viewpoint copy
    final index = _viewpoints.indexWhere((vp) => vp.id == viewpointId);
    if (index != -1) {
      _viewpoints[index] = _viewpoints[index].copyWith(isVisited: false);
    }

    // Recompute next itinerary target from unvisited and unskipped stops
    final nextTargetId = _findNextItineraryTarget(updatedVisited, _state.skippedIds);

    _state = _state.copyWith(
      visitedIds: updatedVisited,
      navigationTargetId: () => nextTargetId,
      armedAutoPlayViewpointId: () => nextTargetId,
      navigationStatus: TourNavigationStatus.navigating,
    );

    _notifyState();
  }

  /// Explicit user action: Skips a viewpoint.
  void skipViewpoint(String viewpointId) {
    _announcedApproachViewpointIds.add(viewpointId);
    final updatedSkipped = Set<String>.from(_state.skippedIds)..add(viewpointId);

    String? nextTargetId = _state.navigationTargetId;
    String? prevTargetId = _state.previousTargetId;

    if (_state.navigationTargetId == viewpointId) {
      prevTargetId = viewpointId;
      nextTargetId = _findNextItineraryTarget(_state.visitedIds, updatedSkipped);
    }

    _state = _state.copyWith(
      skippedIds: updatedSkipped,
      previousTargetId: () => prevTargetId,
      navigationTargetId: () => nextTargetId,
      armedAutoPlayViewpointId: () => nextTargetId,
      isExplicitlyClosed: false,
      pausedByUser: false,
      navigationStatus: nextTargetId == null
          ? TourNavigationStatus.itineraryComplete
          : TourNavigationStatus.navigating,
    );

    _notifyState();
  }

  String? _findNextItineraryTarget(
    Set<String> visited,
    Set<String> skipped,
  ) {
    for (final vp in _viewpoints) {
      if (!visited.contains(vp.id) && !skipped.contains(vp.id)) {
        return vp.id;
      }
    }
    return _hasExit ? 'EXIT' : null;
  }

  /// Sets or navigates directly to a target viewpoint (used for developer simulation / snap stop).
  void setNavigationTarget(String viewpointId) {
    final updatedAutoPlayed = Set<String>.from(_state.autoPlayedViewpointIds)
      ..remove(viewpointId);
    final updatedSkipped = Set<String>.from(_state.skippedIds)
      ..remove(viewpointId);

    _state = _state.copyWith(
      navigationTargetId: () => viewpointId,
      armedAutoPlayViewpointId: () => viewpointId,
      reachedViewpointId: () => null,
      activeAudioViewpointId: () => null,
      autoPlayedViewpointIds: updatedAutoPlayed,
      skippedIds: updatedSkipped,
      navigationStatus: TourNavigationStatus.navigating,
      isExplicitlyClosed: false,
      pausedByUser: false,
    );
    _notifyState();
  }

  /// User taps a viewpoint marker to open its card (decoupled from navigation target).
  void selectViewpoint(String viewpointId) {
    _state = _state.copyWith(
      selectedViewpointId: () => viewpointId,
    );
    _notifyState();
  }

  /// User closes the viewpoint card.
  void deselectViewpoint() {
    _state = _state.copyWith(
      selectedViewpointId: () => null,
    );
    _notifyState();
  }

  /// User explicitly pauses audio playback.
  void onUserPauseAudio() {
    _state = _state.copyWith(
      pausedByUser: true,
      pausedBySystem: false,
    );
    _notifyState();
  }

  /// User explicitly resumes audio playback.
  void onUserResumeAudio() {
    _state = _state.copyWith(
      pausedByUser: false,
      pausedBySystem: false,
      navigationStatus: TourNavigationStatus.viewpointAudioPlaying,
    );
    _notifyState();
  }

  /// User explicitly closes the audio mini-player or card.
  void onUserStopOrCloseAudio() {
    _state = _state.copyWith(
      isExplicitlyClosed: true,
      activeAudioViewpointId: () => null,
      navigationStatus: _state.visitedIds.contains(_state.reachedViewpointId)
          ? TourNavigationStatus.waitingForDeparture
          : TourNavigationStatus.waitingAtViewpoint,
    );
    _notifyState();
  }

  /// System audio focus lost (e.g. phone call).
  void onSystemAudioInterrupted() {
    _state = _state.copyWith(
      pausedBySystem: true,
    );
    _notifyState();
  }

  /// System audio focus restored.
  void onSystemAudioRestored() {
    if (_state.pausedBySystem && !_state.pausedByUser) {
      _state = _state.copyWith(
        pausedBySystem: false,
        navigationStatus: TourNavigationStatus.viewpointAudioPlaying,
      );
      _notifyState();
    }
  }

  /// Audio narration finishes playing.
  void onAudioCompleted() {
    final reachedId = _state.activeAudioViewpointId ??
        _state.selectedViewpointId ?? _state.reachedViewpointId;
    _state = _state.copyWith(
      activeAudioViewpointId: () => null,
    );

    if (config.autoMarkVisitedOnAudioComplete && reachedId != null) {
      markVisited(reachedId);
    } else {
      final isAlreadyNavigatingNext = _state.navigationTargetId != null &&
          _state.navigationTargetId != reachedId;

      if (isAlreadyNavigatingNext) {
        _state = _state.copyWith(
          navigationStatus: TourNavigationStatus.navigating,
        );
        if (_state.isVoiceGuidanceEnabled) {
          final nextTargetId = _state.navigationTargetId;
          if (nextTargetId == null) {
            final isColosseum =
                _state.landmarkName.toLowerCase() == 'colosseum';
            if (isColosseum) {
              _speakThrottled(
                  'You have completed the {place} tour.'.tourTextWith({'place': _localizedFloorName}));
            } else {
              final floorLabel = _state.floorName ?? _state.activeFloorId;
              _speakThrottled(
                  'You have completed the {place} tour.'.tourTextWith({'place': '${_state.landmarkName}: $floorLabel'}));
            }
          } else if (nextTargetId == 'EXIT') {
            _speakThrottled('Proceed toward the Exit portal.'.tourText);
          } else {
            final nextVp = _viewpoints
                .where((vp) => vp.id == nextTargetId)
                .firstOrNull;
            if (nextVp != null) {
              _speakThrottled('Next, proceed toward Viewpoint {number}.'.tourTextWith({'number': nextVp.order}));
            }
          }
        }
      } else {
        final isVisited = reachedId != null && _state.visitedIds.contains(reachedId);
        _state = _state.copyWith(
          navigationStatus: isVisited
              ? TourNavigationStatus.waitingForDeparture
              : TourNavigationStatus.waitingAtViewpoint,
        );
      }
      _notifyState();
    }
  }

  /// User toggles voice navigation guidance.
  void toggleVoiceGuidance(bool enabled) {
    _state = _state.copyWith(isVoiceGuidanceEnabled: enabled);
    _notifyState();
  }

  /// User toggles auto-play of viewpoint audio.
  void toggleAutoPlay(bool enabled) {
    _state = _state.copyWith(isAutoPlayEnabled: enabled);
    _notifyState();
  }

  /// Resets the full tour to the beginning.
  void resetTour() {
    _announcedApproachViewpointIds.clear();
    for (int i = 0; i < _viewpoints.length; i++) {
      _viewpoints[i] = _viewpoints[i].copyWith(isVisited: false);
    }

    final firstTarget = _viewpoints.isNotEmpty
        ? _viewpoints.first.id
        : (_hasExit ? 'EXIT' : null);

    _state = TourNavigationState(
      itineraryId: _state.itineraryId,
      activeFloorId: _state.activeFloorId,
      navigationTargetId: firstTarget,
      previousTargetId: null,
      armedAutoPlayViewpointId: firstTarget,
      navigationStatus: TourNavigationStatus.navigating,
      isVoiceGuidanceEnabled: _state.isVoiceGuidanceEnabled,
      isAutoPlayEnabled: _state.isAutoPlayEnabled,
      visitedIds: <String>{},
      skippedIds: <String>{},
      autoPlayedViewpointIds: <String>{},
    );

    _notifyState();

    if (_state.isVoiceGuidanceEnabled && _viewpoints.isNotEmpty) {
      final firstVp = _viewpoints.first;
      _speakInitialGreeting(firstVp);
    }
  }

  void _speakThrottled(String text, {VoidCallback? onDone}) {
    if (!_state.isVoiceGuidanceEnabled) {
      onDone?.call();
      return;
    }

    // Suppress routine TTS while viewpoint audio is playing
    if (_state.activeAudioViewpointId != null &&
        _state.navigationStatus == TourNavigationStatus.viewpointAudioPlaying) {
      onDone?.call();
      return;
    }

    final now = DateTime.now();
    if (onDone == null &&
        _state.lastSpokenInstruction == text &&
        _state.lastSpokenTimestamp != null &&
        now.difference(_state.lastSpokenTimestamp!).inSeconds < 15) {
      return;
    }

    _state = _state.copyWith(
      lastSpokenInstruction: () => text,
      lastSpokenTimestamp: () => now,
    );

    onSpeakInstruction?.call(text, onDone: onDone);
  }

  void _notifyState() {
    onStateChanged?.call(_state);
  }
}
