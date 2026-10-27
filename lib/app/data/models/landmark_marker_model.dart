import 'dart:convert';
import 'dart:io';
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

  /// Asset path or Cloudinary URL to the correspondent logo / badge image for this landmark.
  final String? imagePath;

  /// Optional thumbnail or card image URL / asset path for this landmark.
  final String? thumbnailUrl;

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
    this.imagePath,
    this.thumbnailUrl,
    this.labelOffset = Offset.zero,
    this.minZoom = 13.0,
    this.maxZoom = 21.0,
    this.onTap,
  });

  /// Whether the primary badge image is hosted on a remote network (e.g. Cloudinary).
  bool get isNetworkImage =>
      assetPath.startsWith('http://') || assetPath.startsWith('https://');

  /// Whether the card thumbnail image is hosted on a remote network (e.g. Cloudinary).
  bool get isThumbnailNetworkImage =>
      thumbnailUrl != null &&
      (thumbnailUrl!.startsWith('http://') || thumbnailUrl!.startsWith('https://'));

  /// Resolves the primary image URL or asset path for this landmark's logo badge image.
  String get assetPath {
    if (imagePath != null && imagePath!.isNotEmpty) {
      return imagePath!;
    }
    return fallbackAssetPath;
  }

  /// Bundled fallback asset path from assets/logo for resilient offline execution.
  String get fallbackAssetPath {
    switch (id) {
      case 'colosseum':
        return 'assets/logo/Colosseum.png';
      case 'arch_of_constantine':
        return 'assets/logo/Arch of Constantine.png';
      case 'ludus_magnus':
        return 'assets/logo/Ludus Magnus.png';
      case 'roman_forum':
        return 'assets/logo/Roman Forum.png';
      case 'temple_venus_rome':
        return 'assets/logo/Temple of Venus and Rome.png';
      default:
        return 'assets/logo/$name.png';
    }
  }

  /// Geographic latitude.
  double get latitude => coordinates.latitude;

  /// Geographic longitude.
  double get longitude => coordinates.longitude;

  factory LandmarkMarkerModel.fromJson(Map<String, dynamic> json) {
    LatLng coords = const LatLng(41.89021, 12.492231);
    if (json['center'] is Map) {
      final c = json['center'] as Map;
      coords = LatLng(
        (c['latitude'] as num?)?.toDouble() ?? 41.89021,
        (c['longitude'] as num?)?.toDouble() ?? 12.492231,
      );
    } else if (json['centerCoordinates'] is Map) {
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
    } else if (json['location'] is Map && (json['location'] as Map)['coordinates'] is List) {
      final list = (json['location'] as Map)['coordinates'] as List;
      if (list.length >= 2) {
        coords = LatLng(
          (list[1] as num).toDouble(),
          (list[0] as num).toDouble(),
        );
      }
    }

    final markerObj = json['marker'] is Map ? (json['marker'] as Map) : null;
    Color markerColor = const Color(0xFFDD1110);
    final colorHex = (markerObj?['colorHex'] ?? json['colorHex']) as String?;
    if (colorHex != null) {
      final hex = colorHex.replaceAll('#', '');
      markerColor = Color(int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16));
    } else if (json['color'] is int) {
      markerColor = Color(json['color'] as int);
    }

    final category = (markerObj?['category'] ?? json['category']) as String?;
    final labelOffsetY = (markerObj?['labelOffsetY'] ?? json['labelOffsetY'] ?? 0.0) as num;
    final labelOffsetX = (json['labelOffsetX'] ?? 0.0) as num;
    final disp = json['display'] is Map ? (json['display'] as Map) : null;
    final minZ = (json['minZoom'] as num?)?.toDouble() ??
        (disp?['minZoom'] as num?)?.toDouble() ??
        13.0;
    final maxZ = (json['maxZoom'] as num?)?.toDouble() ??
        (disp?['maxZoom'] as num?)?.toDouble() ??
        21.0;

    final rawAsset = json['assetPath'] as String? ??
        json['imagePath'] as String? ??
        json['logoUrl'] as String?;
    final thumb = json['thumbnailUrl'] as String? ??
        json['cardUrl'] as String?;

    return LandmarkMarkerModel(
      id: json['code'] as String? ??
          json['id'] as String? ??
          json['landmarkId'] as String? ??
          '',
      name: json['name'] as String? ?? '',
      coordinates: coords,
      color: markerColor,
      category: category,
      imagePath: rawAsset,
      thumbnailUrl: thumb,
      labelOffset: Offset(labelOffsetX.toDouble(), labelOffsetY.toDouble()),
      minZoom: minZ,
      maxZoom: maxZ,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'landmarkId': id,
        'code': id,
        'name': name,
        'latitude': coordinates.latitude,
        'longitude': coordinates.longitude,
        'color': color.toARGB32(),
        'category': category,
        'imagePath': imagePath,
        'assetPath': assetPath,
        'thumbnailUrl': thumbnailUrl,
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
    String? imagePath,
    String? thumbnailUrl,
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
      imagePath: imagePath ?? this.imagePath,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
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
          imagePath == other.imagePath &&
          thumbnailUrl == other.thumbnailUrl &&
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
        imagePath,
        thumbnailUrl,
        labelOffset,
        minZoom,
        maxZoom,
      );

  static final List<LandmarkMarkerModel> _cached = [];

  /// Caches loaded landmark markers in memory
  static void cacheMarkers(Iterable<LandmarkMarkerModel> markers) {
    _cached.clear();
    _cached.addAll(markers);
  }

  /// Initializes landmark markers from seed bundle if not already loaded
  static void ensureInitialized() {
    if (_cached.isNotEmpty) return;
    try {
      final file = File('assets/data/colosseum_seed.json');
      if (file.existsSync()) {
        final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final raw = json['landmarks'] as List<dynamic>? ?? [];
        final list = raw
            .map((lm) => LandmarkMarkerModel.fromJson(Map<String, dynamic>.from(lm as Map)))
            .toList();
        cacheMarkers(list);
      }
    } catch (_) {}
  }

  /// Returns all cached landmark markers
  static List<LandmarkMarkerModel> get all {
    ensureInitialized();
    return List.unmodifiable(_cached);
  }
}
