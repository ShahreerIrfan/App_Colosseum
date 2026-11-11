import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/repositories/i_tour_repository.dart';
import '../../../data/repositories/tour_repository_impl.dart';
import '../../../data/services/language_catalog_service.dart';
import '../../../data/services/offline_landmark_store.dart';
import '../../../data/services/tour_sync_service.dart';
import '../../../core/localization/tour_localizations.dart';
import '../../../routes/app_pages.dart';

class LanguageOption {
  const LanguageOption({
    required this.code,
    required this.name,
    String? nativeName,
    this.flag = '🌐',
    this.ttsLocale,
    this.isAvailable = false,
  }) : nativeName = nativeName ?? name;

  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final String? ttsLocale;
  final bool isAvailable;
}

class LanguageController extends GetxController {
  final ITourRepository tourRepository;

  LanguageController({ITourRepository? tourRepository})
      : tourRepository = tourRepository ??
            (Get.isRegistered<ITourRepository>()
                ? Get.find<ITourRepository>()
                : TourRepositoryImpl());

  static const _bundledLanguages = [
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
  final languages = _bundledLanguages.toList().obs;
  final _catalog = LanguageCatalogService();

  @override
  void onInit() {
    super.onInit();
    unawaited(_loadCatalog());
  }

  Future<void> _loadCatalog() async {
    final cached = await _catalog.loadCached();
    if (cached != null && !isClosed) _applyCatalog(cached);
    try {
      final preferences = await SharedPreferences.getInstance();
      final previous = preferences.getString(LanguageCatalogService.selectionKey);
      if (previous != null && !isClosed) selectLanguage(previous);
    } catch (_) {}
    final remote = await _catalog.refresh();
    if (remote != null && !isClosed) _applyCatalog(remote);
  }

  void _applyCatalog(List<Map<String, dynamic>> rows) {
    final flags = {for (final language in _bundledLanguages) language.code: language.flag};
    final loaded = rows.map((row) {
      final code = row['code'] as String;
      return LanguageOption(
        code: code,
        name: row['name'] as String,
        nativeName: row['nativeName'] as String,
        flag: flags[code] ?? '🌐',
        ttsLocale: row['ttsLocale'] as String?,
        isAvailable: TourLocalizations.supportedLanguages.contains(code) && row['isAvailable'] == true,
      );
    }).toList();
    if (!loaded.any((language) => language.code == 'en' && language.isAvailable)) {
      loaded.removeWhere((language) => language.code == 'en');
      loaded.insert(0, _bundledLanguages.first);
    }
    languages.assignAll(loaded);
    if (!loaded.any((language) =>
        language.code == selectedLanguageCode.value && language.isAvailable)) {
      selectedLanguageCode.value = 'en';
    }
  }

  LanguageOption get selectedLanguage =>
      languages.firstWhere((l) => l.code == selectedLanguageCode.value,
          orElse: () => languages.first);

  final selectedLanguageCode = 'en'.obs;
  final isSyncing = false.obs;
  final downloadFailed = false.obs;

  void selectLanguage(String code) {
    if (languages.any((language) => language.code == code && language.isAvailable)) {
      selectedLanguageCode.value = code;
      downloadFailed.value = false;
    }
  }

  Future<void> _rememberSelection(String language, String locale) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(LanguageCatalogService.selectionKey, language);
      await preferences.setString(LanguageCatalogService.ttsLocaleKey, locale);
    } catch (_) {}
  }

  Future<void> continueToHome() async {
    final selected = selectedLanguage;
    if (!selected.isAvailable || isSyncing.value) return;
    final lang = selected.code;
    final locale = selected.ttsLocale ?? (lang == 'en' ? 'en-US' : lang);
    if (lang != 'en') {
      isSyncing.value = true;
      downloadFailed.value = false;
      try {
        final savedLandmarks = Get.isRegistered<OfflineLandmarkStore>()
            ? await Get.find<OfflineLandmarkStore>().list(lang).catchError(
                (_) => <OfflineLandmark>[],
              ) : const <OfflineLandmark>[];
        if (savedLandmarks.isEmpty) {
          final result = await (Get.isRegistered<TourSyncService>()
              ? Get.find<TourSyncService>().activate(lang)
              : tourRepository.refreshTourBundle(lang: lang));
          if (result == TourSyncResult.unavailable &&
              await tourRepository.getLastBundleDownload(lang: lang) == null) {
            downloadFailed.value = true;
            return;
          }
        }
      } catch (_) {
        downloadFailed.value = true;
        return;
      } finally {
        isSyncing.value = false;
      }
    }
    if (isClosed || selectedLanguageCode.value != lang) return;
    unawaited(_rememberSelection(lang, locale));
    if ((Get.locale?.languageCode ?? 'en') != lang) {
      unawaited(Get.updateLocale(Locale(lang)));
    }
    Get.offNamed(Routes.home, arguments: {'language': lang, 'ttsLocale': locale});
  }
}
