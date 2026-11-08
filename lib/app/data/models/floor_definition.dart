import 'dart:convert';
import 'dart:io';
import 'package:latlong2/latlong.dart';

import '../models/itinerary_segment_model.dart';
import '../models/viewpoint_model.dart';

/// Single source of truth data model representing a monument floor or area level,
/// its architectural configuration, viewpoints, guided itinerary, and calibration.
class FloorDefinition {
  final String id;
  final String landmarkId;
  final String displayName;
  final String shortName;
  final String floorNumberLabel;
  final List<ViewpointModel> viewpoints;
  final List<ItinerarySegmentModel> itinerary;
  final LatLng center;
  final double defaultZoom;
  final double mapNorthOffsetDegrees;
  final String mapAsset;
  final String semanticLabel;

  const FloorDefinition({
    required this.id,
    this.landmarkId = 'colosseum',
    required this.displayName,
    required this.shortName,
    required this.floorNumberLabel,
    required this.viewpoints,
    required this.itinerary,
    this.center = const LatLng(41.890210, 12.492231),
    this.defaultZoom = 18.6,
    this.mapNorthOffsetDegrees = -20.0,
    required this.mapAsset,
    required this.semanticLabel,
  });

  factory FloorDefinition.fromJson(Map<String, dynamic> json) {
    LatLng center = const LatLng(41.890210, 12.492231);
    if (json['center'] is Map) {
      final c = json['center'] as Map;
      center = LatLng(
        (c['latitude'] as num?)?.toDouble() ?? 41.890210,
        (c['longitude'] as num?)?.toDouble() ?? 12.492231,
      );
    } else if (json['calibration'] is Map) {
      final calib = json['calibration'] as Map;
      if (calib['centerCoordinates'] is Map) {
        final c = calib['centerCoordinates'] as Map;
        center = LatLng(
          (c['latitude'] as num?)?.toDouble() ?? 41.890210,
          (c['longitude'] as num?)?.toDouble() ?? 12.492231,
        );
      }
    }

    final rawVps = json['viewpoints'] as List<dynamic>? ?? [];
    final vps = rawVps
        .map((v) => ViewpointModel.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList();

    final rawItinerary = json['itinerary'] as List<dynamic>? ?? [];
    final itinerary = rawItinerary
        .map((i) =>
            ItinerarySegmentModel.fromJson(Map<String, dynamic>.from(i as Map)))
        .toList();

    final rawFloorId = json['id'] as String? ?? json['floorId'] as String? ?? '';
    final parsedLandmarkId = landmarkIdForFloorId(
      rawFloorId,
      json['landmarkId'] as String? ?? json['landmarkCode'] as String?,
    );

    final calibObj = json['calibration'] is Map ? (json['calibration'] as Map) : null;
    final mapAssetObj = json['mapAsset'] is Map ? (json['mapAsset'] as Map) : null;

    final defaultZoom = (json['defaultZoom'] as num?)?.toDouble() ??
        (calibObj?['defaultZoom'] as num?)?.toDouble() ??
        18.6;

    final mapNorthOffset = (json['mapNorthOffsetDegrees'] as num?)?.toDouble() ??
        (calibObj?['mapNorthOffsetDegrees'] as num?)?.toDouble() ??
        -20.0;

    final assetString = (mapAssetObj?['assetId'] as String?) ??
        (json['mapAsset'] as String?) ??
        'level_1_map';

    return FloorDefinition(
      id: json['id'] as String? ?? json['floorId'] as String? ?? 'floor_underground',
      landmarkId: parsedLandmarkId,
      displayName: json['displayName'] as String? ?? json['floorName'] as String? ?? '',
      shortName: json['shortName'] as String? ?? '',
      floorNumberLabel: json['floorNumberLabel'] as String? ?? '',
      viewpoints: vps,
      itinerary: itinerary,
      center: center,
      defaultZoom: defaultZoom,
      mapNorthOffsetDegrees: mapNorthOffset,
      mapAsset: assetString,
      semanticLabel: json['semanticLabel'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'floorId': id,
        'landmarkId': landmarkId,
        'displayName': displayName,
        'shortName': shortName,
        'floorNumberLabel': floorNumberLabel,
        'viewpoints': viewpoints.map((v) => v.toJson()).toList(),
        'itinerary': itinerary.map((i) => i.toJson()).toList(),
        'center': {
          'latitude': center.latitude,
          'longitude': center.longitude,
        },
        'defaultZoom': defaultZoom,
        'mapNorthOffsetDegrees': mapNorthOffsetDegrees,
        'mapAsset': mapAsset,
        'semanticLabel': semanticLabel,
      };

  FloorDefinition copyWith({
    String? id,
    String? landmarkId,
    String? displayName,
    String? shortName,
    String? floorNumberLabel,
    List<ViewpointModel>? viewpoints,
    List<ItinerarySegmentModel>? itinerary,
    LatLng? center,
    double? defaultZoom,
    double? mapNorthOffsetDegrees,
    String? mapAsset,
    String? semanticLabel,
  }) {
    return FloorDefinition(
      id: id ?? this.id,
      landmarkId: landmarkId ?? this.landmarkId,
      displayName: displayName ?? this.displayName,
      shortName: shortName ?? this.shortName,
      floorNumberLabel: floorNumberLabel ?? this.floorNumberLabel,
      viewpoints: viewpoints ?? this.viewpoints,
      itinerary: itinerary ?? this.itinerary,
      center: center ?? this.center,
      defaultZoom: defaultZoom ?? this.defaultZoom,
      mapNorthOffsetDegrees:
          mapNorthOffsetDegrees ?? this.mapNorthOffsetDegrees,
      mapAsset: mapAsset ?? this.mapAsset,
      semanticLabel: semanticLabel ?? this.semanticLabel,
    );
  }

  String get landmarkName => landmarkNameFor(landmarkId);

  static String landmarkNameFor(String? landmarkId) {
    if (landmarkId == null) return 'Colosseum';
    final normalized = landmarkId.toLowerCase().trim();
    if (normalized.contains('arch')) {
      return 'Arch of Constantine';
    }
    if (normalized.contains('ludus')) {
      return 'Ludus Magnus';
    }
    if (normalized.contains('venus') || normalized.contains('temple')) {
      return 'Temple of Venus and Rome';
    }
    if (normalized.contains('forum')) {
      return 'Roman Forum';
    }
    return 'Colosseum';
  }

  /// Effective number of tour viewpoints / stops for this floor.
  int get stopsCount {
    if (viewpoints.isNotEmpty) return viewpoints.length;
    return defaultStopsCountFor(id);
  }

  /// Default calibrated stop count for each monument level.
  static int defaultStopsCountFor(String? floorId) {
    switch (floorId?.toLowerCase().trim()) {
      case 'floor_underground':
        return 7;
      case 'floor_1':
        return 9;
      case 'floor_2':
        return 7;
      case 'floor_3':
        return 5;
      case 'arch_ground':
        return 4;
      case 'arch_attic':
        return 2;
      case 'ludus_arena':
        return 3;
      case 'ludus_tunnel':
        return 2;
      case 'temple_east':
        return 3;
      case 'temple_west':
        return 2;
      case 'forum_via_sacra':
        return 4;
      case 'forum_senate_rostra':
        return 3;
      default:
        return 0;
    }
  }

  /// Default minimal fallback floor while repository data is loading
  static const FloorDefinition defaultFloor = FloorDefinition(
    id: 'floor_underground',
    landmarkId: 'colosseum',
    displayName: 'Underground (Hypogeum)',
    shortName: 'Underground',
    floorNumberLabel: 'Underground',
    viewpoints: [],
    itinerary: [],
    mapAsset: 'underground_map',
    semanticLabel: 'Underground Hypogeum, current floor',
  );

  static const FloorDefinition defaultFloor1 = FloorDefinition(
    id: 'floor_1',
    landmarkId: 'colosseum',
    displayName: 'Level 1',
    shortName: 'Level 1',
    floorNumberLabel: '1',
    viewpoints: [],
    itinerary: [],
    center: LatLng(41.89021, 12.492231),
    mapAsset: 'floor_1',
    semanticLabel: 'Colosseum Level 1',
  );

  static const FloorDefinition defaultFloor2 = FloorDefinition(
    id: 'floor_2',
    landmarkId: 'colosseum',
    displayName: 'Level 2',
    shortName: 'Level 2',
    floorNumberLabel: '2',
    viewpoints: [],
    itinerary: [],
    center: LatLng(41.89021, 12.492231),
    mapAsset: 'floor_2',
    semanticLabel: 'Colosseum Level 2',
  );

  static const FloorDefinition defaultFloor3 = FloorDefinition(
    id: 'floor_3',
    landmarkId: 'colosseum',
    displayName: 'Level 3',
    shortName: 'Level 3',
    floorNumberLabel: '3',
    viewpoints: [],
    itinerary: [],
    center: LatLng(41.89021, 12.492231),
    mapAsset: 'floor_3',
    semanticLabel: 'Colosseum Level 3',
  );

  /// Default minimal fallback floors for Arch of Constantine
  static const FloorDefinition defaultArchFloor = FloorDefinition(
    id: 'arch_ground',
    landmarkId: 'arch_of_constantine',
    displayName: 'Plaza & Constantinian Reliefs',
    shortName: 'Ground',
    floorNumberLabel: '1',
    viewpoints: [],
    itinerary: [],
    center: LatLng(41.889762, 12.490667),
    defaultZoom: 19.0,
    mapAsset: 'arch_ground',
    semanticLabel: 'Arch of Constantine Ground Level',
  );

  static const FloorDefinition defaultArchAtticFloor = FloorDefinition(
    id: 'arch_attic',
    landmarkId: 'arch_of_constantine',
    displayName: 'Attic & Upper Terrace',
    shortName: 'Attic',
    floorNumberLabel: '2',
    viewpoints: [],
    itinerary: [],
    center: LatLng(41.889762, 12.490667),
    defaultZoom: 19.0,
    mapAsset: 'arch_attic',
    semanticLabel: 'Arch of Constantine Attic Level',
  );

  /// Default minimal fallback floors for Ludus Magnus
  static const FloorDefinition defaultLudusFloor = FloorDefinition(
    id: 'ludus_arena',
    landmarkId: 'ludus_magnus',
    displayName: 'Gladiator Arena & Cavea',
    shortName: 'Arena',
    floorNumberLabel: '1',
    viewpoints: [],
    itinerary: [],
    center: LatLng(41.88995, 12.49505),
    defaultZoom: 19.0,
    mapAsset: 'ludus_arena',
    semanticLabel: 'Ludus Magnus Gladiator Arena',
  );

  static const FloorDefinition defaultLudusTunnelFloor = FloorDefinition(
    id: 'ludus_tunnel',
    landmarkId: 'ludus_magnus',
    displayName: 'Subterranean Tunnel to Colosseum',
    shortName: 'Tunnel',
    floorNumberLabel: '2',
    viewpoints: [],
    itinerary: [],
    center: LatLng(41.88995, 12.49505),
    defaultZoom: 19.0,
    mapAsset: 'ludus_tunnel',
    semanticLabel: 'Ludus Magnus Tunnel Level',
  );

  /// Default minimal fallback floors for Temple of Venus and Rome
  static const FloorDefinition defaultTempleFloor = FloorDefinition(
    id: 'temple_east',
    landmarkId: 'temple_venus_rome',
    displayName: 'Venus Cella & East Terrace',
    shortName: 'East (Venus)',
    floorNumberLabel: '1',
    viewpoints: [],
    itinerary: [],
    center: LatLng(41.8908, 12.4902),
    defaultZoom: 19.0,
    mapAsset: 'temple_east',
    semanticLabel: 'Temple of Venus and Rome East Terrace',
  );

  static const FloorDefinition defaultTempleWestFloor = FloorDefinition(
    id: 'temple_west',
    landmarkId: 'temple_venus_rome',
    displayName: 'Roma Cella & Forum Belvedere',
    shortName: 'West (Roma)',
    floorNumberLabel: '2',
    viewpoints: [],
    itinerary: [],
    center: LatLng(41.89088, 12.4892),
    defaultZoom: 19.0,
    mapAsset: 'temple_west',
    semanticLabel: 'Temple of Venus and Rome West Terrace',
  );

  /// Default minimal fallback floors for Roman Forum
  static const FloorDefinition defaultForumFloor = FloorDefinition(
    id: 'forum_via_sacra',
    landmarkId: 'roman_forum',
    displayName: 'Via Sacra & Triumphal Way',
    shortName: 'Via Sacra',
    floorNumberLabel: '1',
    viewpoints: [],
    itinerary: [],
    center: LatLng(41.8914, 12.4874),
    defaultZoom: 19.0,
    mapAsset: 'forum_via_sacra',
    semanticLabel: 'Roman Forum Via Sacra',
  );

  static const FloorDefinition defaultForumSenateFloor = FloorDefinition(
    id: 'forum_senate_rostra',
    landmarkId: 'roman_forum',
    displayName: 'Senate, Curia & The Rostra',
    shortName: 'Curia & Rostra',
    floorNumberLabel: '2',
    viewpoints: [],
    itinerary: [],
    center: LatLng(41.8924, 12.4849),
    defaultZoom: 19.0,
    mapAsset: 'forum_senate_rostra',
    semanticLabel: 'Roman Forum Senate & Rostra',
  );

  /// All 12 canonical initial monument floor levels
  static const List<FloorDefinition> defaultAllFloors = [
    defaultFloor,
    defaultFloor1,
    defaultFloor2,
    defaultFloor3,
    defaultArchFloor,
    defaultArchAtticFloor,
    defaultLudusFloor,
    defaultLudusTunnelFloor,
    defaultTempleFloor,
    defaultTempleWestFloor,
    defaultForumFloor,
    defaultForumSenateFloor,
  ];

  static final Map<String, FloorDefinition> _cachedFloors = {
    for (final f in defaultAllFloors) f.id: f,
  };

  /// Normalizes variations of landmark ID (e.g. 'temple_of_venus_and_rome' -> 'temple_venus_rome')
  static String normalizeLandmarkId(String? landmarkId) {
    if (landmarkId == null) return 'colosseum';
    final normalized = landmarkId.toLowerCase().trim();
    if (normalized.contains('arch')) return 'arch_of_constantine';
    if (normalized.contains('ludus')) return 'ludus_magnus';
    if (normalized.contains('venus') || normalized.contains('temple')) {
      return 'temple_venus_rome';
    }
    if (normalized.contains('forum')) return 'roman_forum';
    return 'colosseum';
  }

  /// Infers the canonical landmark ID from a floor ID with strict prefix enforcement,
  /// overriding any corrupted or legacy landmark ID (e.g. 'arch_ground' with 'colosseum').
  static String landmarkIdForFloorId(String? floorId, [String? fallbackLandmarkId]) {
    if (floorId != null) {
      final lower = floorId.toLowerCase().trim();
      if (lower.startsWith('arch_') || lower.contains('arch')) {
        return 'arch_of_constantine';
      }
      if (lower.startsWith('ludus_') || lower.contains('ludus')) {
        return 'ludus_magnus';
      }
      if (lower.startsWith('temple_') || lower.contains('temple') || lower.contains('venus')) {
        return 'temple_venus_rome';
      }
      if (lower.startsWith('forum_') || lower.contains('forum') || lower.contains('rostra') || lower.contains('sacra')) {
        return 'roman_forum';
      }
      if (lower.startsWith('floor_') || lower.contains('hypogeum')) {
        return 'colosseum';
      }
    }
    if (fallbackLandmarkId != null && fallbackLandmarkId.trim().isNotEmpty) {
      return normalizeLandmarkId(fallbackLandmarkId);
    }
    return 'colosseum';
  }

  /// Resolves the default entrance floor definition for a landmark
  static FloorDefinition defaultFloorForLandmark(String? landmarkId) {
    final normalized = normalizeLandmarkId(landmarkId);
    switch (normalized) {
      case 'arch_of_constantine':
        return defaultArchFloor;
      case 'ludus_magnus':
        return defaultLudusFloor;
      case 'temple_venus_rome':
        return defaultTempleFloor;
      case 'roman_forum':
        return defaultForumFloor;
      case 'colosseum':
      default:
        return defaultFloor;
    }
  }

  /// Caches loaded floor definitions in memory
  static void cacheFloors(Iterable<FloorDefinition> floors, {bool replaceAll = false}) {
    if (replaceAll) {
      _cachedFloors.clear();
    }
    for (final f in floors) {
      _cachedFloors[f.id] = f;
    }
  }

  /// Updates the viewpoints for a specific floor in the in-memory cache.
  static void updateFloorViewpoints(String floorId, List<ViewpointModel> viewpoints) {
    final existing = _cachedFloors[floorId];
    if (existing != null) {
      _cachedFloors[floorId] = existing.copyWith(viewpoints: viewpoints);
    }
  }

  /// Parses complete FloorDefinitions from a tour bundle or seed JSON, correctly
  /// mapping top-level viewpoints and itineraries into their respective floors.
  static List<FloorDefinition> parseFloorsFromBundleJson(Map<String, dynamic> json) {
    final rawFloors = json['floors'] as List<dynamic>? ?? [];
    if (rawFloors.isEmpty) return const [];

    final rawVps = json['viewpoints'] as List<dynamic>? ?? [];
    final allViewpoints = rawVps
        .map((v) => ViewpointModel.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList();

    final rawItineraries = json['itineraries'] as List<dynamic>? ?? [];

    return rawFloors.map<FloorDefinition>((fl) {
      final fMap = Map<String, dynamic>.from(fl as Map);
      final floorId =
          fMap['floorId'] as String? ?? fMap['id'] as String? ?? '';

      List<dynamic> floorVps;
      if (fMap['viewpoints'] is List && (fMap['viewpoints'] as List).isNotEmpty) {
        floorVps = fMap['viewpoints'] as List;
      } else {
        floorVps = allViewpoints
            .where((v) => v.floorId == floorId)
            .map((v) => v.toJson())
            .toList();
      }

      List<dynamic> floorItin;
      if (fMap['itinerary'] is List && (fMap['itinerary'] as List).isNotEmpty) {
        floorItin = fMap['itinerary'] as List;
      } else {
        floorItin = rawItineraries
            .where((i) => (i as Map)['floorId'] == floorId)
            .map((i) => Map<String, dynamic>.from(i as Map))
            .toList();
      }

      final floorLandmarkId = landmarkIdForFloorId(
        floorId,
        fMap['landmarkId'] as String? ?? fMap['landmarkCode'] as String?,
      );

      return FloorDefinition.fromJson({
        ...fMap,
        'id': floorId,
        'landmarkId': floorLandmarkId,
        'viewpoints': floorVps,
        'itinerary': floorItin,
      });
    }).toList();
  }

  /// Initializes floor definitions from seed bundle if not already loaded
  static void ensureInitialized() {
    if (_cachedFloors.values.any((f) => f.viewpoints.isNotEmpty)) return;
    try {
      final file = File('assets/data/colosseum_seed.json');
      if (file.existsSync()) {
        final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final floors = parseFloorsFromBundleJson(json);
        cacheFloors(floors);
      }
    } catch (_) {}
  }

  /// All monumental levels across all landmarks
  static List<FloorDefinition> get allFloors {
    ensureInitialized();
    return _cachedFloors.values.toList();
  }

  /// Convenience getter for default Underground floor
  static FloorDefinition get underground => fromId('floor_underground');

  /// Finds matching FloorDefinition by id across loaded floors, with fallback.
  static FloorDefinition fromId(String? id, [List<FloorDefinition>? loadedFloors]) {
    if (loadedFloors != null && loadedFloors.isNotEmpty) {
      final normalized = id?.toLowerCase().trim();
      for (final floor in loadedFloors) {
        if (floor.id.toLowerCase() == normalized) {
          return floor;
        }
      }
    }

    ensureInitialized();
    if (id != null) {
      final normalized = id.toLowerCase().trim();
      for (final floor in _cachedFloors.values) {
        if (floor.id.toLowerCase() == normalized) {
          return floor;
        }
      }
      // Fuzzy matching for backwards compatibility
      if (normalized.contains('underground') || normalized == '0') {
        return _cachedFloors['floor_underground'] ?? defaultFloor;
      }
      if (normalized.contains('arch_attic') || normalized.contains('attic')) {
        return _cachedFloors['arch_attic'] ?? defaultArchAtticFloor;
      }
      if (normalized.contains('arch')) {
        return _cachedFloors['arch_ground'] ?? defaultArchFloor;
      }
      if (normalized.contains('ludus_tunnel') || normalized.contains('tunnel')) {
        return _cachedFloors['ludus_tunnel'] ?? defaultLudusTunnelFloor;
      }
      if (normalized.contains('ludus')) {
        return _cachedFloors['ludus_arena'] ?? defaultLudusFloor;
      }
      if (normalized.contains('temple_west') || normalized.contains('roma')) {
        return _cachedFloors['temple_west'] ?? defaultTempleWestFloor;
      }
      if (normalized.contains('temple') || normalized.contains('venus')) {
        return _cachedFloors['temple_east'] ?? defaultTempleFloor;
      }
      if (normalized.contains('senate') || normalized.contains('curia') || normalized.contains('rostra')) {
        return _cachedFloors['forum_senate_rostra'] ?? defaultForumSenateFloor;
      }
      if (normalized.contains('forum')) {
        return _cachedFloors['forum_via_sacra'] ?? defaultForumFloor;
      }
      if (normalized.contains('1') || normalized == 'level1' || normalized == 'floor_1') {
        return _cachedFloors['floor_1'] ?? defaultFloor1;
      }
      if (normalized.contains('2') || normalized == 'level2' || normalized == 'floor_2') {
        return _cachedFloors['floor_2'] ?? defaultFloor2;
      }
      if (normalized.contains('3') || normalized == 'level3' || normalized == 'floor_3') {
        return _cachedFloors['floor_3'] ?? defaultFloor3;
      }
    }

    return defaultFloor;
  }

  /// Filters loaded floors for a specific landmark ID.
  static List<FloorDefinition> floorsForLandmark(String? landmarkId, [List<FloorDefinition>? loadedFloors]) {
    final normalizedLandmarkId = normalizeLandmarkId(landmarkId);
    if (loadedFloors != null && loadedFloors.isNotEmpty) {
      final list = loadedFloors
          .where((f) => normalizeLandmarkId(landmarkIdForFloorId(f.id, f.landmarkId)) == normalizedLandmarkId)
          .toList();
      if (list.isNotEmpty) return list;
    }
    ensureInitialized();
    final list = _cachedFloors.values
        .where((f) => normalizeLandmarkId(landmarkIdForFloorId(f.id, f.landmarkId)) == normalizedLandmarkId)
        .toList();
    if (list.isNotEmpty) return list;
    return [defaultFloorForLandmark(normalizedLandmarkId)];
  }

  /// Resolves the initial entrance floor for a given landmark.
  static FloorDefinition initialFloorForLandmark(String? landmarkId, [List<FloorDefinition>? loadedFloors]) {
    final list = floorsForLandmark(landmarkId, loadedFloors);
    return list.isNotEmpty ? list.first : defaultFloorForLandmark(landmarkId);
  }
}
