import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:colosseum_client/app/core/utils/geodesic_utils.dart';
import 'package:colosseum_client/app/data/models/map_view_type.dart';
import 'package:colosseum_client/app/data/models/floor_definition.dart';
import 'package:colosseum_client/app/data/models/viewpoint_model.dart';
import 'package:colosseum_client/app/data/repositories/tour_repository_impl.dart';
import 'package:colosseum_client/app/data/services/visited_viewpoints_service.dart';
import 'package:colosseum_client/app/modules/floor_map/controllers/floor_map_controller.dart';

import '../helpers/mock_tts.dart';

class RefreshingFloorRepository extends TourRepositoryImpl {
  List<ViewpointModel> currentViewpoints = FloorDefinition.underground.viewpoints;

  @override
  Future<List<FloorDefinition>> getFloors({
    String lang = 'en',
    bool forceRefresh = false,
  }) async => [FloorDefinition.underground];

  @override
  Future<List<ViewpointModel>> getViewpointsByFloor(
    String floorId, {
    String lang = 'en',
    bool forceRefresh = false,
  }) async => currentViewpoints;
}

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

  test('resuming with an empty floor clears markers, selection and narration', () async {
    final repository = RefreshingFloorRepository();
    final controller = FloorMapController(tourRepository: repository);
    controller.onInit();
    addTearDown(controller.onClose);
    await Future<void>.delayed(Duration.zero);
    controller.selectViewpoint(controller.viewpoints.first);
    controller.toggleAudio();
    expect(controller.isPlayingAudio.value, isTrue);

    repository.currentViewpoints = [];
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);

    expect(controller.viewpoints, isEmpty);
    expect(controller.selectedViewpoint.value, isNull);
    expect(controller.tourEngine.viewpoints, isEmpty);
    expect(controller.itinerarySegments, isEmpty);
    expect(controller.isPlayingAudio.value, isFalse);
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

    test('snapToTarget snaps user location directly to current tour target with exact LatLng match', () async {
      controller.togglePlaygroundMode();
      expect(controller.tourState.value.navigationTargetId, equals('vp_100'));

      await controller.snapToTarget();
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

    test('snapToTarget sequentially advances through stops on subsequent taps', () async {
      controller.togglePlaygroundMode();
      expect(controller.tourState.value.navigationTargetId, equals('vp_100'));

      // 1st snap -> Viewpoint 100
      await controller.snapToTarget();
      expect(controller.tourState.value.navigationTargetId, equals('vp_100'));
      expect(controller.selectedViewpoint.value?.id, equals('vp_100'));

      // 2nd snap while at Viewpoint 100 -> advances to Viewpoint 101
      await controller.snapToTarget();
      expect(controller.tourState.value.navigationTargetId, equals('vp_101'));
      expect(controller.selectedViewpoint.value?.id, equals('vp_101'));
      expect(controller.userLocation.value!.normalizedX, equals(0.88));

      // 3rd snap while at Viewpoint 101 -> advances to Viewpoint 102
      await controller.snapToTarget();
      expect(controller.tourState.value.navigationTargetId, equals('vp_102'));
      expect(controller.selectedViewpoint.value?.id, equals('vp_102'));
      expect(controller.userLocation.value!.normalizedX, equals(0.68));
    });

    test('snapToTarget prioritizes selectedViewpoint when developer explicitly selects a different stop', () async {
      controller.togglePlaygroundMode();
      
      // Start at Viewpoint 100
      await controller.snapToTarget();
      expect(controller.tourState.value.navigationTargetId, equals('vp_100'));

      // Developer selects Viewpoint 104 on the map
      final vp104 = controller.viewpoints.firstWhere((vp) => vp.id == 'vp_104');
      controller.selectViewpoint(vp104);
      expect(controller.selectedViewpoint.value?.id, equals('vp_104'));

      // Tap Snap Stop -> snaps directly to Viewpoint 104
      await controller.snapToTarget();
      expect(controller.tourState.value.navigationTargetId, equals('vp_104'));
      expect(controller.selectedViewpoint.value?.id, equals('vp_104'));
      expect(controller.userLocation.value!.normalizedX, equals(0.48));
      expect(controller.userLocation.value!.normalizedY, equals(0.50));
    });

    test('setSimulatedLocation enables FoodPanda/Uber style tap-to-place anywhere on satellite map', () async {
      controller.togglePlaygroundMode();
      expect(controller.isPlaygroundMode.value, isTrue);

      // 1. Developer in Bangladesh taps anywhere on satellite map
      final tappedPoint = controller.viewpoints[1].latLng; // Viewpoint 101 LatLng
      await controller.setSimulatedLocation(tappedPoint);

      expect(controller.isUserInLocation.value, isTrue);
      expect(controller.userLocation.value, isNotNull);
      expect(controller.isDisplacementPaused.value, isTrue); // Automatically pauses live drift
      expect(controller.userLocation.value!.latLng.latitude, closeTo(tappedPoint.latitude, 0.000001));
      expect(controller.userLocation.value!.latLng.longitude, closeTo(tappedPoint.longitude, 0.000001));
      final projected = GeodesicUtils.latLngToCanvasOffset(tappedPoint);
      expect(controller.userLocation.value!.normalizedX, closeTo(projected.dx, 0.001));
      expect(controller.userLocation.value!.normalizedY, closeTo(projected.dy, 0.001));
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

      expect(level1Ctrl.floorName.value, 'Level 1');
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

      expect(level2Ctrl.floorName.value, 'Level 2');
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

      expect(level3Ctrl.floorName.value, 'Level 3');
      expect(level3Ctrl.viewpoints.length, 5);
      expect(level3Ctrl.viewpoints.first.order, 400);
      expect(level3Ctrl.viewpoints.last.order, 404);
      expect(level3Ctrl.itinerarySegments.length, 4);
      expect(level3Ctrl.itinerarySegments.first.fromId, 'vp_400');
      expect(level3Ctrl.itinerarySegments.first.toId, 'vp_401');
      expect(level3Ctrl.tourState.value.navigationTargetId, 'vp_400');
      level3Ctrl.onClose();
    });

    test('toggleVisited synchronizes with VisitedViewpointsService', () {
      expect(controller.visitedService.isVisited('vp_100'), isFalse);

      // Toggle visited on vp_100
      controller.toggleVisited('vp_100');
      expect(controller.visitedService.isVisited('vp_100'), isTrue);
      expect(controller.visitedService.getCompletedCountForFloor('floor_underground'), equals(1));

      // Toggle again to unmark
      controller.toggleVisited('vp_100');
      expect(controller.visitedService.isVisited('vp_100'), isFalse);
      expect(controller.visitedService.getCompletedCountForFloor('floor_underground'), equals(0));
    });

    test('restores saved visited viewpoints on floor load and advances target to first unvisited stop', () {
      Get.reset();
      final visitedService = VisitedViewpointsService();
      visitedService.setVisitedIdsForTesting(['vp_100', 'vp_101']);
      Get.put(visitedService);

      final ctrl = FloorMapController(visitedService: visitedService);
      ctrl.floorId.value = 'floor_underground';
      ctrl.onInit();

      // vp_100 and vp_101 are loaded as visited
      expect(ctrl.viewpoints[0].isVisited, isTrue);
      expect(ctrl.viewpoints[1].isVisited, isTrue);
      expect(ctrl.viewpoints[2].isVisited, isFalse);

      // Target was advanced past visited stops to first unvisited stop (vp_102)
      expect(ctrl.tourState.value.navigationTargetId, equals('vp_102'));
      ctrl.onClose();
    });

    test('toggleFloorMenu, openFloorMenu, closeFloorMenu control floor menu visibility', () {
      expect(controller.isFloorMenuOpen.value, isFalse);

      controller.openFloorMenu();
      expect(controller.isFloorMenuOpen.value, isTrue);

      controller.closeFloorMenu();
      expect(controller.isFloorMenuOpen.value, isFalse);

      controller.toggleFloorMenu();
      expect(controller.isFloorMenuOpen.value, isTrue);

      controller.toggleFloorMenu();
      expect(controller.isFloorMenuOpen.value, isFalse);
    });

    test('switchFloor updates all coordinated states atomically and closes menu', () async {
      // Start on underground
      expect(controller.currentFloor.value.id, equals('floor_underground'));
      expect(controller.viewpoints.first.order, equals(100));

      // Select viewpoint and start audio
      controller.selectViewpoint(controller.viewpoints.first);
      controller.toggleAudio();
      expect(controller.selectedViewpoint.value, isNotNull);
      expect(controller.isPlayingAudio.value, isTrue);

      controller.openFloorMenu();
      expect(controller.isFloorMenuOpen.value, isTrue);

      // Switch to Level 2
      await controller.switchFloor('floor_2');

      // Menu closed
      expect(controller.isFloorMenuOpen.value, isFalse);
      // Floor switched
      expect(controller.currentFloor.value.id, equals('floor_2'));
      expect(controller.floorName.value, equals('Level 2'));
      // Audio stopped and card closed
      expect(controller.selectedViewpoint.value, isNull);
      expect(controller.isPlayingAudio.value, isFalse);
      // Viewpoints swapped to Level 2 (300-306)
      expect(controller.viewpoints.length, equals(7));
      expect(controller.viewpoints.first.order, equals(300));
      expect(controller.viewpoints.last.order, equals(306));
      // Navigation target is vp_300
      expect(controller.tourState.value.navigationTargetId, equals('vp_300'));
    });

    test('switchFloor to same floor only closes menu and does not reload', () async {
      controller.openFloorMenu();
      expect(controller.isFloorMenuOpen.value, isTrue);

      final currentFloorId = controller.currentFloor.value.id;
      await controller.switchFloor(currentFloorId);

      expect(controller.isFloorMenuOpen.value, isFalse);
      expect(controller.currentFloor.value.id, equals(currentFloorId));
    });

    test('switchFloor preserves visited progress per floor independently', () async {
      // Mark vp_100 visited on underground
      await controller.switchFloor('floor_underground');
      controller.toggleVisited('vp_100');
      expect(controller.viewpoints[0].isVisited, isTrue);

      // Switch to Level 1
      await controller.switchFloor('floor_1');
      expect(controller.viewpoints.every((v) => !v.isVisited), isTrue);

      // Mark vp_200 visited on Level 1
      controller.toggleVisited('vp_200');
      expect(controller.viewpoints[0].isVisited, isTrue);

      // Switch back to Underground - vp_100 is still visited
      await controller.switchFloor('floor_underground');
      expect(controller.viewpoints[0].isVisited, isTrue);

      // Switch back to Level 1 - vp_200 is still visited
      await controller.switchFloor('floor_1');
      expect(controller.viewpoints[0].isVisited, isTrue);
    });

    test('initializes with default MapViewType.satellite', () {
      expect(controller.selectedMapView.value, equals(MapViewType.satellite));
      expect(controller.currentMapViewDisplayName, equals('Satellite View'));
      expect(controller.currentMapViewShortName, equals('Satellite'));
      expect(controller.isMapViewMenuOpen.value, isFalse);
    });

    test('toggleMapView directly alternates between satellite and general view', () {
      expect(controller.selectedMapView.value, equals(MapViewType.satellite));
      controller.toggleMapView();
      expect(controller.selectedMapView.value, equals(MapViewType.general));
      controller.toggleMapView();
      expect(controller.selectedMapView.value, equals(MapViewType.satellite));
    });

    test('toggleMapViewMenu, openMapViewMenu, closeMapViewMenu, and closeAllBottomMenus', () {
      expect(controller.isMapViewMenuOpen.value, isFalse);

      controller.openMapViewMenu();
      expect(controller.isMapViewMenuOpen.value, isTrue);

      controller.closeMapViewMenu();
      expect(controller.isMapViewMenuOpen.value, isFalse);

      controller.toggleMapViewMenu();
      expect(controller.isMapViewMenuOpen.value, isTrue);

      controller.toggleMapViewMenu();
      expect(controller.isMapViewMenuOpen.value, isFalse);

      // closeAllBottomMenus closes both
      controller.openFloorMenu();
      controller.openMapViewMenu();
      expect(controller.isMapViewMenuOpen.value, isTrue);
      controller.closeAllBottomMenus();
      expect(controller.isFloorMenuOpen.value, isFalse);
      expect(controller.isMapViewMenuOpen.value, isFalse);
    });

    test('mutual menu exclusivity: opening one bottom menu automatically closes the other', () {
      // Open floor menu
      controller.openFloorMenu();
      expect(controller.isFloorMenuOpen.value, isTrue);
      expect(controller.isMapViewMenuOpen.value, isFalse);

      // Now open map view menu -> floor menu closes
      controller.openMapViewMenu();
      expect(controller.isFloorMenuOpen.value, isFalse);
      expect(controller.isMapViewMenuOpen.value, isTrue);

      // Now open floor menu -> map view menu closes
      controller.openFloorMenu();
      expect(controller.isFloorMenuOpen.value, isTrue);
      expect(controller.isMapViewMenuOpen.value, isFalse);
    });

    test('switchMapView updates selectedMapView and preserves floor, viewpoint, audio, and camera', () {
      // Setup active viewpoint and audio
      controller.selectViewpoint(controller.viewpoints.first);
      controller.toggleAudio();
      expect(controller.selectedViewpoint.value, isNotNull);
      expect(controller.isPlayingAudio.value, isTrue);
      final activeFloorId = controller.currentFloor.value.id;

      controller.openMapViewMenu();
      expect(controller.isMapViewMenuOpen.value, isTrue);

      // Switch to General View
      controller.switchMapView(MapViewType.general);

      // Selected map view updated and menu closed
      expect(controller.selectedMapView.value, equals(MapViewType.general));
      expect(controller.currentMapViewShortName, equals('General'));
      expect(controller.isMapViewMenuOpen.value, isFalse);

      // Floor context strictly unchanged
      expect(controller.currentFloor.value.id, equals(activeFloorId));
      expect(controller.viewpoints.first.order, equals(100));

      // Viewpoint card and audio strictly preserved
      expect(controller.selectedViewpoint.value, isNotNull);
      expect(controller.isPlayingAudio.value, isTrue);
    });

    test('switchMapView to same active view only closes menu without reload', () {
      expect(controller.selectedMapView.value, equals(MapViewType.satellite));
      controller.openMapViewMenu();
      expect(controller.isMapViewMenuOpen.value, isTrue);

      controller.switchMapView(MapViewType.satellite);
      expect(controller.isMapViewMenuOpen.value, isFalse);
      expect(controller.selectedMapView.value, equals(MapViewType.satellite));
    });

    test('switchFloor preserves the currently selected map view mode', () async {
      // Select Satellite view
      controller.switchMapView(MapViewType.satellite);
      expect(controller.selectedMapView.value, equals(MapViewType.satellite));

      // Switch floor to Level 1
      await controller.switchFloor('floor_1');

      // Floor changed to Level 1
      expect(controller.currentFloor.value.id, equals('floor_1'));
      // Map view mode remains Satellite
      expect(controller.selectedMapView.value, equals(MapViewType.satellite));
    });

    test('calculates floor-based completed viewpoints progress accurately from currently selected floor only', () async {
      // 1. Initial Underground: 0 completed out of 7
      expect(controller.currentFloor.value.id, equals('floor_underground'));
      expect(controller.currentFloorTotalViewpoints, equals(7));
      expect(controller.currentFloorCompletedViewpoints, equals(0));
      expect(controller.currentFloorProgressText, equals('Completed: 0/7'));
      expect(controller.isCurrentFloorComplete, isFalse);

      // 2. Mark Viewpoint 100 visited -> Completed: 1/7
      controller.toggleVisited('vp_100');
      expect(controller.currentFloorCompletedViewpoints, equals(1));
      expect(controller.currentFloorProgressText, equals('Completed: 1/7'));
      expect(controller.currentFloorProgressRatio, closeTo(1 / 7, 0.001));

      // 3. Mark Viewpoint 101 visited -> Completed: 2/7
      controller.toggleVisited('vp_101');
      expect(controller.currentFloorCompletedViewpoints, equals(2));
      expect(controller.currentFloorProgressText, equals('Completed: 2/7'));

      // 4. Unmark Viewpoint 100 -> Completed: 1/7
      controller.toggleVisited('vp_100');
      expect(controller.currentFloorCompletedViewpoints, equals(1));
      expect(controller.currentFloorProgressText, equals('Completed: 1/7'));

      // 5. Switch to Level 1: 0 completed out of 9 (Underground progress must NOT leak)
      await controller.switchFloor('floor_1');
      expect(controller.currentFloorTotalViewpoints, equals(9));
      expect(controller.currentFloorCompletedViewpoints, equals(0));
      expect(controller.currentFloorProgressText, equals('Completed: 0/9'));

      // Mark 4 visited on Level 1 -> Completed: 4/9
      controller.toggleVisited('vp_200');
      controller.toggleVisited('vp_201');
      controller.toggleVisited('vp_202');
      controller.toggleVisited('vp_203');
      expect(controller.currentFloorCompletedViewpoints, equals(4));
      expect(controller.currentFloorProgressText, equals('Completed: 4/9'));

      // 6. Switch back to Underground: previous Underground progress (1/7) is restored
      await controller.switchFloor('floor_underground');
      expect(controller.currentFloorTotalViewpoints, equals(7));
      expect(controller.currentFloorCompletedViewpoints, equals(1));
      expect(controller.currentFloorProgressText, equals('Completed: 1/7'));

      // 7. Changing map view (General -> Satellite) does NOT reset or alter floor progress
      controller.switchMapView(MapViewType.satellite);
      expect(controller.currentFloorCompletedViewpoints, equals(1));
      expect(controller.currentFloorProgressText, equals('Completed: 1/7'));

      // 8. Complete state on Level 3 (5 out of 5)
      await controller.switchFloor('floor_3');
      expect(controller.currentFloorTotalViewpoints, equals(5));
      for (final vp in controller.viewpoints) {
        controller.toggleVisited(vp.id);
      }
      expect(controller.currentFloorCompletedViewpoints, equals(5));
      expect(controller.isCurrentFloorComplete, isTrue);
      expect(controller.currentFloorProgressText, equals('✓ Completed 5/5'));

      // 9. Reset tour resets current floor progress to 0/5
      controller.resetTour();
      expect(controller.currentFloorCompletedViewpoints, equals(0));
      expect(controller.currentFloorProgressText, equals('Completed: 0/5'));
      expect(controller.isCurrentFloorComplete, isFalse);
    });

    test('initializes with Temple of Venus and Rome arguments without reverting to Colosseum', () {
      Get.reset();
      Get.routing.args = {
        'landmarkId': 'temple_venus_rome',
        'landmarkName': 'Temple of Venus and Rome',
        'floorId': 'temple_east',
        'floorName': 'Venus Cella & East Terrace',
      };
      final customController = FloorMapController();
      customController.onInit();

      expect(customController.landmarkId.value, 'temple_venus_rome');
      expect(customController.landmarkName.value, 'Temple of Venus and Rome');
      expect(customController.floorId.value, 'temple_east');
      expect(customController.floorName.value, 'Venus Cella & East Terrace');
      expect(customController.currentFloor.value.landmarkId, 'temple_venus_rome');
      customController.onClose();
    });
  });

  group('FloorMapController Multi-Monument Navigation Tests', () {
    tearDown(() {
      Get.reset();
    });

    test('correctly configures controller for Arch of Constantine entrance floor', () {
      final controller = FloorMapController();
      controller.floorId.value = 'arch_ground';
      controller.landmarkId.value = 'arch_of_constantine';
      controller.landmarkName.value = 'Arch of Constantine';
      controller.onInit();

      expect(controller.landmarkId.value, 'arch_of_constantine');
      expect(controller.landmarkName.value, 'Arch of Constantine');
      expect(controller.floorId.value, 'arch_ground');
      expect(controller.currentFloor.value.landmarkId, 'arch_of_constantine');
      expect(controller.currentFloor.value.displayName, 'Plaza & Constantinian Reliefs');
      controller.onClose();
    });

    test('correctly configures controller for Temple of Venus and Rome entrance floor', () {
      final controller = FloorMapController();
      controller.floorId.value = 'temple_east';
      controller.landmarkId.value = 'temple_venus_rome';
      controller.landmarkName.value = 'Temple of Venus and Rome';
      controller.onInit();

      expect(controller.landmarkId.value, 'temple_venus_rome');
      expect(controller.landmarkName.value, 'Temple of Venus and Rome');
      expect(controller.floorId.value, 'temple_east');
      expect(controller.currentFloor.value.landmarkId, 'temple_venus_rome');
      expect(controller.currentFloor.value.displayName, 'Venus Cella & East Terrace');
      controller.onClose();
    });

    test('correctly configures controller for Ludus Magnus entrance floor', () {
      final controller = FloorMapController();
      controller.floorId.value = 'ludus_arena';
      controller.landmarkId.value = 'ludus_magnus';
      controller.landmarkName.value = 'Ludus Magnus';
      controller.onInit();

      expect(controller.landmarkId.value, 'ludus_magnus');
      expect(controller.landmarkName.value, 'Ludus Magnus');
      expect(controller.floorId.value, 'ludus_arena');
      expect(controller.currentFloor.value.landmarkId, 'ludus_magnus');
      expect(controller.currentFloor.value.displayName, 'Gladiator Arena & Cavea');
      controller.onClose();
    });

    test('auto floor detection undo reverts to previous floor and closes banner', () async {
      final controller = FloorMapController();
      controller.onInit();
      final undergroundFloor = controller.currentFloor.value;
      await controller.switchFloor('floor_2');
      expect(controller.currentFloor.value.id, 'floor_2');

      controller.showAutoFloorSwitchBanner.value = true;
      controller.autoSwitchBannerFloorName.value = 'Level 2 - Colonnade';
      controller.previousFloorBeforeAutoSwitch = undergroundFloor;

      expect(controller.showAutoFloorSwitchBanner.value, isTrue);
      await controller.undoAutoFloorSwitch();

      expect(controller.showAutoFloorSwitchBanner.value, isFalse);
      expect(controller.currentFloor.value.id, undergroundFloor.id);
      controller.onClose();
    });

    test('Solution 2 backup proximity opens out-of-order Viewpoint 103 even when target is 100, with walk-away reset', () async {
      final controller = FloorMapController();
      controller.onInit();
      addTearDown(controller.onClose);

      // Confirm sequential target is Viewpoint 100 and 100..102 are unvisited
      expect(controller.tourState.value.navigationTargetId, 'vp_100');
      final vp103 = controller.viewpoints.firstWhere((vp) => vp.id == 'vp_103');
      final vp100 = controller.viewpoints.firstWhere((vp) => vp.id == 'vp_100');

      // Walk directly to Viewpoint 103 without visiting 100, 101, 102
      controller.updateGpsPosition(vp103.latitude!, vp103.longitude!);
      expect(controller.selectedViewpoint.value, isNull);

      // Wait past Solution 2's 1.5s watchdog delay
      await Future<void>.delayed(const Duration(milliseconds: 1650));

      expect(controller.selectedViewpoint.value?.id, 'vp_103');
      expect(controller.isCardCollapsed.value, isFalse);

      // Close card while still standing at Viewpoint 103 -> should NOT re-open immediately
      controller.deselectViewpoint();
      controller.updateGpsPosition(vp103.latitude!, vp103.longitude!);
      await Future<void>.delayed(const Duration(milliseconds: 1650));
      expect(controller.selectedViewpoint.value, isNull);

      // Walk away (> triggerRadius + 4m) to Viewpoint 100 (feed multiple fixes for GPS smoothing filter), close, then return to 103
      for (int i = 0; i < 6; i++) {
        controller.updateGpsPosition(vp100.latitude!, vp100.longitude!);
      }
      await Future<void>.delayed(const Duration(milliseconds: 1650));
      expect(controller.selectedViewpoint.value?.id, 'vp_100');
      controller.deselectViewpoint();

      // Returning to Viewpoint 103 should re-arm and auto-open 103 again
      for (int i = 0; i < 6; i++) {
        controller.updateGpsPosition(vp103.latitude!, vp103.longitude!);
      }
      await Future<void>.delayed(const Duration(milliseconds: 1650));
      expect(controller.selectedViewpoint.value?.id, 'vp_103');
    });
  });
}
