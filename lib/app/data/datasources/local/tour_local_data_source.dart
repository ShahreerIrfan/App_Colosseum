import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

import '../../models/floor_definition.dart';
import '../../models/landmark_marker_model.dart';
import '../../models/landmark_overlay_model.dart';
import '../../models/sync_manifest_model.dart';
import '../../models/tour_bundle_model.dart';
import '../../models/viewpoint_model.dart';

/// Contract for local caching of tour assets and manifests.
abstract class ITourLocalDataSource {
  Future<void> saveTourBundle(TourBundleModel bundle, {String lang = 'en'});
  Future<void> saveFloors(List<FloorDefinition> floors, {String lang = 'en'});
  Future<void> saveViewpointsForFloor(String floorId, List<ViewpointModel> viewpoints);
  Future<void> saveLandmarkMarkers(List<LandmarkMarkerModel> markers);
  Future<void> saveLandmarkOverlays(List<MapLandmarkOverlay> overlays);
  Future<TourSyncManifestModel?> getCachedManifest();
  Future<List<FloorDefinition>> getCachedFloors({String lang = 'en'});
  Future<FloorDefinition?> getCachedFloorById(String floorId, {String lang = 'en'});
  Future<List<ViewpointModel>> getCachedViewpointsByFloor(String floorId);
  Future<List<MapLandmarkOverlay>> getCachedLandmarkOverlays();
  Future<List<LandmarkMarkerModel>> getCachedLandmarkMarkers();
  Future<List<List<LatLng>>> getCachedPedestrianStreetSegments();
  Future<void> clearCache();
}

/// Implementation of [ITourLocalDataSource] using Hive boxes with asset seed fallback.
class TourLocalDataSource implements ITourLocalDataSource {
  static const String boxName = 'colosseum_tour_cache';

  final Box? box;
  final Map<String, dynamic> _memoryCache = {};
  TourBundleModel? _cachedSeedBundle;

  TourLocalDataSource({this.box});

  bool get _isHiveInitialized {
    try {
      return (Hive as dynamic).homePath != null;
    } catch (_) {
      return false;
    }
  }

  Future<Box?> _getBox() async {
    if (box != null && box!.isOpen) return box;
    try {
      if (Hive.isBoxOpen(boxName)) {
        return Hive.box(boxName);
      }
      if (!_isHiveInitialized) {
        return null;
      }
      return await Hive.openBox(boxName);
    } catch (_) {
      return null;
    }
  }

  Future<TourBundleModel?> _loadAssetSeed() async {
    if (_cachedSeedBundle != null) return _cachedSeedBundle;
    try {
      final jsonStr =
          await rootBundle.loadString('assets/data/colosseum_seed.json');
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      _cachedSeedBundle = TourBundleModel.fromSeedJson(json);
      FloorDefinition.cacheFloors(_cachedSeedBundle!.floors);
      LandmarkMarkerModel.cacheMarkers(_cachedSeedBundle!.landmarkMarkers);
      MapLandmarkOverlay.cacheOverlays(_cachedSeedBundle!.landmarks);
      return _cachedSeedBundle;
    } catch (_) {
      try {
        final file = File('assets/data/colosseum_seed.json');
        if (file.existsSync()) {
          final jsonStr = file.readAsStringSync();
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          _cachedSeedBundle = TourBundleModel.fromSeedJson(json);
          FloorDefinition.cacheFloors(_cachedSeedBundle!.floors);
          LandmarkMarkerModel.cacheMarkers(_cachedSeedBundle!.landmarkMarkers);
          MapLandmarkOverlay.cacheOverlays(_cachedSeedBundle!.landmarks);
          return _cachedSeedBundle;
        }
      } catch (_) {}
      return null;
    }
  }

  @override
  Future<void> saveTourBundle(TourBundleModel bundle,
      {String lang = 'en'}) async {
    FloorDefinition.cacheFloors(bundle.floors);
    LandmarkMarkerModel.cacheMarkers(bundle.landmarkMarkers);
    MapLandmarkOverlay.cacheOverlays(bundle.landmarks);
    final box = await _getBox();
    final bundleJson = jsonEncode(bundle.toJson());

    if (box != null) {
      await box.put('manifest', jsonEncode(bundle.manifest.toJson()));
      await box.put('bundle_$lang', bundleJson);
    } else {
      _memoryCache['manifest'] = jsonEncode(bundle.manifest.toJson());
      _memoryCache['bundle_$lang'] = bundleJson;
    }
  }

  @override
  Future<TourSyncManifestModel?> getCachedManifest() async {
    final box = await _getBox();
    final raw = box != null
        ? box.get('manifest') as String?
        : _memoryCache['manifest'] as String?;

    if (raw == null) {
      final seed = await _loadAssetSeed();
      return seed?.manifest;
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return TourSyncManifestModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveFloors(List<FloorDefinition> floors, {String lang = 'en'}) async {
    FloorDefinition.cacheFloors(floors, replaceAll: true);
    final box = await _getBox();
    final jsonList = floors.map((f) => f.toJson()).toList();
    final encoded = jsonEncode(jsonList);
    if (box != null) {
      await box.put('cached_floors_$lang', encoded);
    } else {
      _memoryCache['cached_floors_$lang'] = encoded;
    }
  }

  @override
  Future<List<FloorDefinition>> getCachedFloors({String lang = 'en'}) async {
    final box = await _getBox();

    // 1. Direct cached floors list if saved via live sync
    final rawFloors = box != null
        ? box.get('cached_floors_$lang') as String?
        : _memoryCache['cached_floors_$lang'] as String?;

    if (rawFloors != null) {
      try {
        final list = jsonDecode(rawFloors) as List<dynamic>;
        if (list.isNotEmpty) {
          final floors = list
              .map((item) =>
                  FloorDefinition.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
          FloorDefinition.cacheFloors(floors, replaceAll: true);
          return floors;
        }
      } catch (_) {}
    }

    final raw = box != null
        ? box.get('bundle_$lang') as String?
        : _memoryCache['bundle_$lang'] as String?;

    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final floors = FloorDefinition.parseFloorsFromBundleJson(json);
        if (floors.isNotEmpty) {
          FloorDefinition.cacheFloors(floors);
          return floors;
        }
      } catch (_) {}
    }

    final seed = await _loadAssetSeed();
    if (seed != null && seed.floors.isNotEmpty) {
      await saveTourBundle(seed, lang: lang);
      return seed.floors;
    }

    return const [];
  }

  @override
  Future<void> saveViewpointsForFloor(
      String floorId, List<ViewpointModel> viewpoints) async {
    FloorDefinition.updateFloorViewpoints(floorId, viewpoints);
    final box = await _getBox();
    final jsonList = viewpoints.map((vp) => vp.toJson()).toList();
    final encoded = jsonEncode(jsonList);
    if (box != null) {
      await box.put('viewpoints_$floorId', encoded);
    } else {
      _memoryCache['viewpoints_$floorId'] = encoded;
    }
  }

  @override
  Future<List<ViewpointModel>> getCachedViewpointsByFloor(String floorId) async {
    final box = await _getBox();
    final raw = box != null
        ? box.get('viewpoints_$floorId') as String?
        : _memoryCache['viewpoints_$floorId'] as String?;

    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        if (list.isNotEmpty) {
          final vps = list
              .map((item) => ViewpointModel.fromJson(
                  Map<String, dynamic>.from(item as Map)))
              .toList();
          FloorDefinition.updateFloorViewpoints(floorId, vps);
          return vps;
        }
      } catch (_) {}
    }

    final floor = await getCachedFloorById(floorId);
    if (floor != null && floor.viewpoints.isNotEmpty) {
      return floor.viewpoints;
    }

    return const [];
  }

  @override
  Future<FloorDefinition?> getCachedFloorById(String floorId,
      {String lang = 'en'}) async {
    final floors = await getCachedFloors(lang: lang);
    final match = floors.where((f) => f.id == floorId).toList();
    FloorDefinition? floor = match.isNotEmpty ? match.first : FloorDefinition.fromId(floorId);

    // Enforce live Hive cached viewpoints if present
    final box = await _getBox();
    final rawVps = box != null
        ? box.get('viewpoints_$floorId') as String?
        : _memoryCache['viewpoints_$floorId'] as String?;

    if (rawVps != null) {
      try {
        final list = jsonDecode(rawVps) as List<dynamic>;
        if (list.isNotEmpty) {
          final vps = list
              .map((item) => ViewpointModel.fromJson(
                  Map<String, dynamic>.from(item as Map)))
              .toList();
          FloorDefinition.updateFloorViewpoints(floorId, vps);
          floor = floor.copyWith(viewpoints: vps);
        }
      } catch (_) {}
    }

    return floor;
  }

  @override
  Future<void> saveLandmarkMarkers(List<LandmarkMarkerModel> markers) async {
    LandmarkMarkerModel.cacheMarkers(markers);
    final box = await _getBox();
    final jsonList = markers.map((m) => m.toJson()).toList();
    final encoded = jsonEncode(jsonList);
    if (box != null) {
      await box.put('landmark_markers', encoded);
    } else {
      _memoryCache['landmark_markers'] = encoded;
    }
  }

  @override
  Future<void> saveLandmarkOverlays(List<MapLandmarkOverlay> overlays) async {
    MapLandmarkOverlay.cacheOverlays(overlays);
    final box = await _getBox();
    final jsonList = overlays.map((o) => o.toJson()).toList();
    final encoded = jsonEncode(jsonList);
    if (box != null) {
      await box.put('landmark_overlays', encoded);
    } else {
      _memoryCache['landmark_overlays'] = encoded;
    }
  }

  @override
  Future<List<MapLandmarkOverlay>> getCachedLandmarkOverlays() async {
    final box = await _getBox();
    final rawDirect = box != null
        ? box.get('landmark_overlays') as String?
        : _memoryCache['landmark_overlays'] as String?;

    if (rawDirect != null) {
      try {
        final list = jsonDecode(rawDirect) as List<dynamic>;
        if (list.isNotEmpty) {
          final overlays = list
              .map((l) => MapLandmarkOverlay.fromJson(
                  Map<String, dynamic>.from(l as Map)))
              .toList();
          MapLandmarkOverlay.cacheOverlays(overlays);
          return overlays;
        }
      } catch (_) {}
    }

    final raw = box != null
        ? box.get('bundle_en') as String?
        : _memoryCache['bundle_en'] as String?;

    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final rawOverlays = json['landmarks'] as List<dynamic>? ?? [];
        if (rawOverlays.isNotEmpty) {
          final overlays = rawOverlays
              .map((l) => MapLandmarkOverlay.fromJson(
                  Map<String, dynamic>.from(l as Map)))
              .toList();
          MapLandmarkOverlay.cacheOverlays(overlays);
          return overlays;
        }
      } catch (_) {}
    }

    final seed = await _loadAssetSeed();
    if (seed != null && seed.landmarks.isNotEmpty) {
      return seed.landmarks;
    }

    return const [];
  }

  @override
  Future<List<LandmarkMarkerModel>> getCachedLandmarkMarkers() async {
    final box = await _getBox();
    final rawDirect = box != null
        ? box.get('landmark_markers') as String?
        : _memoryCache['landmark_markers'] as String?;

    if (rawDirect != null) {
      try {
        final list = jsonDecode(rawDirect) as List<dynamic>;
        if (list.isNotEmpty) {
          final markers = list
              .map((l) => LandmarkMarkerModel.fromJson(
                  Map<String, dynamic>.from(l as Map)))
              .toList();
          LandmarkMarkerModel.cacheMarkers(markers);
          return markers;
        }
      } catch (_) {}
    }

    final raw = box != null
        ? box.get('bundle_en') as String?
        : _memoryCache['bundle_en'] as String?;

    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final floors = FloorDefinition.parseFloorsFromBundleJson(json);
        if (floors.isNotEmpty) {
          FloorDefinition.cacheFloors(floors);
        }
        final rawLandmarks = json['landmarks'] as List<dynamic>? ?? [];
        if (rawLandmarks.isNotEmpty) {
          final markers = rawLandmarks
              .map((l) => LandmarkMarkerModel.fromJson(
                  Map<String, dynamic>.from(l as Map)))
              .toList();
          LandmarkMarkerModel.cacheMarkers(markers);
          return markers;
        }
      } catch (_) {}
    }

    final seed = await _loadAssetSeed();
    if (seed != null && seed.landmarkMarkers.isNotEmpty) {
      return seed.landmarkMarkers;
    }

    return const [];
  }

  @override
  Future<List<List<LatLng>>> getCachedPedestrianStreetSegments() async {
    final box = await _getBox();
    final raw = box != null
        ? box.get('bundle_en') as String?
        : _memoryCache['bundle_en'] as String?;

    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final rawRoutes = json['pedestrianRoutes'] as List<dynamic>? ?? [];
        final List<List<LatLng>> segments = [];
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
              segments.add(pts);
            }
          }
        }
        if (segments.isNotEmpty) {
          return segments;
        }
      } catch (_) {}
    }

    final seed = await _loadAssetSeed();
    if (seed != null && seed.pedestrianStreetSegments.isNotEmpty) {
      return seed.pedestrianStreetSegments;
    }

    return const [];
  }

  @override
  Future<void> clearCache() async {
    final box = await _getBox();
    if (box != null) {
      await box.clear();
    }
    _memoryCache.clear();
  }
}
