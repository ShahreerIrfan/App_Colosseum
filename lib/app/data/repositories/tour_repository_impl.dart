import 'package:latlong2/latlong.dart';

import '../datasources/local/tour_local_data_source.dart';
import '../datasources/remote/tour_remote_data_source.dart';
import '../models/floor_definition.dart';
import '../models/landmark_marker_model.dart';
import '../models/landmark_overlay_model.dart';
import '../models/sync_manifest_model.dart';
import '../models/viewpoint_model.dart';
import 'i_tour_repository.dart';

/// Implementation of [ITourRepository] orchestrating remote syncing with Hive local cache.
class TourRepositoryImpl implements ITourRepository {
  final ITourRemoteDataSource remoteDataSource;
  final ITourLocalDataSource localDataSource;

  TourRepositoryImpl({
    ITourRemoteDataSource? remoteDataSource,
    ITourLocalDataSource? localDataSource,
  })  : remoteDataSource = remoteDataSource ?? TourRemoteDataSource(),
        localDataSource = localDataSource ?? TourLocalDataSource();

  @override
  Future<bool> syncTourBundle({String lang = 'en'}) async {
    try {
      final remoteManifest = await remoteDataSource.getSyncManifest();
      final cachedManifest = await localDataSource.getCachedManifest();

      // Check if cache needs update
      if (cachedManifest == null ||
          cachedManifest.dataHash != remoteManifest.dataHash) {
        final bundle = await remoteDataSource.getTourBundle(lang: lang);
        await localDataSource.saveTourBundle(bundle, lang: lang);
        return true;
      }
      return false;
    } catch (_) {
      // Offline fallback: continue using cached data silently
      return false;
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
        if (remote.isNotEmpty) {
          await localDataSource.saveFloors(remote, lang: lang);
          return remote;
        }
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
        if (remote.isNotEmpty) {
          await localDataSource.saveViewpointsForFloor(floorId, remote);
          return remote;
        }
      } catch (_) {
        await syncTourBundle(lang: lang);
      }
    }
    final cached = await localDataSource.getCachedViewpointsByFloor(floorId);
    if (cached.isNotEmpty) {
      return cached;
    }
    try {
      final remote =
          await remoteDataSource.getViewpointsByFloor(floorId, lang: lang);
      if (remote.isNotEmpty) {
        await localDataSource.saveViewpointsForFloor(floorId, remote);
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
    bool forceRefresh = false,
  }) async {
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
  Future<TourSyncManifestModel?> getCurrentManifest() async {
    return localDataSource.getCachedManifest();
  }
}
