import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:colosseum_client/app/data/models/map_view_type.dart';
import 'package:colosseum_client/app/modules/home/controllers/home_controller.dart';

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

    test('updateLandmarkOverlay updates specific overlay in list', () {
      final colosseum = controller.landmarkOverlays.firstWhere((o) => o.id == 'colosseum');
      final updated = colosseum.copyWith(opacity: 0.7);
      controller.updateLandmarkOverlay(updated);

      final found = controller.landmarkOverlays.firstWhere((o) => o.id == 'colosseum');
      expect(found.opacity, 0.7);
    });
  });
}
