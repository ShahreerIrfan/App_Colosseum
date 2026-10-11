import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:colosseum_client/app/core/theme/app_theme.dart';
import 'package:colosseum_client/app/modules/home/controllers/home_controller.dart';
import 'package:colosseum_client/app/modules/home/views/home_view.dart';
import 'package:colosseum_client/app/routes/app_pages.dart';

import '../helpers/mock_http_overrides.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets(
    'HomeView renders empty screen with only next button',
    (WidgetTester tester) async {
      Get.put(HomeController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeView(),
          getPages: AppPages.routes,
        ),
      );
      await tester.pump();

      // HomeView has no map directly rendered on it
      expect(find.byType(FlutterMap), findsNothing);

      // Verify the next button exists and displays 'next'
      expect(find.byKey(const Key('home_next_button')), findsOneWidget);
      expect(find.text('next'), findsOneWidget);
    },
  );

  testWidgets(
    'Tapping next button on HomeView navigates to allPointsMap.dart',
    (WidgetTester tester) async {
      Get.put(HomeController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          initialRoute: Routes.home,
          getPages: AppPages.routes,
        ),
      );
      await tester.pump();

      // Verify on HomeView
      expect(find.byKey(const Key('home_next_button')), findsOneWidget);

      // Tap 'next' button
      await tester.tap(find.byKey(const Key('home_next_button')));
      await tester.pumpAndSettle();

      // Verify navigated to AllPointsMapView
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byKey(const Key('home_recenter_button')), findsOneWidget);
      expect(find.byKey(const Key('home_toggle_map_view_button')), findsOneWidget);
      expect(find.text('Colosseum'), findsWidgets);
    },
  );
}
