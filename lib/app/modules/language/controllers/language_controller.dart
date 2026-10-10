import 'package:get/get.dart';

import '../../../data/repositories/i_tour_repository.dart';
import '../../../data/repositories/tour_repository_impl.dart';
import '../../../routes/app_pages.dart';

class LanguageOption {
  const LanguageOption({required this.code, required this.name});

  final String code;
  final String name;
}

class LanguageController extends GetxController {
  final ITourRepository tourRepository;

  LanguageController({ITourRepository? tourRepository})
      : tourRepository = tourRepository ??
            (Get.isRegistered<ITourRepository>()
                ? Get.find<ITourRepository>()
                : TourRepositoryImpl());

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
  final isSyncing = false.obs;

  void selectLanguage(String code) {
    selectedLanguageCode.value = code;
  }

  Future<void> continueToHome() async {
    final lang = selectedLanguageCode.value;
    if (lang != 'en') {
      isSyncing.value = true;
      try {
        await tourRepository.syncTourBundle(lang: lang);
      } catch (_) {} finally {
        isSyncing.value = false;
      }
    }
    Get.offNamed(Routes.home, arguments: {'language': lang});
  }
}
