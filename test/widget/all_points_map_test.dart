import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:colosseum_client/app/core/theme/app_colors.dart';
import 'package:colosseum_client/app/core/theme/app_theme.dart';
import 'package:colosseum_client/app/modules/home/controllers/home_controller.dart';
import 'package:colosseum_client/app/modules/home/views/allPointsMap.dart';
import 'package:colosseum_client/app/modules/home/widgets/landmark_map_marker.dart';
import 'package:colosseum_client/app/modules/home/widgets/landmark_markers_layer.dart';
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
    'AllPointsMapView renders FlutterMap with TileLayer, 5 classic location pins with labels, and NO large image overlays',
    (WidgetTester tester) async {
      final controller = Get.put(HomeController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const AllPointsMapView(),
        ),
      );
      await tester.pump();

      // Verify FlutterMap is rendered with TileLayer, CircleLayer, and LandmarkMarkersLayer
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(TileLayer), findsOneWidget);
      expect(find.byType(CircleLayer), findsOneWidget);
      expect(find.byType(LandmarkMarkersLayer), findsOneWidget);

      // Verify large image overlays were removed from the map
      expect(find.byType(GeoLandmarkOverlayImageWidget), findsNothing);

      // Verify all 5 classic pin markers are present on the map
      expect(find.byKey(const ValueKey('landmark_marker_colosseum')), findsOneWidget);
      expect(find.byKey(const ValueKey('landmark_marker_arch_of_constantine')), findsOneWidget);
      expect(find.byKey(const ValueKey('landmark_marker_ludus_magnus')), findsOneWidget);
      expect(find.byKey(const ValueKey('landmark_marker_roman_forum')), findsOneWidget);
      expect(find.byKey(const ValueKey('landmark_marker_temple_venus_rome')), findsOneWidget);

      // Verify all 5 location name badges (tooltips) are rendered without teardrop pointers
      expect(find.byType(LandmarkLabelBubble), findsNWidgets(5));
      expect(find.byKey(const ValueKey('landmark_pin_colosseum')), findsNothing);

      // Verify visible labels for all 5 monuments
      expect(find.text('Colosseum'), findsWidgets);
      expect(find.text('Arch of Constantine'), findsOneWidget);
      expect(find.text('Ludus Magnus'), findsOneWidget);
      expect(find.text('Roman Forum'), findsOneWidget);
      expect(find.text('Temple of Venus and Rome'), findsOneWidget);

      // Verify top controls exist
      expect(find.byKey(const Key('home_recenter_button')), findsOneWidget);
      expect(find.byKey(const Key('home_toggle_map_view_button')), findsOneWidget);

      // Switch to Satellite View using the top control button
      await tester.tap(find.byKey(const Key('home_toggle_map_view_button')));
      await tester.pump();

      expect(controller.selectedMapView.value.name, 'satellite');
      expect(find.text('General'), findsOneWidget);

      // All 5 landmark pins and labels remain present in satellite view
      expect(find.byKey(const ValueKey('landmark_marker_colosseum')), findsOneWidget);
      expect(find.byKey(const ValueKey('landmark_marker_arch_of_constantine')), findsOneWidget);

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
    'Tapping a location marker activates selected state with distinct visual styling',
    (WidgetTester tester) async {
      final controller = Get.put(HomeController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const AllPointsMapView(),
        ),
      );
      await tester.pump();

      // Initially, Colosseum is selected by default
      expect(controller.selectedLandmarkId.value, 'colosseum');

      // Tap on Arch of Constantine marker
      final archTapFinder = find.byKey(const ValueKey('landmark_tap_arch_of_constantine'));
      expect(archTapFinder, findsOneWidget);

      await tester.tap(archTapFinder);
      await tester.pump();

      // Now Arch of Constantine is the active selected landmark
      expect(controller.selectedLandmarkId.value, 'arch_of_constantine');

      // Tap on Ludus Magnus marker
      final ludusTapFinder = find.byKey(const ValueKey('landmark_tap_ludus_magnus'));
      expect(ludusTapFinder, findsOneWidget);

      await tester.tap(ludusTapFinder);
      await tester.pump();

      expect(controller.selectedLandmarkId.value, 'ludus_magnus');
    },
  );

  testWidgets(
    'Tapping Colosseum marker when selected navigates to FloorsView',
    (WidgetTester tester) async {
      Get.put(HomeController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          initialRoute: Routes.allPointsMap,
          getPages: AppPages.routes,
        ),
      );
      await tester.pump();

      // Colosseum is initially selected; tapping it navigates to floors
      final colosseumTapFinder = find.byKey(const ValueKey('landmark_tap_colosseum'));
      expect(colosseumTapFinder, findsOneWidget);

      await tester.tap(colosseumTapFinder);
      await tester.pumpAndSettle();

      // Verify navigated to FloorsView
      expect(find.text('Floor 1'), findsOneWidget);
      expect(find.text('Floor 2'), findsOneWidget);
      expect(find.text('Floor 3'), findsOneWidget);
    },
  );

  testWidgets(
    'Displays "you are not in the zone" banner and reddish circle when user is outside zone',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = Get.put(HomeController());
      // Set location 700m away from Colosseum (outside 600m zone)
      controller.setUserLocation(const LatLng(41.896510, 12.492231));

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const AllPointsMapView(),
        ),
      );
      await tester.pump();

      // Verify "you are not in the zone" text is displayed at the top
      expect(find.text('you are not in the zone'), findsOneWidget);
      expect(find.byKey(const Key('out_of_zone_banner')), findsOneWidget);

      // Verify user location marker is rendered on the map
      expect(find.byKey(const Key('user_location_marker')), findsOneWidget);

      // Verify the circle is reddish (primary color theme)
      final circleLayer = tester.widget<CircleLayer>(find.byType(CircleLayer));
      expect(circleLayer.circles.first.color, equals(AppTheme.lightTheme.extension<AppColors>()!.primary.withValues(alpha: 0.12)));
    },
  );

  testWidgets(
    'Hides warning banner, renders greenish circle, and displays user location puck when user is in zone',
    (WidgetTester tester) async {
      final controller = Get.put(HomeController());
      // Set location at Arch of Constantine (~139m from Colosseum, well within 600m)
      controller.setUserLocation(const LatLng(41.889762, 12.490667));

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const AllPointsMapView(),
        ),
      );
      await tester.pump();

      // Verify "you are not in the zone" text is NOT present
      expect(find.text('you are not in the zone'), findsNothing);
      expect(find.byKey(const Key('out_of_zone_banner')), findsNothing);

      // Verify user location marker is rendered
      expect(find.byKey(const Key('user_location_marker')), findsOneWidget);

      // Verify the circle is greenish (Roman Laurel Green)
      final circleLayer = tester.widget<CircleLayer>(find.byType(CircleLayer));
      expect(circleLayer.circles.first.color, equals(const Color(0xFF2E7D32).withValues(alpha: 0.12)));
    },
  );
}
