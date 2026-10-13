import 'package:get/get.dart';

import '../../../data/repositories/i_tour_repository.dart';
import '../../../data/repositories/tour_repository_impl.dart';
import '../../../routes/app_pages.dart';

class LanguageOption {
  const LanguageOption({
    required this.code,
    required this.name,
    String? nativeName,
    this.flag = '🌐',
    this.isAvailable = false,
  }) : nativeName = nativeName ?? name;

  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final bool isAvailable;
}

class LanguageController extends GetxController {
  final ITourRepository tourRepository;

  LanguageController({ITourRepository? tourRepository})
      : tourRepository = tourRepository ??
            (Get.isRegistered<ITourRepository>()
                ? Get.find<ITourRepository>()
                : TourRepositoryImpl());

  final List<LanguageOption> languages = const [
    LanguageOption(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flag: '🇬🇧',
      isAvailable: true,
    ),
    LanguageOption(
      code: 'it',
      name: 'Italian',
      nativeName: 'Italiano',
      flag: '🇮🇹',
      isAvailable: false,
    ),
    LanguageOption(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      flag: '🇪🇸',
      isAvailable: false,
    ),
    LanguageOption(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      flag: '🇫🇷',
      isAvailable: false,
    ),
    LanguageOption(
      code: 'de',
      name: 'German',
      nativeName: 'Deutsch',
      flag: '🇩🇪',
      isAvailable: false,
    ),
    LanguageOption(
      code: 'pt',
      name: 'Portuguese',
      nativeName: 'Português',
      flag: '🇵🇹',
      isAvailable: false,
    ),
    LanguageOption(
      code: 'ja',
      name: 'Japanese',
      nativeName: '日本語',
      flag: '🇯🇵',
      isAvailable: false,
    ),
    LanguageOption(
      code: 'ko',
      name: 'Korean',
      nativeName: '한국어',
      flag: '🇰🇷',
      isAvailable: false,
    ),
  ];

  LanguageOption get selectedLanguage =>
      languages.firstWhere((l) => l.code == selectedLanguageCode.value,
          orElse: () => languages.first);

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
