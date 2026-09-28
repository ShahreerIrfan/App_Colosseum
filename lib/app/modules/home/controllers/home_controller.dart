import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/utils/geodesic_utils.dart';
import '../../../data/models/poi_model.dart';

class HomeController extends GetxController {
  late final MapController mapController;

  static const LatLng colosseumCoordinates = LatLng(41.890210, 12.492231);
  static const double defaultZoom = 16.5;
  static const double overlayZoomThreshold = 15.5;

  final currentZoom = defaultZoom.obs;
  final selectedPoi = Rxn<PoiModel>();

  late final List<PoiModel> landmarks;

  @override
  void onInit() {
    super.onInit();
    mapController = MapController();
    _initializeLandmarks();
  }

  void _initializeLandmarks() {
    landmarks = [
      // 1. Colosseum
      PoiModel(
        id: 'colosseum',
        name: 'Colosseum',
        latitude: 41.890210,
        longitude: 12.492231,
        assetPath: AppAssets.colosseum,
        overlayAssetPath: AppAssets.colosseum,
        description: 'The monumental Flavian Amphitheatre of Imperial Rome, built between 72 and 80 AD.',
        baseMarkerSize: 76.0,
        overlayMinZoom: overlayZoomThreshold,
        bounds: GeodesicUtils.createBoundsFromDimensions(
          center: colosseumCoordinates,
          widthMeters: 204.0,
          heightMeters: 174.0,
        ),
        footprintPolygon: GeodesicUtils.createEllipseFootprint(
          center: colosseumCoordinates,
          radiusSemiMajorMeters: 96.0,
          radiusSemiMinorMeters: 80.0,
          rotationDegrees: -22.0,
          pointsCount: 36,
        ),
      ),

      // 2. Arch of Constantine
      PoiModel(
        id: 'arch_of_constantine',
        name: 'Arch of Constantine',
        latitude: 41.889762,
        longitude: 12.490586,
        assetPath: AppAssets.archOfConstantine,
        overlayAssetPath: AppAssets.archOfConstantine,
        description: 'Triumphal arch dedicated to Emperor Constantine the Great, commemorating victory at Milvian Bridge in 312 AD.',
        baseMarkerSize: 64.0,
        overlayMinZoom: overlayZoomThreshold,
        bounds: GeodesicUtils.createBoundsFromDimensions(
          center: const LatLng(41.889762, 12.490586),
          widthMeters: 42.0,
          heightMeters: 32.0,
        ),
        footprintPolygon: GeodesicUtils.createRotatedRectangleFootprint(
          center: const LatLng(41.889762, 12.490586),
          widthMeters: 38.0,
          heightMeters: 26.0,
          rotationDegrees: -15.0,
        ),
      ),

      // 3. Temple of Venus and Rome
      PoiModel(
        id: 'temple_of_venus_and_rome',
        name: 'Temple of Venus and Rome',
        latitude: 41.890940,
        longitude: 12.489080,
        assetPath: AppAssets.templeOfVenusAndRome,
        overlayAssetPath: AppAssets.templeOfVenusAndRome,
        description: 'The largest temple in Ancient Rome, dedicated to Venus Felix and Roma Aeterna on the Velian Hill.',
        baseMarkerSize: 66.0,
        overlayMinZoom: overlayZoomThreshold,
        bounds: GeodesicUtils.createBoundsFromDimensions(
          center: const LatLng(41.890940, 12.489080),
          widthMeters: 155.0,
          heightMeters: 110.0,
        ),
        footprintPolygon: GeodesicUtils.createRotatedRectangleFootprint(
          center: const LatLng(41.890940, 12.489080),
          widthMeters: 148.0,
          heightMeters: 102.0,
          rotationDegrees: -32.0,
        ),
      ),

      // 4. Ludus Magnus
      PoiModel(
        id: 'ludus_magnus',
        name: 'Ludus Magnus',
        latitude: 41.889980,
        longitude: 12.495020,
        assetPath: AppAssets.ludusMagnus,
        overlayAssetPath: AppAssets.ludusMagnus,
        description: 'The primary gladiator training school directly connected to the Colosseum by an underground tunnel.',
        baseMarkerSize: 64.0,
        overlayMinZoom: overlayZoomThreshold,
        bounds: GeodesicUtils.createBoundsFromDimensions(
          center: const LatLng(41.889980, 12.495020),
          widthMeters: 115.0,
          heightMeters: 95.0,
        ),
        footprintPolygon: GeodesicUtils.createRotatedRectangleFootprint(
          center: const LatLng(41.889980, 12.495020),
          widthMeters: 108.0,
          heightMeters: 88.0,
          rotationDegrees: -18.0,
        ),
      ),

      // 5. Roman Forum
      PoiModel(
        id: 'roman_forum',
        name: 'Roman Forum',
        latitude: 41.892460,
        longitude: 12.486220,
        assetPath: AppAssets.romanForum,
        overlayAssetPath: AppAssets.romanForum,
        description: 'The political, religious, and commercial heart of the Roman Empire.',
        baseMarkerSize: 72.0,
        overlayMinZoom: overlayZoomThreshold,
        bounds: GeodesicUtils.createBoundsFromDimensions(
          center: const LatLng(41.892460, 12.486220),
          widthMeters: 195.0,
          heightMeters: 135.0,
        ),
        footprintPolygon: GeodesicUtils.createRotatedRectangleFootprint(
          center: const LatLng(41.892460, 12.486220),
          widthMeters: 185.0,
          heightMeters: 125.0,
          rotationDegrees: -42.0,
        ),
      ),
    ];
  }

  void onPositionChanged(MapCamera camera, bool hasGesture) {
    currentZoom.value = camera.zoom;
  }

  void onMapTap(LatLng point) {
    for (final poi in landmarks) {
      if (poi.containsPoint(point)) {
        selectPoi(poi);
        return;
      }
    }
    clearSelection();
  }

  void selectPoi(PoiModel poi) {
    if (selectedPoi.value?.id == poi.id) {
      selectedPoi.value = null;
    } else {
      selectedPoi.value = poi;
    }
  }

  void clearSelection() {
    selectedPoi.value = null;
  }

  void centerOnColosseum() {
    mapController.move(colosseumCoordinates, defaultZoom);
    clearSelection();
  }

  void centerOnPoi(PoiModel poi) {
    mapController.move(LatLng(poi.latitude, poi.longitude), 17.5);
    selectPoi(poi);
  }

  bool isOverlayActive(PoiModel poi) {
    return poi.hasGroundOverlay && currentZoom.value >= poi.overlayMinZoom;
  }

  bool isMarkerVisible(PoiModel poi) {
    if (!poi.hasGroundOverlay) return true;
    return currentZoom.value < poi.overlayMinZoom;
  }

  @override
  void onClose() {
    mapController.dispose();
    super.onClose();
  }
}
