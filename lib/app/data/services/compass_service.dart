import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_compass/flutter_compass.dart';
import '../models/user_orientation_state.dart';

/// High-precision orientation and compass tracking service.
///
/// Implements:
/// 1. Dead-band noise gating to eliminate stationary jitter.
/// 2. Adaptive circular low-pass filtering (Kalman-style dynamic alpha).
/// 3. Outlier / electromagnetic spike rejection via angular slew-rate clamping.
/// 4. Boundary-safe shortest angular path interpolation (359° <-> 0°).
/// 5. Map-North coordinate space transformation for architectural alignment.
/// 6. Automatic sensor accuracy / calibration tracking.
class CompassService {
  StreamSubscription<CompassEvent>? _subscription;
  final StreamController<UserOrientationState> _orientationController =
      StreamController<UserOrientationState>.broadcast();

  Stream<UserOrientationState> get orientationStream =>
      _orientationController.stream;

  UserOrientationState _currentState =
      const UserOrientationState(isAvailable: true);
  UserOrientationState get currentState => _currentState;

  /// Architectural Map North offset in degrees.
  /// Setting this allows true geographic heading to project accurately onto the floor plan canvas.
  double mapNorthOffsetDegrees;

  /// Angular dead-band in degrees. Heading variations smaller than this threshold
  /// are treated as sensor electronic noise and suppressed when stationary.
  final double deadBandDegrees;

  /// Baseline smoothing alpha for stationary / slow movements [0.0 = max smoothing, 1.0 = raw].
  final double minAlpha;

  /// Maximum smoothing alpha for fast, deliberate device rotations.
  final double maxAlpha;

  /// Maximum physical slew rate in degrees per second to filter anomalous magnetic spikes.
  final double maxSlewRateDegreesPerSec;

  double? _lastFilteredHeading;
  DateTime? _lastTimestamp;

  CompassService({
    this.mapNorthOffsetDegrees = 0.0,
    this.deadBandDegrees = 1.5,
    this.minAlpha = 0.08,
    this.maxAlpha = 0.65,
    this.maxSlewRateDegreesPerSec = 360.0,
    double? smoothingAlpha,
    Stream<CompassEvent>? mockEvents,
  }) {
    if (mockEvents != null) {
      startListening(customStream: mockEvents);
    }
  }

  /// Starts listening to device orientation / compass sensor events.
  void startListening({Stream<CompassEvent>? customStream}) {
    _subscription?.cancel();

    try {
      final events = customStream ?? FlutterCompass.events;
      if (events == null) {
        _currentState = const UserOrientationState(isAvailable: false);
        _orientationController.add(_currentState);
        return;
      }

      _subscription = events.listen(
        _handleCompassEvent,
        onError: (Object error) {
          _currentState = const UserOrientationState(isAvailable: false);
          _orientationController.add(_currentState);
        },
      );
    } catch (_) {
      _currentState = const UserOrientationState(isAvailable: false);
      _orientationController.add(_currentState);
    }
  }

  void _handleCompassEvent(CompassEvent event) {
    final rawHeading = event.heading;
    if (rawHeading == null || rawHeading.isNaN) {
      _currentState = _currentState.copyWith(
        rawHeadingDegrees: () => null,
        headingDegrees: () => null,
        mapHeadingDegrees: () => null,
        sensorAccuracy: () => event.accuracy,
        isAvailable: true,
      );
      _orientationController.add(_currentState);
      return;
    }

    // 1. Normalize raw heading into standard [0, 360) range
    final normalizedRaw = (rawHeading % 360.0 + 360.0) % 360.0;
    final now = DateTime.now();

    double filteredHeading;

    if (_lastFilteredHeading == null) {
      filteredHeading = normalizedRaw;
    } else {
      // 2. Shortest angular delta between last filtered angle and new raw reading
      final delta = shortestAngleDelta(_lastFilteredHeading!, normalizedRaw);
      final absDelta = delta.abs();

      // 3. Slew-rate clamping to reject erratic single-frame magnetic spikes
      double effectiveDelta = delta;
      if (_lastTimestamp != null) {
        final dt = now.difference(_lastTimestamp!).inMicroseconds / 1000000.0;
        if (dt > 0.001 && dt < 0.5) {
          final maxAllowedDelta = maxSlewRateDegreesPerSec * dt;
          if (absDelta > maxAllowedDelta && absDelta > 20.0) {
            effectiveDelta = delta.sign * maxAllowedDelta;
          }
        }
      }

      // 4. Dead-band noise filter: suppress micro-fluctuations (< deadBandDegrees)
      if (effectiveDelta.abs() < deadBandDegrees) {
        filteredHeading = _lastFilteredHeading!;
      } else {
        // 5. Dynamic adaptive alpha: low smoothing for stationary, high responsiveness when turning
        final alpha = calculateAdaptiveAlpha(effectiveDelta.abs());

        // 6. Circular interpolation
        filteredHeading = smoothHeadingAngle(
          _lastFilteredHeading!,
          _lastFilteredHeading! + effectiveDelta,
          alpha: alpha,
        );
      }
    }

    _lastFilteredHeading = filteredHeading;
    _lastTimestamp = now;

    // 7. Architectural Map North correction: displayHeading = (worldHeading - mapNorthOffsetDegrees)
    final mapHeading = (filteredHeading - mapNorthOffsetDegrees + 360.0) % 360.0;

    // 8. Calibration status (accuracy > 30° indicates interference)
    final isLowAccuracy = event.accuracy != null &&
        (event.accuracy! > 30.0 || event.accuracy! == 0.0);

    _currentState = UserOrientationState(
      rawHeadingDegrees: normalizedRaw,
      headingDegrees: filteredHeading,
      mapHeadingDegrees: mapHeading,
      sensorAccuracy: event.accuracy,
      isAvailable: true,
      isCalibrating: isLowAccuracy,
      timestamp: now,
    );

    _orientationController.add(_currentState);
  }

  /// Calculates dynamic alpha factor based on angular change magnitude.
  /// - Small movements (1.5° - 5°): heavy smoothing (alpha = 0.08 - 0.20)
  /// - Medium turns (5° - 25°): balanced tracking (alpha = 0.20 - 0.65)
  /// - Rapid turns (> 25°): fast catch-up (alpha = 0.65 - 0.85)
  double calculateAdaptiveAlpha(double absDeltaDegrees) {
    if (absDeltaDegrees < deadBandDegrees) {
      return 0.0;
    } else if (absDeltaDegrees < 5.0) {
      final t = (absDeltaDegrees - deadBandDegrees) / (5.0 - deadBandDegrees);
      return minAlpha + (0.20 - minAlpha) * t;
    } else if (absDeltaDegrees < 25.0) {
      final t = (absDeltaDegrees - 5.0) / 20.0;
      return 0.20 + (maxAlpha - 0.20) * t;
    } else {
      final t = ((absDeltaDegrees - 25.0) / 35.0).clamp(0.0, 1.0);
      return maxAlpha + (0.85 - maxAlpha) * t;
    }
  }

  /// Dynamically updates the architectural map north offset (e.g. from database floor calibration).
  void setMapNorthOffset(double offset) {
    if (mapNorthOffsetDegrees == offset) return;
    mapNorthOffsetDegrees = offset;
    if (_lastFilteredHeading != null) {
      final mapHeading = (_lastFilteredHeading! - mapNorthOffsetDegrees + 360.0) % 360.0;
      _currentState = _currentState.copyWith(
        mapHeadingDegrees: () => mapHeading,
      );
      _orientationController.add(_currentState);
    }
  }

  /// Manually feeds a simulated mock heading (useful for unit tests and walking simulations).
  void setMockHeading(
    double? heading, {
    double? accuracy,
    bool isAvailable = true,
  }) {
    if (heading == null) {
      _lastFilteredHeading = null;
      _lastTimestamp = null;
      _currentState = UserOrientationState(
        rawHeadingDegrees: null,
        headingDegrees: null,
        mapHeadingDegrees: null,
        sensorAccuracy: accuracy,
        isAvailable: isAvailable,
        timestamp: DateTime.now(),
      );
    } else {
      final normalized = (heading % 360.0 + 360.0) % 360.0;
      _lastFilteredHeading = normalized;
      _lastTimestamp = DateTime.now();
      final mapHeading = (normalized - mapNorthOffsetDegrees + 360.0) % 360.0;

      _currentState = UserOrientationState(
        rawHeadingDegrees: normalized,
        headingDegrees: normalized,
        mapHeadingDegrees: mapHeading,
        sensorAccuracy: accuracy,
        isAvailable: isAvailable,
        isCalibrating: accuracy != null && accuracy > 30.0,
        timestamp: DateTime.now(),
      );
    }
    _orientationController.add(_currentState);
  }

  /// Calculates the shortest angular delta between [fromDegrees] and [toDegrees] in range [-180, 180].
  /// Correctly handles 359° -> 0° boundary crossings (delta = +1° instead of -359°).
  static double shortestAngleDelta(double fromDegrees, double toDegrees) {
    return ((toDegrees - fromDegrees + 540.0) % 360.0) - 180.0;
  }

  /// Circular low-pass filter for angular values to prevent 0°/360° wrapping glitches.
  static double smoothHeadingAngle(
    double current,
    double target, {
    double alpha = 0.30,
  }) {
    final delta = shortestAngleDelta(current, target);
    final smoothed = current + (delta * alpha.clamp(0.0, 1.0));
    return (smoothed % 360.0 + 360.0) % 360.0;
  }

  /// Trigonometric vector interpolation (converts angles to 2D unit vectors before blending).
  static double smoothHeadingVector(
    double currentDegrees,
    double targetDegrees, {
    double alpha = 0.30,
  }) {
    final currentRad = currentDegrees * math.pi / 180.0;
    final targetRad = targetDegrees * math.pi / 180.0;

    final cosCurrent = math.cos(currentRad);
    final sinCurrent = math.sin(currentRad);
    final cosTarget = math.cos(targetRad);
    final sinTarget = math.sin(targetRad);

    final a = alpha.clamp(0.0, 1.0);
    final blendedCos = (1.0 - a) * cosCurrent + a * cosTarget;
    final blendedSin = (1.0 - a) * sinCurrent + a * sinTarget;

    final angleRad = math.atan2(blendedSin, blendedCos);
    final angleDeg = angleRad * 180.0 / math.pi;
    return (angleDeg % 360.0 + 360.0) % 360.0;
  }

  /// Pauses / cancels orientation sensor subscription to conserve battery when screen is inactive.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Disposes orientation stream controllers and cancels listeners.
  void dispose() {
    stopListening();
    _orientationController.close();
  }
}
