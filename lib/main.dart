import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/core/theme/app_theme.dart';
import 'app/data/repositories/i_tour_repository.dart';
import 'app/data/repositories/tour_repository_impl.dart';
import 'app/data/services/visited_viewpoints_service.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Get.putAsync(() => VisitedViewpointsService().init());
  Get.put<ITourRepository>(TourRepositoryImpl(), permanent: true);

  runApp(
    GetMaterialApp(
      title: "Colosseum Tour Guide",
      theme: AppTheme.lightTheme,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
    ),
  );
}
