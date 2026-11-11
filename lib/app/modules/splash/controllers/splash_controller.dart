import 'dart:async';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/repositories/i_tour_repository.dart';
import '../../../data/repositories/tour_repository_impl.dart';
import '../../../data/services/language_catalog_service.dart';
import '../../../data/services/tour_sync_service.dart';
import '../../../routes/app_pages.dart';

class SplashController extends GetxController {
  final Duration navigationDelay;
  final ITourRepository tourRepository;

  SplashController({
    this.navigationDelay = const Duration(seconds: 2),
    ITourRepository? tourRepository,
  }) : tourRepository = tourRepository ??
            (Get.isRegistered<ITourRepository>()
                ? Get.find<ITourRepository>()
                : TourRepositoryImpl());

  final syncStatusMessage = 'Connecting to tour database...'.obs;
  final isSyncing = true.obs;
  Timer? _timer;
  bool _isDisposed = false;

  @override
  void onReady() {
    super.onReady();
    _startStartupSync();
  }

  Future<void> _startStartupSync() async {
    final completer = Completer<void>();
    _timer = Timer(navigationDelay, () {
      if (!completer.isCompleted) completer.complete();
    });

    try {
      syncStatusMessage.value = 'Syncing tour package...';
      if (Get.isRegistered<TourSyncService>()) {
        var language = 'en';
        try {
          final preferences = await SharedPreferences.getInstance();
          language = preferences.getString(LanguageCatalogService.selectionKey) ?? 'en';
        } catch (_) {}
        final result = await Get.find<TourSyncService>().activate(language);
        if (result == TourSyncResult.unavailable) {
          if (!_isDisposed) syncStatusMessage.value = 'Offline mode enabled';
          return;
        }
      } else {
        await tourRepository.syncTourBundle(lang: 'en');
      }
      if (!_isDisposed) {
        syncStatusMessage.value = 'Tour package ready';
      }
    } catch (_) {
      if (!_isDisposed) {
        syncStatusMessage.value = 'Offline mode enabled';
      }
    } finally {
      if (!_isDisposed) {
        isSyncing.value = false;
        await completer.future;
        if (!_isDisposed) {
          navigateToLanguage();
        }
      }
    }
  }

  void navigateToLanguage() {
    Get.offNamed(Routes.language);
  }

  @override
  void onClose() {
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
    super.onClose();
  }
}
