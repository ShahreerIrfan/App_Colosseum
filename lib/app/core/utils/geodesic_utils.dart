import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Geodesic math utilities for calculating building footprints, bounds, and geometric overlays.
abstract class GeodesicUtils {
  GeodesicUtils._();

  /// Generates an elliptical polygon around a center [LatLng] in geographic coordinates.
  /// - [center]: Center point of the monument
  /// - [radiusSemiMajorMeters]: Major radius in meters (e.g. 94.5m for Colosseum)
  /// - [radiusSemiMinorMeters]: Minor radius in meters (e.g. 78.0m for Colosseum)
  /// - [rotationDegrees]: Rotation angle of the major axis relative to east (degrees)
  /// - [pointsCount]: Number of polygon vertices for smoothness
  static List<LatLng> createEllipseFootprint({
    required LatLng center,
    required double radiusSemiMajorMeters,
    required double radiusSemiMinorMeters,
    double rotationDegrees = -20.0,
    int pointsCount = 36,
  }) {
    final List<LatLng> points = [];
    final rad = rotationDegrees * math.pi / 180.0;
    const metersPerDegreeLat = 111139.0;
    final metersPerDegreeLng =
        111139.0 * math.cos(center.latitude * math.pi / 180.0);

    for (int i = 0; i < pointsCount; i++) {
      final theta = (i * 2 * math.pi) / pointsCount;
      final xMeters = radiusSemiMajorMeters * math.cos(theta);
      final yMeters = radiusSemiMinorMeters * math.sin(theta);

      // Rotate ellipse
      final xRotMeters = xMeters * math.cos(rad) - yMeters * math.sin(rad);
      final yRotMeters = xMeters * math.sin(rad) + yMeters * math.cos(rad);

      final lat = center.latitude + (yRotMeters / metersPerDegreeLat);
      final lng = center.longitude + (xRotMeters / metersPerDegreeLng);
      points.add(LatLng(lat, lng));
    }

    return points;
  }

  /// Generates a rotated rectangular polygon around a center [LatLng].
  /// - [center]: Center point of the monument
  /// - [widthMeters]: Width along the major axis in meters
  /// - [heightMeters]: Height along the minor axis in meters
  /// - [rotationDegrees]: Rotation angle relative to east (degrees)
  static List<LatLng> createRotatedRectangleFootprint({
    required LatLng center,
    required double widthMeters,
    required double heightMeters,
    double rotationDegrees = 0.0,
  }) {
    final halfW = widthMeters / 2.0;
    final halfH = heightMeters / 2.0;
    final corners = [
      [-halfW, -halfH],
      [halfW, -halfH],
      [halfW, halfH],
      [-halfW, halfH],
    ];

    final rad = rotationDegrees * math.pi / 180.0;
    const metersPerDegreeLat = 111139.0;
    final metersPerDegreeLng =
        111139.0 * math.cos(center.latitude * math.pi / 180.0);

    return corners.map((c) {
      final xMeters = c[0];
      final yMeters = c[1];
      final xRot = xMeters * math.cos(rad) - yMeters * math.sin(rad);
      final yRot = xMeters * math.sin(rad) + yMeters * math.cos(rad);
      final lat = center.latitude + (yRot / metersPerDegreeLat);
      final lng = center.longitude + (xRot / metersPerDegreeLng);
      return LatLng(lat, lng);
    }).toList();
  }

  /// Calculates a [LatLngBounds] rectangle enclosing a given center and dimensions in meters.
  static LatLngBounds createBoundsFromDimensions({
    required LatLng center,
    required double widthMeters,
    required double heightMeters,
  }) {
    const metersPerDegreeLat = 111139.0;
    final metersPerDegreeLng =
        111139.0 * math.cos(center.latitude * math.pi / 180.0);

    final deltaLat = (heightMeters / 2.0) / metersPerDegreeLat;
    final deltaLng = (widthMeters / 2.0) / metersPerDegreeLng;

    return LatLngBounds(
      LatLng(center.latitude - deltaLat, center.longitude - deltaLng),
      LatLng(center.latitude + deltaLat, center.longitude + deltaLng),
    );
  }

  /// Calculates the 4 corner coordinates in LatLng for a rotated rectangular footprint with anchor offsets.
  static RotatedCorners calculateRotatedCorners({
    required LatLng center,
    required double widthMeters,
    required double heightMeters,
    required double rotationDegrees,
    double anchorX = 0.5,
    double anchorY = 0.5,
  }) {
    final leftDist = anchorX * widthMeters;
    final rightDist = (1.0 - anchorX) * widthMeters;
    final topDist = anchorY * heightMeters;
    final bottomDist = (1.0 - anchorY) * heightMeters;

    final rad = rotationDegrees * math.pi / 180.0;
    final cosR = math.cos(rad);
    final sinR = math.sin(rad);

    const metersPerDegreeLat = 111139.0;
    final metersPerDegreeLng =
        111139.0 * math.cos(center.latitude * math.pi / 180.0);

    LatLng calcCorner(double xLocal, double yLocal) {
      // Local coordinate system: x = East (+right), y = North (+up)
      // Clockwise rotation by rotationDegrees:
      final eastMeters = xLocal * cosR + yLocal * sinR;
      final northMeters = -xLocal * sinR + yLocal * cosR;

      final lat = center.latitude + (northMeters / metersPerDegreeLat);
      final lng = center.longitude + (eastMeters / metersPerDegreeLng);
      return LatLng(lat, lng);
    }

    return RotatedCorners(
      topLeft: calcCorner(-leftDist, topDist),
      bottomLeft: calcCorner(-leftDist, -bottomDist),
      bottomRight: calcCorner(rightDist, -bottomDist),
      topRight: calcCorner(rightDist, topDist),
    );
  }

  /// Converts normalized canvas coordinate ([0.0, 1.0] x [0.0, 1.0]) back to geographic [LatLng] on the Colosseum monument.
  static LatLng canvasToLatLng(
    math.Point<double> point, {
    double centerLat = 41.890210,
    double centerLng = 12.492231,
    double arenaWidthMeters = 86.0,
    double arenaHeightMeters = 54.0,
    double monumentRotationDegrees = -20.0,
  }) {
    final theta = -monumentRotationDegrees * (math.pi / 180.0);
    const metersPerDegreeLat = 111139.0;
    final metersPerDegreeLng =
        111139.0 * math.cos(centerLat * math.pi / 180.0);

    final xRot = (point.x - 0.50) / 0.82 * arenaWidthMeters;
    final yRot = -(point.y - 0.50) / 0.60 * arenaHeightMeters;

    final dEast = xRot * math.cos(theta) + yRot * math.sin(theta);
    final dNorth = -xRot * math.sin(theta) + yRot * math.cos(theta);

    final lat = centerLat + (dNorth / metersPerDegreeLat);
    final lng = centerLng + (dEast / metersPerDegreeLng);
    return LatLng(lat, lng);
  }

  /// Converts normalized canvas [Offset] back to geographic [LatLng].
  static LatLng canvasOffsetToLatLng(
    Offset point, {
    double centerLat = 41.890210,
    double centerLng = 12.492231,
    double arenaWidthMeters = 86.0,
    double arenaHeightMeters = 54.0,
    double monumentRotationDegrees = -20.0,
  }) {
    return canvasToLatLng(
      math.Point<double>(point.dx, point.dy),
      centerLat: centerLat,
      centerLng: centerLng,
      arenaWidthMeters: arenaWidthMeters,
      arenaHeightMeters: arenaHeightMeters,
      monumentRotationDegrees: monumentRotationDegrees,
    );
  }

  /// Converts a real geographic [LatLng] back to normalized canvas [Offset] ([0.0, 1.0] x [0.0, 1.0]).
  static Offset latLngToCanvasOffset(
    LatLng point, {
    double centerLat = 41.890210,
    double centerLng = 12.492231,
    double arenaWidthMeters = 86.0,
    double arenaHeightMeters = 54.0,
    double monumentRotationDegrees = -20.0,
  }) {
    final theta = -monumentRotationDegrees * (math.pi / 180.0);
    const metersPerDegreeLat = 111139.0;
    final metersPerDegreeLng =
        111139.0 * math.cos(centerLat * math.pi / 180.0);

    final dNorth = (point.latitude - centerLat) * metersPerDegreeLat;
    final dEast = (point.longitude - centerLng) * metersPerDegreeLng;

    final xRot = dEast * math.cos(theta) - dNorth * math.sin(theta);
    final yRot = dEast * math.sin(theta) + dNorth * math.cos(theta);

    final normalizedX = 0.50 + (xRot / arenaWidthMeters) * 0.82;
    final normalizedY = 0.50 - (yRot / arenaHeightMeters) * 0.60;

    return Offset(
      normalizedX.clamp(0.02, 0.98),
      normalizedY.clamp(0.02, 0.98),
    );
  }
}

/// Geographic coordinates for the 4 corners of a rotated bounding box.
class RotatedCorners {
  final LatLng topLeft;
  final LatLng bottomLeft;
  final LatLng bottomRight;
  final LatLng topRight;

  const RotatedCorners({
    required this.topLeft,
    required this.bottomLeft,
    required this.bottomRight,
    required this.topRight,
  });

  /// Calculates a non-rotated enclosing [LatLngBounds] encompassing all 4 corners.
  LatLngBounds get bounds {
    final points = [topLeft, bottomLeft, bottomRight, topRight];
    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }
}

