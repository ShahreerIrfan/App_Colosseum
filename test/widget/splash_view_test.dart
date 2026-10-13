import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:colosseum_client/app/core/theme/app_theme.dart';
import 'package:colosseum_client/app/modules/splash/controllers/splash_controller.dart';
import 'package:colosseum_client/app/modules/splash/views/splash_view.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('SplashView renders title, subtitle, and icon', (
    WidgetTester tester,
  ) async {
    final controller = Get.put(
      SplashController(navigationDelay: const Duration(hours: 1)),
    );

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.lightTheme, home: const SplashView()),
    );

    expect(find.text('COLOSSEUM'), findsOneWidget);
    expect(find.text('AUDIO GUIDE'), findsOneWidget);
    expect(find.text('YOUR JOURNEY THROUGH HISTORY'), findsOneWidget);
    expect(find.byIcon(Icons.stadium_rounded), findsOneWidget);

    controller.onClose();
  });
}
