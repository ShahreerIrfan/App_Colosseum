import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../../models/floor_definition.dart';
import '../../models/landmark_marker_model.dart';
import '../../models/landmark_overlay_model.dart';
import '../../models/sync_manifest_model.dart';
import '../../models/tour_bundle_model.dart';
import '../../models/viewpoint_model.dart';

/// Contract for fetching tour data from the remote backend.
abstract class ITourRemoteDataSource {
  Future<TourSyncManifestModel> getSyncManifest();
  Future<TourBundleModel> getTourBundle({String lang = 'en'});
  Future<List<MapLandmarkOverlay>> getLandmarks();
  Future<List<LandmarkMarkerModel>> getLandmarkMarkers();
  Future<List<FloorDefinition>> getFloors({String lang = 'en'});
  Future<FloorDefinition?> getFloorDetail(String floorId, {String lang = 'en'});
  Future<List<ViewpointModel>> getViewpointsByFloor(String floorId, {String lang = 'en'});
}

/// Implementation of [ITourRemoteDataSource] using [http.Client] and centralized [ApiConstants].
class TourRemoteDataSource implements ITourRemoteDataSource {
  final http.Client _client;
  final Duration timeout;

  TourRemoteDataSource({
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  Future<http.Response> _get(String url) async {
    return _client.get(Uri.parse(url)).timeout(timeout);
  }

  @override
  Future<TourSyncManifestModel> getSyncManifest() async {
    final response = await _get(ApiConstants.syncManifest);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>? ?? json;
      return TourSyncManifestModel.fromJson(data);
    } else {
      throw Exception(
          'Failed to load sync manifest: ${response.statusCode} ${response.reasonPhrase}');
    }
  }

  @override
  Future<TourBundleModel> getTourBundle({String lang = 'en', String? landmarkId}) async {
    final uri = Uri.parse(ApiConstants.tourBundleUrl(lang: lang));
    final url = landmarkId == null ? uri : uri.replace(queryParameters: {
      ...uri.queryParameters,
      'landmark': landmarkId,
    });
    final response = await _get(url.toString());

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>? ?? json;
      if (data['manifest'] is! Map || data['floors'] is! List ||
          data['landmarks'] is! List || data['pedestrianRoutes'] is! List) {
        throw const FormatException('Incomplete tour bundle');
      }
      // Older servers ignore the scope parameter. Filter their full response
      // before decoding floor IDs, which also have legacy landmark aliases.
      if (landmarkId != null) {
        data['floors'] = (data['floors'] as List).where((entry) {
          final floor = entry as Map;
          return (floor['landmarkCode'] ?? floor['landmarkId']) == landmarkId;
        }).toList();
      }
      final bundle = TourBundleModel.fromJson(data);
      if (bundle.manifest.dataHash.isEmpty || bundle.floors.any((floor) => floor.id.isEmpty)) {
        throw const FormatException('Invalid tour bundle');
      }
      return bundle;
    } else {
      throw Exception(
          'Failed to load tour bundle: ${response.statusCode} ${response.reasonPhrase}');
    }
  }

  @override
  Future<List<MapLandmarkOverlay>> getLandmarks() async {
    final response = await _get(ApiConstants.landmarks);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (json['data'] ?? json['payload']) as List<dynamic>;
      return list
          .map((item) =>
              MapLandmarkOverlay.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } else {
      throw Exception(
          'Failed to load landmarks: ${response.statusCode} ${response.reasonPhrase}');
    }
  }

  @override
  Future<List<LandmarkMarkerModel>> getLandmarkMarkers() async {
    final response = await _get(ApiConstants.landmarks);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (json['data'] ?? json['payload']) as List<dynamic>;
      return list
          .map((item) =>
              LandmarkMarkerModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } else {
      throw Exception(
          'Failed to load landmark markers: ${response.statusCode} ${response.reasonPhrase}');
    }
  }

  @override
  Future<List<FloorDefinition>> getFloors({String lang = 'en'}) async {
    final response = await _get(ApiConstants.floors);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = json['data'] as List<dynamic>;
      return list
          .where((item) => (item as Map)['isPublished'] != false)
          .map((item) =>
              FloorDefinition.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } else {
      throw Exception(
          'Failed to load floors: ${response.statusCode} ${response.reasonPhrase}');
    }
  }

  @override
  Future<FloorDefinition?> getFloorDetail(String floorId,
      {String lang = 'en'}) async {
    final url = '${ApiConstants.floors}/$floorId?lang=$lang';
    final response = await _get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>? ?? json;
      return FloorDefinition.fromJson(data);
    }
    return null;
  }

  @override
  Future<List<ViewpointModel>> getViewpointsByFloor(String floorId,
      {String lang = 'en'}) async {
    const pageSize = 100;
    final viewpoints = <String, ViewpointModel>{};
    for (var page = 1; ; page++) {
      final url = Uri.parse(ApiConstants.viewpoints).replace(queryParameters: {
        'floorId': floorId,
        'lang': lang,
        'limit': '$pageSize',
        'page': '$page',
      });
      final response = await _get(url.toString());
      if (response.statusCode != 200) {
        throw Exception('Failed to load viewpoints for floor $floorId: ${response.statusCode}');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = json['data'] as List<dynamic>;
      final previousSize = viewpoints.length;
      for (final item in list) {
        final viewpoint = ViewpointModel.fromJson(Map<String, dynamic>.from(item as Map));
        if (viewpoint.id.isEmpty || viewpoint.floorId != floorId) {
          throw const FormatException('Invalid Viewpoint in floor response');
        }
        viewpoints[viewpoint.id] = viewpoint;
      }
      if (list.length < pageSize) return viewpoints.values.toList();
      if (viewpoints.length == previousSize) {
        throw const FormatException('Viewpoint pagination did not advance');
      }
    }
  }
}
