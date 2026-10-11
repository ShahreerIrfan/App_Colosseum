import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../routes/app_pages.dart';
import '../controllers/home_controller.dart';
import 'allPointsMap.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ElevatedButton(
            key: const Key('home_next_button'),
            onPressed: () {
              if (Get.routeTree.routes.any((route) => route.name == Routes.allPointsMap)) {
                Get.toNamed(Routes.allPointsMap);
              } else {
                Get.to(() => const AllPointsMapView());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.primaryForeground,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.borderMd,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 14.0,
              ),
            ),
            child: Text(
              'next',
              style: textTheme.titleMedium?.copyWith(
                color: colors.primaryForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
