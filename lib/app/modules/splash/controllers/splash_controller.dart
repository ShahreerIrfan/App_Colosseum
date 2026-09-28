import 'dart:async';

import 'package:get/get.dart';

import '../../../routes/app_pages.dart';

class SplashController extends GetxController {
  SplashController({this.navigationDelay = const Duration(seconds: 2)});

  final Duration navigationDelay;
  Timer? _navigationTimer;

  @override
  void onReady() {
    super.onReady();
    _startNavigationTimer();
  }

  void _startNavigationTimer() {
    _navigationTimer = Timer(navigationDelay, navigateToLanguage);
  }

  void navigateToLanguage() {
    Get.offNamed(Routes.language);
  }

  @override
  void onClose() {
    _navigationTimer?.cancel();
    _navigationTimer = null;
    super.onClose();
  }
}
