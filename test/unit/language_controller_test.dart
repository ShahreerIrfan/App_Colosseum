import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:colosseum_client/app/modules/language/controllers/language_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('LanguageController Unit Tests', () {
    late LanguageController controller;

    setUp(() {
      controller = LanguageController();
    });

    test('initializes with English selected by default', () {
      expect(controller.selectedLanguageCode.value, 'en');
    });

    test('contains all required languages', () {
      final codes = controller.languages.map((l) => l.code).toList();
      expect(
        codes,
        containsAll(['en', 'it', 'fr', 'de', 'es', 'pt', 'ja', 'ko']),
      );
    });

    test('selectLanguage changes selectedLanguageCode to "it"', () {
      controller.selectLanguage('it');
      expect(controller.selectedLanguageCode.value, 'it');
    });

    test('selectLanguage changes selectedLanguageCode to "fr"', () {
      controller.selectLanguage('fr');
      expect(controller.selectedLanguageCode.value, 'fr');
    });
  });
}
