import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosseum_client/app/core/theme/app_colors.dart';
import 'package:colosseum_client/app/core/theme/app_theme.dart';
import 'package:colosseum_client/app/data/models/floor_definition.dart';
import 'package:colosseum_client/app/data/models/landmark_overlay_model.dart';
import 'package:colosseum_client/app/data/models/offline_aerial_map.dart';
import 'package:colosseum_client/app/data/models/pedestrian_route_data.dart';
import 'package:colosseum_client/app/data/models/sync_manifest_model.dart';
import 'package:colosseum_client/app/data/services/offline_landmark_store.dart';
import 'package:colosseum_client/app/modules/home/controllers/home_controller.dart';
import 'package:colosseum_client/app/modules/home/views/allPointsMap.dart';
import 'package:colosseum_client/app/modules/home/widgets/landmark_map_marker.dart';
import 'package:colosseum_client/app/modules/home/widgets/landmark_markers_layer.dart';
import 'package:colosseum_client/app/modules/home/widgets/landmark_overlay_layer.dart';
import 'package:colosseum_client/app/modules/home/widgets/landmark_detail_card.dart';
import 'package:colosseum_client/app/modules/floor_map/views/floor_map_view.dart';
import 'package:colosseum_client/app/routes/app_pages.dart';

import '../helpers/mock_http_overrides.dart';
import '../helpers/mock_tts.dart';

class _DownloadStore extends OfflineLandmarkStore {
  OfflineLandmark? package;

  @override
  Future<OfflineLandmark?> get(String id, String language) async =>
      package?.landmark.id == id ? package : null;

  @override
  Future<TourSyncManifestModel> latestManifest() async => package!.manifest;

  @override
  Future<List<OfflineLandmark>> list(String language) async =>
      [if (package case final OfflineLandmark saved) saved];
}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
    setupMockTts();
  });

  setUp(() {
    Get.reset();
    Get.put<OfflineLandmarkStore>(_DownloadStore(), permanent: true);
  });

  tearDown(() {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'AllPointsMapView renders FlutterMap with TileLayer, 5 landmark logo image badges, and NO large image overlays',
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

      // Verify all 5 landmark markers are present on the map
      expect(find.byKey(const ValueKey('landmark_marker_colosseum')), findsOneWidget);
      expect(find.byKey(const ValueKey('landmark_marker_arch_of_constantine')), findsOneWidget);
      expect(find.byKey(const ValueKey('landmark_marker_ludus_magnus')), findsOneWidget);
      expect(find.byKey(const ValueKey('landmark_marker_roman_forum')), findsOneWidget);
      expect(find.byKey(const ValueKey('landmark_marker_temple_venus_rome')), findsOneWidget);

      // Verify all 5 location image badges are rendered with correspondent images from assets/logo
      expect(find.byType(LandmarkImageBadge), findsNWidgets(5));
      expect(find.byKey(const ValueKey('landmark_image_colosseum')), findsOneWidget);
      expect(find.byKey(const ValueKey('landmark_image_arch_of_constantine')), findsOneWidget);
      expect(find.byKey(const ValueKey('landmark_image_ludus_magnus')), findsOneWidget);
      expect(find.byKey(const ValueKey('landmark_image_roman_forum')), findsOneWidget);
      expect(find.byKey(const ValueKey('landmark_image_temple_venus_rome')), findsOneWidget);

      final colosseumImg = tester.widget<Image>(find.byKey(const ValueKey('landmark_image_colosseum')));
      final colosseumSrc = colosseumImg.image is NetworkImage
          ? (colosseumImg.image as NetworkImage).url
          : (colosseumImg.image as AssetImage).assetName;
      expect(colosseumSrc.toLowerCase(), contains('colosseum'));

      final archImg = tester.widget<Image>(find.byKey(const ValueKey('landmark_image_arch_of_constantine')));
      final archSrc = archImg.image is NetworkImage
          ? (archImg.image as NetworkImage).url
          : (archImg.image as AssetImage).assetName;
      expect(archSrc.toLowerCase(), contains('constantine'));

      final ludusImg = tester.widget<Image>(find.byKey(const ValueKey('landmark_image_ludus_magnus')));
      final ludusSrc = ludusImg.image is NetworkImage
          ? (ludusImg.image as NetworkImage).url
          : (ludusImg.image as AssetImage).assetName;
      expect(ludusSrc.toLowerCase(), contains('ludus'));

      final forumImg = tester.widget<Image>(find.byKey(const ValueKey('landmark_image_roman_forum')));
      final forumSrc = forumImg.image is NetworkImage
          ? (forumImg.image as NetworkImage).url
          : (forumImg.image as AssetImage).assetName;
      expect(forumSrc.toLowerCase(), contains('forum'));

      final templeImg = tester.widget<Image>(find.byKey(const ValueKey('landmark_image_temple_venus_rome')));
      final templeSrc = templeImg.image is NetworkImage
          ? (templeImg.image as NetworkImage).url
          : (templeImg.image as AssetImage).assetName;
      expect(templeSrc.toLowerCase(), contains('venus'));

      // Verify Colosseum recenter button text is present
      expect(find.text('Colosseum'), findsOneWidget);

      // Verify top controls exist
      expect(find.byKey(const Key('home_recenter_button')), findsOneWidget);
      expect(find.byKey(const Key('home_toggle_map_view_button')), findsOneWidget);

      // Initially starts in Satellite View by default
      expect(controller.selectedMapView.value.name, 'satellite');
      expect(find.text('General'), findsOneWidget);

      // Switch to General View using the top control button
      await tester.tap(find.byKey(const Key('home_toggle_map_view_button')));
      await tester.pump();

      expect(controller.selectedMapView.value.name, 'general');
      expect(find.text('Satellite'), findsOneWidget);

      // All 5 landmark pins and labels remain present
      expect(find.byKey(const ValueKey('landmark_marker_colosseum')), findsOneWidget);
      expect(find.byKey(const ValueKey('landmark_marker_arch_of_constantine')), findsOneWidget);

      // Switch back to Satellite View
      await tester.tap(find.byKey(const Key('home_toggle_map_view_button')));
      await tester.pump();

      expect(controller.selectedMapView.value.name, 'satellite');
      expect(find.text('General'), findsOneWidget);

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
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('close_landmark_card')));
      await tester.pumpAndSettle();

      // Tap on Ludus Magnus marker
      final ludusTapFinder = find.byKey(const ValueKey('landmark_tap_ludus_magnus'));
      expect(ludusTapFinder, findsOneWidget);

      await tester.tap(ludusTapFinder);
      await tester.pump();

      expect(controller.selectedLandmarkId.value, 'ludus_magnus');
    },
  );

  for (final withAerial in [false, true]) {
    testWidgets(
      withAerial ? 'The saved floor draws the aerial image below the offline map layers'
          : 'A legacy offline floor opens without tiles or a landmark badge as its basemap',
      (WidgetTester tester) async {
        Get.put(HomeController());
        final store = Get.find<OfflineLandmarkStore>() as _DownloadStore;
        const outdoorPath = [LatLng(41.89021, 12.492231), LatLng(41.892, 12.489)];
        store.package = OfflineLandmark(
          landmark: const MapLandmarkOverlay(
            id: 'colosseum', name: 'Colosseum', assetPath: 'assets/logo/Colosseum.png',
            center: LatLng(41.89021, 12.492231), widthMeters: 100, heightMeters: 80,
          ),
          floors: [FloorDefinition.underground.copyWith(displayName: 'Saved Hypogeum')],
          routes: const [PedestrianRouteData(outdoorPath)],
          manifest: const TourSyncManifestModel(
            version: '1', dataHash: 'saved', totalFloors: 1, totalViewpoints: 0,
            totalLandmarks: 1, languages: ['en'],
          ),
          language: 'en',
          aerialMap: withAerial ? OfflineAerialMap.forLandmark(const LatLng(41.89021, 12.492231))
              ?.withImagePath('assets/images/viewpoint_default.png') : null,
        );

        await tester.pumpWidget(
          GetMaterialApp(
            theme: AppTheme.lightTheme,
            initialRoute: Routes.allPointsMap,
            getPages: AppPages.routes,
          ),
        );
        await tester.pump();

        final colosseumTapFinder = find.byKey(const ValueKey('landmark_tap_colosseum'));
        expect(colosseumTapFinder, findsOneWidget);

        await tester.tap(colosseumTapFinder);
        await tester.pumpAndSettle();
        expect(find.byType(LandmarkDetailCard), findsOneWidget);
        expect(find.byType(FloorMapView), findsNothing);
        await tester.tap(find.byKey(const Key('landmark_card_enter_button')));
        await tester.pumpAndSettle();

        expect(find.byType(FloorMapView), findsOneWidget);
        expect(find.byType(TileLayer), findsNothing);
        expect(find.byType(OverlayImageLayer), withAerial ? findsOneWidget : findsNothing);
        expect(find.text(OfflineAerialMap.attribution), withAerial ? findsOneWidget : findsNothing);
        expect(find.byType(PolygonLayer), findsNothing);
        final floorPaths = tester.widgetList<PolylineLayer>(
          find.descendant(
            of: find.byType(FloorMapView),
            matching: find.byType(PolylineLayer),
          ),
        ).expand((layer) => layer.polylines);
        expect(floorPaths.map((path) => path.points), isNot(contains(outdoorPath)));
        expect(find.text('Offline map'), findsOneWidget);
        expect(find.text('Colosseum'), findsWidgets);
        expect(find.textContaining('Saved Hypogeum'), findsWidgets);
        expect(find.byKey(const Key('exit_landmark_button')), findsOneWidget);
      },
    );
  }

  testWidgets(
    'A landmark without a download can still open the live floor',
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

      final templeTapFinder = find.byKey(const ValueKey('landmark_tap_temple_venus_rome'));
      expect(templeTapFinder, findsOneWidget);

      await tester.tap(templeTapFinder);
      await tester.pumpAndSettle();
      expect(find.byType(LandmarkDetailCard), findsOneWidget);
      await tester.tap(find.byKey(const Key('landmark_card_enter_button')));
      await tester.pumpAndSettle();

      // Verify navigated directly to FloorMapView displaying Temple of Venus and Rome
      expect(find.byType(FloorMapView), findsOneWidget);
      expect(find.text('Temple of Venus and Rome'), findsWidgets);
      expect(find.textContaining('Venus Cella & East Terrace'), findsWidgets);
      expect(find.byKey(const Key('exit_landmark_button')), findsOneWidget);
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

  testWidgets(
    'Tapping "Show Itinerary" activates tour, renders PolylineLayer and active tour bar, and "End Tour" stops it',
    (WidgetTester tester) async {
      final controller = Get.put(HomeController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const AllPointsMapView(),
        ),
      );
      await tester.pump();

      // Initially "Show Itinerary" button is visible and no PolylineLayer
      expect(find.byKey(const Key('map_start_tour_button')), findsOneWidget);
      expect(find.text('Show Itinerary'), findsOneWidget);
      expect(find.byType(PolylineLayer), findsNothing);

      // Tap "Show Itinerary"
      await tester.tap(find.byKey(const Key('map_start_tour_button')));
      await tester.pump();

      // Tour becomes active: PolylineLayer rendered, active tour bar rendered
      expect(controller.isTourActive.value, isTrue);
      expect(find.byType(PolylineLayer), findsOneWidget);
      expect(find.byKey(const Key('map_active_tour_bar')), findsOneWidget);
      expect(find.textContaining('remaining'), findsOneWidget);

      // Tap "End Tour"
      await tester.tap(find.byKey(const Key('map_end_tour_button')));
      await tester.pumpAndSettle();

      expect(controller.isTourActive.value, isFalse);
      expect(find.byType(PolylineLayer), findsNothing);
      expect(find.byKey(const Key('map_start_tour_button')), findsOneWidget);
      expect(find.text('Show Itinerary'), findsOneWidget);
    },
  );

  testWidgets(
    'Approaching landmark displays arrival popup with Skip and Enter options, and skipping recalculates route',
    (WidgetTester tester) async {
      final controller = Get.put(HomeController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const AllPointsMapView(),
        ),
      );
      await tester.pump();

      // Start tour
      await tester.tap(find.byKey(const Key('map_start_tour_button')));
      await tester.pump();

      // User walks to Arch of Constantine (< 75m)
      controller.setUserLocation(const LatLng(41.889762, 12.490667));
      await tester.pumpAndSettle();

      // Arrival popup should appear
      expect(find.byKey(const Key('landmark_arrival_popup')), findsOneWidget);
      expect(find.text('You are near Arch of Constantine'), findsOneWidget);
      expect(find.textContaining('enter'), findsWidgets);
      expect(find.byKey(const Key('tour_skip_landmark_button')), findsOneWidget);
      expect(find.byKey(const Key('tour_enter_landmark_button')), findsOneWidget);

      // Tap Skip
      await tester.tap(find.byKey(const Key('tour_skip_landmark_button')));
      await tester.pumpAndSettle();

      // Popup is dismissed, landmark is skipped
      expect(find.byKey(const Key('landmark_arrival_popup')), findsNothing);
      expect(controller.skippedLandmarkIds.contains('arch_of_constantine'), isTrue);
      expect(controller.approachingLandmark.value, isNull);
    },
  );

  testWidgets(
    'Approaching landmark and tapping Enter navigates directly to FloorMapView',
    (WidgetTester tester) async {
      final controller = Get.put(HomeController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          initialRoute: Routes.allPointsMap,
          getPages: AppPages.routes,
        ),
      );
      await tester.pump();

      // Start tour
      await tester.tap(find.byKey(const Key('map_start_tour_button')));
      await tester.pump();

      // User walks to Arch of Constantine (< 75m)
      controller.setUserLocation(const LatLng(41.889762, 12.490667));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('landmark_arrival_popup')), findsOneWidget);
      expect(find.byKey(const Key('tour_enter_landmark_button')), findsOneWidget);

      // Tap Enter
      await tester.tap(find.byKey(const Key('tour_enter_landmark_button')));
      await tester.pumpAndSettle();

      // Directly navigates to FloorMapView
      expect(find.byType(FloorMapView), findsOneWidget);
      expect(find.byKey(const Key('exit_landmark_button')), findsOneWidget);
    },
  );
}
