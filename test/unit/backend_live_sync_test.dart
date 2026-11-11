import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:colosseum_client/app/core/constants/api_constants.dart';
import 'package:colosseum_client/app/data/datasources/remote/tour_remote_data_source.dart';
import 'package:colosseum_client/app/data/datasources/local/tour_local_data_source.dart';
import 'package:colosseum_client/app/data/repositories/tour_repository_impl.dart';

void main() {
  group('Backend Live Sync Integration Test', () {
    test('fetches live manifest and caches the published tour bundle if online',
        () async {
      final client = http.Client();
      addTearDown(client.close);
      bool isBackendReachable = false;
      try {
        final res = await client
            .get(Uri.parse('${ApiConstants.apiV1}/health'))
            .timeout(const Duration(seconds: 2));
        isBackendReachable = res.statusCode == 200;
      } catch (_) {
        isBackendReachable = false;
      }

      if (!isBackendReachable) {
        // Skip live network verification if local daemon is not running in test runner environment
        return;
      }

      final remoteSource = TourRemoteDataSource(client: client);
      final localSource = TourLocalDataSource();
      final repository = TourRepositoryImpl(
        remoteDataSource: remoteSource,
        localDataSource: localSource,
      );

      final manifest = await remoteSource.getSyncManifest();
      expect(manifest.dataHash, isNotEmpty);

      final synced = await repository.syncTourBundle(lang: 'en');
      expect(synced, isTrue);

      final cachedBundle = await localSource.getCachedTourBundle();
      expect(cachedBundle, isNotNull);
      expect(cachedBundle!.floors, isNotEmpty);
      expect(cachedBundle.landmarks, isNotEmpty);
      final cachedFloors = await repository.getFloors();
      expect(cachedFloors.map((floor) => floor.id),
          unorderedEquals(cachedBundle.floors.map((floor) => floor.id)));
    });
  });
}
