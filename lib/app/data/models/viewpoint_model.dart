import 'dart:ui' show Offset;
import 'package:latlong2/latlong.dart';
import '../../core/utils/geodesic_utils.dart';

/// Immutable model representing an interactive viewpoint / audio stop on a landmark floor.
class ViewpointModel {
  final String id;
  final String floorId;
  final String title;
  final int order;
  final double normalizedX;
  final double normalizedY;
  final String description;
  final String audioDuration;
  final bool isVisited;
  final double? latitude;
  final double? longitude;
  final String? imageAsset;

  /// Gets the real geographic coordinate [LatLng] on the map.
  LatLng get latLng {
    if (latitude != null && longitude != null && !floorId.startsWith('floor_')) {
      return LatLng(latitude!, longitude!);
    }
    return GeodesicUtils.canvasOffsetToLatLng(Offset(normalizedX, normalizedY));
  }

  const ViewpointModel({
    required this.id,
    required this.floorId,
    required this.title,
    required this.order,
    required this.normalizedX,
    required this.normalizedY,
    this.description = '',
    this.audioDuration = '2 min',
    this.isVisited = false,
    this.latitude,
    this.longitude,
    this.imageAsset,
  });

  factory ViewpointModel.fromJson(Map<String, dynamic> json) {
    return ViewpointModel(
      id: json['id'] as String? ?? '',
      floorId: json['floorId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
      normalizedX: (json['normalizedX'] as num?)?.toDouble() ?? 0.0,
      normalizedY: (json['normalizedY'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      audioDuration: json['audioDuration'] as String? ?? '2 min',
      isVisited: json['isVisited'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      imageAsset: json['imageAsset'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'floorId': floorId,
        'title': title,
        'order': order,
        'normalizedX': normalizedX,
        'normalizedY': normalizedY,
        'description': description,
        'audioDuration': audioDuration,
        'isVisited': isVisited,
        'latitude': latitude,
        'longitude': longitude,
        'imageAsset': imageAsset,
      };

  ViewpointModel copyWith({
    String? id,
    String? floorId,
    String? title,
    int? order,
    double? normalizedX,
    double? normalizedY,
    String? description,
    String? audioDuration,
    bool? isVisited,
    double? latitude,
    double? longitude,
    String? imageAsset,
  }) {
    return ViewpointModel(
      id: id ?? this.id,
      floorId: floorId ?? this.floorId,
      title: title ?? this.title,
      order: order ?? this.order,
      normalizedX: normalizedX ?? this.normalizedX,
      normalizedY: normalizedY ?? this.normalizedY,
      description: description ?? this.description,
      audioDuration: audioDuration ?? this.audioDuration,
      isVisited: isVisited ?? this.isVisited,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageAsset: imageAsset ?? this.imageAsset,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ViewpointModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          floorId == other.floorId &&
          title == other.title &&
          order == other.order &&
          normalizedX == other.normalizedX &&
          normalizedY == other.normalizedY &&
          description == other.description &&
          audioDuration == other.audioDuration &&
          isVisited == other.isVisited &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          imageAsset == other.imageAsset;

  @override
  int get hashCode => Object.hash(
        id,
        floorId,
        title,
        order,
        normalizedX,
        normalizedY,
        description,
        audioDuration,
        isVisited,
        latitude,
        longitude,
        imageAsset,
      );
}
