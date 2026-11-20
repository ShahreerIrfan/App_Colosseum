import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/core/localization/tour_localizations.dart';
import 'app/core/theme/app_theme.dart';
import 'app/data/repositories/i_tour_repository.dart';
import 'app/data/repositories/tour_repository_impl.dart';
import 'app/data/services/offline_landmark_store.dart';
import 'app/data/services/tour_sync_service.dart';
import 'app/data/services/visited_viewpoints_service.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Hive.initFlutter();
  } catch (e) {
    debugPrint('Hive.initFlutter error: $e');
  }
  try {
    await Get.putAsync(() => VisitedViewpointsService().init());
  } catch (e) {
    debugPrint('VisitedViewpointsService init error: $e');
  }
  final repository = TourRepositoryImpl();
  Get.put<ITourRepository>(repository, permanent: true);
  final downloads = Get.put(OfflineLandmarkStore(), permanent: true);
  Get.put(TourSyncService(repository, downloads), permanent: true);
  Get.locale = const Locale('en');

  runApp(
    GetMaterialApp(
      title: "Colosseum Tour Guide",
      supportedLocales: TourLocalizations.supportedLanguages.map(Locale.new).toList(),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.lightTheme,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
    ),
  );
}
