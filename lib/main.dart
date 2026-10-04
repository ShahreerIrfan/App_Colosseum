import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/core/theme/app_theme.dart';
import 'app/data/services/visited_viewpoints_service.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Get.putAsync(() => VisitedViewpointsService().init());

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
