import 'dart:ui' show Color;
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:colosseum_client/app/data/datasources/local/tour_local_data_source.dart';
import 'package:colosseum_client/app/data/datasources/remote/tour_remote_data_source.dart';
import 'package:colosseum_client/app/data/models/floor_definition.dart';
import 'package:colosseum_client/app/data/models/landmark_marker_model.dart';
import 'package:colosseum_client/app/data/models/landmark_overlay_model.dart';
import 'package:colosseum_client/app/data/models/sync_manifest_model.dart';
import 'package:colosseum_client/app/data/models/tour_bundle_model.dart';
import 'package:colosseum_client/app/data/models/viewpoint_model.dart';
import 'package:colosseum_client/app/data/repositories/tour_repository_impl.dart';
import 'package:colosseum_client/app/data/repositories/i_tour_repository.dart';

class FakeRemoteDataSource implements ITourRemoteDataSource {
  TourSyncManifestModel manifestToReturn = const TourSyncManifestModel(
    version: '1.0.0',
    dataHash: 'hash_v1',
    totalFloors: 4,
    totalViewpoints: 28,
    totalLandmarks: 5,
    languages: ['en'],
  );

  bool shouldThrow = false;
  int bundleCallCount = 0;
  List<LandmarkMarkerModel> markersToReturn = [];

  @override
  Future<TourSyncManifestModel> getSyncManifest() async {
    if (shouldThrow) throw Exception('Network timeout');
    return manifestToReturn;
  }

  @override
  Future<TourBundleModel> getTourBundle({String lang = 'en'}) async {
    if (shouldThrow) throw Exception('Network timeout');
    bundleCallCount++;
    return TourBundleModel(
      manifest: manifestToReturn,
      landmarks: const [],
      floors: [FloorDefinition.underground],
    );
  }

  @override
  Future<List<MapLandmarkOverlay>> getLandmarks() async {
    if (shouldThrow) throw Exception('Network timeout');
    return const [];
  }

  @override
  Future<List<LandmarkMarkerModel>> getLandmarkMarkers() async {
    if (shouldThrow) throw Exception('Network timeout');
    return markersToReturn;
  }

  @override
  Future<List<FloorDefinition>> getFloors({String lang = 'en'}) async {
    if (shouldThrow) throw Exception('Network timeout');
    return [FloorDefinition.underground];
  }

  @override
  Future<FloorDefinition?> getFloorDetail(String floorId,
      {String lang = 'en'}) async {
    if (shouldThrow) throw Exception('Network timeout');
    return FloorDefinition.underground;
  }

  @override
  Future<List<ViewpointModel>> getViewpointsByFloor(String floorId,
      {String lang = 'en'}) async {
    if (shouldThrow) throw Exception('Network timeout');
    return FloorDefinition.underground.viewpoints;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tour Repository & Data Source Unit Tests', () {
    late FakeRemoteDataSource remoteDataSource;
    late TourLocalDataSource localDataSource;
    late TourRepositoryImpl repository;

    setUp(() {
      remoteDataSource = FakeRemoteDataSource();
      localDataSource = TourLocalDataSource();
      repository = TourRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );
    });

    test('floor Viewpoints load across pages before replacing the cache', () async {
      final pages = <String>[];
      final client = MockClient((request) async {
        final page = request.url.queryParameters['page']!;
        pages.add(page);
        final start = page == '1' ? 0 : 100;
        final count = page == '1' ? 100 : 1;
        return http.Response(jsonEncode({
          'data': List.generate(count, (index) => {
            'id': 'vp_${start + index}',
            'floorId': 'floor_underground',
          }),
        }), 200);
      });
      final repo = TourRepositoryImpl(
        remoteDataSource: TourRemoteDataSource(client: client),
        localDataSource: localDataSource,
      );
      final items = await repo.getViewpointsByFloor('floor_underground', forceRefresh: true);
      expect(pages, ['1', '2']);
      expect(items.last.id, 'vp_100');
      expect(await localDataSource.getCachedViewpointsByFloor('floor_underground'), hasLength(101));
    });

    test('explicit empty caches do not restore bundled content', () async {
      await localDataSource.saveFloors([]);
      await localDataSource.saveViewpointsForFloor('floor_underground', []);
      await localDataSource.saveLandmarkMarkers([]);
      await localDataSource.saveLandmarkOverlays([]);

      expect(await localDataSource.getCachedFloors(), isEmpty);
      expect(await localDataSource.getCachedViewpointsByFloor('floor_underground'), isEmpty);
      expect(await localDataSource.getCachedLandmarkMarkers(), isEmpty);
      expect(await localDataSource.getCachedLandmarkOverlays(), isEmpty);
    });

    test('a new bundle invalidates earlier live catalog overrides', () async {
      final floor = FloorDefinition.underground;
      await localDataSource.saveFloors([floor]);
      await localDataSource.saveViewpointsForFloor(floor.id, floor.viewpoints);
      await localDataSource.saveTourBundle(TourBundleModel(
        manifest: remoteDataSource.manifestToReturn,
        landmarks: const [],
        floors: [floor.copyWith(viewpoints: [])],
      ));
      expect(await localDataSource.getCachedViewpointsByFloor(floor.id), isEmpty);

      await localDataSource.saveViewpointsForFloor(floor.id, floor.viewpoints);
      expect(await localDataSource.getCachedViewpointsByFloor(floor.id), floor.viewpoints);

      await localDataSource.saveTourBundle(TourBundleModel(
        manifest: remoteDataSource.manifestToReturn,
        landmarks: const [],
        floors: const [],
      ));
      expect(await localDataSource.getCachedFloorById(floor.id), isNull);
      expect(await localDataSource.getCachedViewpointsByFloor(floor.id), isEmpty);
    });

    test('a new language downloads even when the content hash is unchanged', () async {
      await repository.syncTourBundle(lang: 'en');
      expect(await repository.syncTourBundle(lang: 'it'), isTrue);
      expect(remoteDataSource.bundleCallCount, 2);
      expect(await repository.syncTourBundle(lang: 'it'), isFalse);
    });

    test('a published offline seed preserves nested viewpoints and floor settings', () {
      final seed = TourBundleModel.fromSeedJson({
        'seedFormat': 'published-bundle-v1',
        'manifest': {'packageVersion': '2.0.0'},
        'floors': [{
          'id': 'exported_floor',
          'center': {'latitude': 41.89, 'longitude': 12.49},
          'defaultZoom': 17,
          'viewpoints': [{
            'id': 'exported_stop',
            'floorId': 'exported_floor',
            'latitude': 41.89,
            'longitude': 12.49,
            'description': 'Published narration',
          }],
        }],
      });
      expect(seed.manifest.version, '2.0.0');
      expect(seed.floors.single.center, const LatLng(41.89, 12.49));
      expect(seed.floors.single.defaultZoom, 17);
      expect(seed.floors.single.viewpoints.single.description, 'Published narration');
    });

    test('expired content refreshes with the same manifest and survives a failed refresh', () async {
      expect(await repository.refreshTourBundle(), TourSyncResult.updated);
      expect(await repository.refreshTourBundle(maxAge: const Duration(hours: 24)), TourSyncResult.unchanged);
      expect(await repository.refreshTourBundle(maxAge: Duration.zero), TourSyncResult.updated);
      expect(remoteDataSource.bundleCallCount, 2);
      final savedAt = await repository.getLastBundleDownload();
      remoteDataSource.shouldThrow = true;
      expect(await repository.refreshTourBundle(maxAge: Duration.zero), TourSyncResult.unavailable);
      expect(await repository.getLastBundleDownload(), savedAt);
    });

    test('TourSyncManifestModel parses json and matches equality', () {
      final json = {
        'version': '1.0.0',
        'dataHash': 'hash_test',
        'totalFloors': 4,
        'totalViewpoints': 28,
        'totalLandmarks': 5,
        'languages': ['en', 'it'],
      };
      final model = TourSyncManifestModel.fromJson(json);
      expect(model.version, '1.0.0');
      expect(model.dataHash, 'hash_test');
      expect(model.totalFloors, 4);
      expect(model.totalViewpoints, 28);
      expect(model.totalLandmarks, 5);
      expect(model.languages, contains('it'));

      final serialized = model.toJson();
      expect(serialized['dataHash'], 'hash_test');
    });

    test('LocalDataSource falls back to default floors when cache is empty',
        () async {
      final floors = await localDataSource.getCachedFloors();
      expect(floors.length, equals(FloorDefinition.allFloors.length));
      expect(floors[0].id, equals('floor_underground'));
    });

    test('LocalDataSource falls back to Colosseum overlays when cache is empty',
        () async {
      final overlays = await localDataSource.getCachedLandmarkOverlays();
      expect(overlays.length, equals(5));
      expect(overlays.any((o) => o.id == 'colosseum'), isTrue);
    });

    test('Repository syncs when cache is empty and remote manifest exists',
        () async {
      final updated = await repository.syncTourBundle();
      expect(updated, isTrue);
      expect(remoteDataSource.bundleCallCount, equals(1));

      final cachedManifest = await repository.getCurrentManifest();
      expect(cachedManifest?.dataHash, equals('hash_v1'));
    });

    test('Repository skips download when remote manifest hash matches cache',
        () async {
      // First sync
      await repository.syncTourBundle();
      expect(remoteDataSource.bundleCallCount, equals(1));

      // Second sync with identical hash
      final updatedAgain = await repository.syncTourBundle();
      expect(updatedAgain, isFalse);
      expect(remoteDataSource.bundleCallCount, equals(1)); // not called again
    });

    test('Repository gracefully falls back offline when remote throws network error',
        () async {
      remoteDataSource.shouldThrow = true;
      final updated = await repository.syncTourBundle();
      expect(updated, isFalse);

      final floors = await repository.getFloors();
      expect(floors.isNotEmpty, isTrue);
    });

    test('getFloorById returns matching floor or fallback definition',
        () async {
      final floor = await repository.getFloorById('floor_underground');
      expect(floor, isNotNull);
      expect(floor!.displayName, contains('Underground'));
    });

    test('getLandmarkMarkers forceRefresh saves created, edited, and deleted landmarks to local storage',
        () async {
      // 1. Initially return 1 landmark
      final initial = const LandmarkMarkerModel(
        id: 'monument_1',
        name: 'Monument 1',
        coordinates: LatLng(41.890, 12.492),
        color: Color(0xFFC68642),
      );
      remoteDataSource.markersToReturn = [initial];

      final res1 = await repository.getLandmarkMarkers(forceRefresh: true);
      expect(res1.length, equals(1));
      expect(res1.first.id, equals('monument_1'));

      // Check local storage has saved it
      final cached1 = await localDataSource.getCachedLandmarkMarkers();
      expect(cached1.length, equals(1));
      expect(cached1.first.id, equals('monument_1'));

      // 2. Add (create) a second landmark
      final created = const LandmarkMarkerModel(
        id: 'monument_2',
        name: 'Monument 2',
        coordinates: LatLng(41.895, 12.493),
        color: Color(0xFF2E7D32),
      );
      remoteDataSource.markersToReturn = [initial, created];

      final res2 = await repository.getLandmarkMarkers(forceRefresh: true);
      expect(res2.length, equals(2));
      final cached2 = await localDataSource.getCachedLandmarkMarkers();
      expect(cached2.length, equals(2));

      // 3. Edit landmark 1 (name change)
      final edited = initial.copyWith(name: 'Monument 1 Edited');
      remoteDataSource.markersToReturn = [edited, created];

      final res3 = await repository.getLandmarkMarkers(forceRefresh: true);
      expect(res3.first.name, equals('Monument 1 Edited'));
      final cached3 = await localDataSource.getCachedLandmarkMarkers();
      expect(cached3.first.name, equals('Monument 1 Edited'));

      // 4. Delete landmark 2
      remoteDataSource.markersToReturn = [edited];

      final res4 = await repository.getLandmarkMarkers(forceRefresh: true);
      expect(res4.length, equals(1));
      final cached4 = await localDataSource.getCachedLandmarkMarkers();
      expect(cached4.length, equals(1));
      expect(cached4.any((m) => m.id == 'monument_2'), isFalse);
    });

    test('getViewpointsByFloor fetches live viewpoints and saves to local cache', () async {
      const dynamicVp = ViewpointModel(
        id: 'vp_online_1',
        floorId: 'floor_underground',
        title: 'Online Discovered Stop',
        order: 1,
        normalizedX: 0.5,
        normalizedY: 0.5,
        description: 'New viewpoint from admin panel',
      );

      await localDataSource.saveViewpointsForFloor('floor_underground', [dynamicVp]);
      final cached = await localDataSource.getCachedViewpointsByFloor('floor_underground');
      expect(cached.length, equals(1));
      expect(cached.first.id, equals('vp_online_1'));
      expect(cached.first.title, equals('Online Discovered Stop'));

      final fromRepo = await repository.getViewpointsByFloor('floor_underground');
      expect(fromRepo.length, equals(1));
      expect(fromRepo.first.id, equals('vp_online_1'));

      final floor = await localDataSource.getCachedFloorById('floor_underground');
      expect(floor?.viewpoints.any((v) => v.id == 'vp_online_1'), isTrue);
    });
  });
}
