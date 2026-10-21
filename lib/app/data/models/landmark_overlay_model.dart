import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/utils/geodesic_utils.dart';

/// Reusable data model representing a geo-referenced ground overlay on Google Maps.
@immutable
class MapLandmarkOverlay {
  /// Unique identifier for this landmark overlay (e.g. 'colosseum').
  final String id;

  /// Human-readable landmark name (e.g. 'Colosseum').
  final String name;

  /// Flutter asset bundle path to the transparent PNG.
  final String assetPath;

  /// Real-world geographic center coordinate.
  final LatLng center;

  /// Real-world physical footprint width in meters.
  final double widthMeters;

  /// Real-world physical footprint height in meters.
  final double heightMeters;

  /// Clockwise rotation in degrees relative to true North.
  final double rotationDegrees;

  /// Normalized horizontal anchor point within the PNG [0.0 - 1.0]. Defaults to 0.50 (center).
  final double anchorX;

  /// Normalized vertical anchor point within the PNG [0.0 - 1.0]. Defaults to 0.50 (center).
  final double anchorY;

  /// Rendering stack order (lower values render underneath higher values).
  final int zIndex;

  /// Minimum zoom level at which this overlay is visible.
  final double minZoom;

  /// Maximum zoom level at which this overlay is visible.
  final double maxZoom;

  /// Master visibility toggle for this overlay.
  final bool isVisible;

  /// Opacity multiplier [0.0 - 1.0] for image rendering.
  final double opacity;

  /// Optional tap callback for future interactive landmark behaviors.
  final VoidCallback? onTap;

  const MapLandmarkOverlay({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.center,
    required this.widthMeters,
    required this.heightMeters,
    this.rotationDegrees = 0.0,
    this.anchorX = 0.5,
    this.anchorY = 0.5,
    this.zIndex = 0,
    this.minZoom = 13.0,
    this.maxZoom = 21.0,
    this.isVisible = true,
    this.opacity = 1.0,
    this.onTap,
  });

  factory MapLandmarkOverlay.fromJson(Map<String, dynamic> json) {
    LatLng center = const LatLng(41.89021, 12.492231);
    if (json['centerCoordinates'] is Map) {
      final c = json['centerCoordinates'] as Map;
      center = LatLng(
        (c['latitude'] as num?)?.toDouble() ?? 41.89021,
        (c['longitude'] as num?)?.toDouble() ?? 12.492231,
      );
    } else if (json['center'] is Map) {
      final c = json['center'] as Map;
      center = LatLng(
        (c['latitude'] as num?)?.toDouble() ?? 41.89021,
        (c['longitude'] as num?)?.toDouble() ?? 12.492231,
      );
    }

    final dim = json['dimensions'] is Map ? (json['dimensions'] as Map) : null;
    final calib = json['calibration'] is Map ? (json['calibration'] as Map) : null;
    final disp = json['display'] is Map ? (json['display'] as Map) : null;

    final width = (json['widthMeters'] as num?)?.toDouble() ??
        (dim?['widthMeters'] as num?)?.toDouble() ??
        0.0;
    final height = (json['heightMeters'] as num?)?.toDouble() ??
        (dim?['heightMeters'] as num?)?.toDouble() ??
        0.0;
    final rot = (json['rotationDegrees'] as num?)?.toDouble() ??
        (calib?['rotationDegrees'] as num?)?.toDouble() ??
        0.0;
    final aX = (json['anchorX'] as num?)?.toDouble() ??
        (calib?['anchorX'] as num?)?.toDouble() ??
        0.5;
    final aY = (json['anchorY'] as num?)?.toDouble() ??
        (calib?['anchorY'] as num?)?.toDouble() ??
        0.5;
    final zIdx = (json['zIndex'] as num?)?.toInt() ??
        (disp?['zIndex'] as num?)?.toInt() ??
        0;
    final minZ = (json['minZoom'] as num?)?.toDouble() ??
        (disp?['minZoom'] as num?)?.toDouble() ??
        13.0;
    final maxZ = (json['maxZoom'] as num?)?.toDouble() ??
        (disp?['maxZoom'] as num?)?.toDouble() ??
        21.0;

    return MapLandmarkOverlay(
      id: json['code'] as String? ?? json['landmarkId'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      assetPath: json['assetPath'] as String? ?? '',
      center: center,
      widthMeters: width,
      heightMeters: height,
      rotationDegrees: rot,
      anchorX: aX,
      anchorY: aY,
      zIndex: zIdx,
      minZoom: minZ,
      maxZoom: maxZ,
      isVisible: json['isVisible'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'landmarkId': id,
        'name': name,
        'assetPath': assetPath,
        'centerCoordinates': {
          'latitude': center.latitude,
          'longitude': center.longitude,
        },
        'widthMeters': widthMeters,
        'heightMeters': heightMeters,
        'rotationDegrees': rotationDegrees,
        'anchorX': anchorX,
        'anchorY': anchorY,
        'zIndex': zIndex,
        'minZoom': minZoom,
        'maxZoom': maxZoom,
        'isVisible': isVisible,
        'opacity': opacity,
      };

  /// Calculates the 4 real-world corner coordinates for the rotated overlay with anchor offsets.
  RotatedCorners get rotatedCorners => GeodesicUtils.calculateRotatedCorners(
        center: center,
        widthMeters: widthMeters,
        heightMeters: heightMeters,
        rotationDegrees: rotationDegrees,
        anchorX: anchorX,
        anchorY: anchorY,
      );

  /// Non-rotated enclosing [LatLngBounds] encompassing the entire rotated footprint.
  LatLngBounds get geographicBounds => rotatedCorners.bounds;

  MapLandmarkOverlay copyWith({
    String? id,
    String? name,
    String? assetPath,
    LatLng? center,
    double? widthMeters,
    double? heightMeters,
    double? rotationDegrees,
    double? anchorX,
    double? anchorY,
    int? zIndex,
    double? minZoom,
    double? maxZoom,
    bool? isVisible,
    double? opacity,
    VoidCallback? onTap,
  }) {
    return MapLandmarkOverlay(
      id: id ?? this.id,
      name: name ?? this.name,
      assetPath: assetPath ?? this.assetPath,
      center: center ?? this.center,
      widthMeters: widthMeters ?? this.widthMeters,
      heightMeters: heightMeters ?? this.heightMeters,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      anchorX: anchorX ?? this.anchorX,
      anchorY: anchorY ?? this.anchorY,
      zIndex: zIndex ?? this.zIndex,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      isVisible: isVisible ?? this.isVisible,
      opacity: opacity ?? this.opacity,
      onTap: onTap ?? this.onTap,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapLandmarkOverlay &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          assetPath == other.assetPath &&
          center == other.center &&
          widthMeters == other.widthMeters &&
          heightMeters == other.heightMeters &&
          rotationDegrees == other.rotationDegrees &&
          anchorX == other.anchorX &&
          anchorY == other.anchorY &&
          zIndex == other.zIndex &&
          minZoom == other.minZoom &&
          maxZoom == other.maxZoom &&
          isVisible == other.isVisible &&
          opacity == other.opacity;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        assetPath,
        center,
        widthMeters,
        heightMeters,
        rotationDegrees,
        anchorX,
        anchorY,
        zIndex,
        minZoom,
        maxZoom,
        isVisible,
        opacity,
      );

  @override
  String toString() =>
      'MapLandmarkOverlay(id: $id, name: $name, center: $center, ${widthMeters}m x ${heightMeters}m, rot: $rotationDegrees°, anchor: ($anchorX, $anchorY))';

  static final List<MapLandmarkOverlay> _cached = [];

  /// Caches loaded landmark overlays in memory
  static void cacheOverlays(Iterable<MapLandmarkOverlay> overlays) {
    _cached.clear();
    _cached.addAll(overlays);
  }

  /// Initializes landmark overlays from seed bundle if not already loaded
  static void ensureInitialized() {
    if (_cached.isNotEmpty) return;
    try {
      final file = File('assets/data/colosseum_seed.json');
      if (file.existsSync()) {
        final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final raw = json['landmarks'] as List<dynamic>? ?? [];
        final list = raw
            .map((lm) => MapLandmarkOverlay.fromJson(Map<String, dynamic>.from(lm as Map)))
            .toList();
        cacheOverlays(list);
      }
    } catch (_) {}
  }

  /// Returns all cached landmark overlays
  static List<MapLandmarkOverlay> get all {
    ensureInitialized();
    return List.unmodifiable(_cached);
  }
}
