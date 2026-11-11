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
  final String? narrationLanguage;
  final bool isVisited;
  final double? latitude;
  final double? longitude;
  final String? imageAsset;
  final double? triggerRadiusMeters;
  final double? targetGazeHeadingDegrees;

  /// Gets the real geographic coordinate [LatLng] on the map.
  LatLng get latLng {
    if (hasGeographicPosition) {
      return LatLng(latitude!, longitude!);
    }
    return GeodesicUtils.canvasOffsetToLatLng(Offset(normalizedX, normalizedY));
  }

  // Older backend records without a position were written as (0, 0).
  bool get hasGeographicPosition =>
      latitude != null && longitude != null &&
      latitude!.isFinite && longitude!.isFinite &&
      latitude!.abs() <= 90 && longitude!.abs() <= 180 &&
      (latitude != 0 || longitude != 0);

  const ViewpointModel({
    required this.id,
    required this.floorId,
    required this.title,
    required this.order,
    required this.normalizedX,
    required this.normalizedY,
    this.description = '',
    this.narrationLanguage,
    this.isVisited = false,
    this.latitude,
    this.longitude,
    this.imageAsset,
    this.triggerRadiusMeters,
    this.targetGazeHeadingDegrees,
  });

  factory ViewpointModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] as String? ?? json['viewpointId'] as String? ?? '';
    final rawImage = json['imageAsset'] as String? ?? json['image']?['url'] as String?;

    return ViewpointModel(
      id: rawId,
      floorId: json['floorId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
      normalizedX: (json['normalizedX'] as num?)?.toDouble() ?? 0.0,
      normalizedY: (json['normalizedY'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      narrationLanguage: json['narrationLanguage'] as String?,
      isVisited: json['isVisited'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      imageAsset: _resolveImageAsset(rawId, rawImage),
      triggerRadiusMeters: (json['triggerRadiusMeters'] as num?)?.toDouble(),
      targetGazeHeadingDegrees: (json['targetGazeHeadingDegrees'] as num?)?.toDouble(),
    );
  }

  static String? _resolveImageAsset(String id, String? rawImage) {
    if (rawImage != null &&
        rawImage.isNotEmpty &&
        !rawImage.startsWith('assets/logo/') &&
        !rawImage.endsWith('viewpoint_default.png')) {
      return rawImage;
    }
    const knownViewpoints = {
      'vp_100': 'assets/images/vp_100_arena_spectacles.jpg',
      'vp_101': 'assets/images/vp_101_ludus_magnus_tunnel.jpg',
      'vp_102': 'assets/images/vp_102_hypogeum_phases.jpg',
      'vp_103': 'assets/images/vp_103_flavian_hoists.jpg',
      'vp_104': 'assets/images/vp_104_corridor_h.jpg',
      'vp_105': 'assets/images/vp_105_severan_hoists.jpg',
      'vp_106': 'assets/images/vp_106_excavations_restorations.jpg',
      'vp_200': 'assets/images/vp_200.jpg',
      'vp_201': 'assets/images/vp_201.jpg',
      'vp_202': 'assets/images/vp_202.jpg',
      'vp_203': 'assets/images/vp_203.jpg',
      'vp_204': 'assets/images/vp_204.jpg',
      'vp_205': 'assets/images/vp_205.jpg',
      'vp_206': 'assets/images/vp_206.jpg',
      'vp_207': 'assets/images/vp_207.jpg',
      'vp_208': 'assets/images/vp_208.jpg',
      'vp_300': 'assets/images/vp_300.jpg',
      'vp_301': 'assets/images/vp_301.jpg',
      'vp_302': 'assets/images/vp_302.jpg',
      'vp_303': 'assets/images/vp_303.jpg',
      'vp_304': 'assets/images/vp_304.jpg',
      'vp_305': 'assets/images/vp_305.jpg',
      'vp_306': 'assets/images/vp_306.jpg',
      'vp_400': 'assets/images/vp_400.jpg',
      'vp_401': 'assets/images/vp_401.jpg',
      'vp_402': 'assets/images/vp_402.jpg',
      'vp_403': 'assets/images/vp_403.jpg',
      'vp_404': 'assets/images/vp_404.jpg',
      'vp_arch_200': 'assets/images/vp_arch_200.jpg',
      'vp_arch_201': 'assets/images/vp_arch_201.jpg',
      'vp_arch_202': 'assets/images/vp_arch_202.jpg',
      'vp_arch_203': 'assets/images/vp_arch_203.jpg',
      'vp_arch_204': 'assets/images/vp_arch_204.jpg',
      'vp_arch_205': 'assets/images/vp_arch_205.jpg',
      'vp_ludus_300': 'assets/images/vp_ludus_300.jpg',
      'vp_ludus_301': 'assets/images/vp_ludus_301.jpg',
      'vp_ludus_302': 'assets/images/vp_ludus_302.jpg',
      'vp_ludus_303': 'assets/images/vp_ludus_303.jpg',
      'vp_ludus_304': 'assets/images/vp_ludus_304.jpg',
      'vp_tvr_400': 'assets/images/vp_tvr_400.jpg',
      'vp_tvr_401': 'assets/images/vp_tvr_401.jpg',
      'vp_tvr_402': 'assets/images/vp_tvr_402.jpg',
      'vp_tvr_403': 'assets/images/vp_tvr_403.jpg',
      'vp_tvr_404': 'assets/images/vp_tvr_404.jpg',
      'vp_forum_500': 'assets/images/vp_forum_500.jpg',
      'vp_forum_501': 'assets/images/vp_forum_501.jpg',
      'vp_forum_502': 'assets/images/vp_forum_502.jpg',
      'vp_forum_503': 'assets/images/vp_forum_503.jpg',
      'vp_forum_504': 'assets/images/vp_forum_504.jpg',
      'vp_forum_505': 'assets/images/vp_forum_505.jpg',
      'vp_forum_506': 'assets/images/vp_forum_506.jpg',
    };
    return knownViewpoints[id] ?? rawImage ?? 'assets/images/viewpoint_default.png';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'floorId': floorId,
        'title': title,
        'order': order,
        'normalizedX': normalizedX,
        'normalizedY': normalizedY,
        'description': description,
        'narrationLanguage': narrationLanguage,
        'isVisited': isVisited,
        'latitude': latitude,
        'longitude': longitude,
        'imageAsset': imageAsset,
        'triggerRadiusMeters': triggerRadiusMeters,
        'targetGazeHeadingDegrees': targetGazeHeadingDegrees,
      };

  ViewpointModel copyWith({
    String? id,
    String? floorId,
    String? title,
    int? order,
    double? normalizedX,
    double? normalizedY,
    String? description,
    String? narrationLanguage,
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
      narrationLanguage: narrationLanguage ?? this.narrationLanguage,
      isVisited: isVisited ?? this.isVisited,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageAsset: imageAsset ?? this.imageAsset,
      triggerRadiusMeters: triggerRadiusMeters,
      targetGazeHeadingDegrees: targetGazeHeadingDegrees,
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
          narrationLanguage == other.narrationLanguage &&
          isVisited == other.isVisited &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          imageAsset == other.imageAsset &&
          triggerRadiusMeters == other.triggerRadiusMeters &&
          targetGazeHeadingDegrees == other.targetGazeHeadingDegrees;

  @override
  int get hashCode => Object.hash(
        id,
        floorId,
        title,
        order,
        normalizedX,
        normalizedY,
        description,
        narrationLanguage,
        isVisited,
        latitude,
        longitude,
        imageAsset,
        triggerRadiusMeters,
        targetGazeHeadingDegrees,
      );
}
