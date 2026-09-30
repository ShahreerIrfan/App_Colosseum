import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
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
  });
}

