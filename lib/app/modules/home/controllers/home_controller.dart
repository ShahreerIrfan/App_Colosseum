import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/landmark_marker_model.dart';
import '../../../data/models/landmark_overlay_model.dart';
import '../../../data/models/map_view_type.dart';
import '../../../data/providers/colosseum_landmark_overlays.dart';
import '../../../data/providers/landmark_markers_provider.dart';
import '../../../data/repositories/i_tour_repository.dart';
import '../../../data/repositories/tour_repository_impl.dart';
import '../../../routes/app_pages.dart';

class HomeController extends GetxController {
  late final MapController mapController;
  final ITourRepository tourRepository;

  static const LatLng colosseumCoordinates = LatLng(41.890210, 12.492231);
  static const double defaultZoom = 16.5;

  final currentZoom = defaultZoom.obs;

  /// Single source of truth for the 5 classic landmark pin markers.
  final landmarkMarkers = <LandmarkMarkerModel>[].obs;

  /// Currently selected landmark id (defaults to 'colosseum').
  final selectedLandmarkId = RxnString('colosseum');

  /// Single source of truth for the 5 calibrated landmark overlays (legacy / offline sync).
  final landmarkOverlays = <MapLandmarkOverlay>[].obs;

  /// Global toggle for landmark marker rendering.
  final isLandmarksVisible = true.obs;

  /// Debug mode toggle for developer alignment tools and visual bounds.
  final isDebugLandmarks = false.obs;

  /// Active base map view type (General vs Satellite).
  final selectedMapView = MapViewType.general.obs;

  HomeController({ITourRepository? tourRepository})
      : tourRepository = tourRepository ??
            (Get.isRegistered<ITourRepository>()
                ? Get.find<ITourRepository>()
                : TourRepositoryImpl());

  @override
  void onInit() {
    super.onInit();
    mapController = MapController();
    _initLandmarkMarkers();
    _initLandmarkOverlays();
  }

  void _initLandmarkMarkers() {
    landmarkMarkers.assignAll(LandmarkMarkersProvider.all);
  }

  void _initLandmarkOverlays() {
    _applyOverlays(ColosseumLandmarkOverlays.all);
    _loadRepositoryOverlays();
  }

  Future<void> _loadRepositoryOverlays() async {
    try {
      final overlays = await tourRepository.getLandmarkOverlays();
      if (overlays.isNotEmpty) {
        _applyOverlays(overlays);
      }
    } catch (_) {}
  }

  void _applyOverlays(List<MapLandmarkOverlay> list) {
    final overlays = list.map((overlay) {
      if (overlay.id == 'colosseum') {
        return overlay.copyWith(
          onTap: onColosseumTapped,
        );
      }
      return overlay;
    }).toList();
    landmarkOverlays.assignAll(overlays);
  }

  /// Navigation triggered when tapping on the Colosseum ground overlay image.
  void onColosseumTapped() {
    Get.toNamed(
      Routes.floors,
      arguments: {'landmarkName': 'Colosseum'},
    );
  }

  /// Selects a landmark marker and activates its highlighted state.
  /// If Colosseum is tapped while already selected, navigates directly to FloorsView.
  void selectLandmark(String landmarkId) {
    if (selectedLandmarkId.value == landmarkId) {
      if (landmarkId == 'colosseum') {
        onColosseumTapped();
      }
    } else {
      selectedLandmarkId.value = landmarkId;
    }
  }

  /// Updates properties of a specific landmark marker in the reactive list.
  void updateLandmarkMarker(LandmarkMarkerModel updated) {
    final index = landmarkMarkers.indexWhere((m) => m.id == updated.id);
    if (index != -1) {
      landmarkMarkers[index] = updated;
    }
  }

  void onPositionChanged(MapCamera camera, bool hasGesture) {
    currentZoom.value = camera.zoom;
  }

  void centerOnColosseum() {
    selectedLandmarkId.value = 'colosseum';
    try {
      mapController.move(colosseumCoordinates, defaultZoom);
    } catch (_) {
      // MapController is only attached when FlutterMap is rendered
    }
  }

  /// Toggles visibility of all landmark ground overlays.
  void toggleLandmarksVisibility() {
    isLandmarksVisible.toggle();
  }

  /// Toggles debug overlay outlines and center calibration labels.
  void toggleDebugLandmarks() {
    isDebugLandmarks.toggle();
  }

  /// Updates calibration parameters of a specific landmark overlay.
  void updateLandmarkOverlay(MapLandmarkOverlay updated) {
    final index = landmarkOverlays.indexWhere((o) => o.id == updated.id);
    if (index != -1) {
      landmarkOverlays[index] = updated;
    }
  }

  /// Switches base map between General and Satellite view.
  void switchMapView(MapViewType type) {
    selectedMapView.value = type;
  }

  /// Toggles base map view between General and Satellite.
  void toggleMapView() {
    selectedMapView.value = selectedMapView.value == MapViewType.general
        ? MapViewType.satellite
        : MapViewType.general;
  }

  @override
  void onClose() {
    mapController.dispose();
    super.onClose();
  }
}
