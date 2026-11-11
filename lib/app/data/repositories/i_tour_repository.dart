import 'package:latlong2/latlong.dart';

import '../models/floor_definition.dart';
import '../models/landmark_marker_model.dart';
import '../models/landmark_overlay_model.dart';
import '../models/sync_manifest_model.dart';
import '../models/viewpoint_model.dart';
import '../models/pedestrian_route_data.dart';

enum TourSyncResult { updated, unchanged, unavailable }

/// Contract for accessing tour data following the Repository Design Pattern.
abstract class ITourRepository {
  /// Synchronizes tour data from MongoDB backend if remote manifest is newer.
  /// Returns true if new data was synced, false if already up to date or offline.
  Future<bool> syncTourBundle({String lang = 'en'});
  Future<TourSyncResult> refreshTourBundle({String lang = 'en', bool force = false,
    Duration? maxAge});
  Future<DateTime?> getLastBundleDownload({String lang = 'en'});

  /// Retrieves list of all Colosseum monumental floors (cache-first).
  Future<List<FloorDefinition>> getFloors(
      {String lang = 'en', bool forceRefresh = false});

  /// Retrieves a specific floor definition by ID.
  Future<FloorDefinition?> getFloorById(String floorId, {String lang = 'en'});

  /// Retrieves viewpoints for a specific floor (cache-first or live backend sync).
  Future<List<ViewpointModel>> getViewpointsByFloor(
    String floorId, {
    bool forceRefresh = false,
    String lang = 'en',
  });

  /// Retrieves ground landmark overlays for monument and surrounding landmarks.
  Future<List<MapLandmarkOverlay>> getLandmarkOverlays(
      {bool forceRefresh = false});

  /// Retrieves landmark pin markers with color coding and coordinates.
  Future<List<LandmarkMarkerModel>> getLandmarkMarkers(
      {String lang = 'en', bool forceRefresh = false});

  /// Retrieves pedestrian street routing segments connecting all landmarks.
  Future<List<List<LatLng>>> getPedestrianStreetSegments(
      {bool forceRefresh = false});
  Future<List<PedestrianRouteData>> getPedestrianRoutes({
    String lang = 'en',
    bool forceRefresh = false,
  });

  /// Retrieves the current cached tour manifest.
  Future<TourSyncManifestModel?> getCurrentManifest();
}
