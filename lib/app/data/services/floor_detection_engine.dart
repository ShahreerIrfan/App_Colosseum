import 'dart:math' as math;
import 'dart:ui' show Offset;
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/floor_definition.dart';
import '../models/floor_transition_portal.dart';

class FloorTransitionCandidate {
  final FloorDefinition targetFloor;
  final FloorTransitionPortal portal;
  final double confidenceScore;
  final String reason;
  final DateTime detectedAt;

  const FloorTransitionCandidate({
    required this.targetFloor,
    required this.portal,
    required this.confidenceScore,
    required this.reason,
    required this.detectedAt,
  });
}

/// Hybrid multi-sensor floor detection engine.
///
/// Combines topological staircase portal geofencing, IMU vertical movement
/// analysis, and barometric altimetry (when hardware exists) with anti-bounce
/// hysteresis and undo protections.
class FloorDetectionEngine {
  List<FloorDefinition> _availableFloors = [];
  String _currentFloorId = '';
  bool isEnabled;

  double? _baselineBarometricPressureHpa;
  double? _lastBarometricPressureHpa;

  bool _isVerticalStairMotionActive = false;
  DateTime? _lastStairMotionTime;

  String? _cooldownPairKey;
  DateTime? _cooldownExpiresAt;

  final Map<String, double> _portalDwellScores = {};

  ValueChanged<FloorTransitionCandidate>? onFloorTransitionDetected;

  FloorDetectionEngine({
    List<FloorDefinition>? availableFloors,
    String? currentFloorId,
    this.isEnabled = true,
  })  : _availableFloors = availableFloors ?? [],
        _currentFloorId = currentFloorId ?? '';

  String get currentFloorId => _currentFloorId;

  /// Updates active floor context and resets portal dwell trackers.
  void setFloorContext({
    required String currentFloorId,
    required List<FloorDefinition> availableFloors,
  }) {
    _currentFloorId = currentFloorId;
    _availableFloors = availableFloors;
    _portalDwellScores.clear();
  }

  /// Sets cooldown between two floors to prevent rapid bouncing (e.g., after switch or undo).
  void armCooldown(String floorA, String floorB, {Duration duration = const Duration(seconds: 60)}) {
    _cooldownPairKey = _makePairKey(floorA, floorB);
    _cooldownExpiresAt = DateTime.now().add(duration);
    _portalDwellScores.clear();
  }

  bool _isPairInCooldown(String floorA, String floorB) {
    if (_cooldownExpiresAt == null || _cooldownPairKey == null) return false;
    if (DateTime.now().isAfter(_cooldownExpiresAt!)) {
      _cooldownPairKey = null;
      _cooldownExpiresAt = null;
      return false;
    }
    return _cooldownPairKey == _makePairKey(floorA, floorB);
  }

  static String _makePairKey(String a, String b) {
    final list = [a, b]..sort();
    return list.join('<->');
  }

  /// Called on user location updates inside the floor map.
  void updateLocation({
    required Offset canvasOffset,
    LatLng? latLng,
    double accuracyMeters = 5.0,
  }) {
    if (!isEnabled || _availableFloors.isEmpty || _currentFloorId.isEmpty) {
      return;
    }

    final currentFloor = _availableFloors.where((f) => f.id == _currentFloorId).firstOrNull;
    if (currentFloor == null || currentFloor.portals.isEmpty) {
      return;
    }

    for (final portal in currentFloor.portals) {
      if (_isPairInCooldown(portal.fromFloorId, portal.toFloorId)) {
        continue;
      }

      final distMeters = _calculateCanvasMetricDistance(canvasOffset, portal.canvasOffset);
      if (distMeters <= portal.triggerRadiusMeters) {
        // Increment dwell confidence in portal zone
        final currentScore = _portalDwellScores[portal.id] ?? 0.0;
        final newScore = (currentScore + 0.35).clamp(0.0, 1.0);
        _portalDwellScores[portal.id] = newScore;

        _evaluateCandidate(portal, newScore);
      } else {
        // Decay dwell score outside trigger radius
        if (_portalDwellScores.containsKey(portal.id)) {
          final decayed = (_portalDwellScores[portal.id]! - 0.20).clamp(0.0, 1.0);
          if (decayed <= 0.0) {
            _portalDwellScores.remove(portal.id);
          } else {
            _portalDwellScores[portal.id] = decayed;
          }
        }
      }
    }
  }

  /// Records periodic vertical acceleration / stair movement pattern from IMU accelerometer.
  void recordStairMotion({required bool isClimbingUp, required bool isClimbingDown}) {
    _isVerticalStairMotionActive = isClimbingUp || isClimbingDown;
    _lastStairMotionTime = DateTime.now();
  }

  /// Records ambient barometric pressure in hectopascals (hPa) if hardware is available.
  void recordBarometricPressure(double pressureHpa) {
    _baselineBarometricPressureHpa ??= pressureHpa;
    _lastBarometricPressureHpa = pressureHpa;
  }

  void _evaluateCandidate(FloorTransitionPortal portal, double portalDwellScore) {
    var totalConfidence = 0.0;

    // 1. Topological Portal Proximity & Dwell (Weight: 60%)
    totalConfidence += portalDwellScore * 0.60;

    // 2. IMU Vertical Stair Movement (Weight: 25%)
    final now = DateTime.now();
    final hasRecentMotion = _lastStairMotionTime != null &&
        now.difference(_lastStairMotionTime!).inSeconds < 8;
    if (hasRecentMotion && _isVerticalStairMotionActive) {
      totalConfidence += 0.25;
    } else {
      // Default baseline motion assumption if user dwells right in the stairwell
      if (portalDwellScore >= 0.70) {
        totalConfidence += 0.15;
      }
    }

    // 3. Barometric Pressure Delta (Weight: 15% when hardware exists)
    if (_baselineBarometricPressureHpa != null && _lastBarometricPressureHpa != null) {
      final deltaPressure = _baselineBarometricPressureHpa! - _lastBarometricPressureHpa!;
      // ~0.12 hPa per meter of elevation gain
      final estimatedElevationDelta = deltaPressure / 0.12;
      final expectedDelta = portal.elevationDeltaMeters;

      if ((estimatedElevationDelta > 0 && expectedDelta > 0) ||
          (estimatedElevationDelta < 0 && expectedDelta < 0)) {
        totalConfidence += 0.15;
      }
    } else {
      // On devices without barometer (e.g. Galaxy M35), distribute weight to portal dwell
      if (portalDwellScore >= 0.80) {
        totalConfidence += 0.15;
      }
    }

    // Trigger threshold: 85% confidence
    if (totalConfidence >= 0.85) {
      final targetFloor = _availableFloors.where((f) => f.id == portal.toFloorId).firstOrNull;
      if (targetFloor != null) {
        _portalDwellScores.remove(portal.id);
        armCooldown(portal.fromFloorId, portal.toFloorId, duration: const Duration(seconds: 45));

        final candidate = FloorTransitionCandidate(
          targetFloor: targetFloor,
          portal: portal,
          confidenceScore: totalConfidence,
          reason: 'Traversed ${portal.name}',
          detectedAt: now,
        );
        onFloorTransitionDetected?.call(candidate);
      }
    }
  }

  static double _calculateCanvasMetricDistance(Offset a, Offset b) {
    // Normalization to approx 86m x 54m arena metric bounds
    final dx = (a.dx - b.dx) * 86.0;
    final dy = (a.dy - b.dy) * 54.0;
    return math.sqrt(dx * dx + dy * dy);
  }
}
