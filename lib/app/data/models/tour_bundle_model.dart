import 'package:latlong2/latlong.dart';

import 'floor_definition.dart';
import 'itinerary_segment_model.dart';
import 'landmark_marker_model.dart';
import 'landmark_overlay_model.dart';
import 'sync_manifest_model.dart';
import 'viewpoint_model.dart';

/// Complete bundle representing all tour assets, floors, viewpoints, and overlays
/// fetched from MongoDB backend and cached locally for offline tour navigation.
class TourBundleModel {
  final TourSyncManifestModel manifest;
  final List<MapLandmarkOverlay> landmarks;
  final List<LandmarkMarkerModel> landmarkMarkers;
  final List<FloorDefinition> floors;
  final List<List<LatLng>> pedestrianStreetSegments;

  const TourBundleModel({
    required this.manifest,
    required this.landmarks,
    this.landmarkMarkers = const [],
    required this.floors,
    this.pedestrianStreetSegments = const [],
  });

  factory TourBundleModel.fromJson(Map<String, dynamic> json) {
    final manifestData = json['manifest'] as Map<String, dynamic>? ?? {};
    final manifest = TourSyncManifestModel.fromJson(manifestData);

    final rawLandmarks = json['landmarks'] as List<dynamic>? ?? [];
    final landmarks = rawLandmarks
        .map((lm) =>
            MapLandmarkOverlay.fromJson(Map<String, dynamic>.from(lm as Map)))
        .toList();

    final landmarkMarkers = rawLandmarks
        .map((lm) =>
            LandmarkMarkerModel.fromJson(Map<String, dynamic>.from(lm as Map)))
        .toList();

    final floors = FloorDefinition.parseFloorsFromBundleJson(json);

    final rawRoutes = json['pedestrianRoutes'] as List<dynamic>? ?? [];
    final List<List<LatLng>> streetSegments = [];
    for (final r in rawRoutes) {
      if (r is Map && r['waypoints'] is List) {
        final pts = (r['waypoints'] as List).map<LatLng>((w) {
          final wm = w as Map;
          return LatLng(
            (wm['latitude'] as num).toDouble(),
            (wm['longitude'] as num).toDouble(),
          );
        }).toList();
        if (pts.length >= 2) {
          streetSegments.add(pts);
        }
      }
    }

    return TourBundleModel(
      manifest: manifest,
      landmarks: landmarks,
      landmarkMarkers: landmarkMarkers,
      floors: floors,
      pedestrianStreetSegments: streetSegments,
    );
  }

  factory TourBundleModel.fromSeedJson(Map<String, dynamic> json) {
    final manifestData = json['manifest'] as Map<String, dynamic>?;
    final manifest = manifestData != null
        ? TourSyncManifestModel.fromJson(manifestData)
        : const TourSyncManifestModel(
            version: '1.0.0',
            dataHash: 'colosseum_v1_seed',
            totalFloors: 12,
            totalViewpoints: 51,
            totalLandmarks: 5,
            languages: ['en', 'it', 'fr', 'de', 'es', 'pt', 'ja', 'ko'],
          );

    final rawLandmarks = json['landmarks'] as List<dynamic>? ?? [];
    final landmarks = rawLandmarks
        .map((lm) =>
            MapLandmarkOverlay.fromJson(Map<String, dynamic>.from(lm as Map)))
        .toList();

    final landmarkMarkers = rawLandmarks
        .map((lm) =>
            LandmarkMarkerModel.fromJson(Map<String, dynamic>.from(lm as Map)))
        .toList();

    final allViewpoints = (json['viewpoints'] as List<dynamic>? ?? [])
        .map((v) =>
            ViewpointModel.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList();

    final rawFloors = json['floors'] as List<dynamic>? ?? [];
    final List<FloorDefinition> floors = rawFloors.map<FloorDefinition>((fl) {
      final fMap = Map<String, dynamic>.from(fl as Map);
      final floorId =
          fMap['floorId'] as String? ?? fMap['id'] as String? ?? '';
      final List<ViewpointModel> floorVps =
          allViewpoints.where((v) => v.floorId == floorId).toList();
      final List<ItinerarySegmentModel> floorItin =
          (json['itineraries'] as List<dynamic>? ?? [])
              .where((i) => (i as Map)['floorId'] == floorId)
              .map<ItinerarySegmentModel>((i) =>
                  ItinerarySegmentModel.fromJson(
                      Map<String, dynamic>.from(i as Map)))
              .toList();

      final calib = fMap['calibration'] as Map<String, dynamic>? ?? {};
      final centerMap =
          calib['centerCoordinates'] as Map<String, dynamic>? ?? {};
      final mapAssetObj = fMap['mapAsset'] as Map<String, dynamic>?;

      return FloorDefinition(
        id: floorId,
        landmarkId: FloorDefinition.landmarkIdForFloorId(
          floorId,
          fMap['landmarkCode'] as String? ?? fMap['landmarkId'] as String?,
        ),
        displayName: fMap['displayName'] as String? ?? '',
        shortName: fMap['shortName'] as String? ?? '',
        floorNumberLabel: fMap['floorNumberLabel'] as String? ?? '',
        semanticLabel: fMap['semanticLabel'] as String? ?? '',
        center: LatLng(
          (centerMap['latitude'] as num?)?.toDouble() ?? 41.89021,
          (centerMap['longitude'] as num?)?.toDouble() ?? 12.492231,
        ),
        defaultZoom: (calib['defaultZoom'] as num?)?.toDouble() ?? 18.6,
        mapNorthOffsetDegrees:
            (calib['mapNorthOffsetDegrees'] as num?)?.toDouble() ?? -20.0,
        mapAsset: mapAssetObj?['assetId'] as String? ??
            fMap['mapAsset'] as String? ??
            'level_1_map',
        viewpoints: floorVps,
        itinerary: floorItin,
      );
    }).toList();

    final rawRoutes = json['pedestrianRoutes'] as List<dynamic>? ?? [];
    final List<List<LatLng>> streetSegments = [];
    for (final r in rawRoutes) {
      if (r is Map && r['waypoints'] is List) {
        final pts = (r['waypoints'] as List).map<LatLng>((w) {
          final wm = w as Map;
          return LatLng(
            (wm['latitude'] as num).toDouble(),
            (wm['longitude'] as num).toDouble(),
          );
        }).toList();
        if (pts.length >= 2) {
          streetSegments.add(pts);
        }
      }
    }

    return TourBundleModel(
      manifest: manifest,
      landmarks: landmarks,
      landmarkMarkers: landmarkMarkers,
      floors: floors,
      pedestrianStreetSegments: streetSegments,
    );
  }

  Map<String, dynamic> toJson() => {
        'manifest': manifest.toJson(),
        'landmarks': landmarks.map((l) => l.toJson()).toList(),
        'landmarkMarkers': landmarkMarkers.map((m) => m.toJson()).toList(),
        'floors': floors.map((f) => f.toJson()).toList(),
        'pedestrianRoutes': pedestrianStreetSegments
            .map((seg) => {
                  'waypoints': seg
                      .map((p) => {
                            'latitude': p.latitude,
                            'longitude': p.longitude,
                          })
                      .toList()
                })
            .toList(),
      };
}
