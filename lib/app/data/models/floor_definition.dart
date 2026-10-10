import 'package:latlong2/latlong.dart';

import '../models/itinerary_segment_model.dart';
import '../models/viewpoint_model.dart';
import '../providers/colosseum_tour_data.dart';

/// Single source of truth data model representing a Colosseum floor level,
/// its architectural configuration, viewpoints, guided itinerary, and calibration.
class FloorDefinition {
  final String id;
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

    return FloorDefinition(
      id: json['id'] as String? ?? json['floorId'] as String? ?? '',
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

  /// Canonical definition for Underground (Hypogeum)
  static const FloorDefinition underground = FloorDefinition(
    id: 'floor_underground',
    displayName: 'Underground (Hypogeum)',
    shortName: 'Underground',
    floorNumberLabel: 'Underground',
    viewpoints: ColosseumTourData.undergroundViewpoints,
    itinerary: ColosseumTourData.undergroundItinerary,
    mapAsset: 'underground_map',
    semanticLabel: 'Underground Hypogeum, current floor',
  );

  /// Canonical definition for Level 1 (Ground / Arena)
  static const FloorDefinition level1 = FloorDefinition(
    id: 'floor_1',
    displayName: 'Level 1',
    shortName: 'Level 1',
    floorNumberLabel: 'Floor 1',
    viewpoints: ColosseumTourData.level1Viewpoints,
    itinerary: ColosseumTourData.level1Itinerary,
    mapAsset: 'level_1_map',
    semanticLabel: 'Level 1, current floor',
  );

  /// Canonical definition for Level 2 (First Level)
  static const FloorDefinition level2 = FloorDefinition(
    id: 'floor_2',
    displayName: 'Level 2',
    shortName: 'Level 2',
    floorNumberLabel: 'Floor 2',
    viewpoints: ColosseumTourData.level2Viewpoints,
    itinerary: ColosseumTourData.level2Itinerary,
    mapAsset: 'level_2_map',
    semanticLabel: 'Level 2, current floor',
  );

  /// Canonical definition for Level 3 (Second Level / Belvedere)
  static const FloorDefinition level3 = FloorDefinition(
    id: 'floor_3',
    displayName: 'Level 3',
    shortName: 'Level 3',
    floorNumberLabel: 'Floor 3',
    viewpoints: ColosseumTourData.level3Viewpoints,
    itinerary: ColosseumTourData.level3Itinerary,
    mapAsset: 'level_3_map',
    semanticLabel: 'Level 3, current floor',
  );

  /// All 4 monumental levels in sequential order.
  static const List<FloorDefinition> allFloors = [
    underground,
    level1,
    level2,
    level3,
  ];

  /// Finds matching FloorDefinition by id or name, with robust fallback.
  static FloorDefinition fromId(String? id) {
    if (id == null) return underground;
    final normalized = id.toLowerCase().trim();
    if (normalized.contains('underground') || normalized == '0') {
      return underground;
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
