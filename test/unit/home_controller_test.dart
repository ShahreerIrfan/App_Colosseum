import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
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

    test('initializes with all 5 Roman historical landmarks', () {
      expect(controller.landmarks.length, 5);
      final ids = controller.landmarks.map((poi) => poi.id).toList();
      expect(
        ids,
        containsAll([
          'colosseum',
          'arch_of_constantine',
          'temple_of_venus_and_rome',
          'ludus_magnus',
          'roman_forum',
        ]),
      );
    });

    test(
      'all 5 landmarks have georeferenced bounds and footprint polygons',
      () {
        for (final landmark in controller.landmarks) {
          expect(
            landmark.hasGroundOverlay,
            isTrue,
            reason: '${landmark.name} should have ground overlay',
          );
          expect(
            landmark.bounds,
            isNotNull,
            reason: '${landmark.name} should have bounds',
          );
          expect(
            landmark.footprintPolygon,
            isNotNull,
            reason: '${landmark.name} should have footprint polygon',
          );
          expect(landmark.footprintPolygon!.isNotEmpty, isTrue);
        }
      },
    );

    test(
      'isOverlayActive and isMarkerVisible toggle based on zoom threshold',
      () {
        final colosseum = controller.landmarks.firstWhere(
          (p) => p.id == 'colosseum',
        );

        // Close zoom (default 16.5 >= 15.5)
        controller.currentZoom.value = 16.5;
        expect(controller.isOverlayActive(colosseum), isTrue);
        expect(controller.isMarkerVisible(colosseum), isFalse);

        // Far zoom (< 15.5)
        controller.currentZoom.value = 14.0;
        expect(controller.isOverlayActive(colosseum), isFalse);
        expect(controller.isMarkerVisible(colosseum), isTrue);
      },
    );

    test('onMapTap selects POI when tapping inside its footprint', () {
      expect(controller.selectedPoi.value, isNull);

      // Tap directly at Colosseum center
      controller.onMapTap(HomeController.colosseumCoordinates);
      expect(controller.selectedPoi.value?.id, 'colosseum');

      // Tap at Arch of Constantine
      controller.onMapTap(const LatLng(41.889762, 12.490586));
      expect(controller.selectedPoi.value?.id, 'arch_of_constantine');

      // Tap at Roman Forum
      controller.onMapTap(const LatLng(41.892460, 12.486220));
      expect(controller.selectedPoi.value?.id, 'roman_forum');

      // Tap outside any monument
      controller.onMapTap(const LatLng(41.900000, 12.500000));
      expect(controller.selectedPoi.value, isNull);
    });

    test('selectPoi toggles POI selection', () {
      final colosseum = controller.landmarks.first;
      expect(controller.selectedPoi.value, isNull);

      controller.selectPoi(colosseum);
      expect(controller.selectedPoi.value?.id, colosseum.id);

      // Tapping same POI toggles it off
      controller.selectPoi(colosseum);
      expect(controller.selectedPoi.value, isNull);
    });

    test('clearSelection clears selected POI', () {
      final colosseum = controller.landmarks.first;
      controller.selectPoi(colosseum);
      expect(controller.selectedPoi.value, isNotNull);

      controller.clearSelection();
      expect(controller.selectedPoi.value, isNull);
    });
  });
}
