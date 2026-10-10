import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:colosseum_client/app/core/theme/app_theme.dart';
import 'package:colosseum_client/app/modules/home/controllers/home_controller.dart';
import 'package:colosseum_client/app/modules/home/views/home_view.dart';
import 'package:colosseum_client/app/modules/home/widgets/landmark_overlay_layer.dart';
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
    'HomeView renders FlutterMap with TileLayer, 5 geo-anchored landmark overlays, top map controls, and no pin marker',
    (WidgetTester tester) async {
      final controller = Get.put(HomeController());

      await tester.pumpWidget(
        GetMaterialApp(theme: AppTheme.lightTheme, home: const HomeView()),
      );
      await tester.pump();

      // Verify FlutterMap is rendered with TileLayer and LandmarkOverlayLayer
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(TileLayer), findsOneWidget);
      expect(find.byType(LandmarkOverlayLayer), findsOneWidget);

      // Verify the landmark pointer marker was removed
      expect(find.byType(MarkerLayer), findsNothing);
      expect(find.text('1'), findsNothing);

      // Verify all 5 landmark ground overlays are present
      expect(find.byType(GeoLandmarkOverlayImageWidget), findsNWidgets(5));
      expect(find.byKey(const ValueKey('landmark_overlay_colosseum')), findsOneWidget);
      expect(find.byKey(const ValueKey('landmark_overlay_arch_of_constantine')), findsOneWidget);
      expect(find.byKey(const ValueKey('landmark_overlay_ludus_magnus')), findsOneWidget);
      expect(find.byKey(const ValueKey('landmark_overlay_roman_forum')), findsOneWidget);
      expect(find.byKey(const ValueKey('landmark_overlay_temple_venus_rome')), findsOneWidget);

      // Colosseum overlay is clickable
      expect(find.byKey(const ValueKey('landmark_tap_colosseum')), findsOneWidget);

      // Controls
      expect(find.text('Colosseum'), findsOneWidget); // Recenter button label only
      expect(find.byKey(const Key('home_recenter_button')), findsOneWidget);
      expect(find.byKey(const Key('home_toggle_map_view_button')), findsOneWidget);

      // Switch to Satellite View using the top control button
      await tester.tap(find.byKey(const Key('home_toggle_map_view_button')));
      await tester.pump();

      expect(controller.selectedMapView.value.name, 'satellite');
      expect(find.text('General'), findsOneWidget);

      // All 5 landmark overlays remain in satellite view
      expect(find.byType(GeoLandmarkOverlayImageWidget), findsNWidgets(5));
      expect(find.byKey(const ValueKey('landmark_overlay_colosseum')), findsOneWidget);

      // Switch back to General View
      await tester.tap(find.byKey(const Key('home_toggle_map_view_button')));
      await tester.pump();

      expect(controller.selectedMapView.value.name, 'general');
      expect(find.text('Satellite'), findsOneWidget);

      // Tap recenter button
      await tester.tap(find.byKey(const Key('home_recenter_button')));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Tapping Colosseum overlay image directly navigates to FloorsView',
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

      // Find the clickable Colosseum image overlay
      final colosseumTapFinder = find.byKey(const ValueKey('landmark_tap_colosseum'));
      expect(colosseumTapFinder, findsOneWidget);

      // Tap on the Colosseum overlay image
      await tester.tap(colosseumTapFinder);
      await tester.pumpAndSettle();

      // Verify navigated to FloorsView
      expect(find.text('Floor 1'), findsOneWidget);
      expect(find.text('Floor 2'), findsOneWidget);
      expect(find.text('Floor 3'), findsOneWidget);
    },
  );
}
