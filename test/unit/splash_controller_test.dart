import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:colosseum_client/app/modules/splash/controllers/splash_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('SplashController Unit Tests', () {
    test('initializes with default navigation delay', () {
      final controller = SplashController();
      expect(controller.navigationDelay, const Duration(seconds: 2));
      controller.onClose();
    });

    test('initializes with custom navigation delay', () {
      final controller = SplashController(
        navigationDelay: const Duration(milliseconds: 50),
      );
      expect(controller.navigationDelay, const Duration(milliseconds: 50));
      controller.onClose();
    });

    test('cancels navigation timer on close without throwing', () {
      final controller = SplashController(
        navigationDelay: const Duration(seconds: 5),
      );
      controller.onReady();
      expect(() => controller.onClose(), returnsNormally);
    });
  });
}
