import 'package:latlong2/latlong.dart';

import '../models/itinerary_segment_model.dart';
import '../models/viewpoint_model.dart';
import '../providers/colosseum_tour_data.dart';
import '../providers/landmarks_tour_data.dart';

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

    final parsedLandmarkId = json['landmarkId'] as String? ??
        json['landmarkCode'] as String? ??
        'colosseum';

    return FloorDefinition(
      id: json['id'] as String? ?? json['floorId'] as String? ?? '',
      landmarkId: parsedLandmarkId,
      displayName: json['displayName'] as String? ?? '',
      shortName: json['shortName'] as String? ?? '',
      floorNumberLabel: json['floorNumberLabel'] as String? ?? '',
      viewpoints: vps,
      itinerary: itinerary,
      center: center,
      defaultZoom: (json['defaultZoom'] as num?)?.toDouble() ?? 18.6,
      mapNorthOffsetDegrees:
          (json['mapNorthOffsetDegrees'] as num?)?.toDouble() ?? -20.0,
      mapAsset: json['mapAsset'] as String? ?? 'level_1_map',
      semanticLabel: json['semanticLabel'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'floorId': id,
        'landmarkId': landmarkId,
        'landmarkCode': landmarkId,
        'displayName': displayName,
        'shortName': shortName,
        'floorNumberLabel': floorNumberLabel,
        'semanticLabel': semanticLabel,
        'center': {
          'latitude': center.latitude,
          'longitude': center.longitude,
        },
        'defaultZoom': defaultZoom,
        'mapNorthOffsetDegrees': mapNorthOffsetDegrees,
        'mapAsset': mapAsset,
        'viewpoints': viewpoints.map((v) => v.toJson()).toList(),
        'itinerary': itinerary.map((i) => i.toJson()).toList(),
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

  // ===========================================================================
  // COLOSSEUM FLOORS (4 LEVELS)
  // ===========================================================================

  static const FloorDefinition underground = FloorDefinition(
    id: 'floor_underground',
    landmarkId: 'colosseum',
    displayName: 'Underground (Hypogeum)',
    shortName: 'Underground',
    floorNumberLabel: 'Underground',
    viewpoints: ColosseumTourData.undergroundViewpoints,
    itinerary: ColosseumTourData.undergroundItinerary,
    mapAsset: 'underground_map',
    semanticLabel: 'Underground Hypogeum, current floor',
  );

  static const FloorDefinition level1 = FloorDefinition(
    id: 'floor_1',
    landmarkId: 'colosseum',
    displayName: 'Level 1',
    shortName: 'Level 1',
    floorNumberLabel: 'Floor 1',
    viewpoints: ColosseumTourData.level1Viewpoints,
    itinerary: ColosseumTourData.level1Itinerary,
    mapAsset: 'level_1_map',
    semanticLabel: 'Level 1, current floor',
  );

  static const FloorDefinition level2 = FloorDefinition(
    id: 'floor_2',
    landmarkId: 'colosseum',
    displayName: 'Level 2',
    shortName: 'Level 2',
    floorNumberLabel: 'Floor 2',
    viewpoints: ColosseumTourData.level2Viewpoints,
    itinerary: ColosseumTourData.level2Itinerary,
    mapAsset: 'level_2_map',
    semanticLabel: 'Level 2, current floor',
  );

  static const FloorDefinition level3 = FloorDefinition(
    id: 'floor_3',
    landmarkId: 'colosseum',
    displayName: 'Level 3',
    shortName: 'Level 3',
    floorNumberLabel: 'Floor 3',
    viewpoints: ColosseumTourData.level3Viewpoints,
    itinerary: ColosseumTourData.level3Itinerary,
    mapAsset: 'level_3_map',
    semanticLabel: 'Level 3, current floor',
  );

  // ===========================================================================
  // ARCH OF CONSTANTINE FLOORS (2 LEVELS)
  // ===========================================================================

  static const FloorDefinition archGround = FloorDefinition(
    id: 'arch_ground',
    landmarkId: 'arch_of_constantine',
    displayName: 'Plaza & Constantinian Reliefs',
    shortName: 'Ground',
    floorNumberLabel: 'Ground Level',
    center: LatLng(41.889762, 12.490667),
    defaultZoom: 19.5,
    mapNorthOffsetDegrees: 0.0,
    mapAsset: 'assets/logo/Arch of Constantine.png',
    viewpoints: LandmarksTourData.archGroundViewpoints,
    itinerary: LandmarksTourData.archGroundItinerary,
    semanticLabel: 'Arch of Constantine Ground Plaza, current floor',
  );

  static const FloorDefinition archAttic = FloorDefinition(
    id: 'arch_attic',
    landmarkId: 'arch_of_constantine',
    displayName: 'Attic & Upper Terrace',
    shortName: 'Attic',
    floorNumberLabel: 'Attic Level',
    center: LatLng(41.889762, 12.490667),
    defaultZoom: 19.5,
    mapNorthOffsetDegrees: 0.0,
    mapAsset: 'assets/logo/Arch of Constantine.png',
    viewpoints: LandmarksTourData.archAtticViewpoints,
    itinerary: LandmarksTourData.archAtticItinerary,
    semanticLabel: 'Arch of Constantine Attic Terrace, current floor',
  );

  // ===========================================================================
  // LUDUS MAGNUS FLOORS (2 LEVELS)
  // ===========================================================================

  static const FloorDefinition ludusArena = FloorDefinition(
    id: 'ludus_arena',
    landmarkId: 'ludus_magnus',
    displayName: 'Gladiator Arena & Cavea',
    shortName: 'Arena',
    floorNumberLabel: 'Arena Floor',
    center: LatLng(41.890450, 12.495100),
    defaultZoom: 19.2,
    mapNorthOffsetDegrees: 0.0,
    mapAsset: 'assets/logo/Ludus Magnus.png',
    viewpoints: LandmarksTourData.ludusArenaViewpoints,
    itinerary: LandmarksTourData.ludusArenaItinerary,
    semanticLabel: 'Ludus Magnus Training Arena, current floor',
  );

  static const FloorDefinition ludusSubterranean = FloorDefinition(
    id: 'ludus_tunnel',
    landmarkId: 'ludus_magnus',
    displayName: 'Subterranean Tunnel to Colosseum',
    shortName: 'Tunnel',
    floorNumberLabel: 'Subterranean',
    center: LatLng(41.890450, 12.495100),
    defaultZoom: 19.2,
    mapNorthOffsetDegrees: 0.0,
    mapAsset: 'assets/logo/Ludus Magnus.png',
    viewpoints: LandmarksTourData.ludusSubterraneanViewpoints,
    itinerary: LandmarksTourData.ludusSubterraneanItinerary,
    semanticLabel: 'Ludus Magnus Subterranean Tunnel, current floor',
  );

  // ===========================================================================
  // TEMPLE OF VENUS AND ROME FLOORS (2 LEVELS)
  // ===========================================================================

  static const FloorDefinition templeEast = FloorDefinition(
    id: 'temple_east',
    landmarkId: 'temple_venus_rome',
    displayName: 'Venus Cella & East Terrace',
    shortName: 'East (Venus)',
    floorNumberLabel: 'East Terrace',
    center: LatLng(41.890900, 12.489100),
    defaultZoom: 18.8,
    mapNorthOffsetDegrees: 0.0,
    mapAsset: 'assets/logo/Temple of Venus and Rome.png',
    viewpoints: LandmarksTourData.templeEastViewpoints,
    itinerary: LandmarksTourData.templeEastItinerary,
    semanticLabel: 'Temple of Venus and Rome East Cella, current floor',
  );

  static const FloorDefinition templeWest = FloorDefinition(
    id: 'temple_west',
    landmarkId: 'temple_venus_rome',
    displayName: 'Roma Cella & Forum Belvedere',
    shortName: 'West (Roma)',
    floorNumberLabel: 'West Terrace',
    center: LatLng(41.890900, 12.489100),
    defaultZoom: 18.8,
    mapNorthOffsetDegrees: 0.0,
    mapAsset: 'assets/logo/Temple of Venus and Rome.png',
    viewpoints: LandmarksTourData.templeWestViewpoints,
    itinerary: LandmarksTourData.templeWestItinerary,
    semanticLabel: 'Temple of Venus and Rome West Cella, current floor',
  );

  // ===========================================================================
  // ROMAN FORUM FLOORS (2 LEVELS)
  // ===========================================================================

  static const FloorDefinition forumViaSacra = FloorDefinition(
    id: 'forum_via_sacra',
    landmarkId: 'roman_forum',
    displayName: 'Via Sacra & Triumphal Way',
    shortName: 'Via Sacra',
    floorNumberLabel: 'Via Sacra',
    center: LatLng(41.892050, 12.486600),
    defaultZoom: 17.5,
    mapNorthOffsetDegrees: 0.0,
    mapAsset: 'assets/logo/Roman Forum.png',
    viewpoints: LandmarksTourData.forumViaSacraViewpoints,
    itinerary: LandmarksTourData.forumViaSacraItinerary,
    semanticLabel: 'Roman Forum Via Sacra, current floor',
  );

  static const FloorDefinition forumSenateRostra = FloorDefinition(
    id: 'forum_senate_rostra',
    landmarkId: 'roman_forum',
    displayName: 'Senate, Curia & The Rostra',
    shortName: 'Curia & Rostra',
    floorNumberLabel: 'Political Core',
    center: LatLng(41.892050, 12.486600),
    defaultZoom: 17.5,
    mapNorthOffsetDegrees: 0.0,
    mapAsset: 'assets/logo/Roman Forum.png',
    viewpoints: LandmarksTourData.forumSenateViewpoints,
    itinerary: LandmarksTourData.forumSenateItinerary,
    semanticLabel: 'Roman Forum Curia and Rostra, current floor',
  );

  // ===========================================================================
  // REGISTRY & LOOKUP HELPERS
  // ===========================================================================

  /// All monumental levels across all 5 landmarks.
  static const List<FloorDefinition> allFloors = [
    underground,
    level1,
    level2,
    level3,
    archGround,
    archAttic,
    ludusArena,
    ludusSubterranean,
    templeEast,
    templeWest,
    forumViaSacra,
    forumSenateRostra,
  ];

  /// Returns all available levels/floors for a specific landmark ID.
  static List<FloorDefinition> floorsForLandmark(String? landmarkId) {
    if (landmarkId == null) return const [underground, level1, level2, level3];
    final normalized = landmarkId.toLowerCase().trim();
    if (normalized.contains('arch')) {
      return const [archGround, archAttic];
    }
    if (normalized.contains('ludus')) {
      return const [ludusArena, ludusSubterranean];
    }
    if (normalized.contains('venus') || normalized.contains('temple')) {
      return const [templeEast, templeWest];
    }
    if (normalized.contains('forum')) {
      return const [forumViaSacra, forumSenateRostra];
    }
    return const [underground, level1, level2, level3];
  }

  /// Returns the initial entrance floor for a given landmark.
  static FloorDefinition initialFloorForLandmark(String? landmarkId) {
    final list = floorsForLandmark(landmarkId);
    return list.isNotEmpty ? list.first : underground;
  }

  /// Finds matching FloorDefinition by id or name across all landmarks, with robust fallback.
  static FloorDefinition fromId(String? id) {
    if (id == null) return underground;
    final normalized = id.toLowerCase().trim();

    for (final floor in allFloors) {
      if (floor.id.toLowerCase() == normalized) {
        return floor;
      }
    }

    if (normalized.contains('underground') || normalized == '0') {
      return underground;
    }
    if (normalized.contains('arch_attic') || normalized.contains('attic')) {
      return archAttic;
    }
    if (normalized.contains('arch')) {
      return archGround;
    }
    if (normalized.contains('ludus_tunnel') || normalized.contains('tunnel')) {
      return ludusSubterranean;
    }
    if (normalized.contains('ludus')) {
      return ludusArena;
    }
    if (normalized.contains('temple_west') || normalized.contains('roma')) {
      return templeWest;
    }
    if (normalized.contains('temple') || normalized.contains('venus')) {
      return templeEast;
    }
    if (normalized.contains('senate') || normalized.contains('curia') || normalized.contains('rostra')) {
      return forumSenateRostra;
    }
    if (normalized.contains('forum')) {
      return forumViaSacra;
    }
    if (normalized.contains('1') || normalized == 'level1' || normalized == 'floor_1') {
      return level1;
    }
    if (normalized.contains('2') || normalized == 'level2' || normalized == 'floor_2') {
      return level2;
    }
    if (normalized.contains('3') || normalized == 'level3' || normalized == 'floor_3') {
      return level3;
    }
    return underground;
  }
}
