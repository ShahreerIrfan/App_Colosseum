import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:colosseum_client/app/data/models/map_view_type.dart';
import 'package:colosseum_client/app/modules/home/controllers/home_controller.dart';
import 'package:latlong2/latlong.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('HomeController Unit Tests', () {
    late HomeController controller;

    setUp(() {
      controller = HomeController();
      controller.onInit();
    });

    tearDown(() {
      controller.onClose();
    });

    test('initializes with default coordinates and zoom level', () {
      expect(HomeController.colosseumCoordinates.latitude, 41.890210);
      expect(HomeController.colosseumCoordinates.longitude, 12.492231);
      expect(controller.currentZoom.value, HomeController.defaultZoom);
    });

    test('centerOnColosseum moves map back to Colosseum coordinates', () {
      controller.centerOnColosseum();
      expect(controller.currentZoom.value, HomeController.defaultZoom);
    });

    test('initializes with 5 landmark overlays', () {
      expect(controller.landmarkOverlays.length, 5);
      expect(controller.isLandmarksVisible.value, isTrue);
      expect(controller.isDebugLandmarks.value, isFalse);
      expect(controller.selectedMapView.value, MapViewType.general);
    });

    test('toggles landmark visibility and debug mode', () {
      controller.toggleLandmarksVisibility();
      expect(controller.isLandmarksVisible.value, isFalse);

      controller.toggleLandmarksVisibility();
      expect(controller.isLandmarksVisible.value, isTrue);

      controller.toggleDebugLandmarks();
      expect(controller.isDebugLandmarks.value, isTrue);
    });

    test('switches and toggles map view type between general and satellite', () {
      controller.toggleMapView();
      expect(controller.selectedMapView.value, MapViewType.satellite);

      controller.toggleMapView();
      expect(controller.selectedMapView.value, MapViewType.general);

      controller.switchMapView(MapViewType.satellite);
      expect(controller.selectedMapView.value, MapViewType.satellite);
    });

    test('initializes with 5 landmark markers and colosseum selected by default', () {
      expect(controller.landmarkMarkers.length, 5);
      expect(controller.selectedLandmarkId.value, 'colosseum');
    });

    test('selectLandmark updates selectedLandmarkId correctly', () {
      controller.selectLandmark('arch_of_constantine');
      expect(controller.selectedLandmarkId.value, 'arch_of_constantine');

      controller.selectLandmark('ludus_magnus');
      expect(controller.selectedLandmarkId.value, 'ludus_magnus');
    });

    test('updateLandmarkMarker updates marker in list', () {
      final colosseum = controller.landmarkMarkers.firstWhere((m) => m.id == 'colosseum');
      final updated = colosseum.copyWith(name: 'Colosseum Amphitheatre');
      controller.updateLandmarkMarker(updated);

      final found = controller.landmarkMarkers.firstWhere((m) => m.id == 'colosseum');
      expect(found.name, 'Colosseum Amphitheatre');
    });

    test('updateLandmarkOverlay updates specific overlay in list', () {
      final colosseum = controller.landmarkOverlays.firstWhere((o) => o.id == 'colosseum');
      final updated = colosseum.copyWith(opacity: 0.7);
      controller.updateLandmarkOverlay(updated);

      final found = controller.landmarkOverlays.firstWhere((o) => o.id == 'colosseum');
      expect(found.opacity, 0.7);
    });

    test('isUserInZone is false when userLocation is null', () {
      controller.userLocation.value = null;
      expect(controller.isUserInZone, isFalse);
      expect(controller.distanceToColosseumMeters, isNull);
    });

    test('isUserInZone is true when user is within 600m of Colosseum', () {
      // Arch of Constantine is ~139m away
      controller.setUserLocation(const LatLng(41.889762, 12.490667));
      expect(controller.isUserInZone, isTrue);
      expect(controller.distanceToColosseumMeters!, lessThan(600.0));
    });

    test('isUserInZone is false when user is farther than 600m from Colosseum', () {
      // 2km away from Colosseum
      controller.setUserLocation(const LatLng(41.910000, 12.492231));
      expect(controller.isUserInZone, isFalse);
      expect(controller.distanceToColosseumMeters!, greaterThan(600.0));
    });
  });
}
