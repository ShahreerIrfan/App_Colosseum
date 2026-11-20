import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/landmark_marker_model.dart';
import 'tts_service.dart';

enum PedestrianManeuverType {
  straight,
  slightRight,
  turnRight,
  sharpRight,
  slightLeft,
  turnLeft,
  sharpLeft,
  uTurn,
  arrived,
}

class PedestrianNavStep {
  final LatLng point;
  final PedestrianManeuverType maneuver;
  final String instruction;
  final double distanceToNextMeters;
  final double bearingDegrees;

  const PedestrianNavStep({
    required this.point,
    required this.maneuver,
    required this.instruction,
    required this.distanceToNextMeters,
    required this.bearingDegrees,
  });
}

class PedestrianNavStatus {
  final PedestrianManeuverType maneuver;
  final String instruction;
  final double distanceToNextTurnMeters;
  final double totalRemainingDistanceMeters;
  final LandmarkMarkerModel? targetLandmark;
  final bool hasArrived;
  final int currentWaypointIndex;

  const PedestrianNavStatus({
    this.maneuver = PedestrianManeuverType.straight,
    this.instruction = '',
    this.distanceToNextTurnMeters = 0.0,
    this.totalRemainingDistanceMeters = 0.0,
    this.targetLandmark,
    this.hasArrived = false,
    this.currentWaypointIndex = 0,
  });
}

/// Turn-by-turn navigation engine for outdoor pedestrian routes.
///
/// Computes bearings, turn maneuvers, remaining distances, and orchestrates
/// collision-free voice guidance across outdoor archaeological paths.
class PedestrianNavigationEngine {
  final TtsService ttsService;

  List<LatLng> _routePoints = [];
  List<PedestrianNavStep> _steps = [];
  LandmarkMarkerModel? _destinationLandmark;
  int _currentStepIndex = 0;
  bool _isNavigating = false;

  int? _lastAdvanceSpokenStepIndex;
  int? _lastImmediateSpokenStepIndex;
  bool _hasAnnouncedArrival = false;

  PedestrianNavStatus _status = const PedestrianNavStatus();
  PedestrianNavStatus get status => _status;

  ValueChanged<PedestrianNavStatus>? onStatusChanged;
  VoidCallback? onArrival;

  PedestrianNavigationEngine({required this.ttsService});

  bool get isNavigating => _isNavigating;
  List<LatLng> get routePoints => _routePoints;

  /// Starts or updates navigation for a given route and destination.
  void startNavigation({
    required List<LatLng> route,
    required LandmarkMarkerModel destination,
  }) {
    _routePoints = List.unmodifiable(route);
    _destinationLandmark = destination;
    _isNavigating = true;
    _currentStepIndex = 0;
    _lastAdvanceSpokenStepIndex = null;
    _lastImmediateSpokenStepIndex = null;
    _hasAnnouncedArrival = false;

    _buildSteps();
    if (_steps.isNotEmpty) {
      final first = _steps.first;
      _status = PedestrianNavStatus(
        maneuver: first.maneuver,
        instruction: first.instruction,
        distanceToNextTurnMeters: first.distanceToNextMeters,
        totalRemainingDistanceMeters: _calculateTotalRemaining(0),
        targetLandmark: destination,
        hasArrived: false,
        currentWaypointIndex: 0,
      );
      onStatusChanged?.call(_status);
    }
  }

  void stopNavigation() {
    _isNavigating = false;
    _routePoints = [];
    _steps = [];
    _destinationLandmark = null;
    _currentStepIndex = 0;
    _status = const PedestrianNavStatus();
    onStatusChanged?.call(_status);
  }

  /// Evaluates user position against the route and triggers voice & visual guidance.
  void updatePosition(LatLng userPos) {
    if (!_isNavigating || _routePoints.isEmpty || _destinationLandmark == null) {
      return;
    }

    // 1. Check distance to final destination
    final distToDest = _distanceMeters(userPos, _destinationLandmark!.coordinates);
    if (distToDest <= 30.0 && !_hasAnnouncedArrival) {
      _hasAnnouncedArrival = true;
      _status = PedestrianNavStatus(
        maneuver: PedestrianManeuverType.arrived,
        instruction: 'Arrived at ${_destinationLandmark!.name}',
        distanceToNextTurnMeters: 0.0,
        totalRemainingDistanceMeters: 0.0,
        targetLandmark: _destinationLandmark,
        hasArrived: true,
        currentWaypointIndex: _routePoints.length - 1,
      );
      onStatusChanged?.call(_status);
      ttsService.speakInstruction(
        'You have arrived at ${_destinationLandmark!.name}',
        onDone: () {
          onArrival?.call();
        },
      );
      return;
    }

    // 2. Find closest waypoint along route
    var nearestIdx = _currentStepIndex;
    var nearestDist = double.infinity;
    for (var i = _currentStepIndex; i < _routePoints.length; i++) {
      final d = _distanceMeters(userPos, _routePoints[i]);
      if (d < nearestDist) {
        nearestDist = d;
        nearestIdx = i;
      }
    }

    final currentStep = _steps[_currentStepIndex];
    final distToNextTurn = _distanceMeters(userPos, currentStep.point);
    final totalRemaining = _calculateTotalRemaining(_currentStepIndex) + distToNextTurn;

    _status = PedestrianNavStatus(
      maneuver: currentStep.maneuver,
      instruction: currentStep.instruction,
      distanceToNextTurnMeters: distToNextTurn,
      totalRemainingDistanceMeters: totalRemaining,
      targetLandmark: _destinationLandmark,
      hasArrived: false,
      currentWaypointIndex: _currentStepIndex,
    );
    onStatusChanged?.call(_status);

    // 3. Audio Guidance Triggers (Throttled & Non-overlapping)
    // Advance warning prompt: 30 - 45 meters before turn
    if (distToNextTurn <= 45.0 && distToNextTurn > 18.0) {
      if (_lastAdvanceSpokenStepIndex != _currentStepIndex) {
        _lastAdvanceSpokenStepIndex = _currentStepIndex;
        final roundedDist = (distToNextTurn / 5).round() * 5;
        final voiceText = 'In $roundedDist meters, ${currentStep.instruction.toLowerCase()}';
        ttsService.speakInstruction(voiceText);
      }
    }
    // Immediate turn prompt: 4 - 18 meters before turn
    else if (distToNextTurn <= 18.0 && distToNextTurn > 3.0) {
      if (_lastImmediateSpokenStepIndex != _currentStepIndex) {
        _lastImmediateSpokenStepIndex = _currentStepIndex;
        ttsService.speakInstruction(currentStep.instruction);
      }
    }

    // Progress step index forward once the turn point is reached/passed (< 6 meters)
    if (nearestIdx > _currentStepIndex && distToNextTurn < 6.0) {
      _currentStepIndex = nearestIdx;
    }
  }

  void _buildSteps() {
    _steps = [];
    if (_routePoints.length < 2) return;

    for (var i = 0; i < _routePoints.length - 1; i++) {
      final p1 = _routePoints[i];
      final p2 = _routePoints[i + 1];
      final dist = _distanceMeters(p1, p2);
      final bearing1 = _calculateBearing(p1, p2);

      if (i == _routePoints.length - 2) {
        // Final leg approaching destination
        _steps.add(PedestrianNavStep(
          point: p2,
          maneuver: PedestrianManeuverType.straight,
          instruction: 'Proceed straight toward ${_destinationLandmark?.name ?? 'destination'}',
          distanceToNextMeters: dist,
          bearingDegrees: bearing1,
        ));
      } else {
        final p3 = _routePoints[i + 2];
        final bearing2 = _calculateBearing(p2, p3);
        final delta = _calculateTurnDelta(bearing1, bearing2);
        final maneuver = _classifyTurn(delta);
        final instruction = _maneuverText(maneuver);

        _steps.add(PedestrianNavStep(
          point: p2,
          maneuver: maneuver,
          instruction: instruction,
          distanceToNextMeters: dist,
          bearingDegrees: bearing1,
        ));
      }
    }
  }

  double _calculateTotalRemaining(int fromIndex) {
    var total = 0.0;
    for (var i = fromIndex; i < _steps.length; i++) {
      total += _steps[i].distanceToNextMeters;
    }
    return total;
  }

  static double _calculateBearing(LatLng start, LatLng end) {
    final startLat = start.latitudeInRad;
    final startLng = start.longitudeInRad;
    final endLat = end.latitudeInRad;
    final endLng = end.longitudeInRad;
    final dLng = endLng - startLng;

    final y = math.sin(dLng) * math.cos(endLat);
    final x = math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(dLng);
    final bearing = math.atan2(y, x);
    return (bearing * 180 / math.pi + 360) % 360;
  }

  static double _calculateTurnDelta(double incomingBearing, double outgoingBearing) {
    return ((outgoingBearing - incomingBearing + 540) % 360) - 180;
  }

  static PedestrianManeuverType _classifyTurn(double delta) {
    if (delta.abs() < 22.0) {
      return PedestrianManeuverType.straight;
    } else if (delta >= 22.0 && delta < 50.0) {
      return PedestrianManeuverType.slightRight;
    } else if (delta >= 50.0 && delta <= 125.0) {
      return PedestrianManeuverType.turnRight;
    } else if (delta > 125.0) {
      return PedestrianManeuverType.sharpRight;
    } else if (delta <= -22.0 && delta > -50.0) {
      return PedestrianManeuverType.slightLeft;
    } else if (delta <= -50.0 && delta >= -125.0) {
      return PedestrianManeuverType.turnLeft;
    } else {
      return PedestrianManeuverType.sharpLeft;
    }
  }

  static String _maneuverText(PedestrianManeuverType maneuver) {
    switch (maneuver) {
      case PedestrianManeuverType.slightRight:
        return 'Turn slightly right';
      case PedestrianManeuverType.turnRight:
        return 'Turn right';
      case PedestrianManeuverType.sharpRight:
        return 'Take a sharp right';
      case PedestrianManeuverType.slightLeft:
        return 'Turn slightly left';
      case PedestrianManeuverType.turnLeft:
        return 'Turn left';
      case PedestrianManeuverType.sharpLeft:
        return 'Take a sharp left';
      case PedestrianManeuverType.uTurn:
        return 'Make a U-turn';
      case PedestrianManeuverType.arrived:
        return 'You have arrived';
      case PedestrianManeuverType.straight:
        return 'Continue straight';
    }
  }

  static double _distanceMeters(LatLng a, LatLng b) {
    const distance = Distance(roundResult: false);
    return distance.as(LengthUnit.Meter, a, b);
  }
}
