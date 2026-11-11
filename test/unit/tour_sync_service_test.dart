import 'dart:async';

import 'package:colosseum_client/app/data/datasources/local/tour_local_data_source.dart';
import 'package:colosseum_client/app/data/datasources/remote/tour_remote_data_source.dart';
import 'package:colosseum_client/app/data/models/sync_manifest_model.dart';
import 'package:colosseum_client/app/data/models/tour_bundle_model.dart';
import 'package:colosseum_client/app/data/repositories/i_tour_repository.dart';
import 'package:colosseum_client/app/data/repositories/tour_repository_impl.dart';
import 'package:colosseum_client/app/data/services/offline_landmark_store.dart';
import 'package:colosseum_client/app/data/services/tour_sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

class _Connection implements Connectivity {
  final controller = StreamController<List<ConnectivityResult>>.broadcast(sync: true);
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [
    ConnectivityResult.mobile,
  ];
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      controller.stream;
}

class _Server extends TourRemoteDataSource {
  int revision = 1;
  int downloads = 0;
  int checks = 0;
  bool offline = false;
  String? requestedLanguage;

  TourSyncManifestModel get manifest => TourSyncManifestModel(
    version: '1',
    dataHash: '$revision',
    totalFloors: 0,
    totalViewpoints: 0,
    totalLandmarks: revision == 1 ? 1 : 0,
    languages: const ['it'],
  );

  @override
  Future<TourSyncManifestModel> getSyncManifest() async {
    checks++;
    if (offline) throw StateError('No internet');
    return manifest;
  }

  @override
  Future<TourBundleModel> getTourBundle({
    String lang = 'en',
    String? landmarkId,
  }) async {
    downloads++;
    requestedLanguage = lang;
    if (offline) throw StateError('No internet');
    return TourBundleModel.fromJson({
      'manifest': manifest.toJson(),
      'floors': [],
      'landmarks': [
        if (revision == 1) {'id': 'deleted-landmark', 'name': 'Old marker'},
      ],
      'pedestrianRoutes': [],
    });
  }
}

void main() {
  testWidgets(
    'polls every five minutes, replaces deleted markers, and syncs on reconnect',
    (tester) async {
      final connection = _Connection();
      final server = _Server();
      final local = TourLocalDataSource();
      final service = TourSyncService(
        TourRepositoryImpl(remoteDataSource: server, localDataSource: local),
        OfflineLandmarkStore(),
        connectivity: connection,
      );
      service.onInit();
      addTearDown(() {
        service.onClose();
        unawaited(connection.controller.close());
      });
      final seen = <TourBundleModel>[];
      final subscription = service.snapshots.listen(seen.add);
      addTearDown(() => unawaited(subscription.cancel()));

      await service.activate('it');
      expect(seen.single.landmarkMarkers.single.id, 'deleted-landmark');
      await tester.pump(const Duration(minutes: 4, seconds: 59));
      expect(server.checks, 0);
      await tester.pump(const Duration(seconds: 1));
      expect(server.checks, 1);
      expect(
        server.downloads,
        1,
        reason: 'unchanged version does not fetch the bundle',
      );

      server.revision = 2;
      server.offline = true;
      connection.controller.add([ConnectivityResult.none]);
      await tester.pump(const Duration(minutes: 5));
      expect(seen.last.landmarkMarkers, isNotEmpty);

      server.offline = false;
      connection.controller.add([ConnectivityResult.mobile]);
      expect(server.checks, 3);
      final update = service.check();
      await tester.pump();
      expect(await update, TourSyncResult.updated);
      expect(seen.last.landmarkMarkers, isEmpty);
      expect(
        (await local.getCachedTourBundle(lang: 'it'))!.landmarkMarkers,
        isEmpty,
      );
      expect(server.downloads, 2);
      expect(server.requestedLanguage, 'it');
      unawaited(subscription.cancel());
      service.onClose();
    },
  );
}
