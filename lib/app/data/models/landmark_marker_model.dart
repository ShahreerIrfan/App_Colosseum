import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Reusable data model representing a classic map pin marker with text label and color coding.
@immutable
class LandmarkMarkerModel {
  /// Unique identifier for this landmark (e.g. 'colosseum', 'arch_of_constantine').
  final String id;

  /// Human-readable display name (e.g. 'Colosseum').
  final String name;

  /// Real-world geographic anchor coordinate.
  final LatLng coordinates;

  /// Distinct marker theme color.
  final Color color;

  /// Optional architectural or historical category (e.g. 'Amphitheatre', 'Temple').
  final String? category;

  /// Optional icon representing the landmark type.
  final IconData? icon;

  /// Fine-grained label offset for overlap avoidance in dense areas.
  final Offset labelOffset;

  /// Minimum zoom level at which this marker is visible.
  final double minZoom;

  /// Maximum zoom level at which this marker is visible.
  final double maxZoom;

  /// Optional tap callback for custom marker behavior.
  final VoidCallback? onTap;

  const LandmarkMarkerModel({
    required this.id,
    required this.name,
    required this.coordinates,
    required this.color,
    this.category,
    this.icon,
    this.labelOffset = Offset.zero,
    this.minZoom = 13.0,
    this.maxZoom = 21.0,
    this.onTap,
  });

  /// Geographic latitude.
  double get latitude => coordinates.latitude;

  /// Geographic longitude.
  double get longitude => coordinates.longitude;

  factory LandmarkMarkerModel.fromJson(Map<String, dynamic> json) {
    LatLng coords = const LatLng(41.89021, 12.492231);
    if (json['centerCoordinates'] is Map) {
      final c = json['centerCoordinates'] as Map;
      coords = LatLng(
        (c['latitude'] as num?)?.toDouble() ?? 41.89021,
        (c['longitude'] as num?)?.toDouble() ?? 12.492231,
      );
    } else if (json['coordinates'] is Map) {
      final c = json['coordinates'] as Map;
      coords = LatLng(
        (c['latitude'] as num?)?.toDouble() ?? 41.89021,
        (c['longitude'] as num?)?.toDouble() ?? 12.492231,
      );
    } else if (json['latitude'] != null && json['longitude'] != null) {
      coords = LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      );
    }

    Color markerColor = const Color(0xFFDD1110);
    if (json['color'] is int) {
      markerColor = Color(json['color'] as int);
    } else if (json['colorHex'] is String) {
      final hex = (json['colorHex'] as String).replaceAll('#', '');
      markerColor = Color(int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16));
    }

    return LandmarkMarkerModel(
      id: json['id'] as String? ?? json['landmarkId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      coordinates: coords,
      color: markerColor,
      category: json['category'] as String?,
      labelOffset: Offset(
        (json['labelOffsetX'] as num?)?.toDouble() ?? 0.0,
        (json['labelOffsetY'] as num?)?.toDouble() ?? 0.0,
      ),
      minZoom: (json['minZoom'] as num?)?.toDouble() ?? 13.0,
      maxZoom: (json['maxZoom'] as num?)?.toDouble() ?? 21.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'landmarkId': id,
        'name': name,
        'latitude': coordinates.latitude,
        'longitude': coordinates.longitude,
        'color': color.toARGB32(),
        'category': category,
        'labelOffsetX': labelOffset.dx,
        'labelOffsetY': labelOffset.dy,
        'minZoom': minZoom,
        'maxZoom': maxZoom,
      };

  LandmarkMarkerModel copyWith({
    String? id,
    String? name,
    LatLng? coordinates,
    Color? color,
    String? category,
    IconData? icon,
    Offset? labelOffset,
    double? minZoom,
    double? maxZoom,
    VoidCallback? onTap,
  }) {
    return LandmarkMarkerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      coordinates: coordinates ?? this.coordinates,
      color: color ?? this.color,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      labelOffset: labelOffset ?? this.labelOffset,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      onTap: onTap ?? this.onTap,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LandmarkMarkerModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          coordinates == other.coordinates &&
          color == other.color &&
          category == other.category &&
          icon == other.icon &&
          labelOffset == other.labelOffset &&
          minZoom == other.minZoom &&
          maxZoom == other.maxZoom;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        coordinates,
        color,
        category,
        icon,
        labelOffset,
        minZoom,
        maxZoom,
      );
}
