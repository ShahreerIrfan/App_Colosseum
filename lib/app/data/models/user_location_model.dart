import 'dart:ui' show Offset;
import 'package:latlong2/latlong.dart';
import '../../core/utils/geodesic_utils.dart';

/// Immutable model representing the user's live indoor coordinates on a floor plan.
class UserLocationModel {
  final String floorId;
  final double normalizedX;
  final double normalizedY;
  final double? latitude;
  final double? longitude;
  final double? headingDegrees;
  final double accuracyMeters;

  final DateTime? timestamp;

  /// Gets the real geographic coordinate [LatLng] on the map.
  LatLng get latLng {
    if (latitude != null && longitude != null) {
      return LatLng(latitude!, longitude!);
    }
    return GeodesicUtils.canvasOffsetToLatLng(Offset(normalizedX, normalizedY));
  }

  const UserLocationModel({
    required this.floorId,
    required this.normalizedX,
    required this.normalizedY,
    this.latitude,
    this.longitude,
    this.headingDegrees,
    this.accuracyMeters = 3.0,
    this.timestamp,
  });

  UserLocationModel copyWith({
    String? floorId,
    double? normalizedX,
    double? normalizedY,
    double? latitude,
    double? longitude,
    double? headingDegrees,
    double? accuracyMeters,
    DateTime? timestamp,
  }) {
    return UserLocationModel(
      floorId: floorId ?? this.floorId,
      normalizedX: normalizedX ?? this.normalizedX,
      normalizedY: normalizedY ?? this.normalizedY,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      headingDegrees: headingDegrees ?? this.headingDegrees,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserLocationModel &&
          runtimeType == other.runtimeType &&
          floorId == other.floorId &&
          normalizedX == other.normalizedX &&
          normalizedY == other.normalizedY;

  @override
  int get hashCode => Object.hash(floorId, normalizedX, normalizedY);
}
