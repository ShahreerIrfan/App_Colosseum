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
    'HomeView renders client UI with Aurelia branding, emblem, description, and Start Tour button',
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

      // Verify Aurelia branding, emblem, and descriptive copy
      expect(find.text('Aurelia'), findsOneWidget);
      expect(
        find.text(
          'Explore the Colosseum through panoramic views and immersive audio narration. Navigate through 5 iconic stops.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.stadium), findsOneWidget);
      expect(find.text('Immersive Audio Experience'), findsOneWidget);
      expect(find.byIcon(Icons.headphones_rounded), findsOneWidget);

      // Verify the Start Tour CTA button exists
      expect(find.byKey(const Key('home_next_button')), findsOneWidget);
      expect(find.text('Start Tour'), findsOneWidget);
    },
  );

  testWidgets(
    'Tapping Start Tour button on HomeView navigates to allPointsMap.dart',
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
      expect(find.text('Start Tour'), findsOneWidget);

      // Tap 'Start Tour' button
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
