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
    test('initializes cleanly', () {
      final controller = HomeController();
      expect(controller, isNotNull);
      expect(controller.isClosed, isFalse);
    });
  });
}
