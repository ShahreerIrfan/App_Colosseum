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
import '../../models/pedestrian_route_data.dart';

/// Contract for local caching of tour assets and manifests.
abstract class ITourLocalDataSource {
  Future<TourBundleModel?> getCachedTourBundle({String lang = 'en', bool allowSeed = false});
  Future<void> saveTourBundle(TourBundleModel bundle, {String lang = 'en'});
  Future<void> saveFloors(List<FloorDefinition> floors, {String lang = 'en'});
  Future<void> saveViewpointsForFloor(String floorId, List<ViewpointModel> viewpoints, {String lang = 'en'});
  Future<void> saveLandmarkMarkers(List<LandmarkMarkerModel> markers);
  Future<void> saveLandmarkOverlays(List<MapLandmarkOverlay> overlays);
  Future<TourSyncManifestModel?> getCachedManifest({String lang = 'en'});
  Future<DateTime?> getLastBundleDownload({String lang = 'en'});
  Future<List<FloorDefinition>> getCachedFloors({String lang = 'en'});
  Future<FloorDefinition?> getCachedFloorById(String floorId, {String lang = 'en'});
  Future<List<ViewpointModel>> getCachedViewpointsByFloor(String floorId, {String lang = 'en'});
  Future<List<MapLandmarkOverlay>> getCachedLandmarkOverlays();
  Future<List<LandmarkMarkerModel>> getCachedLandmarkMarkers({String lang = 'en'});
  Future<List<List<LatLng>>> getCachedPedestrianStreetSegments();
  Future<List<PedestrianRouteData>> getCachedPedestrianRoutes({String lang = 'en'});
  Future<void> clearCache();
}

/// Implementation of [ITourLocalDataSource] using Hive boxes with asset seed fallback.
class TourLocalDataSource implements ITourLocalDataSource {
  static const String boxName = 'colosseum_tour_cache';

  final Box? box;
  final Map<String, dynamic> _memoryCache = {};
  TourBundleModel? _cachedSeedBundle;
  int _bundleSequence = 0;

  Object? _read(Box? box, String key) =>
      box == null ? _memoryCache[key] : box.get(key);

  Future<void> _write(Box? box, String key, String value) async {
    if (box == null) {
      _memoryCache[key] = value;
    } else {
      await box.put(key, value);
    }
  }

  String? _bundleGeneration(Box? box, String lang) {
    final raw = _read(box, 'bundle_$lang');
    if (raw is! String) return null;
    try {
      return (jsonDecode(raw) as Map)['cacheGeneration'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveOverride(Box? box, String key, List<dynamic> values, {String lang = 'en'}) =>
      _write(box, key, jsonEncode({
        'generation': _bundleGeneration(box, lang),
        'values': values,
      }));

  List<dynamic>? _readOverride(Box? box, String key, {String lang = 'en'}) {
    final raw = _read(box, key);
    if (raw is! String) return null;
    try {
      final decoded = jsonDecode(raw);
      final generation = _bundleGeneration(box, lang);
      if (decoded is List<dynamic>) return generation == null ? decoded : null;
      if (decoded is Map && decoded['generation'] == generation) {
        return decoded['values'] as List<dynamic>?;
      }
    } catch (_) {}
    return null;
  }

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
  Future<TourBundleModel?> getCachedTourBundle({String lang = 'en', bool allowSeed = false}) async {
    final raw = _read(await _getBox(), 'bundle_$lang');
    if (raw is String) {
      try {
        return TourBundleModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    return allowSeed && lang == 'en' ? _loadAssetSeed() : null;
  }

  @override
  Future<void> saveTourBundle(TourBundleModel bundle,
      {String lang = 'en'}) async {
    final box = await _getBox();
    final generation = '${DateTime.now().microsecondsSinceEpoch}-${_bundleSequence++}';
    final bundleJson = jsonEncode({
      ...bundle.toJson(),
      'cacheSchemaVersion': 1,
      'cacheGeneration': generation,
      'downloadedAt': DateTime.now().toUtc().toIso8601String(),
    });

    // One write commits the bundle and its manifest together. Older overrides
    // become invalid at the same time because their generation no longer matches.
    await _write(box, 'bundle_$lang', bundleJson);
    FloorDefinition.cacheFloors(bundle.floors, replaceAll: true);
    LandmarkMarkerModel.cacheMarkers(bundle.landmarkMarkers);
    MapLandmarkOverlay.cacheOverlays(bundle.landmarks);
  }

  @override
  Future<TourSyncManifestModel?> getCachedManifest({String lang = 'en'}) async {
    final box = await _getBox();
    final raw = box != null
        ? box.get('bundle_$lang') as String?
        : _memoryCache['bundle_$lang'] as String?;
    if (raw == null) return null;
    try {
      final bundle = jsonDecode(raw) as Map<String, dynamic>;
      return TourSyncManifestModel.fromJson(
        Map<String, dynamic>.from(bundle['manifest'] as Map),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<DateTime?> getLastBundleDownload({String lang = 'en'}) async {
    final raw = _read(await _getBox(), 'bundle_$lang');
    if (raw is! String) return null;
    try {
      final timestamp = (jsonDecode(raw) as Map)['downloadedAt'];
      return timestamp is String ? DateTime.tryParse(timestamp) : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveFloors(List<FloorDefinition> floors, {String lang = 'en'}) async {
    FloorDefinition.cacheFloors(floors, replaceAll: true);
    final box = await _getBox();
    final jsonList = floors.map((f) => f.toJson()).toList();
    await _saveOverride(box, 'cached_floors_$lang', jsonList, lang: lang);
  }

  @override
  Future<List<FloorDefinition>> getCachedFloors({String lang = 'en'}) async {
    final box = await _getBox();
    List<FloorDefinition>? bundledFloors;
    final raw = _read(box, 'bundle_$lang');
    if (raw is String) {
      try {
        bundledFloors = FloorDefinition.parseFloorsFromBundleJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    // The live floor catalog supplies metadata; the bundle supplies route geometry.
    final cachedOverride = _readOverride(box, 'cached_floors_$lang', lang: lang);

    if (cachedOverride != null) {
      try {
        final list = cachedOverride;
        final bundledById = {for (final floor in bundledFloors ?? <FloorDefinition>[]) floor.id: floor};
        final floors = list
            .map((item) =>
                FloorDefinition.fromJson(Map<String, dynamic>.from(item as Map)))
            .map((floor) {
              final bundled = bundledById[floor.id];
              if (bundled == null) return floor;
              return floor.copyWith(
                viewpoints: floor.viewpoints.isEmpty ? bundled.viewpoints : floor.viewpoints,
                itinerary: floor.itinerary.isEmpty ? bundled.itinerary : floor.itinerary,
              );
            }).toList();
        FloorDefinition.cacheFloors(floors, replaceAll: true);
        return floors;
      } catch (_) {}
    }

    if (bundledFloors != null) {
      FloorDefinition.cacheFloors(bundledFloors, replaceAll: true);
      return bundledFloors;
    }

    final seed = await _loadAssetSeed();
    if (seed != null && seed.floors.isNotEmpty) {
      return seed.floors;
    }

    return const [];
  }

  @override
  Future<void> saveViewpointsForFloor(
      String floorId, List<ViewpointModel> viewpoints, {String lang = 'en'}) async {
    FloorDefinition.updateFloorViewpoints(floorId, viewpoints);
    final box = await _getBox();
    final jsonList = viewpoints.map((vp) => vp.toJson()).toList();
    await _saveOverride(box, 'viewpoints_${lang}_$floorId', jsonList, lang: lang);
  }

  @override
  Future<List<ViewpointModel>> getCachedViewpointsByFloor(String floorId, {String lang = 'en'}) async {
    final box = await _getBox();
    final cachedOverride = _readOverride(box, 'viewpoints_${lang}_$floorId', lang: lang);

    if (cachedOverride != null) {
      try {
        final list = cachedOverride;
        final vps = list
            .map((item) => ViewpointModel.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList();
        FloorDefinition.updateFloorViewpoints(floorId, vps);
        return vps;
      } catch (_) {}
    }

    final floor = await getCachedFloorById(floorId, lang: lang);
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
    if (match.isEmpty) return null;
    var floor = match.first;

    // Enforce live Hive cached viewpoints if present
    final box = await _getBox();
    final cachedViewpoints = _readOverride(box, 'viewpoints_${lang}_$floorId', lang: lang);

    if (cachedViewpoints != null) {
      try {
        final list = cachedViewpoints;
        final vps = list
            .map((item) => ViewpointModel.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList();
        FloorDefinition.updateFloorViewpoints(floorId, vps);
        floor = floor.copyWith(viewpoints: vps);
      } catch (_) {}
    }

    return floor;
  }

  @override
  Future<void> saveLandmarkMarkers(List<LandmarkMarkerModel> markers) async {
    LandmarkMarkerModel.cacheMarkers(markers);
    final box = await _getBox();
    final jsonList = markers.map((m) => m.toJson()).toList();
    await _saveOverride(box, 'landmark_markers', jsonList);
  }

  @override
  Future<void> saveLandmarkOverlays(List<MapLandmarkOverlay> overlays) async {
    MapLandmarkOverlay.cacheOverlays(overlays);
    final box = await _getBox();
    final jsonList = overlays.map((o) => o.toJson()).toList();
    await _saveOverride(box, 'landmark_overlays', jsonList);
  }

  @override
  Future<List<MapLandmarkOverlay>> getCachedLandmarkOverlays() async {
    final box = await _getBox();
    final cachedOverride = _readOverride(box, 'landmark_overlays');

    if (cachedOverride != null) {
      try {
        final list = cachedOverride;
        final overlays = list
            .map((l) => MapLandmarkOverlay.fromJson(
                Map<String, dynamic>.from(l as Map)))
            .toList();
        MapLandmarkOverlay.cacheOverlays(overlays);
        return overlays;
      } catch (_) {}
    }

    final raw = box != null
        ? box.get('bundle_en') as String?
        : _memoryCache['bundle_en'] as String?;

    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final rawOverlays = json['landmarks'] as List<dynamic>? ?? [];
        final overlays = rawOverlays
            .map((l) => MapLandmarkOverlay.fromJson(
                Map<String, dynamic>.from(l as Map)))
            .toList();
        MapLandmarkOverlay.cacheOverlays(overlays);
        return overlays;
      } catch (_) {}
    }

    final seed = await _loadAssetSeed();
    if (seed != null && seed.landmarks.isNotEmpty) {
      return seed.landmarks;
    }

    return const [];
  }

  @override
  Future<List<LandmarkMarkerModel>> getCachedLandmarkMarkers({String lang = 'en'}) async {
    final box = await _getBox();
    final cachedOverride = lang == 'en' ? _readOverride(box, 'landmark_markers') : null;

    if (cachedOverride != null) {
      try {
        final list = cachedOverride;
        final markers = list
            .map((l) => LandmarkMarkerModel.fromJson(
                Map<String, dynamic>.from(l as Map)))
            .toList();
        LandmarkMarkerModel.cacheMarkers(markers);
        return markers;
      } catch (_) {}
    }

    final raw = _read(box, 'bundle_$lang') as String?;

    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final floors = FloorDefinition.parseFloorsFromBundleJson(json);
        if (floors.isNotEmpty) {
          FloorDefinition.cacheFloors(floors);
        }
        final rawLandmarks = json['landmarks'] as List<dynamic>? ?? [];
        final markers = rawLandmarks
            .map((l) => LandmarkMarkerModel.fromJson(
                Map<String, dynamic>.from(l as Map)))
            .toList();
        LandmarkMarkerModel.cacheMarkers(markers);
        return markers;
      } catch (_) {}
    }

    if (lang != 'en') return getCachedLandmarkMarkers();
    final seed = await _loadAssetSeed();
    if (seed != null && seed.landmarkMarkers.isNotEmpty) {
      return seed.landmarkMarkers;
    }

    return const [];
  }

  @override
  Future<List<List<LatLng>>> getCachedPedestrianStreetSegments() async =>
      (await getCachedPedestrianRoutes()).map((route) => route.waypoints).toList();

  @override
  Future<List<PedestrianRouteData>> getCachedPedestrianRoutes({String lang = 'en'}) async {
    final raw = _read(await _getBox(), 'bundle_$lang');
    if (raw is String) {
      try {
        return PedestrianRouteData.parseList((jsonDecode(raw) as Map)['pedestrianRoutes']);
      } catch (_) {}
    }
    final seed = await _loadAssetSeed();
    return seed?.pedestrianRoutes ?? const [];
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
