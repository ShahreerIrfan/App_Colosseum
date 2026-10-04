import 'package:flutter/foundation.dart';
import 'user_location_model.dart';

/// Distinct navigation & tour progression statuses within the indoor guided experience.
enum TourNavigationStatus {
  /// No active tour running.
  idle,

  /// Actively guiding the visitor toward the current target.
  navigating,

  /// Visitor is within the approach zone (<= 8m) of the target stop.
  approaching,

  /// Visitor has entered the arrival zone (<= 4m) and dwell verification is in progress.
  arrivalPending,

  /// Arrival has been confidently confirmed after sustained dwell time.
  arrived,

  /// Viewpoint audio narration is actively playing.
  viewpointAudioPlaying,

  /// Visitor is actively exploring the viewpoint location.
  waitingAtViewpoint,

  /// Stop reached or audio completed, waiting for visitor to mark it as visited.
  waitingForVisited,

  /// Stop is marked visited, but visitor is still inside the departure zone (< 7m).
  waitingForDeparture,

  /// Visitor has physically departed from the previous stop; guidance to next is active.
  navigatingToNext,

  /// Indoor positioning accuracy is too poor or stale to make confident proximity decisions.
  locationUncertain,

  /// All itinerary stops are visited and the visitor has arrived at the Exit portal.
  itineraryComplete,
}

/// Lifecycle state for an individual viewpoint during an active tour.
enum ViewpointTourState {
  unvisited,
  approaching,
  reached,
  visited,
  skipped,
}

/// Centralized configuration parameters for indoor proximity, dwell, and hysteresis.
class TourConfig {
  /// Distance threshold to announce approach (default 8.0 meters).
  final double approachRadiusMeters;

  /// Distance threshold to initiate arrival dwell (default 4.0 meters).
  final double arrivalRadiusMeters;

  /// Distance threshold required to confirm physical departure from a visited stop (default 7.0 meters).
  final double departureRadiusMeters;

  /// Minimum sustained dwell duration required inside arrival radius before confirming arrival.
  final Duration arrivalDwellDuration;

  /// Maximum realistic position jump between consecutive updates before flagging as suspicious.
  final double maxJumpDistanceMeters;

  /// Maximum age of location update before treating as stale.
  final Duration maxLocationAge;

  /// Maximum allowable positioning error before marking location uncertain.
  final double maxAcceptableAccuracyMeters;

  /// Physical dimensions of Colosseum Hypogeum in meters (East-West x North-South).
  final double arenaWidthMeters;
  final double arenaHeightMeters;

  /// Whether completing audio narration automatically marks the viewpoint visited.
  final bool autoMarkVisitedOnAudioComplete;

  const TourConfig({
    this.approachRadiusMeters = 10.0,
    this.arrivalRadiusMeters = 6.0,
    this.departureRadiusMeters = 6.0,
    this.arrivalDwellDuration = const Duration(milliseconds: 1200),
    this.maxJumpDistanceMeters = 15.0,
    this.maxLocationAge = const Duration(seconds: 5),
    this.maxAcceptableAccuracyMeters = 25.0,
    this.arenaWidthMeters = 86.0,
    this.arenaHeightMeters = 54.0,
    this.autoMarkVisitedOnAudioComplete = false,
  });
}

/// Immutable state model capturing the full indoor guided-tour state.
@immutable
class TourNavigationState {
  final String itineraryId;
  final String activeFloorId;

  /// The viewpoint/portal currently being guided toward (e.g., 'vp_100', 'vp_101', ..., 'EXIT').
  final String? navigationTargetId;

  /// The previous stop/portal completed or departed from.
  final String? previousTargetId;

  /// The specific stop armed for proximity auto-play. Disarmed once triggered.
  final String? armedAutoPlayViewpointId;

  /// The viewpoint currently selected by the user for manual card inspection (decoupled from tour).
  final String? selectedViewpointId;

  /// The viewpoint whose arrival zone has been verified.
  final String? reachedViewpointId;

  /// The viewpoint whose narration is currently active.
  final String? activeAudioViewpointId;

  /// Set of completed stop IDs.
  final Set<String> visitedIds;

  /// Set of explicitly skipped stop IDs.
  final Set<String> skippedIds;

  /// Set of stop IDs whose narration has auto-played in the current tour session.
  final Set<String> autoPlayedViewpointIds;

  /// Overall navigation state machine status.
  final TourNavigationStatus navigationStatus;

  /// Distance in meters to current navigation target.
  final double? distanceToTarget;

  /// Distance in meters from previous stop/portal.
  final double? distanceFromPrevious;

  /// Timestamp when visitor first crossed into arrival radius of current target.
  final DateTime? arrivalDwellStartedAt;

  /// User setting toggles.
  final bool isVoiceGuidanceEnabled;
  final bool isAutoPlayEnabled;

  /// Throttled speech tracking.
  final String? lastSpokenInstruction;
  final DateTime? lastSpokenTimestamp;

  /// Quality & uncertainty flags.
  final bool isOffRoute;
  final bool isLocationUncertain;

  /// User override & system interruption flags.
  final bool pausedByUser;
  final bool pausedBySystem;
  final bool isExplicitlyClosed;

  /// Latest raw user location.
  final UserLocationModel? userLocation;

  const TourNavigationState({
    this.itineraryId = 'underground_itinerary',
    this.activeFloorId = 'floor_underground',
    this.navigationTargetId,
    this.previousTargetId,
    this.armedAutoPlayViewpointId,
    this.selectedViewpointId,
    this.reachedViewpointId,
    this.activeAudioViewpointId,
    this.visitedIds = const <String>{},
    this.skippedIds = const <String>{},
    this.autoPlayedViewpointIds = const <String>{},
    this.navigationStatus = TourNavigationStatus.idle,
    this.distanceToTarget,
    this.distanceFromPrevious,
    this.arrivalDwellStartedAt,
    this.isVoiceGuidanceEnabled = true,
    this.isAutoPlayEnabled = true,
    this.lastSpokenInstruction,
    this.lastSpokenTimestamp,
    this.isOffRoute = false,
    this.isLocationUncertain = false,
    this.pausedByUser = false,
    this.pausedBySystem = false,
    this.isExplicitlyClosed = false,
    this.userLocation,
  });

  TourNavigationState copyWith({
    String? itineraryId,
    String? activeFloorId,
    String? Function()? navigationTargetId,
    String? Function()? previousTargetId,
    String? Function()? armedAutoPlayViewpointId,
    String? Function()? selectedViewpointId,
    String? Function()? reachedViewpointId,
    String? Function()? activeAudioViewpointId,
    Set<String>? visitedIds,
    Set<String>? skippedIds,
    Set<String>? autoPlayedViewpointIds,
    TourNavigationStatus? navigationStatus,
    double? Function()? distanceToTarget,
    double? Function()? distanceFromPrevious,
    DateTime? Function()? arrivalDwellStartedAt,
    bool? isVoiceGuidanceEnabled,
    bool? isAutoPlayEnabled,
    String? Function()? lastSpokenInstruction,
    DateTime? Function()? lastSpokenTimestamp,
    bool? isOffRoute,
    bool? isLocationUncertain,
    bool? pausedByUser,
    bool? pausedBySystem,
    bool? isExplicitlyClosed,
    UserLocationModel? Function()? userLocation,
  }) {
    return TourNavigationState(
      itineraryId: itineraryId ?? this.itineraryId,
      activeFloorId: activeFloorId ?? this.activeFloorId,
      navigationTargetId: navigationTargetId != null
          ? navigationTargetId()
          : this.navigationTargetId,
      previousTargetId: previousTargetId != null
          ? previousTargetId()
          : this.previousTargetId,
      armedAutoPlayViewpointId: armedAutoPlayViewpointId != null
          ? armedAutoPlayViewpointId()
          : this.armedAutoPlayViewpointId,
      selectedViewpointId: selectedViewpointId != null
          ? selectedViewpointId()
          : this.selectedViewpointId,
      reachedViewpointId: reachedViewpointId != null
          ? reachedViewpointId()
          : this.reachedViewpointId,
      activeAudioViewpointId: activeAudioViewpointId != null
          ? activeAudioViewpointId()
          : this.activeAudioViewpointId,
      visitedIds: visitedIds ?? this.visitedIds,
      skippedIds: skippedIds ?? this.skippedIds,
      autoPlayedViewpointIds: autoPlayedViewpointIds ?? this.autoPlayedViewpointIds,
      navigationStatus: navigationStatus ?? this.navigationStatus,
      distanceToTarget: distanceToTarget != null
          ? distanceToTarget()
          : this.distanceToTarget,
      distanceFromPrevious: distanceFromPrevious != null
          ? distanceFromPrevious()
          : this.distanceFromPrevious,
      arrivalDwellStartedAt: arrivalDwellStartedAt != null
          ? arrivalDwellStartedAt()
          : this.arrivalDwellStartedAt,
      isVoiceGuidanceEnabled:
          isVoiceGuidanceEnabled ?? this.isVoiceGuidanceEnabled,
      isAutoPlayEnabled: isAutoPlayEnabled ?? this.isAutoPlayEnabled,
      lastSpokenInstruction: lastSpokenInstruction != null
          ? lastSpokenInstruction()
          : this.lastSpokenInstruction,
      lastSpokenTimestamp: lastSpokenTimestamp != null
          ? lastSpokenTimestamp()
          : this.lastSpokenTimestamp,
      isOffRoute: isOffRoute ?? this.isOffRoute,
      isLocationUncertain: isLocationUncertain ?? this.isLocationUncertain,
      pausedByUser: pausedByUser ?? this.pausedByUser,
      pausedBySystem: pausedBySystem ?? this.pausedBySystem,
      isExplicitlyClosed: isExplicitlyClosed ?? this.isExplicitlyClosed,
      userLocation:
          userLocation != null ? userLocation() : this.userLocation,
    );
  }
}
