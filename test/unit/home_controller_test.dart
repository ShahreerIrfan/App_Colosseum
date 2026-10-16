import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:colosseum_client/app/data/models/map_view_type.dart';
import 'package:colosseum_client/app/modules/home/controllers/home_controller.dart';
import 'package:latlong2/latlong.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    Get.testMode = true;
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
      expect(controller.selectedMapView.value, MapViewType.satellite);
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
      expect(controller.selectedMapView.value, MapViewType.satellite);

      controller.toggleMapView();
      expect(controller.selectedMapView.value, MapViewType.general);

      controller.toggleMapView();
      expect(controller.selectedMapView.value, MapViewType.satellite);

      controller.switchMapView(MapViewType.general);
      expect(controller.selectedMapView.value, MapViewType.general);
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

    test('startTour initializes active tour, default location, and generates route', () {
      expect(controller.isTourActive.value, isFalse);
      expect(controller.currentTourRoutePoints, isEmpty);

      controller.startTour();

      expect(controller.isTourActive.value, isTrue);
      expect(controller.userLocation.value, equals(HomeController.defaultTourStartLocation));
      // Route follows realistic pedestrian streets with multiple dense waypoints
      expect(controller.currentTourRoutePoints.length, greaterThan(15));
      expect(controller.currentTourRoutePoints.first, equals(HomeController.defaultTourStartLocation));
    });

    test('dynamic itinerary route updates when user moves', () {
      controller.startTour();
      expect(controller.currentTourRoutePoints.first, equals(HomeController.defaultTourStartLocation));

      // User moves to a new location near Ludus Magnus
      const newPos = LatLng(41.890400, 12.494800);
      controller.setUserLocation(newPos);

      expect(controller.currentTourRoutePoints.first, equals(newPos));
      // Route begins along the nearest street node on Via di San Giovanni in Laterano
      expect(controller.currentTourRoutePoints[1], equals(const LatLng(41.8904, 12.495)));
      expect(controller.currentTourRoutePoints.length, greaterThan(15));
    });

    test('proximity detection triggers approachingLandmark when user is near the border of Colosseum', () {
      controller.startTour();
      expect(controller.approachingLandmark.value, isNull);

      // User is at northern border/promenade of Colosseum (~91m from center, as in user test)
      const colosseumBorderPos = LatLng(41.891000, 12.492000);
      controller.setUserLocation(colosseumBorderPos);

      expect(controller.approachingLandmark.value, isNotNull);
      expect(controller.approachingLandmark.value!.id, 'colosseum');
    });

    test('skipApproachingLandmark marks landmark skipped and recalculates route without it', () {
      controller.startTour();
      const nearColosseum = LatLng(41.890250, 12.492231);
      controller.setUserLocation(nearColosseum);

      expect(controller.approachingLandmark.value?.id, 'colosseum');

      controller.skipApproachingLandmark();

      expect(controller.approachingLandmark.value, isNull);
      expect(controller.skippedLandmarkIds.contains('colosseum'), isTrue);
      expect(controller.remainingTourLandmarks.length, 4);
      expect(controller.remainingTourLandmarks.any((m) => m.id == 'colosseum'), isFalse);
      // Route recalculates along streets with remaining landmarks
      expect(controller.currentTourRoutePoints.length, greaterThan(10));
    });

    test('enterApproachingLandmark marks landmark visited and removes it from tour route', () {
      controller.startTour();
      const nearArch = LatLng(41.889762, 12.490667);
      controller.setUserLocation(nearArch);

      expect(controller.approachingLandmark.value?.id, 'arch_of_constantine');

      controller.enterApproachingLandmark();

      expect(controller.approachingLandmark.value, isNull);
      expect(controller.visitedLandmarkIds.contains('arch_of_constantine'), isTrue);
      expect(controller.remainingTourLandmarks.any((m) => m.id == 'arch_of_constantine'), isFalse);
    });

    test('stopTour stops tour and clears route points', () {
      controller.startTour();
      expect(controller.isTourActive.value, isTrue);
      expect(controller.currentTourRoutePoints.isNotEmpty, isTrue);

      controller.stopTour();

      expect(controller.isTourActive.value, isFalse);
      expect(controller.currentTourRoutePoints, isEmpty);
    });
  });
}
