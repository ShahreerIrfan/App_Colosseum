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

    test('initializes with isUserInLocation false and null userLocation until GPS in-bounds fix arrives', () {
      expect(controller.isUserInLocation.value, isFalse);
      expect(controller.userLocation.value, isNull);

      // Feed in-bounds GPS position at Stop 100
      controller.updateGpsPosition(41.890250, 12.492820);
      expect(controller.isUserInLocation.value, isTrue);
      expect(controller.userLocation.value, isNotNull);
      expect(controller.userLocation.value!.normalizedX, greaterThan(0.70));
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
      controller.updateGpsPosition(41.890250, 12.492820);
      final initialX = controller.userLocation.value!.normalizedX;

      controller.updateHeading(45.0, accuracy: 5.0);
      expect(controller.userOrientation.value.headingDegrees, closeTo(45.0, 0.001));
      expect(controller.userOrientation.value.sensorAccuracy, equals(5.0));

      // User location coordinates remain unaffected
      expect(controller.userLocation.value!.normalizedX, equals(initialX));
    });

    test('recenter preserves current live compass heading', () {
      controller.updateHeading(120.0);
      controller.zoomIn();
      controller.recenter();

      expect(controller.userOrientation.value.headingDegrees, closeTo(120.0, 0.001));
    });

    test('togglePlaygroundMode switches between Geofence and Local Field Test mode', () {
      expect(controller.isPlaygroundMode.value, isFalse);

      controller.togglePlaygroundMode();
      expect(controller.isPlaygroundMode.value, isTrue);

      controller.togglePlaygroundMode();
      expect(controller.isPlaygroundMode.value, isFalse);
    });

    test('resetPlaygroundOrigin resets reference anchor without errors', () {
      controller.togglePlaygroundMode();
      controller.resetPlaygroundOrigin();
      expect(controller.isPlaygroundMode.value, isTrue);
      expect(controller.isDisplacementPaused.value, isFalse);
    });

    test('togglePauseDisplacement pauses and resumes walking displacement in field test mode', () {
      controller.togglePlaygroundMode();
      expect(controller.isDisplacementPaused.value, isFalse);

      controller.togglePauseDisplacement();
      expect(controller.isDisplacementPaused.value, isTrue);

      controller.togglePauseDisplacement();
      expect(controller.isDisplacementPaused.value, isFalse);
    });

    test('snapToTarget snaps user location directly to current tour target', () {
      controller.togglePlaygroundMode();
      expect(controller.tourState.value.navigationTargetId, equals('vp_100'));

      controller.snapToTarget();
      expect(controller.isUserInLocation.value, isTrue);
      expect(controller.userLocation.value, isNotNull);
      expect(controller.userLocation.value!.normalizedX, equals(0.80));
      expect(controller.userLocation.value!.normalizedY, equals(0.50));
    });

    test('speaking navigation instruction does not trigger onAudioCompleted or mark stop visited', () {
      expect(controller.tourState.value.visitedIds, isEmpty);

      // Speak navigation instruction
      controller.ttsService.speakInstruction('Next, proceed toward Viewpoint 101.');
      expect(controller.tourState.value.visitedIds, isEmpty);
      expect(controller.tourState.value.navigationTargetId, equals('vp_100'));
    });

    test('toggleAudio pauses narration and resumes from bookmark position', () {
      final vp = controller.viewpoints.first;
      controller.selectViewpoint(vp);

      // Start narration
      controller.toggleAudio();
      expect(controller.isPlayingAudio.value, isTrue);

      // Simulate TTS progress to 50 characters
      controller.ttsService.onProgress?.call(0, 50, 'word');
      expect(controller.audioProgress.value, greaterThan(0.0));

      // Pause narration
      controller.toggleAudio();
      expect(controller.isPlayingAudio.value, isFalse);

      // Resume narration -> resumes with remaining text
      controller.toggleAudio();
      expect(controller.isPlayingAudio.value, isTrue);
    });
  });
}
