import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:colosseum_client/app/data/datasources/remote/tour_remote_data_source.dart';
import 'package:colosseum_client/app/data/services/offline_landmark_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('stores georeferenced aerial imagery and preserves it after a failed update', () async {
    final directory = await Directory.systemTemp.createTemp(
      'offline-landmark-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    const imageUrl = 'https://example.test/viewpoint.png';
    const landmarkId = 'colosseum';
    var version = 'v1';
    var usePlaceholder = false;
    final aerialRequests = <Uri>[];
    final image = await File('assets/images/viewpoint_default.png')
        .readAsBytes();
    Future<List<int>> tileBytes({required bool placeholder}) async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      for (var row = 0; row < 8; row++) {
        for (var column = 0; column < 8; column++) {
          final even = (row + column).isEven;
          canvas.drawRect(
            ui.Rect.fromLTWH(column * 32.0, row * 32.0, 32, 32),
            ui.Paint()
              ..color = ui.Color(
                placeholder
                    ? (even ? 0xff000000 : 0xffffffff)
                    : (even ? 0xff557744 : 0xff996633),
              ),
          );
        }
      }
      final picture = recorder.endRecording();
      final tile = await picture.toImage(256, 256);
      final bytes = (await tile.toByteData(format: ui.ImageByteFormat.png))!;
      tile.dispose();
      picture.dispose();
      return bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
    }

    final photoTile = await tileBytes(placeholder: false);
    final placeholderTile = await tileBytes(placeholder: true);
    final remote = TourRemoteDataSource(
      client: MockClient((request) async {
        expect(request.url.queryParameters['landmark'], landmarkId);
        expect(request.url.queryParameters['lang'], 'it');
        return http.Response(
          jsonEncode({
            'data': {
              'manifest': {'packageVersion': version, 'contentHash': version},
              'landmarks': [
                {
                  'id': landmarkId,
                  'name': 'Colosseo',
                  'description': 'Anfiteatro',
                },
                {'id': 'roman_forum', 'name': 'Foro Romano'},
              ],
              'floors': [
                {
                  'id': 'floor_underground',
                  'landmarkCode': landmarkId,
                  'displayName': 'Sotterranei',
                  'viewpoints': [
                    {
                      'id': 'offline_stop',
                      'floorId': 'floor_underground',
                      'title': 'Ingresso',
                      'description': 'La visita inizia qui.',
                      'narrationLanguage': 'it',
                      'imageAsset': imageUrl,
                    },
                  ],
                },
                {'id': 'forum_via_sacra', 'landmarkCode': 'roman_forum'},
              ],
              'pedestrianRoutes': [
                {
                  'fromLandmarkCode': landmarkId,
                  'toLandmarkCode': 'roman_forum',
                  'instruction': 'Segui il percorso',
                  'waypoints': [
                    {'latitude': 41.89, 'longitude': 12.49},
                    {'latitude': 41.891, 'longitude': 12.491},
                  ],
                },
              ],
            },
          }),
          200,
        );
      }),
    );
    OfflineLandmarkStore newStore() => OfflineLandmarkStore(
      remote: remote,
      directory: () async => directory,
      client: () => MockClient((request) async {
        if (request.url.host == 'geoportale.agea.gov.it') {
          aerialRequests.add(request.url);
          return http.Response.bytes(
            usePlaceholder ? placeholderTile : photoTile,
            200,
          );
        }
        return http.Response.bytes(
          image,
          200,
          headers: {'content-length': image.length.toString()},
        );
      }),
    );
    final store = newStore();
    final package = await store.prepare(landmarkId, 'it');
    expect(package.floors.map((floor) => floor.id), ['floor_underground']);
    expect(package.routes.single.instruction, 'Segui il percorso');
    final progress = <int>[];
    await store.save(package, onProgress: (done, _) => progress.add(done));
    expect(progress, [0, 1, 2]);
    final preparedMap = package.aerialMap!;
    expect(
      aerialRequests.length,
      preparedMap.tileRows * preparedMap.tileColumns,
    );
    expect(aerialRequests.first.path, contains('/WMTS/tile/'));
    expect(aerialRequests.toSet().length, aerialRequests.length);

    usePlaceholder = true;
    final reloadedStore = newStore();
    final saved = (await reloadedStore.list('it')).single;
    expect(saved.landmark.description, 'Anfiteatro');
    expect(saved.floors.single.viewpoints.single.narrationLanguage, 'it');
    final file = File.fromUri(
      Uri.parse(saved.floors.single.viewpoints.single.imageAsset!),
    );
    expect(await file.readAsBytes(), image);
    final map = saved.aerialMap!;
    final aerialFile = File.fromUri(Uri.parse(map.imagePath));
    final codec = await ui.instantiateImageCodec(
      await aerialFile.readAsBytes(),
    );
    final mosaic = (await codec.getNextFrame()).image;
    expect(mosaic.width, preparedMap.tileColumns * 256);
    expect(mosaic.height, preparedMap.tileRows * 256);
    final pixels = (await mosaic.toByteData())!;
    expect(pixels.getUint32(0), 0x557744ff);
    expect(pixels.getUint32(256 * 4), 0x557744ff);
    mosaic.dispose();
    codec.dispose();
    expect(map.bounds.contains(saved.landmark.center), isTrue);
    expect(saved.needsAerialMap, isFalse);
    final legacyMap = map.toJson()..remove('source');
    final legacy = OfflineLandmark.fromJson({
      ...saved.toJson(),
      'aerialMap': legacyMap,
    });
    expect(legacy.aerialMap, isNull);
    expect(legacy.needsAerialMap, isTrue);
    expect(await reloadedStore.list('en'), isEmpty);

    version = 'v2';
    final replacement = await store.prepare(landmarkId, 'it');
    await expectLater(
      store.save(replacement, onProgress: (_, _) {}),
      throwsA(isA<FormatException>()),
    );
    expect(
      (await reloadedStore.get(landmarkId, 'it'))?.manifest.dataHash,
      'v1',
    );
    expect(await file.exists(), isTrue);
    expect(await aerialFile.exists(), isTrue);

    await reloadedStore.remove(saved);
    expect(await reloadedStore.list('it'), isEmpty);
    expect(await file.exists(), isFalse);
    expect(await aerialFile.exists(), isFalse);
  });
}
