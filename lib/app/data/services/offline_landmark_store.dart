import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../core/utils/geodesic_utils.dart';
import '../datasources/remote/tour_remote_data_source.dart';
import '../models/floor_definition.dart';
import '../models/landmark_overlay_model.dart';
import '../models/offline_aerial_map.dart';
import '../models/pedestrian_route_data.dart';
import '../models/sync_manifest_model.dart';

class OfflineLandmark {
  final MapLandmarkOverlay landmark;
  final List<FloorDefinition> floors;
  final List<PedestrianRouteData> routes;
  final TourSyncManifestModel manifest;
  final String language;
  final OfflineAerialMap? aerialMap;

  const OfflineLandmark({
    required this.landmark,
    required this.floors,
    required this.routes,
    required this.manifest,
    required this.language,
    this.aerialMap,
  });

  factory OfflineLandmark.fromJson(Map<String, dynamic> json) =>
      OfflineLandmark(
        landmark: MapLandmarkOverlay.fromJson(
          json['landmark'] as Map<String, dynamic>,
        ),
        floors: FloorDefinition.parseFloorsFromBundleJson(json)
            .map(
              (floor) => floor.copyWith(
                landmarkId: (json['landmark'] as Map)['id'] as String,
              ),
            )
            .toList(),
        routes: PedestrianRouteData.parseList(json['pedestrianRoutes']),
        manifest: TourSyncManifestModel.fromJson(
          json['manifest'] as Map<String, dynamic>,
        ),
        language: json['language'] as String,
        aerialMap: json['aerialMap'] is Map<String, dynamic>
            ? OfflineAerialMap.fromJson(
                json['aerialMap'] as Map<String, dynamic>,
              )
            : null,
      );

  Map<String, dynamic> toJson() => {
    'landmark': landmark.toJson(),
    'floors': floors.map((floor) => floor.toJson()).toList(),
    'pedestrianRoutes': routes.map((route) => route.toJson()).toList(),
    'manifest': manifest.toJson(),
    'language': language,
    'aerialMap': aerialMap?.toJson(),
  };

  Set<String> get media => {
    landmark.assetPath,
    if (aerialMap case final OfflineAerialMap map) map.imagePath,
    if (landmark.thumbnailUrl case final String path) path,
    for (final floor in floors)
      for (final viewpoint in floor.viewpoints)
        if (viewpoint.imageAsset case final String path) path,
  };

  bool get needsAerialMap =>
      aerialMap == null && OfflineAerialMap.covers(landmark.center);
}

/// Explicit downloads are stored separately from the rotating tour cache.
class OfflineLandmarkStore {
  static const maxImageBytes = 20 * 1024 * 1024;
  static const maxPackageBytes = 250 * 1024 * 1024;
  static const _requestTimeout = Duration(seconds: 25);

  final TourRemoteDataSource _remote;
  final Future<Directory> Function() _directory;
  final http.Client Function() _client;
  final _writing = <String>{};
  final _inUse = <String, int>{};

  void pin(OfflineLandmark package) {
    final key = _key(package.landmark.id, package.language);
    _inUse.update(key, (count) => count + 1, ifAbsent: () => 1);
  }

  void unpin(OfflineLandmark package) {
    final key = _key(package.landmark.id, package.language);
    final count = _inUse[key] ?? 0;
    if (count <= 1) {
      _inUse.remove(key);
    } else {
      _inUse[key] = count - 1;
    }
  }

  Future<void> refreshSaved(
    OfflineLandmark saved, {
    required bool Function() canContinue,
  }) async {
    final key = _key(saved.landmark.id, saved.language);
    bool allowed() => !_inUse.containsKey(key) && canContinue();
    if (!allowed() || _writing.contains(key)) return;
    final fresh = await prepare(saved.landmark.id, saved.language);
    if (!allowed() ||
        _writing.contains(key) ||
        (fresh.manifest == saved.manifest && !saved.needsAerialMap)) {
      return;
    }
    // The visitor may have removed or updated this package during the request.
    final current = await get(saved.landmark.id, saved.language);
    if (current == null || current.manifest != saved.manifest || !allowed()) {
      return;
    }
    await save(fresh, onProgress: (_, _) {}, canContinue: allowed);
  }

  OfflineLandmarkStore({
    TourRemoteDataSource? remote,
    Future<Directory> Function()? directory,
    http.Client Function()? client,
  }) : _remote = remote ?? TourRemoteDataSource(),
       _directory = directory ?? getApplicationSupportDirectory,
       _client = client ?? http.Client.new;

  Future<Directory> _root() async {
    final base = await _directory();
    return Directory('${base.path}/offline-landmarks-v1')
        .create(recursive: true);
  }

  String _key(String id, String language) =>
      base64Url.encode(utf8.encode('$language:$id'));

  Future<OfflineLandmark> prepare(String id, String language) async {
    final bundle = await _remote.getTourBundle(lang: language, landmarkId: id);
    final landmark = bundle.landmarks.firstWhere((entry) => entry.id == id);
    final floors = bundle.floors
        .map(
          (floor) => floor.copyWith(
            landmarkId: id,
            viewpoints: floor.viewpoints.map((viewpoint) {
              if (viewpoint.hasGeographicPosition) return viewpoint;
              final point = GeodesicUtils.canvasOffsetToLatLng(
                ui.Offset(viewpoint.normalizedX, viewpoint.normalizedY),
                centerLat: floor.center.latitude,
                centerLng: floor.center.longitude,
                monumentRotationDegrees: floor.mapNorthOffsetDegrees,
              );
              return viewpoint.copyWith(
                latitude: point.latitude,
                longitude: point.longitude,
              );
            }).toList(),
          ),
        )
        .toList();
    if (floors.isEmpty) throw const FormatException('No published floors');
    return OfflineLandmark(
      landmark: landmark,
      floors: floors,
      routes: (bundle.pedestrianRoutes ?? [])
          .where(
            (route) =>
                route.fromLandmarkCode == id || route.toLandmarkCode == id,
          )
          .toList(),
      manifest: bundle.manifest,
      language: language,
      aerialMap: OfflineAerialMap.forLandmark(landmark.center),
    );
  }

  Future<TourSyncManifestModel> latestManifest() => _remote.getSyncManifest();

  Future<int?> estimateBytes(OfflineLandmark package) async {
    final client = _client();
    try {
      var bytes = utf8.encode(jsonEncode(package.toJson())).length;
      final aerialPath = package.aerialMap?.imagePath;
      if (aerialPath != null) bytes += 1024 * 1024;
      final urls = package.media
          .where((path) => path != aerialPath)
          .map(_remoteUri)
          .whereType<Uri>()
          .toList();
      for (var offset = 0; offset < urls.length; offset += 6) {
        final lengths = await Future.wait(
          urls.skip(offset).take(6).map((url) async {
            try {
              final response = await client
                  .head(url)
                  .timeout(const Duration(seconds: 3));
              return response.statusCode == 200
                  ? int.tryParse(response.headers['content-length'] ?? '')
                  : null;
            } catch (_) {
              return null;
            }
          }),
        );
        if (lengths.any((length) => length == null)) return null;
        bytes += lengths.fold(0, (total, length) => total + length!);
      }
      return bytes;
    } finally {
      client.close();
    }
  }

  Future<OfflineLandmark?> get(String id, String language) async {
    final root = await _root();
    return _read(File('${root.path}/${_key(id, language)}.json'));
  }

  Future<List<OfflineLandmark>> list(String language) async {
    final root = await _root();
    final packages = <OfflineLandmark>[];
    await for (final entry in root.list(followLinks: false)) {
      if (entry is! File || !entry.path.endsWith('.json')) continue;
      final package = await _read(entry);
      if (package?.language == language) packages.add(package!);
    }
    return packages..sort((a, b) => a.landmark.name.compareTo(b.landmark.name));
  }

  Future<OfflineLandmark?> _read(File index) async {
    try {
      final data =
          jsonDecode(await index.readAsString()) as Map<String, dynamic>;
      final package = OfflineLandmark.fromJson(data);
      if (package.floors.isEmpty) return null;
      for (final path in package.media) {
        final uri = Uri.tryParse(path);
        if (uri?.scheme == 'file' && !await File.fromUri(uri!).exists()) {
          return null;
        }
      }
      return package;
    } catch (_) {
      return null;
    }
  }

  Future<void> _removeGeneration(Directory root, File index) async {
    try {
      final data = jsonDecode(await index.readAsString()) as Map;
      final generation = data['generation'];
      if (generation is String &&
          RegExp(r'^media-[a-zA-Z0-9]+$').hasMatch(generation)) {
        await Directory('${root.path}/$generation').delete(recursive: true);
      }
    } on Exception {
      // An obsolete directory must not prevent a valid package from opening.
    }
  }

  Future<OfflineLandmark> save(
    OfflineLandmark package, {
    required void Function(int completed, int total) onProgress,
    bool Function()? canContinue,
  }) async {
    final key = _key(package.landmark.id, package.language);
    if (!_writing.add(key)) throw StateError('Download already in progress');
    Directory? generation;
    File? stagedIndex;
    File? obsoleteIndex;
    http.Client? client;
    var committed = false;
    try {
      final root = await _root();
      final directory = generation = await root.createTemp('media-');
      final index = File('${root.path}/$key.json');
      final network = client = _client();
      final aerialMap = package.aerialMap;
      final aerialUri = _remoteUri(aerialMap?.imagePath);
      final urls = package.media.map(_remoteUri).whereType<Uri>().toSet();
      final files = <Uri, String>{};
      var totalBytes = 0;
      onProgress(0, urls.length);
      for (final uri in urls) {
        if (canContinue?.call() == false) throw StateError('Download paused');
        final file = File('${directory.path}/${files.length}.image');
        final remainingBytes = maxPackageBytes - totalBytes;
        totalBytes += aerialMap != null && uri == aerialUri
            ? await _saveAerialMap(
                network,
                aerialMap,
                file,
                remainingBytes,
                canContinue,
              )
            : await _saveImage(network, uri, file, remainingBytes, canContinue);
        files[uri] = file.uri.toString();
        onProgress(files.length, urls.length);
      }

      String? local(String? path) => files[_remoteUri(path)] ?? path;
      final saved = OfflineLandmark(
        landmark: package.landmark.copyWith(
          assetPath: local(package.landmark.assetPath),
          thumbnailUrl: local(package.landmark.thumbnailUrl),
        ),
        floors: package.floors
            .map(
              (floor) => floor.copyWith(
                viewpoints: floor.viewpoints
                    .map((vp) => vp.copyWith(imageAsset: local(vp.imageAsset)))
                    .toList(),
              ),
            )
            .toList(),
        routes: package.routes,
        manifest: package.manifest,
        language: package.language,
        aerialMap: aerialMap?.withImagePath(local(aerialMap.imagePath)!),
      );
      final name = directory.uri.pathSegments
          .where((segment) => segment.isNotEmpty)
          .last;
      final staged = stagedIndex = File('${root.path}/$name.pending');
      await staged.writeAsString(
        jsonEncode({...saved.toJson(), 'generation': name}),
        flush: true,
      );
      if (await index.exists()) {
        obsoleteIndex = await index.copy('${root.path}/$name.previous');
      }
      if (canContinue?.call() == false) throw StateError('Download paused');
      await staged.rename(index.path);
      committed = true;
      if (obsoleteIndex != null && !_inUse.containsKey(key)) {
        await _removeGeneration(root, obsoleteIndex);
      }
      return saved;
    } finally {
      client?.close();
      _writing.remove(key);
      await _deleteQuietly(stagedIndex);
      await _deleteQuietly(obsoleteIndex);
      if (!committed) await _deleteQuietly(generation);
    }
  }

  Future<void> remove(OfflineLandmark package) async {
    final key = _key(package.landmark.id, package.language);
    if (!_writing.add(key)) throw StateError('Download in progress');
    try {
      final root = await _root();
      final index = File('${root.path}/$key.json');
      if (!await index.exists()) return;
      final obsolete = await index.rename('${root.path}/$key.removed');
      await _removeGeneration(root, obsolete);
      await _deleteQuietly(obsolete);
    } finally {
      _writing.remove(key);
    }
  }

  static Uri? _remoteUri(String? path) {
    final uri = path == null ? null : Uri.tryParse(path);
    return uri != null &&
            (uri.scheme == 'https' || uri.scheme == 'http') &&
            uri.host.isNotEmpty
        ? uri
        : null;
  }

  Future<int> _saveImage(
    http.Client client,
    Uri uri,
    File file,
    int remainingBytes,
    bool Function()? canContinue,
  ) async {
    final bytes = await _downloadImage(
      client,
      uri,
      file,
      remainingBytes,
      canContinue,
    );
    final codec = await ui.instantiateImageCodec(
      await file.readAsBytes(),
      targetWidth: 16,
    );
    try {
      final frame = await codec.getNextFrame();
      frame.image.dispose();
    } finally {
      codec.dispose();
    }
    return bytes;
  }

  Future<int> _downloadImage(
    http.Client client,
    Uri uri,
    File file,
    int remainingBytes,
    bool Function()? canContinue,
  ) async {
    final request = http.Request('GET', uri);
    final response = await client.send(request).timeout(_requestTimeout);
    final limit = remainingBytes < maxImageBytes
        ? remainingBytes
        : maxImageBytes;
    if (response.statusCode != 200 || (response.contentLength ?? 0) > limit) {
      throw const FormatException(
        'Image download failed or exceeds the size limit',
      );
    }
    final sink = file.openWrite();
    var bytes = 0;
    try {
      await sink.addStream(
        response.stream.timeout(_requestTimeout).map((chunk) {
          if (canContinue?.call() == false) throw StateError('Download paused');
          bytes += chunk.length;
          if (bytes > limit) {
            throw const FormatException('Image exceeds size limit');
          }
          return chunk;
        }),
      );
    } finally {
      await sink.close();
    }
    return bytes;
  }

  Future<int> _saveAerialMap(
    http.Client client,
    OfflineAerialMap map,
    File file,
    int remainingBytes,
    bool Function()? canContinue,
  ) async {
    const tileSize = OfflineAerialMap.tilePixels;
    final rows = map.tileRows;
    final columns = map.tileColumns;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    try {
      for (var row = 0; row < rows; row++) {
        if (canContinue?.call() == false) throw StateError('Download paused');
        await Future.wait(
          List.generate(columns, (column) async {
            final tile = File('${file.path}-$row-$column');
            try {
              await _downloadImage(
                client,
                map.tileUrl(row, column),
                tile,
                1024 * 1024,
                canContinue,
              );
              final codec = await ui.instantiateImageCodec(
                await tile.readAsBytes(),
              );
              try {
                final frame = await codec.getNextFrame();
                final image = frame.image;
                try {
                  if (image.width != tileSize || image.height != tileSize) {
                    throw const FormatException('Unexpected aerial tile size');
                  }
                  await _validateAerialImage(image);
                  canvas.drawImage(
                    image,
                    ui.Offset(
                      column * tileSize.toDouble(),
                      row * tileSize.toDouble(),
                    ),
                    ui.Paint(),
                  );
                } finally {
                  image.dispose();
                }
              } finally {
                codec.dispose();
              }
            } finally {
              await _deleteQuietly(tile);
            }
          }),
        );
      }
    } catch (_) {
      recorder.endRecording().dispose();
      rethrow;
    }
    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(columns * tileSize, rows * tileSize);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes == null || bytes.lengthInBytes > remainingBytes) {
          throw const FormatException('Aerial map could not be saved');
        }
        await file.writeAsBytes(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
        return bytes.lengthInBytes;
      } finally {
        image.dispose();
      }
    } finally {
      picture.dispose();
    }
  }

  Future<void> _validateAerialImage(ui.Image image) async {
    final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (pixels == null) {
      throw const FormatException('Aerial imagery could not be read');
    }
    // Missing coverage can be returned as a valid JPEG of black and white squares.
    var blankPixels = 0;
    for (var offset = 0; offset < pixels.lengthInBytes; offset += 4) {
      final r = pixels.getUint8(offset);
      final g = pixels.getUint8(offset + 1);
      final b = pixels.getUint8(offset + 2);
      final a = pixels.getUint8(offset + 3);
      if (a == 0 ||
          (r < 24 && g < 24 && b < 24) ||
          (r > 231 && g > 231 && b > 231)) {
        blankPixels++;
      }
    }
    if (blankPixels >= image.width * image.height * 0.75) {
      throw const FormatException(
        'Aerial imagery is unavailable for this area',
      );
    }
  }

  Future<void> _deleteQuietly(FileSystemEntity? entity) async {
    try {
      await entity?.delete(recursive: true);
    } on FileSystemException {
      // Cleanup can be retried without invalidating the committed package.
    }
  }
}
