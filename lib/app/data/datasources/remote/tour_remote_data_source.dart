import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../../models/floor_definition.dart';
import '../../models/landmark_marker_model.dart';
import '../../models/landmark_overlay_model.dart';
import '../../models/sync_manifest_model.dart';
import '../../models/tour_bundle_model.dart';

/// Contract for fetching tour data from the remote backend.
abstract class ITourRemoteDataSource {
  Future<TourSyncManifestModel> getSyncManifest();
  Future<TourBundleModel> getTourBundle({String lang = 'en'});
  Future<List<MapLandmarkOverlay>> getLandmarks();
  Future<List<LandmarkMarkerModel>> getLandmarkMarkers();
  Future<List<FloorDefinition>> getFloors({String lang = 'en'});
  Future<FloorDefinition?> getFloorDetail(String floorId, {String lang = 'en'});
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
    // 1. Check candidate backend hosts in priority order
    for (final base in ApiConstants.candidateBaseUrls) {
      final targetUrl = url.replaceFirst(RegExp(r'^https?://[^/]+'), base);
      try {
        final targetUri = Uri.parse(targetUrl);
        final response =
            await _client.get(targetUri).timeout(const Duration(seconds: 3));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
      } catch (_) {}
    }

    final fallbackUri = Uri.parse(url);
    return await _client.get(fallbackUri).timeout(timeout);
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
  Future<TourBundleModel> getTourBundle({String lang = 'en'}) async {
    final response = await _get(ApiConstants.tourBundleUrl(lang: lang));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>? ?? json;
      return TourBundleModel.fromJson(data);
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
      final list = (json['data'] as List<dynamic>?) ??
          (json['payload'] as List<dynamic>?) ??
          [];
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
      final list = (json['data'] as List<dynamic>?) ??
          (json['payload'] as List<dynamic>?) ??
          [];
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
      final list = (json['data'] as List<dynamic>?) ?? [];
      return list
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
    final response = await _get(ApiConstants.floorDetail(floorId, lang: lang));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>?;
      if (data != null) {
        return FloorDefinition.fromJson(data);
      }
      return null;
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception(
          'Failed to load floor detail: ${response.statusCode} ${response.reasonPhrase}');
    }
  }
}
