import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';

import '../../models/floor_definition.dart';
import '../../models/landmark_overlay_model.dart';
import '../../models/sync_manifest_model.dart';
import '../../models/tour_bundle_model.dart';
import '../../providers/colosseum_landmark_overlays.dart';

/// Contract for local caching of tour assets and manifests.
abstract class ITourLocalDataSource {
  Future<void> saveTourBundle(TourBundleModel bundle, {String lang = 'en'});
  Future<TourSyncManifestModel?> getCachedManifest();
  Future<List<FloorDefinition>> getCachedFloors({String lang = 'en'});
  Future<FloorDefinition?> getCachedFloorById(String floorId, {String lang = 'en'});
  Future<List<MapLandmarkOverlay>> getCachedLandmarkOverlays();
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
      // If Hive is uninitialized (e.g. unit tests), fallback to memory cache
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
      return _cachedSeedBundle;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveTourBundle(TourBundleModel bundle,
      {String lang = 'en'}) async {
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
  Future<List<FloorDefinition>> getCachedFloors({String lang = 'en'}) async {
    final box = await _getBox();
    final raw = box != null
        ? box.get('bundle_$lang') as String?
        : _memoryCache['bundle_$lang'] as String?;

    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final rawFloors = json['floors'] as List<dynamic>? ?? [];
        if (rawFloors.isNotEmpty) {
          return rawFloors
              .map((f) =>
                  FloorDefinition.fromJson(Map<String, dynamic>.from(f as Map)))
              .toList();
        }
      } catch (_) {}
    }

    // Dynamic asset seed fallback
    final seed = await _loadAssetSeed();
    if (seed != null && seed.floors.isNotEmpty) {
      await saveTourBundle(seed, lang: lang);
      return seed.floors;
    }

    // Default offline fallback
    return FloorDefinition.allFloors;
  }

  @override
  Future<FloorDefinition?> getCachedFloorById(String floorId,
      {String lang = 'en'}) async {
    final floors = await getCachedFloors(lang: lang);
    return floors.cast<FloorDefinition?>().firstWhere(
          (f) => f?.id == floorId,
          orElse: () => FloorDefinition.fromId(floorId),
        );
  }

  @override
  Future<List<MapLandmarkOverlay>> getCachedLandmarkOverlays() async {
    final box = await _getBox();
    final raw = box != null
        ? box.get('bundle_en') as String?
        : _memoryCache['bundle_en'] as String?;

    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final rawOverlays = json['landmarks'] as List<dynamic>? ?? [];
        if (rawOverlays.isNotEmpty) {
          return rawOverlays
              .map((l) => MapLandmarkOverlay.fromJson(
                  Map<String, dynamic>.from(l as Map)))
              .toList();
        }
      } catch (_) {}
    }

    final seed = await _loadAssetSeed();
    if (seed != null && seed.landmarks.isNotEmpty) {
      return seed.landmarks;
    }

    // Default offline fallback
    return ColosseumLandmarkOverlays.all;
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
