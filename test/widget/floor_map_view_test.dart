import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:colosseum_client/app/core/theme/app_theme.dart';
import 'package:colosseum_client/app/data/models/map_view_type.dart';
import 'package:colosseum_client/app/modules/floor_map/controllers/floor_map_controller.dart';
import 'package:colosseum_client/app/modules/floor_map/views/floor_map_view.dart';
import 'package:colosseum_client/app/modules/floor_map/widgets/user_location_puck.dart';
import 'package:colosseum_client/app/modules/floor_map/widgets/viewpoint_detail_card.dart';
import 'package:colosseum_client/app/modules/floor_map/widgets/viewpoint_marker.dart';

import '../helpers/mock_http_overrides.dart';
import '../helpers/mock_tts.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
    setupMockTts();
  });

  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets(
    'FloorMapView renders top bar, map canvas, underground markers (100-106), user puck, and detail card',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = Get.put(FloorMapController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const FloorMapView(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Top bar Exit button and bottom bar landmark & floor name verification
      expect(find.byKey(const Key('exit_landmark_button')), findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);
      expect(find.text('Colosseum'), findsOneWidget);
      expect(find.text('Level : Underground (Hypogeum)'), findsOneWidget);

      // 2. Out-of-Location Badge is shown initially and UserLocationPuck is hidden
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(TileLayer), findsOneWidget);
      expect(find.byType(PolylineLayer), findsOneWidget);
      expect(find.byKey(const Key('out_of_location_badge')), findsOneWidget);
      expect(find.text('You are not in the location'), findsOneWidget);
      expect(find.byType(UserLocationPuck), findsNothing);

      // Markers (7 Underground Stops) are fully visible, Portals (ENTRY & EXIT) are removed
      expect(find.byType(ViewpointMarker), findsNWidgets(7));
      expect(find.byKey(const Key('itinerary_entry_marker')), findsNothing);
      expect(find.byKey(const Key('itinerary_exit_marker')), findsNothing);
      expect(find.text('ENTRY'), findsNothing);
      expect(find.text('EXIT'), findsNothing);

      // Now feed in-bounds GPS position -> Puck appears and out_of_location_badge disappears
      controller.updateGpsPosition(41.890250, 12.492820);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(UserLocationPuck), findsOneWidget);
      expect(find.byKey(const Key('out_of_location_badge')), findsNothing);

      // 3. Floating Controls
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);

      // 4. Initial state: NO viewpoint detail card is visible
      expect(find.byType(ViewpointDetailCard), findsNothing);
      expect(controller.selectedViewpoint.value, isNull);

      // 5. Tap Viewpoint marker (Stop 100) to select and open detail card
      final vp100Marker = find.text('100');
      expect(vp100Marker, findsOneWidget);
      await tester.tap(vp100Marker);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(controller.selectedViewpoint.value?.id, 'vp_100');
      expect(find.byType(ViewpointDetailCard), findsOneWidget);
      expect(
        find.text('Spectacles in the Colosseum Arena Floor. The Superstars'),
        findsAtLeastNWidgets(1),
      );
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Listen Guide'), findsOneWidget);

      // Verify and toggle Visited control
      final visitedButton = find.byKey(const Key('toggle_visited_button'));
      expect(visitedButton, findsOneWidget);
      await tester.tap(visitedButton);
      await tester.pump(const Duration(milliseconds: 200));

      // 5. Audio playback toggle in expanded mode
      await tester.tap(find.byKey(const Key('toggle_audio_expanded')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(controller.isPlayingAudio.value, true);
      expect(find.text('Pause Audio'), findsOneWidget);

      // 6. Collapse the detail card
      final collapseButton = find.byKey(const Key('collapse_card_button'));
      expect(collapseButton, findsOneWidget);
      await tester.tap(collapseButton);
      await tester.pump(const Duration(milliseconds: 350));

      expect(controller.isCardCollapsed.value, true);
      // In collapsed mode, compact toggle audio button and expand button are visible
      expect(find.byKey(const Key('toggle_audio_collapsed')), findsOneWidget);
      expect(find.byKey(const Key('expand_card_button')), findsOneWidget);

      // 7. Toggle audio while in collapsed mode
      await tester.tap(find.byKey(const Key('toggle_audio_collapsed')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.isPlayingAudio.value, false);

      await tester.tap(find.byKey(const Key('toggle_audio_collapsed')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.isPlayingAudio.value, true);

      // 8. Tap another viewpoint marker (Stop 104) while audio is playing -> should automatically pause
      final vp104Marker = find.text('104');
      expect(vp104Marker, findsOneWidget);
      await tester.tap(vp104Marker);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(controller.selectedViewpoint.value?.id, 'vp_104');
      // Automatically paused on viewpoint change
      expect(controller.isPlayingAudio.value, false);

      // 9. Expand the card back
      final expandButton = find.byKey(const Key('expand_card_button'));
      expect(expandButton, findsOneWidget);
      await tester.tap(expandButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(controller.isCardCollapsed.value, false);

      expect(
        find.text(
          'Corridor H: Large Ramps and the Four Galleries to the North, South, East & West',
        ),
        findsAtLeastNWidgets(1),
      );

      // 10. Dismiss detail card
      final closeButton = find.byKey(const Key('close_viewpoint_card')).last;
      await tester.tap(closeButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(controller.selectedViewpoint.value, isNull);
      expect(find.byType(ViewpointDetailCard), findsNothing);

      // 11. Floating zoom control tap
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        controller.transformationController.value.getMaxScaleOnAxis(),
        greaterThan(1.0),
      );

      await tester.tap(find.byIcon(Icons.my_location_rounded));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        controller.transformationController.value.getMaxScaleOnAxis(),
        1.0,
      );
    },
  );

  testWidgets(
    'FloorMapView toggles Field Test mode and renders reset origin button',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = Get.put(FloorMapController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const FloorMapView(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Initially out of location, quick field test button is visible
      expect(find.byKey(const Key('out_of_location_badge')), findsOneWidget);
      final quickButton = find.byKey(const Key('quick_field_test_button'));
      expect(quickButton, findsOneWidget);

      // 2. Tap Quick Field Test button -> activates Playground mode
      await tester.tap(quickButton);
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.isPlaygroundMode.value, isTrue);

      // 3. Feed mock GPS position anywhere (e.g. Dhaka) -> Puck appears at ENTRY
      controller.updateGpsPosition(23.8103, 90.4125);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(UserLocationPuck), findsOneWidget);
      expect(find.textContaining('Field Test'), findsWidgets);
      expect(find.byKey(const Key('reset_origin_button')), findsOneWidget);
      expect(find.byKey(const Key('toggle_pause_walk_button')), findsOneWidget);
      expect(find.byKey(const Key('snap_target_button')), findsOneWidget);

      // 4. Tap Pause Walk button -> pauses displacement and renders walking_paused_banner
      await tester.tap(find.byKey(const Key('toggle_pause_walk_button')));
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.isDisplacementPaused.value, isTrue);
      expect(find.byKey(const Key('walking_paused_banner')), findsOneWidget);
      expect(find.text('Resume'), findsWidgets);

      // 5. Tap Resume on banner -> unfreezes displacement
      await tester.tap(find.byKey(const Key('banner_resume_button')));
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.isDisplacementPaused.value, isFalse);
      expect(find.byKey(const Key('walking_paused_banner')), findsNothing);

      // 6. Tap Reset Origin button
      await tester.tap(find.byKey(const Key('reset_origin_button')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.isPlaygroundMode.value, isTrue);
    },
  );

  testWidgets(
    'Viewpoint number badge remains strictly stationary at exact map coordinates when selected or unselected',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = Get.put(FloorMapController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const FloorMapView(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final vp100Text = find.descendant(
        of: find.byType(ViewpointMarker),
        matching: find.text('100'),
      );
      expect(vp100Text, findsOneWidget);

      // Record unselected center position
      final unselectedCenter = tester.getCenter(vp100Text);

      // Select Viewpoint 100 via controller (as occurs on auto-play / arrival)
      controller.selectViewpoint(controller.viewpoints.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(controller.selectedViewpoint.value?.id, 'vp_100');

      // Verify the center position of the number badge has NOT moved
      final selectedCenter = tester.getCenter(vp100Text);
      expect((selectedCenter.dx - unselectedCenter.dx).abs(), lessThan(0.5));
      expect((selectedCenter.dy - unselectedCenter.dy).abs(), lessThan(0.5));

      // Close / deselect viewpoint
      final closeButton = find.byKey(const Key('close_viewpoint_card')).last;
      await tester.tap(closeButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(controller.selectedViewpoint.value, isNull);

      // Verify after deselect the number badge center remains identical
      final afterDeselectCenter = tester.getCenter(vp100Text);
      expect((afterDeselectCenter.dx - unselectedCenter.dx).abs(), lessThan(0.5));
      expect((afterDeselectCenter.dy - unselectedCenter.dy).abs(), lessThan(0.5));
    },
  );

  testWidgets(
    'Tapping on the map screen does NOT shift user location or place simulated location',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = Get.put(FloorMapController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const FloorMapView(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // In-bounds GPS position placed
      controller.updateGpsPosition(41.890250, 12.492820);
      await tester.pump(const Duration(milliseconds: 100));

      final originalLocation = controller.userLocation.value;
      expect(originalLocation, isNotNull);

      // Tap empty area on map canvas
      await tester.tapAt(const Offset(300, 400));
      await tester.pump(const Duration(milliseconds: 350));

      // Location must remain unchanged
      expect(controller.userLocation.value?.latLng.latitude, originalLocation?.latLng.latitude);
      expect(controller.userLocation.value?.latLng.longitude, originalLocation?.latLng.longitude);
    },
  );

  testWidgets(
    'FloorMapView renders persistent FloorBottomBar, opens FloorSelectionMenu, and switches floor atomically to Level 2',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = Get.put(FloorMapController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const FloorMapView(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Bottom menu bar is visible and persistent
      final floorSelectionButton = find.byKey(const Key('floor_selection_bottom_button'));
      expect(floorSelectionButton, findsOneWidget);
      expect(find.text('Colosseum'), findsOneWidget);
      expect(find.text('Level : Underground (Hypogeum)'), findsAtLeastNWidgets(1));

      // Initially, floor selection menu is NOT visible
      expect(find.byKey(const Key('floor_menu_item_floor_2')), findsNothing);

      // 2. Tap Floor Selection button to open menu
      await tester.tap(floorSelectionButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(controller.isFloorMenuOpen.value, isTrue);
      // Verify all 4 floor options are rendered
      expect(find.byKey(const Key('floor_menu_item_floor_underground')), findsOneWidget);
      expect(find.byKey(const Key('floor_menu_item_floor_1')), findsOneWidget);
      expect(find.byKey(const Key('floor_menu_item_floor_2')), findsOneWidget);
      expect(find.byKey(const Key('floor_menu_item_floor_3')), findsOneWidget);

      // Verify active checkmark is rendered for Underground
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // 3. Tap Level 2 in the menu
      await tester.tap(find.byKey(const Key('floor_menu_item_floor_2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Menu closes
      expect(controller.isFloorMenuOpen.value, isFalse);
      expect(find.byKey(const Key('floor_menu_item_floor_2')), findsNothing);

      // Bottom floor button updates to Level : Level 2
      expect(find.text('Level : Level 2'), findsAtLeastNWidgets(1));
      expect(controller.currentFloor.value.id, 'floor_2');

      // Markers are updated: Level 2 has 7 viewpoints (300-306)
      expect(find.text('300'), findsOneWidget);
      expect(find.text('306'), findsOneWidget);
      expect(find.text('100'), findsNothing);

      // 4. Test closing menu by tapping scrim
      await tester.tap(floorSelectionButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(controller.isFloorMenuOpen.value, isTrue);

      final scrim = find.byKey(const Key('floor_menu_scrim'));
      expect(scrim, findsOneWidget);
      await tester.tap(scrim);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(controller.isFloorMenuOpen.value, isFalse);
    },
  );

  testWidgets(
    'FloorMapView renders Floor Selection button with full floor name, removes bottom Map View button, and toggles map view via toolbar button',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = Get.put(FloorMapController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const FloorMapView(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Floor Selection bottom button is rendered with landmark name and Level
      final floorBtn = find.byKey(const Key('floor_selection_bottom_button'));
      expect(floorBtn, findsOneWidget);
      expect(find.text('Colosseum'), findsOneWidget);
      expect(find.text('Level : Underground (Hypogeum)'), findsAtLeastNWidgets(1));

      // Map View bottom button is removed from bottom bar
      expect(find.byKey(const Key('map_view_bottom_button')), findsNothing);

      // Initially floor selection menu is NOT visible
      expect(find.byKey(const Key('floor_menu_item_floor_1')), findsNothing);

      // 2. Map view defaults to satellite
      expect(controller.selectedMapView.value, equals(MapViewType.satellite));

      // 3. Test toolbar toggle button alternates between General and Satellite view
      final toolbarToggleBtn = find.byKey(const Key('toolbar_toggle_map_view_button'));
      expect(toolbarToggleBtn, findsOneWidget);

      await tester.tap(toolbarToggleBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Toggled to General View
      expect(controller.selectedMapView.value, equals(MapViewType.general));

      // Overlays remain fully intact
      expect(find.byType(TileLayer), findsOneWidget);
      expect(find.byType(PolylineLayer), findsOneWidget);
      expect(find.byType(ViewpointMarker), findsNWidgets(7));

      await tester.tap(toolbarToggleBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Toggled back to Satellite View
      expect(controller.selectedMapView.value, equals(MapViewType.satellite));

      // 4. Tap Floor Selection button to open floor menu
      await tester.tap(floorBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(controller.isFloorMenuOpen.value, isTrue);
      expect(find.byKey(const Key('floor_menu_item_floor_1')), findsOneWidget);

      // 5. Test closing menu via scrim
      final scrim = find.byKey(const Key('floor_menu_scrim'));
      await tester.tap(scrim);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(controller.isFloorMenuOpen.value, isFalse);
    },
  );

  testWidgets(
    'FloorMapView renders floor-based completed viewpoints progress indicator in bottom bar and updates dynamically on visit toggle and floor switch',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Get.put(FloorMapController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const FloorMapView(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Initial Underground: progress indicator is rendered with Completed: 0/7
      expect(find.byKey(const Key('floor_progress_indicator')), findsOneWidget);
      expect(find.text('Completed: 0/7'), findsOneWidget);

      // 2. Select Viewpoint 100 to open card
      final vp100Marker = find.text('100');
      expect(vp100Marker, findsOneWidget);
      await tester.tap(vp100Marker);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // 3. Tap Mark as Visited
      final visitedButton = find.byKey(const Key('toggle_visited_button'));
      expect(visitedButton, findsOneWidget);
      await tester.tap(visitedButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Progress updates to Completed: 1/7
      expect(find.text('Completed: 1/7'), findsOneWidget);

      // 4. Tap Unmark as Visited -> immediately drops back to Completed: 0/7
      await tester.tap(visitedButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Completed: 0/7'), findsOneWidget);

      // Mark it visited again
      await tester.tap(visitedButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Completed: 1/7'), findsOneWidget);

      // 5. Dismiss detail card
      final closeButton = find.byKey(const Key('close_viewpoint_card')).last;
      await tester.tap(closeButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // 6. Switch floor to Level 1
      final floorSelectionButton = find.byKey(const Key('floor_selection_bottom_button'));
      await tester.tap(floorSelectionButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byKey(const Key('floor_menu_item_floor_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Level 1 has 9 viewpoints, none visited -> Completed: 0/9 (No leakage from Underground)
      expect(find.text('Completed: 0/9'), findsOneWidget);

      // 7. Switch Map View to General -> Level 1 progress remains Completed: 0/9
      final toolbarToggleBtn = find.byKey(const Key('toolbar_toggle_map_view_button'));
      await tester.tap(toolbarToggleBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Completed: 0/9'), findsOneWidget);

      // 8. Switch back to Underground -> Underground progress (1/7) is restored accurately
      await tester.tap(floorSelectionButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byKey(const Key('floor_menu_item_floor_underground')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Completed: 1/7'), findsOneWidget);
    },
  );

  testWidgets(
    'FloorMapView renders Exit button in top-right, closes floor menu if open and navigates back on tap',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Get.put(FloorMapController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: Text('Previous Screen')),
        ),
      );

      // Navigate to FloorMapView
      Get.to(() => const FloorMapView());
      await tester.pumpAndSettle();

      expect(find.byType(FloorMapView), findsOneWidget);
      final exitBtn = find.byKey(const Key('exit_landmark_button'));
      expect(exitBtn, findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);

      // Tap Exit button -> navigates back to previous screen
      await tester.tap(exitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Previous Screen'), findsOneWidget);
      expect(find.byType(FloorMapView), findsNothing);
    },
  );
}


