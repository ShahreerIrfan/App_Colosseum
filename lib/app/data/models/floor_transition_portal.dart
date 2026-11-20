import 'dart:ui' show Offset;
import 'package:latlong2/latlong.dart';

/// Represents a physical staircase, ramp, or portal connecting two architectural floors.
class FloorTransitionPortal {
  final String id;
  final String name;
  final String fromFloorId;
  final String toFloorId;
  final double normalizedX;
  final double normalizedY;
  final LatLng? coordinates;
  final double triggerRadiusMeters;
  final double elevationDeltaMeters;
  final bool isAscending;

  const FloorTransitionPortal({
    required this.id,
    required this.name,
    required this.fromFloorId,
    required this.toFloorId,
    required this.normalizedX,
    required this.normalizedY,
    this.coordinates,
    this.triggerRadiusMeters = 16.0,
    this.elevationDeltaMeters = 6.0,
    this.isAscending = true,
  });

  Offset get canvasOffset => Offset(normalizedX, normalizedY);

  factory FloorTransitionPortal.fromJson(Map<String, dynamic> json) {
    LatLng? coords;
    if (json['coordinates'] is Map) {
      final c = json['coordinates'] as Map;
      coords = LatLng(
        (c['latitude'] as num).toDouble(),
        (c['longitude'] as num).toDouble(),
      );
    }
    return FloorTransitionPortal(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Stairs',
      fromFloorId: json['fromFloorId'] as String? ?? '',
      toFloorId: json['toFloorId'] as String? ?? '',
      normalizedX: (json['normalizedX'] as num?)?.toDouble() ?? 0.5,
      normalizedY: (json['normalizedY'] as num?)?.toDouble() ?? 0.5,
      coordinates: coords,
      triggerRadiusMeters: (json['triggerRadiusMeters'] as num?)?.toDouble() ?? 16.0,
      elevationDeltaMeters: (json['elevationDeltaMeters'] as num?)?.toDouble() ?? 6.0,
      isAscending: json['isAscending'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'fromFloorId': fromFloorId,
    'toFloorId': toFloorId,
    'normalizedX': normalizedX,
    'normalizedY': normalizedY,
    if (coordinates != null)
      'coordinates': {
        'latitude': coordinates!.latitude,
        'longitude': coordinates!.longitude,
      },
    'triggerRadiusMeters': triggerRadiusMeters,
    'elevationDeltaMeters': elevationDeltaMeters,
    'isAscending': isAscending,
  };
}
