import 'dart:async';
import 'package:flutter_compass/flutter_compass.dart';
import '../models/user_orientation_state.dart';

/// Service responsible for managing live device compass / orientation sensor data,
/// filtering sensor noise, handling wrap-around angular interpolation, and reporting calibration state.
class CompassService {
  StreamSubscription<CompassEvent>? _subscription;
  final StreamController<UserOrientationState> _orientationController =
      StreamController<UserOrientationState>.broadcast();

  Stream<UserOrientationState> get orientationStream =>
      _orientationController.stream;

  UserOrientationState _currentState =
      const UserOrientationState(isAvailable: true);
  UserOrientationState get currentState => _currentState;

  double? _lastFilteredHeading;

  /// Low-pass filter smoothing factor between 0.0 (maximum smoothing) and 1.0 (no smoothing).
  final double smoothingAlpha;

  CompassService({
    this.smoothingAlpha = 0.30,
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
        headingDegrees: () => null,
        sensorAccuracy: () => event.accuracy,
        isAvailable: true,
      );
      _orientationController.add(_currentState);
      return;
    }

    // Normalize raw heading to standard [0, 360) range
    final normalizedHeading = (rawHeading % 360.0 + 360.0) % 360.0;

    // Apply circular low-pass angular filter to smooth small sensor fluctuations
    final smoothedHeading = _lastFilteredHeading == null
        ? normalizedHeading
        : smoothHeadingAngle(
            _lastFilteredHeading!,
            normalizedHeading,
            alpha: smoothingAlpha,
          );
    _lastFilteredHeading = smoothedHeading;

    // Determine calibration state based on sensor accuracy
    // (accuracy > 30 degrees or status == 0/unreliable)
    final isLowAccuracy = event.accuracy != null &&
        (event.accuracy! > 30.0 || event.accuracy! == 0.0);

    _currentState = UserOrientationState(
      headingDegrees: smoothedHeading,
      sensorAccuracy: event.accuracy,
      isAvailable: true,
      isCalibrating: isLowAccuracy,
      timestamp: DateTime.now(),
    );

    _orientationController.add(_currentState);
  }

  /// Manually feeds a simulated mock heading (useful for unit tests and walking simulations).
  void setMockHeading(
    double? heading, {
    double? accuracy,
    bool isAvailable = true,
  }) {
    if (heading == null) {
      _lastFilteredHeading = null;
      _currentState = UserOrientationState(
        headingDegrees: null,
        sensorAccuracy: accuracy,
        isAvailable: isAvailable,
        timestamp: DateTime.now(),
      );
    } else {
      final normalized = (heading % 360.0 + 360.0) % 360.0;
      _lastFilteredHeading = normalized;
      _currentState = UserOrientationState(
        headingDegrees: normalized,
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

  /// Low-pass filter for circular angles to avoid unnatural spinning on 0°/360° wraps.
  static double smoothHeadingAngle(
    double current,
    double target, {
    double alpha = 0.30,
  }) {
    final delta = shortestAngleDelta(current, target);
    final smoothed = current + (delta * alpha.clamp(0.0, 1.0));
    return (smoothed % 360.0 + 360.0) % 360.0;
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
