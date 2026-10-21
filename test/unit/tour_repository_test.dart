import 'package:flutter_test/flutter_test.dart';
import 'package:colosseum_client/app/data/datasources/local/tour_local_data_source.dart';
import 'package:colosseum_client/app/data/datasources/remote/tour_remote_data_source.dart';
import 'package:colosseum_client/app/data/models/floor_definition.dart';
import 'package:colosseum_client/app/data/models/landmark_overlay_model.dart';
import 'package:colosseum_client/app/data/models/sync_manifest_model.dart';
import 'package:colosseum_client/app/data/models/tour_bundle_model.dart';
import 'package:colosseum_client/app/data/repositories/tour_repository_impl.dart';

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
  });
}
