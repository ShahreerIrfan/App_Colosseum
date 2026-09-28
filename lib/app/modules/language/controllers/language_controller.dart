import 'package:get/get.dart';

import '../../../routes/app_pages.dart';

class LanguageOption {
  const LanguageOption({required this.code, required this.name});

  final String code;
  final String name;
}

class LanguageController extends GetxController {
  final List<LanguageOption> languages = const [
    LanguageOption(code: 'en', name: 'English'),
    LanguageOption(code: 'it', name: 'Italiano'),
    LanguageOption(code: 'fr', name: 'Français'),
    LanguageOption(code: 'de', name: 'Deutsch'),
    LanguageOption(code: 'es', name: 'Español'),
    LanguageOption(code: 'pt', name: 'Português'),
    LanguageOption(code: 'ja', name: '日本語'),
    LanguageOption(code: 'ko', name: '한국어'),
  ];

  final selectedLanguageCode = 'en'.obs;

  void selectLanguage(String code) {
    selectedLanguageCode.value = code;
  }

  void continueToHome() {
    Get.offNamed(Routes.home);
  }
}
