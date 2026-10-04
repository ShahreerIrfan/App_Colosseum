import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:colosseum_client/app/modules/floors/controllers/floors_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('FloorsController Unit Tests', () {
    late FloorsController controller;

    setUp(() {
      controller = FloorsController();
      controller.onInit();
    });

    tearDown(() {
      controller.onClose();
    });

    test('initializes with default landmark name "Colosseum"', () {
      expect(controller.landmarkName.value, 'Colosseum');
    });

    test('initializes with floors including Underground', () {
      expect(controller.floors.length, 4);
      expect(controller.floors[0].floorName, 'Underground (Hypogeum)');
      expect(controller.floors[0].viewpointCount, 7);
      expect(controller.floors[1].floorName, 'Floor 1');
      expect(controller.floors[1].viewpointCount, 9);
      expect(controller.floors[2].floorName, 'Floor 2');
      expect(controller.floors[2].viewpointCount, 7);
      expect(controller.floors[3].floorName, 'Floor 3');
      expect(controller.floors[3].viewpointCount, 5);
    });

    test('initializes with Underground selected by default', () {
      expect(controller.selectedFloorId.value, 'floor_underground');
    });

    test('selectFloor updates selectedFloorId', () {
      controller.selectFloor('floor_2');
      expect(controller.selectedFloorId.value, 'floor_2');

      controller.selectFloor('floor_3');
      expect(controller.selectedFloorId.value, 'floor_3');
    });

    test('initializes with 0 completed viewpoints when none are visited', () {
      for (final floor in controller.floors) {
        expect(floor.completedCount, equals(0));
        expect(floor.isCompleted, isFalse);
        expect(floor.progress, equals(0.0));
      }
    });

    test('reactively updates completedCount when viewpoints are marked visited (e.g. Underground: 7 viewpoints, completed: 5)', () {
      // Initially 0 completed
      expect(controller.floors[0].completedCount, equals(0));
      expect(controller.floors[0].viewpointCount, equals(7));

      // Mark 5 viewpoints on Underground as visited
      controller.visitedService.setVisitedIdsForTesting(['vp_100', 'vp_101', 'vp_102', 'vp_103', 'vp_104']);

      // Floors reactively recomputed
      final underground = controller.floors.firstWhere((f) => f.id == 'floor_underground');
      expect(underground.viewpointCount, equals(7));
      expect(underground.completedCount, equals(5));
      expect(underground.isCompleted, isFalse);
      expect(underground.progress, closeTo(5 / 7, 0.001));

      // Mark the remaining 2 viewpoints as visited
      controller.visitedService.setVisitedIdsForTesting([
        'vp_100', 'vp_101', 'vp_102', 'vp_103', 'vp_104', 'vp_105', 'vp_106'
      ]);

      final completedUnderground = controller.floors.firstWhere((f) => f.id == 'floor_underground');
      expect(completedUnderground.completedCount, equals(7));
      expect(completedUnderground.isCompleted, isTrue);
      expect(completedUnderground.progress, equals(1.0));
    });
  });
}
