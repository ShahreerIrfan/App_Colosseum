import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show Offset;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_location_model.dart';

/// GPS tracking mode options.
enum GpsTrackingMode {
  /// Default: absolute GPS tracking inside the physical Rome Colosseum monument (120m geofence).
  colosseumGeofence,

  /// Field Test Mode: relative walking projection anchored to local ground (field, park, street, rooftop).
  localPlayground,
}

/// Service managing device GPS location streaming, geofence boundary verification,
/// local playground field-test displacement projection, and coordinate transforms.
class GpsLocationService {
  static const double colosseumCenterLat = 41.890210;
  static const double colosseumCenterLng = 12.492231;
  static const double geofenceRadiusMeters = 120.0;

  static const double arenaWidthMeters = 86.0;
  static const double arenaHeightMeters = 54.0;
  static const double monumentRotationDegrees = -20.0;

  /// Default Entry point normalized coordinate on Colosseum canvas
  static const Offset defaultCanvasEntry = Offset(0.92, 0.50);

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

  /// Active tracking mode (Colosseum geofence vs Local playground field-test)
  GpsTrackingMode _trackingMode = GpsTrackingMode.colosseumGeofence;
  GpsTrackingMode get trackingMode => _trackingMode;
  bool get isPlaygroundMode => _trackingMode == GpsTrackingMode.localPlayground;

  /// Local playground reference anchor coordinates (Lat, Lng)
  double? _playgroundOriginLat;
  double? _playgroundOriginLng;
  double? get playgroundOriginLat => _playgroundOriginLat;
  double? get playgroundOriginLng => _playgroundOriginLng;

  double? _lastFilteredX;
  double? _lastFilteredY;

  /// Low-pass filter factor between 0.0 (maximum smoothing) and 1.0 (raw instant updates).
  final double positionSmoothingAlpha;

  GpsLocationService({
    this.positionSmoothingAlpha = 0.40,
    GpsTrackingMode initialMode = GpsTrackingMode.colosseumGeofence,
    Stream<Position>? mockPositionStream,
  }) : _trackingMode = initialMode {
    if (mockPositionStream != null) {
      startTracking(customStream: mockPositionStream);
    }
  }

  /// Switches tracking mode between Colosseum Geofence and Local Playground Field Test.
  void setTrackingMode(GpsTrackingMode mode, {String floorId = 'floor_underground'}) {
    _trackingMode = mode;
    _lastFilteredX = null;
    _lastFilteredY = null;
    if (mode == GpsTrackingMode.localPlayground) {
      // Clear origin so the next incoming GPS fix becomes the new reference anchor
      _playgroundOriginLat = null;
      _playgroundOriginLng = null;
    }
  }

  /// Resets or sets the local playground reference origin anchor.
  void resetPlaygroundOrigin({double? lat, double? lng}) {
    _playgroundOriginLat = lat;
    _playgroundOriginLng = lng;
    _lastFilteredX = null;
    _lastFilteredY = null;
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

  /// Projects physical Colosseum GPS (latitude, longitude) into normalized [0.0, 1.0] floor map coordinates.
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

  /// Projects relative local displacement (from local playground origin) into normalized floor map canvas.
  ///
  /// Starting at [originLat], [originLng] maps directly to [defaultCanvasEntry] (0.92, 0.50).
  /// Walking westward/forward in local field moves the user progressively into the Colosseum arena:
  /// ENTRY -> Stop 100 -> 101 -> 102 -> 103 -> 104 -> 105 -> 106 -> EXIT.
  static Offset projectPlaygroundToCanvas({
    required double currentLat,
    required double currentLng,
    required double originLat,
    required double originLng,
    Offset entryOffset = defaultCanvasEntry,
  }) {
    const rotationRad = monumentRotationDegrees * (math.pi / 180.0);
    const metersPerDegreeLat = 111139.0;
    final metersPerDegreeLng =
        111139.0 * math.cos(originLat * math.pi / 180.0);

    final dNorth = (currentLat - originLat) * metersPerDegreeLat;
    final dEast = (currentLng - originLng) * metersPerDegreeLng;

    // Rotate local displacement vector by monument tilt (-20°)
    final xRot = dEast * math.cos(-rotationRad) - dNorth * math.sin(-rotationRad);
    final yRot = dEast * math.sin(-rotationRad) + dNorth * math.cos(-rotationRad);

    // Relative displacement from Entry gate
    final normalizedX = entryOffset.dx + (xRot / arenaWidthMeters) * 0.82;
    final normalizedY = entryOffset.dy - (yRot / arenaHeightMeters) * 0.60;

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

  /// Builds platform-optimized LocationSettings for walking speed tracking (1 sec interval).
  LocationSettings _buildLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        intervalDuration: const Duration(milliseconds: 1000),
        distanceFilter: 0,
        forceLocationManager: false,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.fitness,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
      );
    } else {
      return const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );
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

    final locationSettings = _buildLocationSettings();

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

  void _handlePositionUpdate(
    Position position, {
    String floorId = 'floor_underground',
  }) {
    // 1. Dynamic Accuracy Filter: Discard severe GPS outliers (> 30m)
    if (position.accuracy > 30.0) {
      return;
    }

    // Dynamic smoothing factor based on GPS precision:
    // High precision (<= 12m) -> snappy alpha (0.40)
    // Moderate precision (12m - 30m) -> heavier smoothing (0.20) to eliminate noise
    final effectiveAlpha = position.accuracy <= 12.0
        ? positionSmoothingAlpha
        : (positionSmoothingAlpha * 0.50).clamp(0.15, 0.30);

    Offset targetCanvasOffset;
    double? distanceToCenter;
    bool inLocation;

    if (_trackingMode == GpsTrackingMode.localPlayground) {
      // --- FIELD TEST / PLAYGROUND MODE ---
      // Anchor origin to the first received GPS coordinate if not already set
      if (_playgroundOriginLat == null || _playgroundOriginLng == null) {
        _playgroundOriginLat = position.latitude;
        _playgroundOriginLng = position.longitude;
      }

      targetCanvasOffset = projectPlaygroundToCanvas(
        currentLat: position.latitude,
        currentLng: position.longitude,
        originLat: _playgroundOriginLat!,
        originLng: _playgroundOriginLng!,
      );

      inLocation = true;
      distanceToCenter = 0.0;
    } else {
      // --- ABSOLUTE COLOSSEUM GEOFENCE MODE ---
      distanceToCenter =
          calculateDistanceToCenter(position.latitude, position.longitude);
      inLocation = distanceToCenter <= geofenceRadiusMeters;

      if (!inLocation) {
        _lastFilteredX = null;
        _lastFilteredY = null;
        _safeAddResult(
          GpsLocationResult(
            isInLocation: false,
            userLocation: null,
            distanceToCenterMeters: distanceToCenter,
            isPlaygroundMode: false,
          ),
        );
        return;
      }

      targetCanvasOffset = projectGpsToCanvas(
        position.latitude,
        position.longitude,
      );
    }

    // Low-Pass Exponential Moving Average Smoothing to eliminate standing jitter
    final smoothedX = _lastFilteredX == null
        ? targetCanvasOffset.dx
        : _lastFilteredX! +
            (targetCanvasOffset.dx - _lastFilteredX!) * effectiveAlpha;

    final smoothedY = _lastFilteredY == null
        ? targetCanvasOffset.dy
        : _lastFilteredY! +
            (targetCanvasOffset.dy - _lastFilteredY!) * effectiveAlpha;

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
        isInLocation: inLocation,
        userLocation: userLoc,
        distanceToCenterMeters: distanceToCenter,
        isPlaygroundMode: _trackingMode == GpsTrackingMode.localPlayground,
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
  final bool isPlaygroundMode;

  const GpsLocationResult({
    required this.isInLocation,
    required this.userLocation,
    this.distanceToCenterMeters,
    this.errorMessage,
    this.isPlaygroundMode = false,
  });
}
