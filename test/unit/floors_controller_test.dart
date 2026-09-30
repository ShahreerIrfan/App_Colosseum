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
  });
}
