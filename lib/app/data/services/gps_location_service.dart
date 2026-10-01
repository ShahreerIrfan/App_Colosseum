import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show Offset;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_location_model.dart';

/// Service managing device GPS location streaming, geofence boundary verification,
/// GPS jitter filtering, and real-to-canvas coordinate projections for the Colosseum arena.
class GpsLocationService {
  static const double colosseumCenterLat = 41.890210;
  static const double colosseumCenterLng = 12.492231;
  static const double geofenceRadiusMeters = 120.0;

  static const double arenaWidthMeters = 86.0;
  static const double arenaHeightMeters = 54.0;
  static const double monumentRotationDegrees = -20.0;

  StreamSubscription<Position>? _positionSubscription;
  final StreamController<GpsLocationResult> _locationResultController =
      StreamController<GpsLocationResult>.broadcast();

  Stream<GpsLocationResult> get locationStream =>
      _locationResultController.stream;

  GpsLocationResult _currentResult = const GpsLocationResult(
    isInLocation: false,
    userLocation: null,
  );
  GpsLocationResult get currentResult => _currentResult;

  double? _lastFilteredX;
  double? _lastFilteredY;

  /// Low-pass filter factor between 0.0 (maximum smoothing) and 1.0 (raw instant updates).
  final double positionSmoothingAlpha;

  GpsLocationService({
    this.positionSmoothingAlpha = 0.40,
    Stream<Position>? mockPositionStream,
  }) {
    if (mockPositionStream != null) {
      startTracking(customStream: mockPositionStream);
    }
  }

  /// Calculates metric Euclidean distance in meters from a given coordinate to the Colosseum center.
  static double calculateDistanceToCenter(double lat, double lng) {
    const metersPerDegreeLat = 111139.0;
    final metersPerDegreeLng =
        111139.0 * math.cos(colosseumCenterLat * math.pi / 180.0);

    final dNorth = (lat - colosseumCenterLat) * metersPerDegreeLat;
    final dEast = (lng - colosseumCenterLng) * metersPerDegreeLng;

    return math.sqrt(dNorth * dNorth + dEast * dEast);
  }

  /// Determines whether a given coordinate is within the Colosseum monument geofence (<= 120m).
  static bool isWithinColosseum(double lat, double lng) {
    return calculateDistanceToCenter(lat, lng) <= geofenceRadiusMeters;
  }

  /// Projects physical GPS (latitude, longitude) into normalized [0.0, 1.0] floor map coordinates.
  static Offset projectGpsToCanvas(double lat, double lng) {
    const rotationRad = monumentRotationDegrees * (math.pi / 180.0);
    const metersPerDegreeLat = 111139.0;
    final metersPerDegreeLng =
        111139.0 * math.cos(colosseumCenterLat * math.pi / 180.0);

    final dNorth = (lat - colosseumCenterLat) * metersPerDegreeLat;
    final dEast = (lng - colosseumCenterLng) * metersPerDegreeLng;

    // Rotate coordinates by monument tilt (-20°) to align horizontally on canvas
    final xRot = dEast * math.cos(-rotationRad) - dNorth * math.sin(-rotationRad);
    final yRot = dEast * math.sin(-rotationRad) + dNorth * math.cos(-rotationRad);

    // Normalize into [0.0, 1.0] canvas space (canvas Y is inverted: down is positive)
    final normalizedX = 0.50 + (xRot / arenaWidthMeters) * 0.82;
    final normalizedY = 0.50 - (yRot / arenaHeightMeters) * 0.60;

    return Offset(
      normalizedX.clamp(0.02, 0.98),
      normalizedY.clamp(0.02, 0.98),
    );
  }

  /// Checks and requests location permissions from the OS.
  Future<bool> checkAndRequestPermissions() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      if (!e.toString().contains('MissingPluginException')) {
        debugPrint('GpsLocationService permission error: $e');
      }
      return false;
    }
  }

  /// Starts listening to device GPS position updates.
  Future<void> startTracking({
    Stream<Position>? customStream,
    String floorId = 'floor_underground',
  }) async {
    _positionSubscription?.cancel();

    if (customStream != null) {
      _positionSubscription = customStream.listen(
        (pos) => _handlePositionUpdate(pos, floorId: floorId),
        onError: (err) => debugPrint('GPS stream error: $err'),
      );
      return;
    }

    final hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) {
      _safeAddResult(
        const GpsLocationResult(
          isInLocation: false,
          userLocation: null,
          errorMessage: 'Location permissions required for live GPS navigation',
        ),
      );
      return;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );

    try {
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (pos) => _handlePositionUpdate(pos, floorId: floorId),
        onError: (err) {
          debugPrint('GPS stream error: $err');
          _safeAddResult(
            const GpsLocationResult(
              isInLocation: false,
              userLocation: null,
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Error starting position stream: $e');
    }
  }

  void _safeAddResult(GpsLocationResult result) {
    _currentResult = result;
    if (!_locationResultController.isClosed) {
      _locationResultController.add(result);
    }
  }

  void _handlePositionUpdate(Position position, {String floorId = 'floor_underground'}) {
    // 1. Accuracy Filter: Ignore highly inaccurate GPS spikes (> 15m)
    if (position.accuracy > 15.0) {
      return;
    }

    final distanceToCenter =
        calculateDistanceToCenter(position.latitude, position.longitude);
    final inLocation = distanceToCenter <= geofenceRadiusMeters;

    if (!inLocation) {
      _lastFilteredX = null;
      _lastFilteredY = null;
      _safeAddResult(
        GpsLocationResult(
          isInLocation: false,
          userLocation: null,
          distanceToCenterMeters: distanceToCenter,
        ),
      );
      return;
    }

    // 2. Project GPS coordinates to normalized [0.0, 1.0] floor canvas
    final rawCanvasOffset = projectGpsToCanvas(
      position.latitude,
      position.longitude,
    );

    // 3. Low-Pass Exponential Moving Average Smoothing to eliminate standing jitter
    final smoothedX = _lastFilteredX == null
        ? rawCanvasOffset.dx
        : _lastFilteredX! +
            (rawCanvasOffset.dx - _lastFilteredX!) * positionSmoothingAlpha;

    final smoothedY = _lastFilteredY == null
        ? rawCanvasOffset.dy
        : _lastFilteredY! +
            (rawCanvasOffset.dy - _lastFilteredY!) * positionSmoothingAlpha;

    _lastFilteredX = smoothedX;
    _lastFilteredY = smoothedY;

    final userLoc = UserLocationModel(
      floorId: floorId,
      normalizedX: smoothedX,
      normalizedY: smoothedY,
      accuracyMeters: position.accuracy,
      timestamp: position.timestamp,
    );

    _safeAddResult(
      GpsLocationResult(
        isInLocation: true,
        userLocation: userLoc,
        distanceToCenterMeters: distanceToCenter,
      ),
    );
  }

  /// Manually feeds a simulated mock position (useful for unit testing and Fake GPS simulation).
  void setMockPosition({
    required double latitude,
    required double longitude,
    double accuracy = 2.0,
    String floorId = 'floor_underground',
  }) {
    final pos = Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: accuracy,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
    _handlePositionUpdate(pos, floorId: floorId);
  }

  /// Stops GPS stream tracking.
  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Disposes stream controllers and subscriptions.
  void dispose() {
    stopTracking();
    _locationResultController.close();
  }
}

/// Result payload emitted by [GpsLocationService].
class GpsLocationResult {
  final bool isInLocation;
  final UserLocationModel? userLocation;
  final double? distanceToCenterMeters;
  final String? errorMessage;

  const GpsLocationResult({
    required this.isInLocation,
    required this.userLocation,
    this.distanceToCenterMeters,
    this.errorMessage,
  });
}
