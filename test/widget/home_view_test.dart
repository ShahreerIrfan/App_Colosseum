import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:colosseum_client/app/core/theme/app_theme.dart';
import 'package:colosseum_client/app/modules/home/controllers/home_controller.dart';
import 'package:colosseum_client/app/modules/home/views/home_view.dart';

void main() {
  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('HomeView renders successfully with welcome messages', (
    WidgetTester tester,
  ) async {
    Get.put(HomeController());

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.lightTheme, home: const HomeView()),
    );

    expect(find.text('Welcome to the\nColosseum'), findsOneWidget);
    expect(
      find.text('Your audio experience\nis ready to begin.'),
      findsOneWidget,
    );
    expect(find.text('Main Tour Experience Coming Next'), findsOneWidget);
    expect(find.byIcon(Icons.museum_outlined), findsOneWidget);
  });
}
