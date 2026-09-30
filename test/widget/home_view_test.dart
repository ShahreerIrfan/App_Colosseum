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
    'HomeView renders FlutterMap with TileLayer, Colosseum UI marker, and recenter control',
    (WidgetTester tester) async {
      Get.put(HomeController());

      await tester.pumpWidget(
        GetMaterialApp(theme: AppTheme.lightTheme, home: const HomeView()),
      );

      // Verify FlutterMap is rendered with TileLayer and MarkerLayer
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(TileLayer), findsOneWidget);
      expect(find.byType(MarkerLayer), findsOneWidget);

      // Verify no raster overlay image layers exist
      expect(find.byType(OverlayImageLayer), findsNothing);

      // Verify UI Marker with label 'Colosseum' and number '1'
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Colosseum'), findsNWidgets(2)); // Button + Marker Label
      expect(find.byIcon(Icons.center_focus_strong_rounded), findsOneWidget);

      // Tap recenter button
      await tester.tap(find.byIcon(Icons.center_focus_strong_rounded));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Tapping Colosseum map marker navigates to FloorsView',
    (WidgetTester tester) async {
      Get.put(HomeController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          initialRoute: Routes.home,
          getPages: AppPages.routes,
        ),
      );

      // Verify Home is visible with map marker
      expect(find.text('1'), findsOneWidget);

      // Tap on the map marker
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      // Verify navigated to FloorsView
      expect(find.text('Floor 1'), findsOneWidget);
      expect(find.text('Floor 2'), findsOneWidget);
      expect(find.text('Floor 3'), findsOneWidget);
    },
  );
}



