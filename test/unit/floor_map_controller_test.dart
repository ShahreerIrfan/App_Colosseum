import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:colosseum_client/app/modules/floor_map/controllers/floor_map_controller.dart';

import '../helpers/mock_tts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    setupMockTts();
  });

  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('FloorMapController Unit Tests', () {
    late FloorMapController controller;

    setUp(() {
      controller = FloorMapController();
      controller.onInit();
    });

    tearDown(() {
      controller.onClose();
    });

    test('initializes with default landmark name "Colosseum" and "Underground (Hypogeum)"', () {
      expect(controller.landmarkName.value, 'Colosseum');
      expect(controller.floorName.value, 'Underground (Hypogeum)');
      expect(controller.floorId.value, 'floor_underground');
      expect(controller.selectedViewpoint.value, isNull);
    });

    test('initializes with Colosseum Underground 7 viewpoints (100 - 106) and imageAssets', () {
      expect(controller.viewpoints.isNotEmpty, true);
      expect(controller.viewpoints.length, 7);
      expect(controller.viewpoints[0].order, 100);
      expect(
        controller.viewpoints[0].title,
        'Spectacles in the Colosseum Arena Floor. The Superstars',
      );
      expect(controller.viewpoints[0].latitude, 41.890250);
      expect(controller.viewpoints[0].longitude, 12.492820);
      expect(controller.viewpoints[0].imageAsset, 'assets/images/vp_100_arena_spectacles.jpg');
      expect(controller.viewpoints[6].order, 106);
      expect(controller.viewpoints[6].imageAsset, 'assets/images/vp_106_excavations_restorations.jpg');
    });

    test('initializes with all viewpoints unvisited and itinerary segments loaded for underground', () {
      expect(controller.viewpoints.every((vp) => !vp.isVisited), true);
      expect(controller.itinerarySegments.isNotEmpty, true);
      expect(controller.itinerarySegments.length, 8);
      expect(controller.itinerarySegments.first.fromId, 'ENTRY');
      expect(controller.itinerarySegments.first.toId, 'vp_100');
      expect(controller.itinerarySegments.last.fromId, 'vp_106');
      expect(controller.itinerarySegments.last.toId, 'EXIT');
    });

    test('initializes with valid user indoor location for underground at eastern entry', () {
      final user = controller.userLocation.value;
      expect(user.floorId, 'floor_underground');
      expect(user.normalizedX, 0.92);
      expect(user.normalizedY, 0.50);
    });

    test('selectViewpoint sets active stop without mutating route geometry', () {
      final vp3 = controller.viewpoints[2]; // Stop 3
      controller.selectViewpoint(vp3);

      expect(controller.selectedViewpoint.value, vp3);
      expect(controller.itinerarySegments.length, 8);
    });

    test('switching viewpoint automatically pauses active audio playback', () {
      final vp1 = controller.viewpoints[0];
      final vp2 = controller.viewpoints[1];
      controller.selectViewpoint(vp1);

      // Start audio
      controller.toggleAudio();
      expect(controller.isPlayingAudio.value, true);

      // Switch to vp2
      controller.selectViewpoint(vp2);
      expect(controller.selectedViewpoint.value, vp2);
      expect(controller.isPlayingAudio.value, false);
    });

    test('toggleCardCollapse, expandCard, and collapseCard manage card presentation state', () {
      expect(controller.isCardCollapsed.value, false);
      controller.toggleCardCollapse();
      expect(controller.isCardCollapsed.value, true);
      controller.toggleCardCollapse();
      expect(controller.isCardCollapsed.value, false);
      controller.collapseCard();
      expect(controller.isCardCollapsed.value, true);
      controller.expandCard();
      expect(controller.isCardCollapsed.value, false);
    });

    test('deselectViewpoint clears active stop', () {
      controller.deselectViewpoint();

      expect(controller.selectedViewpoint.value, isNull);
      expect(controller.isPlayingAudio.value, false);
    });

    test('toggleAudio flips playback status when a viewpoint is selected', () {
      expect(controller.isPlayingAudio.value, false);
      // When no viewpoint is selected, toggleAudio does nothing
      controller.toggleAudio();
      expect(controller.isPlayingAudio.value, false);

      // When viewpoint is selected, toggleAudio toggles speech playback
      controller.selectViewpoint(controller.viewpoints.first);
      controller.toggleAudio();
      expect(controller.isPlayingAudio.value, true);
      controller.toggleAudio();
      expect(controller.isPlayingAudio.value, false);
    });

    test('toggleVisited flips visited status on selected viewpoint and viewpoints list', () {
      final vp1 = controller.viewpoints[0];
      final initialVisited = vp1.isVisited;
      controller.selectViewpoint(vp1);

      controller.toggleVisited();
      expect(controller.selectedViewpoint.value?.isVisited, !initialVisited);
      expect(controller.viewpoints[0].isVisited, !initialVisited);

      controller.toggleVisited();
      expect(controller.selectedViewpoint.value?.isVisited, initialVisited);
      expect(controller.viewpoints[0].isVisited, initialVisited);
    });

    test('zoomIn, zoomOut, and recenter manipulate camera transformation matrix', () {
      controller.recenter();
      expect(
        controller.transformationController.value.getMaxScaleOnAxis(),
        1.0,
      );

      controller.zoomIn();
      expect(
        controller.transformationController.value.getMaxScaleOnAxis(),
        greaterThan(1.0),
      );

      controller.zoomOut();
      controller.recenter();
      expect(
        controller.transformationController.value.getMaxScaleOnAxis(),
        1.0,
      );
    });

    test('updateHeading updates userOrientation reactive state independently of location', () {
      expect(controller.userLocation.value.normalizedX, equals(0.92));

      controller.updateHeading(45.0, accuracy: 5.0);
      expect(controller.userOrientation.value.headingDegrees, closeTo(45.0, 0.001));
      expect(controller.userOrientation.value.sensorAccuracy, equals(5.0));

      // User location coordinates remain unaffected
      expect(controller.userLocation.value.normalizedX, equals(0.92));
      expect(controller.userLocation.value.normalizedY, equals(0.50));
    });

    test('recenter preserves current live compass heading', () {
      controller.updateHeading(120.0);
      controller.zoomIn();
      controller.recenter();

      expect(controller.userOrientation.value.headingDegrees, closeTo(120.0, 0.001));
    });
  });
}
