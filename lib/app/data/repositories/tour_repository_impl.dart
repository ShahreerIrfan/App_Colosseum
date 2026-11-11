import 'package:latlong2/latlong.dart';

import '../datasources/local/tour_local_data_source.dart';
import '../datasources/remote/tour_remote_data_source.dart';
import '../models/floor_definition.dart';
import '../models/landmark_marker_model.dart';
import '../models/landmark_overlay_model.dart';
import '../models/sync_manifest_model.dart';
import '../models/viewpoint_model.dart';
import '../models/pedestrian_route_data.dart';
import 'i_tour_repository.dart';

/// Implementation of [ITourRepository] orchestrating remote syncing with Hive local cache.
class TourRepositoryImpl implements ITourRepository {
  final ITourRemoteDataSource remoteDataSource;
  final ITourLocalDataSource localDataSource;
  final _bundleRefreshes = <String, Future<TourSyncResult>>{};

  TourRepositoryImpl({
    ITourRemoteDataSource? remoteDataSource,
    ITourLocalDataSource? localDataSource,
  })  : remoteDataSource = remoteDataSource ?? TourRemoteDataSource(),
        localDataSource = localDataSource ?? TourLocalDataSource();

  @override
  Future<bool> syncTourBundle({String lang = 'en'}) async =>
      await refreshTourBundle(lang: lang) == TourSyncResult.updated;

  @override
  Future<DateTime?> getLastBundleDownload({String lang = 'en'}) =>
      localDataSource.getLastBundleDownload(lang: lang);

  @override
  Future<TourSyncResult> refreshTourBundle({String lang = 'en', bool force = false,
    Duration? maxAge}) async {
    final downloadedAt = maxAge == null ? null : await getLastBundleDownload(lang: lang);
    final stale = maxAge != null &&
        (downloadedAt == null || DateTime.now().difference(downloadedAt) >= maxAge);
    final shouldDownload = force || stale;
    final running = _bundleRefreshes[lang];
    if (running != null) {
      final result = await running;
      if (!shouldDownload || result != TourSyncResult.unchanged) return result;
      return refreshTourBundle(lang: lang, force: true);
    }
    final refresh = _refreshBundle(lang, force: shouldDownload);
    _bundleRefreshes[lang] = refresh;
    try {
      return await refresh;
    } finally {
      _bundleRefreshes.remove(lang);
    }
  }

  Future<TourSyncResult> _refreshBundle(String lang, {required bool force}) async {
    try {
      if (!force) {
        final remoteManifest = await remoteDataSource.getSyncManifest();
        final cachedManifest = await localDataSource.getCachedManifest(lang: lang);
        if (cachedManifest == remoteManifest) {
          return TourSyncResult.unchanged;
        }
      }
      final bundle = await remoteDataSource.getTourBundle(lang: lang);
      await localDataSource.saveTourBundle(bundle, lang: lang);
      return TourSyncResult.updated;
    } catch (_) {
      return TourSyncResult.unavailable;
    }
  }

  @override
  Future<List<FloorDefinition>> getFloors({
    String lang = 'en',
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      try {
        final remote = await remoteDataSource.getFloors(lang: lang);
        await localDataSource.saveFloors(remote, lang: lang);
        return remote;
      } catch (_) {
        await syncTourBundle(lang: lang);
      }
    }
    return localDataSource.getCachedFloors(lang: lang);
  }

  @override
  Future<FloorDefinition?> getFloorById(
    String floorId, {
    String lang = 'en',
  }) async {
    return localDataSource.getCachedFloorById(floorId, lang: lang);
  }

  @override
  Future<List<ViewpointModel>> getViewpointsByFloor(
    String floorId, {
    bool forceRefresh = false,
    String lang = 'en',
  }) async {
    if (forceRefresh) {
      try {
        final remote =
            await remoteDataSource.getViewpointsByFloor(floorId, lang: lang);
        await localDataSource.saveViewpointsForFloor(floorId, remote, lang: lang);
        return remote;
      } catch (_) {
        await syncTourBundle(lang: lang);
      }
    }
    final cached = await localDataSource.getCachedViewpointsByFloor(floorId, lang: lang);
    if (cached.isNotEmpty) {
      return cached;
    }
    try {
      final remote =
          await remoteDataSource.getViewpointsByFloor(floorId, lang: lang);
      if (remote.isNotEmpty) {
        await localDataSource.saveViewpointsForFloor(floorId, remote, lang: lang);
        return remote;
      }
    } catch (_) {}
    return cached;
  }

  @override
  Future<List<MapLandmarkOverlay>> getLandmarkOverlays({
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      try {
        final remote = await remoteDataSource.getLandmarks();
        await localDataSource.saveLandmarkOverlays(remote);
        return remote;
      } catch (_) {
        await syncTourBundle();
      }
    }
    return localDataSource.getCachedLandmarkOverlays();
  }

  @override
  Future<List<LandmarkMarkerModel>> getLandmarkMarkers({
    String lang = 'en',
    bool forceRefresh = false,
  }) async {
    if (lang != 'en') {
      if (forceRefresh) await syncTourBundle(lang: lang);
      return localDataSource.getCachedLandmarkMarkers(lang: lang);
    }
    if (forceRefresh) {
      try {
        final remote = await remoteDataSource.getLandmarkMarkers();
        await localDataSource.saveLandmarkMarkers(remote);
        return remote;
      } catch (_) {
        await syncTourBundle();
      }
    }
    return localDataSource.getCachedLandmarkMarkers();
  }

  @override
  Future<List<List<LatLng>>> getPedestrianStreetSegments({
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      await syncTourBundle();
    }
    return localDataSource.getCachedPedestrianStreetSegments();
  }

  @override
  Future<List<PedestrianRouteData>> getPedestrianRoutes({
    String lang = 'en',
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) await syncTourBundle(lang: lang);
    return localDataSource.getCachedPedestrianRoutes(lang: lang);
  }

  @override
  Future<TourSyncManifestModel?> getCurrentManifest() async {
    return localDataSource.getCachedManifest();
  }
}
