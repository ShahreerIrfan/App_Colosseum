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
      expect(controller.itinerarySegments.length, 6);
      expect(controller.itinerarySegments.first.fromId, 'vp_100');
      expect(controller.itinerarySegments.first.toId, 'vp_101');
      expect(controller.itinerarySegments.last.fromId, 'vp_105');
      expect(controller.itinerarySegments.last.toId, 'vp_106');
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
      expect(controller.itinerarySegments.length, 6);
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

    test('snapToTarget snaps user location directly to current tour target with exact LatLng match', () {
      controller.togglePlaygroundMode();
      expect(controller.tourState.value.navigationTargetId, equals('vp_100'));

      controller.snapToTarget();
      expect(controller.isUserInLocation.value, isTrue);
      expect(controller.userLocation.value, isNotNull);
      expect(controller.userLocation.value!.normalizedX, equals(0.80));
      expect(controller.userLocation.value!.normalizedY, equals(0.50));
      expect(controller.isDisplacementPaused.value, isTrue); // Live drift is paused

      // Coordinate Unification: LatLng must match viewpoint 100 exactly
      final vp100 = controller.viewpoints.first;
      expect(controller.userLocation.value!.latLng.latitude, closeTo(vp100.latLng.latitude, 0.000001));
      expect(controller.userLocation.value!.latLng.longitude, closeTo(vp100.latLng.longitude, 0.000001));
    });

    test('snapToTarget sequentially advances through stops on subsequent taps', () {
      controller.togglePlaygroundMode();
      expect(controller.tourState.value.navigationTargetId, equals('vp_100'));

      // 1st snap -> Viewpoint 100
      controller.snapToTarget();
      expect(controller.tourState.value.navigationTargetId, equals('vp_100'));
      expect(controller.selectedViewpoint.value?.id, equals('vp_100'));

      // 2nd snap while at Viewpoint 100 -> advances to Viewpoint 101
      controller.snapToTarget();
      expect(controller.tourState.value.navigationTargetId, equals('vp_101'));
      expect(controller.selectedViewpoint.value?.id, equals('vp_101'));
      expect(controller.userLocation.value!.normalizedX, equals(0.88));

      // 3rd snap while at Viewpoint 101 -> advances to Viewpoint 102
      controller.snapToTarget();
      expect(controller.tourState.value.navigationTargetId, equals('vp_102'));
      expect(controller.selectedViewpoint.value?.id, equals('vp_102'));
      expect(controller.userLocation.value!.normalizedX, equals(0.68));
    });

    test('snapToTarget prioritizes selectedViewpoint when developer explicitly selects a different stop', () {
      controller.togglePlaygroundMode();
      
      // Start at Viewpoint 100
      controller.snapToTarget();
      expect(controller.tourState.value.navigationTargetId, equals('vp_100'));

      // Developer selects Viewpoint 104 on the map
      final vp104 = controller.viewpoints.firstWhere((vp) => vp.id == 'vp_104');
      controller.selectViewpoint(vp104);
      expect(controller.selectedViewpoint.value?.id, equals('vp_104'));

      // Tap Snap Stop -> snaps directly to Viewpoint 104
      controller.snapToTarget();
      expect(controller.tourState.value.navigationTargetId, equals('vp_104'));
      expect(controller.selectedViewpoint.value?.id, equals('vp_104'));
      expect(controller.userLocation.value!.normalizedX, equals(0.48));
      expect(controller.userLocation.value!.normalizedY, equals(0.50));
    });

    test('setSimulatedLocation enables FoodPanda/Uber style tap-to-place anywhere on satellite map', () {
      controller.togglePlaygroundMode();
      expect(controller.isPlaygroundMode.value, isTrue);

      // 1. Developer in Bangladesh taps anywhere on satellite map
      final tappedPoint = controller.viewpoints[1].latLng; // Viewpoint 101 LatLng
      controller.setSimulatedLocation(tappedPoint);

      expect(controller.isUserInLocation.value, isTrue);
      expect(controller.userLocation.value, isNotNull);
      expect(controller.isDisplacementPaused.value, isTrue); // Automatically pauses live drift
      expect(controller.userLocation.value!.latLng.latitude, closeTo(tappedPoint.latitude, 0.000001));
      expect(controller.userLocation.value!.latLng.longitude, closeTo(tappedPoint.longitude, 0.000001));
      expect(controller.userLocation.value!.normalizedX, closeTo(controller.viewpoints[1].normalizedX, 0.001));
      expect(controller.userLocation.value!.normalizedY, closeTo(controller.viewpoints[1].normalizedY, 0.001));
    });

    test('speaking navigation instruction does not trigger onAudioCompleted or mark stop visited (Bug 1 fixed)', () async {
      expect(controller.tourState.value.visitedIds, isEmpty);

      // Speak navigation instruction
      await controller.ttsService.speakInstruction('Next, proceed toward Viewpoint 101.');
      // Native completion of instruction must NOT mark visited
      controller.ttsService.handleNativeCompletion();

      expect(controller.tourState.value.visitedIds, isEmpty);
      expect(controller.tourState.value.navigationTargetId, equals('vp_100'));
    });

    test('genuine narration completion triggers onAudioCompleted without force-marking visited (decoupled)', () async {
      expect(controller.tourState.value.visitedIds, isEmpty);

      final vp = controller.viewpoints.first;
      controller.selectViewpoint(vp);

      // Start narration
      controller.toggleAudio();
      expect(controller.isPlayingAudio.value, isTrue);

      // Native TTS completes narration
      controller.ttsService.handleNativeCompletion();

      // Audio narration completes without force-marking the stop as visited
      expect(controller.isPlayingAudio.value, isFalse);
      expect(controller.tourState.value.visitedIds, isEmpty);

      // User independently marks as visited
      controller.toggleVisited('vp_100');
      expect(controller.tourState.value.visitedIds, contains('vp_100'));
      expect(controller.tourState.value.navigationTargetId, equals('vp_101'));
    });

    test('viewpoint audio guide plays independently even when viewpoint is already marked as visited (fully decoupled)', () {
      // Pre-mark viewpoint 100 as visited
      controller.toggleVisited('vp_100');
      expect(controller.tourState.value.visitedIds, contains('vp_100'));

      // Selecting visited viewpoint still freely plays audio guide
      controller.selectViewpoint(controller.viewpoints.first);
      controller.toggleAudio();
      expect(controller.isPlayingAudio.value, isTrue);
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

    test('hybrid timer advances audioProgress when native onProgress is absent (Bug 2 fixed)', () async {
      final vp = controller.viewpoints.first;
      controller.selectViewpoint(vp);

      // Start narration without calling onProgress (simulating Samsung/Xiaomi TTS)
      controller.toggleAudio();
      expect(controller.isPlayingAudio.value, isTrue);

      // Wait 300ms for periodic hybrid progress timer to fire
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(controller.audioProgress.value, greaterThan(0.0));

      // Pause audio
      controller.toggleAudio();
      expect(controller.isPlayingAudio.value, isFalse);
      final savedProgress = controller.audioProgress.value;
      expect(savedProgress, greaterThan(0.0));

      // Resume audio
      controller.toggleAudio();
      expect(controller.isPlayingAudio.value, isTrue);
    });

    test('loads Level 1 viewpoints (200-208) and itinerary segments when floorId is floor_1', () {
      Get.reset();
      final level1Ctrl = FloorMapController();
      level1Ctrl.floorId.value = 'floor_1';
      level1Ctrl.onInit();

      expect(level1Ctrl.floorName.value, 'Floor 1');
      expect(level1Ctrl.viewpoints.length, 9);
      expect(level1Ctrl.viewpoints.first.order, 200);
      expect(level1Ctrl.viewpoints.last.order, 208);
      expect(level1Ctrl.itinerarySegments.length, 8);
      expect(level1Ctrl.itinerarySegments.first.fromId, 'vp_200');
      expect(level1Ctrl.itinerarySegments.first.toId, 'vp_201');
      expect(level1Ctrl.tourState.value.navigationTargetId, 'vp_200');
      level1Ctrl.onClose();
    });

    test('loads Level 2 viewpoints (300-306) and itinerary segments when floorId is floor_2', () {
      Get.reset();
      final level2Ctrl = FloorMapController();
      level2Ctrl.floorId.value = 'floor_2';
      level2Ctrl.onInit();

      expect(level2Ctrl.floorName.value, 'Floor 2');
      expect(level2Ctrl.viewpoints.length, 7);
      expect(level2Ctrl.viewpoints.first.order, 300);
      expect(level2Ctrl.viewpoints.last.order, 306);
      expect(level2Ctrl.itinerarySegments.length, 6);
      expect(level2Ctrl.itinerarySegments.first.fromId, 'vp_300');
      expect(level2Ctrl.itinerarySegments.first.toId, 'vp_301');
      expect(level2Ctrl.tourState.value.navigationTargetId, 'vp_300');
      level2Ctrl.onClose();
    });

    test('loads Level 3 viewpoints (400-404) and itinerary segments when floorId is floor_3', () {
      Get.reset();
      final level3Ctrl = FloorMapController();
      level3Ctrl.floorId.value = 'floor_3';
      level3Ctrl.onInit();

      expect(level3Ctrl.floorName.value, 'Floor 3');
      expect(level3Ctrl.viewpoints.length, 5);
      expect(level3Ctrl.viewpoints.first.order, 400);
      expect(level3Ctrl.viewpoints.last.order, 404);
      expect(level3Ctrl.itinerarySegments.length, 4);
      expect(level3Ctrl.itinerarySegments.first.fromId, 'vp_400');
      expect(level3Ctrl.itinerarySegments.first.toId, 'vp_401');
      expect(level3Ctrl.tourState.value.navigationTargetId, 'vp_400');
      level3Ctrl.onClose();
    });
  });
}
