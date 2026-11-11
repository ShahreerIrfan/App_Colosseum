import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:colosseum_client/app/core/localization/tour_localizations.dart';
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

    test('a language absent from the available server catalog cannot be selected', () {
      controller.selectLanguage('it');
      expect(controller.selectedLanguageCode.value, 'en');
    });

    test('all bundled languages translate navigation prompts with the stop number', () {
      addTearDown(() => Get.locale = const Locale('en'));
      const phrase = 'Next, proceed toward Viewpoint {number}.';
      for (final language in TourLocalizations.supportedLanguages.where((code) => code != 'en')) {
        Get.locale = Locale(language);
        final prompt = phrase.tourTextWith({'number': 7});
        expect(prompt, contains('7'), reason: language);
        expect(prompt, isNot('Next, proceed toward Viewpoint 7.'), reason: language);
      }
    });
  });
}
