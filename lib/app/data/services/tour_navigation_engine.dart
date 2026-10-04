import 'dart:math' as math;
import 'dart:ui' show Offset;
import 'package:flutter/foundation.dart';
import '../models/tour_navigation_state.dart';
import '../models/user_location_model.dart';
import '../models/viewpoint_model.dart';

/// Centralized state machine engine managing location-aware indoor tour guidance,
/// proximity detection, arrival dwell, departure hysteresis, audio auto-play, and user overrides.
class TourNavigationEngine {
  final TourConfig config;

  TourNavigationState _state = const TourNavigationState();
  TourNavigationState get state => _state;

  List<ViewpointModel> _viewpoints = [];
  List<ViewpointModel> get viewpoints => List.unmodifiable(_viewpoints);

  Offset? _entryLocation;
  Offset? _exitLocation;
  final Set<String> _announcedApproachViewpointIds = <String>{};

  /// Callbacks for engine events
  void Function(String text, {VoidCallback? onDone})? onSpeakInstruction;
  void Function(ViewpointModel viewpoint)? onAutoPlayViewpoint;
  void Function(TourNavigationState state)? onStateChanged;

  TourNavigationEngine({
    TourConfig? config,
    this.onSpeakInstruction,
    this.onAutoPlayViewpoint,
    this.onStateChanged,
  }) : config = config ?? const TourConfig();

  /// Initializes or starts the guided tour on a specific floor.
  void startTour({
    required String floorId,
    required List<ViewpointModel> viewpoints,
    Offset? entryLocation,
    Offset? exitLocation,
    bool isVoiceGuidanceEnabled = true,
    bool isAutoPlayEnabled = true,
  }) {
    _viewpoints = List.from(viewpoints);
    _entryLocation = entryLocation;
    _exitLocation = exitLocation;
    _announcedApproachViewpointIds.clear();

    // Sort viewpoints by order if present
    _viewpoints.sort((a, b) => a.order.compareTo(b.order));

    final firstTarget = _viewpoints.isNotEmpty
        ? _viewpoints.first.id
        : (_exitLocation != null ? 'EXIT' : null);

    _state = TourNavigationState(
      itineraryId: '${floorId}_tour',
      activeFloorId: floorId,
      navigationTargetId: firstTarget,
      previousTargetId: null,
      armedAutoPlayViewpointId: firstTarget,
      navigationStatus: TourNavigationStatus.navigating,
      isVoiceGuidanceEnabled: isVoiceGuidanceEnabled,
      isAutoPlayEnabled: isAutoPlayEnabled,
      visitedIds: <String>{},
      skippedIds: <String>{},
      autoPlayedViewpointIds: <String>{},
    );

    _notifyState();

    if (isVoiceGuidanceEnabled && _viewpoints.isNotEmpty) {
      final firstVp = _viewpoints.first;
      _speakThrottled(
        'Begin the Underground tour. Proceed toward Viewpoint ${firstVp.order}.',
      );
    }
  }

  /// Calculates real-world metric physical distance between two normalized floor offsets.
  double calculateMetricDistance(Offset p1, Offset p2) {
    final dx = (p2.dx - p1.dx) * config.arenaWidthMeters;
    final dy = (p2.dy - p1.dy) * config.arenaHeightMeters;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Evaluates an incoming indoor location beacon and advances navigation state.
  void updateLocation(UserLocationModel location, {DateTime? now}) {
    final currentTime = now ?? location.timestamp ?? DateTime.now();

    // 1. Floor Validation Check
    if (location.floorId != _state.activeFloorId) {
      // Location update belongs to another floor, ignore proximity
      return;
    }

    // 2. Location Staleness Check
    if (location.timestamp != null) {
      final age = currentTime.difference(location.timestamp!);
      if (age > config.maxLocationAge) {
        // Discard stale location
        return;
      }
    }

    // 3. Accuracy / Quality Check
    if (location.accuracyMeters > config.maxAcceptableAccuracyMeters) {
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

    // 4. Sudden Impossible Jump Detection
    if (_state.userLocation != null) {
      final prevOffset = Offset(
        _state.userLocation!.normalizedX,
        _state.userLocation!.normalizedY,
      );
      final newOffset = Offset(location.normalizedX, location.normalizedY);
      final jumpDist = calculateMetricDistance(prevOffset, newOffset);

      if (jumpDist > config.maxJumpDistanceMeters) {
        // Mark jump suspicious; invalidate pending arrival dwell
        _state = _state.copyWith(
          userLocation: () => location,
          arrivalDwellStartedAt: () => null,
        );
        _notifyState();
        return;
      }
    }

    // Record user location
    _state = _state.copyWith(userLocation: () => location);

    final userOffset = Offset(location.normalizedX, location.normalizedY);

    // 5. Evaluate Departure from Previous Stop (Hysteresis)
    _evaluateDeparture(userOffset, currentTime);

    // 6. Evaluate Target Proximity & Arrival
    _evaluateTargetProximity(userOffset, currentTime);
  }

  void _evaluateDeparture(Offset userOffset, DateTime currentTime) {
    if (_state.previousTargetId == null) return;

    Offset? prevOffset;
    if (_state.previousTargetId == 'ENTRY') {
      prevOffset = _entryLocation;
    } else {
      final prevVp = _viewpoints
          .where((vp) => vp.id == _state.previousTargetId)
          .firstOrNull;
      if (prevVp != null) {
        prevOffset = Offset(prevVp.normalizedX, prevVp.normalizedY);
      }
    }

    if (prevOffset != null) {
      final distFromPrev = calculateMetricDistance(userOffset, prevOffset);
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
        if (distFromPrev >= config.departureRadiusMeters) {
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
                'Next, proceed toward Viewpoint ${nextVp.order}.',
              );
            } else if (nextTargetId == 'EXIT') {
              _speakThrottled('Proceed toward the Exit portal.');
            }
          }
        }
      }
    }
  }

  void _evaluateTargetProximity(Offset userOffset, DateTime currentTime) {
    if (_state.navigationTargetId == null) return;

    // Handle EXIT Portal Target
    if (_state.navigationTargetId == 'EXIT') {
      if (_exitLocation != null) {
        final distToExit = calculateMetricDistance(userOffset, _exitLocation!);
        _state = _state.copyWith(distanceToTarget: () => distToExit);

        if (distToExit <= config.arrivalRadiusMeters) {
          if (_state.arrivalDwellStartedAt == null) {
            _state = _state.copyWith(
              arrivalDwellStartedAt: () => currentTime,
              navigationStatus: TourNavigationStatus.arrivalPending,
            );
          } else if (currentTime.difference(_state.arrivalDwellStartedAt!) >=
              config.arrivalDwellDuration) {
            if (_state.navigationStatus != TourNavigationStatus.itineraryComplete) {
              _state = _state.copyWith(
                navigationStatus: TourNavigationStatus.itineraryComplete,
                reachedViewpointId: () => 'EXIT',
                arrivalDwellStartedAt: () => null,
              );
              if (_state.isVoiceGuidanceEnabled) {
                _speakThrottled(
                  'You have completed the Underground itinerary. The exit is here.',
                );
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

    final targetOffset = Offset(targetVp.normalizedX, targetVp.normalizedY);
    final distToTarget = calculateMetricDistance(userOffset, targetOffset);

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
    if (distToTarget > config.approachRadiusMeters + 2.0) {
      if (_state.navigationStatus == TourNavigationStatus.approaching ||
          _state.navigationStatus == TourNavigationStatus.arrivalPending) {
        _state = _state.copyWith(
          arrivalDwellStartedAt: () => null,
          navigationStatus: TourNavigationStatus.navigating,
        );
      }
    }
    // 2. Inside Approach Radius (arrivalRadius < dist <= approachRadius)
    else if (distToTarget > config.arrivalRadiusMeters && distToTarget <= config.approachRadiusMeters) {
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
          _speakThrottled('Viewpoint ${targetVp.order} is ahead.');
        }
      }
    }
    // 3. Inside Arrival Radius (<= arrivalRadius) -> Dwell Verification
    else if (distToTarget <= config.arrivalRadiusMeters) {
      if (_state.arrivalDwellStartedAt == null) {
        _state = _state.copyWith(
          arrivalDwellStartedAt: () => currentTime,
          navigationStatus: TourNavigationStatus.arrivalPending,
        );
      } else if (currentTime.difference(_state.arrivalDwellStartedAt!) >=
          config.arrivalDwellDuration) {
        // ARRIVAL CONFIRMED!
        _announcedApproachViewpointIds.add(targetVp.id);
        _state = _state.copyWith(
          navigationStatus: TourNavigationStatus.arrived,
          reachedViewpointId: () => targetVp.id,
          arrivalDwellStartedAt: () => null,
        );

        final isEligibleForAutoPlay = _state.isAutoPlayEnabled &&
            !_state.autoPlayedViewpointIds.contains(targetVp.id) &&
            !_state.visitedIds.contains(targetVp.id) &&
            !_state.skippedIds.contains(targetVp.id) &&
            !_state.pausedByUser &&
            !_state.isExplicitlyClosed;

        if (_state.isVoiceGuidanceEnabled) {
          _speakThrottled(
            'You have arrived at Viewpoint ${targetVp.order}.',
            onDone: () {
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
        _speakThrottled('You have completed the Underground tour.');
      } else if (nextTargetId == 'EXIT') {
        _speakThrottled('Proceed toward the Exit portal.');
      } else {
        final nextVp = _viewpoints
            .where((vp) => vp.id == nextTargetId)
            .firstOrNull;
        if (nextVp != null) {
          _speakThrottled('Next, proceed toward Viewpoint ${nextVp.order}.');
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
      armedAutoPlayViewpointId: () => null,
      navigationStatus: TourNavigationStatus.navigating,
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
    return _exitLocation != null ? 'EXIT' : null;
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
    final reachedId = _state.reachedViewpointId ?? _state.selectedViewpointId;
    _state = _state.copyWith(
      activeAudioViewpointId: () => null,
    );

    if (config.autoMarkVisitedOnAudioComplete && reachedId != null) {
      markVisited(reachedId);
    } else {
      final isVisited = reachedId != null && _state.visitedIds.contains(reachedId);
      _state = _state.copyWith(
        navigationStatus: isVisited
            ? TourNavigationStatus.waitingForDeparture
            : TourNavigationStatus.waitingForVisited,
      );
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
        : (_exitLocation != null ? 'EXIT' : null);

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
      _speakThrottled(
        'Begin the Underground tour. Proceed toward Viewpoint ${firstVp.order}.',
      );
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
