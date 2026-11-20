import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../datasources/local/landmark_onboarding_data.dart';
import 'landmark_onboarding_model.dart';

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

  /// Construction era or archaeological period (e.g. '70 – 80 AD (Flavian Dynasty)').
  final String? era;

  /// Commissioning architects or emperors.
  final String? builders;

  /// Concise historical summary for visitor orientation.
  final String? historicalSummary;

  /// Security, baggage, and entry regulations.
  final List<String>? securityGuidelines;

  /// Key architectural tiers and accessible floor highlights.
  final List<String>? levelHighlights;

  /// Spoken audio narration script for automatic proximity greeting.
  final String? audioIntroText;

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
    this.era,
    this.builders,
    this.historicalSummary,
    this.securityGuidelines,
    this.levelHighlights,
    this.audioIntroText,
    this.labelOffset = Offset.zero,
    this.minZoom = 13.0,
    this.maxZoom = 21.0,
    this.onTap,
  });

  /// Resolved onboarding orientation model with live backend overrides and resilient fallbacks.
  LandmarkOnboardingModel get onboardingModel {
    final defaultModel = LandmarkOnboardingData.getForLandmark(id);
    return LandmarkOnboardingModel(
      landmarkId: id,
      title: name.isNotEmpty ? name : defaultModel.title,
      subtitle: (category != null && category!.isNotEmpty)
          ? category!
          : defaultModel.subtitle,
      era: (era != null && era!.isNotEmpty) ? era! : defaultModel.era,
      builders: (builders != null && builders!.isNotEmpty)
          ? builders!
          : defaultModel.builders,
      historicalSummary: (historicalSummary != null && historicalSummary!.isNotEmpty)
          ? historicalSummary!
          : defaultModel.historicalSummary,
      securityGuidelines:
          (securityGuidelines != null && securityGuidelines!.isNotEmpty)
              ? securityGuidelines!
              : defaultModel.securityGuidelines,
      levelHighlights: (levelHighlights != null && levelHighlights!.isNotEmpty)
          ? levelHighlights!
          : defaultModel.levelHighlights,
      audioIntroText: (audioIntroText != null && audioIntroText!.isNotEmpty)
          ? audioIntroText!
          : defaultModel.audioIntroText,
      outerRadiusMeters: defaultModel.outerRadiusMeters,
    );
  }

  /// Canonical set of pre-bundled built-in landmark IDs.
  static const Set<String> builtInIds = {
    'colosseum',
    'arch_of_constantine',
    'ludus_magnus',
    'roman_forum',
    'temple_venus_rome',
  };

  /// Whether this landmark is one of the 5 built-in classical monuments.
  bool get isBuiltIn => builtInIds.contains(id);

  /// Resolves the primary photo card image URL or fallback for the proximity pop-up card.
  String get cardImageUrl {
    if (thumbnailUrl != null && thumbnailUrl!.trim().isNotEmpty) {
      return thumbnailUrl!.trim();
    }
    switch (id) {
      case 'colosseum':
      case 'colosseo':
        return 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=800&auto=format&fit=crop&q=80';
      case 'arch_of_constantine':
      case 'arco_di_costantino':
      case 'arch-of-constantine':
        return 'https://res.cloudinary.com/ddt9rog0e/image/upload/v1793117917/colosseum/landmarks/arch_of_constantine/cards/Arch_of_Constantine__Rome__-_South_side__from_Via_triumphalis_ajiyme.jpg';
      case 'ludus_magnus':
      case 'ludus-magnus':
        return 'https://res.cloudinary.com/ddt9rog0e/image/upload/v1793118097/colosseum/landmarks/ludus_magnus/cards/Ludus_magnus_Rome_2006_en686t.jpg';
      case 'roman_forum':
      case 'foro_romano':
      case 'roman-forum':
        return 'https://res.cloudinary.com/ddt9rog0e/image/upload/v1793117872/colosseum/landmarks/roman_forum/cards/Roman-Forum-1024x683_wq6pg4.jpg';
      case 'temple_venus_rome':
      case 'temple-venus-rome':
      case 'tempio_di_venere_e_roma':
        return 'https://res.cloudinary.com/ddt9rog0e/image/upload/v1793118042/colosseum/landmarks/temple_venus_rome/cards/3823503951_9dff623ffc_o-20261027-222030_wt8dn4.jpg';
      default:
        return assetPath;
    }
  }

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
    final rawThumb = json['thumbnailUrl'] as String? ?? json['cardUrl'] as String?;
    final thumb = (rawThumb != null && rawThumb.trim().isNotEmpty) ? rawThumb.trim() : null;

    final landmarkId = json['code'] as String? ??
        json['id'] as String? ??
        json['landmarkId'] as String? ??
        '';

    final era = json['era'] as String?;
    final builders = json['builders'] as String?;
    final historicalSummary =
        json['historicalSummary'] as String? ?? json['description'] as String?;
    final securityGuidelines = (json['securityGuidelines'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();
    final levelHighlights = (json['levelHighlights'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();
    final audioIntroText = json['audioIntroText'] as String?;

    // Auto-register dynamic onboarding data when received from server
    final hasCustomOnboarding = (json['era'] != null && (json['era'] as String).isNotEmpty) ||
        (json['builders'] != null && (json['builders'] as String).isNotEmpty) ||
        (json['historicalSummary'] != null && (json['historicalSummary'] as String).isNotEmpty) ||
        (json['securityGuidelines'] is List && (json['securityGuidelines'] as List).isNotEmpty) ||
        (json['levelHighlights'] is List && (json['levelHighlights'] as List).isNotEmpty) ||
        (json['audioIntroText'] != null && (json['audioIntroText'] as String).isNotEmpty);

    if (hasCustomOnboarding) {
      final defaultModel = LandmarkOnboardingData.getForLandmark(landmarkId);
      LandmarkOnboardingData.registerOnboarding(
        LandmarkOnboardingModel(
          landmarkId: landmarkId,
          title: (json['name'] as String?)?.isNotEmpty == true
              ? json['name'] as String
              : defaultModel.title,
          subtitle: (category != null && category.isNotEmpty)
              ? category
              : defaultModel.subtitle,
          era: (era != null && era.isNotEmpty) ? era : defaultModel.era,
          builders: (builders != null && builders.isNotEmpty)
              ? builders
              : defaultModel.builders,
          historicalSummary:
              (historicalSummary != null && historicalSummary.isNotEmpty)
                  ? historicalSummary
                  : defaultModel.historicalSummary,
          securityGuidelines:
              (securityGuidelines != null && securityGuidelines.isNotEmpty)
                  ? securityGuidelines
                  : defaultModel.securityGuidelines,
          levelHighlights:
              (levelHighlights != null && levelHighlights.isNotEmpty)
                  ? levelHighlights
                  : defaultModel.levelHighlights,
          audioIntroText: (audioIntroText != null && audioIntroText.isNotEmpty)
              ? audioIntroText
              : defaultModel.audioIntroText,
          outerRadiusMeters: defaultModel.outerRadiusMeters,
        ),
      );
    }

    return LandmarkMarkerModel(
      id: landmarkId,
      name: json['name'] as String? ?? '',
      coordinates: coords,
      color: markerColor,
      category: category,
      imagePath: rawAsset,
      thumbnailUrl: thumb,
      era: era,
      builders: builders,
      historicalSummary: historicalSummary,
      securityGuidelines: securityGuidelines,
      levelHighlights: levelHighlights,
      audioIntroText: audioIntroText,
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
        'era': era,
        'builders': builders,
        'historicalSummary': historicalSummary,
        'securityGuidelines': securityGuidelines,
        'levelHighlights': levelHighlights,
        'audioIntroText': audioIntroText,
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
    String? era,
    String? builders,
    String? historicalSummary,
    List<String>? securityGuidelines,
    List<String>? levelHighlights,
    String? audioIntroText,
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
      era: era ?? this.era,
      builders: builders ?? this.builders,
      historicalSummary: historicalSummary ?? this.historicalSummary,
      securityGuidelines: securityGuidelines ?? this.securityGuidelines,
      levelHighlights: levelHighlights ?? this.levelHighlights,
      audioIntroText: audioIntroText ?? this.audioIntroText,
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
