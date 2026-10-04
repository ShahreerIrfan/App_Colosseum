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
