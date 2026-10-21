import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:colosseum_client/app/core/theme/app_theme.dart';
import 'package:colosseum_client/app/data/models/landmark_marker_model.dart';
import 'package:colosseum_client/app/modules/home/widgets/landmark_map_marker.dart';
import 'package:colosseum_client/app/modules/home/widgets/landmark_markers_layer.dart';

import '../helpers/mock_http_overrides.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  const testMarkers = [
    LandmarkMarkerModel(
      id: 'colosseum',
      name: 'Colosseum',
      coordinates: LatLng(41.890210, 12.492231),
      color: Color(0xFFDD1110),
      category: 'Amphitheatre',
      imagePath: 'assets/logo/Colosseum.png',
    ),
    LandmarkMarkerModel(
      id: 'arch_of_constantine',
      name: 'Arch of Constantine',
      coordinates: LatLng(41.889762, 12.490667),
      color: Color(0xFFFF8F00),
      category: 'Triumphal Arch',
      imagePath: 'assets/logo/Arch of Constantine.png',
    ),
    LandmarkMarkerModel(
      id: 'ludus_magnus',
      name: 'Ludus Magnus',
      coordinates: LatLng(41.889950, 12.495050),
      color: Color(0xFF1E88E5),
      category: 'Gladiator School',
      imagePath: 'assets/logo/Ludus Magnus.png',
    ),
    LandmarkMarkerModel(
      id: 'roman_forum',
      name: 'Roman Forum',
      coordinates: LatLng(41.892050, 12.486600),
      color: Color(0xFF2E7D32),
      category: 'Forum & Valley',
      imagePath: 'assets/logo/Roman Forum.png',
    ),
    LandmarkMarkerModel(
      id: 'temple_venus_rome',
      name: 'Temple of Venus and Rome',
      coordinates: LatLng(41.890880, 12.489700),
      color: Color(0xFF8E24AA),
      category: 'Double Temple',
      imagePath: 'assets/logo/Temple of Venus and Rome.png',
    ),
  ];

  Widget buildTestMap({
    required List<LandmarkMarkerModel> markers,
    String? selectedLandmarkId,
    double zoom = 16.5,
    ValueChanged<String>? onLandmarkTap,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: FlutterMap(
          options: MapOptions(
            initialCenter: const LatLng(41.890250, 12.492230),
            initialZoom: zoom,
          ),
          children: [
            LandmarkMarkersLayer(
              markers: markers,
              selectedLandmarkId: selectedLandmarkId,
              currentZoom: zoom,
              onLandmarkTap: onLandmarkTap,
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('LandmarkMarkersLayer renders all 5 landmark image badges at zoom 16.5', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildTestMap(
        markers: testMarkers,
        zoom: 16.5,
      ),
    );
    await tester.pump();

    // Verify all 5 markers and image badges exist
    expect(find.byType(LandmarkMapMarker), findsNWidgets(5));
    expect(find.byType(LandmarkImageBadge), findsNWidgets(5));
    expect(find.byKey(const ValueKey('landmark_marker_colosseum')), findsOneWidget);
    expect(find.byKey(const ValueKey('landmark_marker_arch_of_constantine')), findsOneWidget);
    expect(find.byKey(const ValueKey('landmark_marker_ludus_magnus')), findsOneWidget);
    expect(find.byKey(const ValueKey('landmark_marker_roman_forum')), findsOneWidget);
    expect(find.byKey(const ValueKey('landmark_marker_temple_venus_rome')), findsOneWidget);

    // Verify all 5 correspondent images from assets/logo are rendered
    expect(find.byKey(const ValueKey('landmark_image_colosseum')), findsOneWidget);
    expect(find.byKey(const ValueKey('landmark_image_arch_of_constantine')), findsOneWidget);
    expect(find.byKey(const ValueKey('landmark_image_ludus_magnus')), findsOneWidget);
    expect(find.byKey(const ValueKey('landmark_image_roman_forum')), findsOneWidget);
    expect(find.byKey(const ValueKey('landmark_image_temple_venus_rome')), findsOneWidget);

    final colosseumImg = tester.widget<Image>(find.byKey(const ValueKey('landmark_image_colosseum')));
    expect((colosseumImg.image as AssetImage).assetName, 'assets/logo/Colosseum.png');

    final archImg = tester.widget<Image>(find.byKey(const ValueKey('landmark_image_arch_of_constantine')));
    expect((archImg.image as AssetImage).assetName, 'assets/logo/Arch of Constantine.png');

    final ludusImg = tester.widget<Image>(find.byKey(const ValueKey('landmark_image_ludus_magnus')));
    expect((ludusImg.image as AssetImage).assetName, 'assets/logo/Ludus Magnus.png');

    final forumImg = tester.widget<Image>(find.byKey(const ValueKey('landmark_image_roman_forum')));
    expect((forumImg.image as AssetImage).assetName, 'assets/logo/Roman Forum.png');

    final templeImg = tester.widget<Image>(find.byKey(const ValueKey('landmark_image_temple_venus_rome')));
    expect((templeImg.image as AssetImage).assetName, 'assets/logo/Temple of Venus and Rome.png');
  });

  testWidgets('Tapping marker invokes onLandmarkTap with landmark ID', (
    WidgetTester tester,
  ) async {
    String? tappedId;

    await tester.pumpWidget(
      buildTestMap(
        markers: testMarkers,
        zoom: 16.5,
        onLandmarkTap: (id) => tappedId = id,
      ),
    );
    await tester.pump();

    final archTapFinder = find.byKey(const ValueKey('landmark_tap_arch_of_constantine'));
    expect(archTapFinder, findsOneWidget);

    await tester.tap(archTapFinder);
    await tester.pump();

    expect(tappedId, 'arch_of_constantine');
  });

  testWidgets('Selected marker displays active highlighted visual styling', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildTestMap(
        markers: testMarkers,
        selectedLandmarkId: 'colosseum',
        zoom: 16.5,
      ),
    );
    final semantics = tester.ensureSemantics();
    await tester.pump();

    // Colosseum marker has semantics "Colosseum, selected"
    expect(find.bySemanticsLabel('Colosseum, selected'), findsOneWidget);

    // Non-selected markers have standard semantics
    expect(find.bySemanticsLabel('Arch of Constantine'), findsOneWidget);

    // Selected marker renders active check badge
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('LandmarkMarkersLayer renders compact badges at zoomed-out level (zoom 15.0)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildTestMap(
        markers: testMarkers,
        zoom: 15.0,
      ),
    );
    await tester.pump();

    // Verify all 5 markers render in compact mode without error
    expect(find.byType(LandmarkMapMarker), findsNWidgets(5));
    expect(find.byType(LandmarkImageBadge), findsNWidgets(5));
    expect(find.byKey(const ValueKey('landmark_image_colosseum')), findsOneWidget);
    expect(find.byKey(const ValueKey('landmark_image_arch_of_constantine')), findsOneWidget);
    expect(find.byKey(const ValueKey('landmark_image_ludus_magnus')), findsOneWidget);
    expect(find.byKey(const ValueKey('landmark_image_roman_forum')), findsOneWidget);
    expect(find.byKey(const ValueKey('landmark_image_temple_venus_rome')), findsOneWidget);

    final badge = tester.widget<LandmarkImageBadge>(
      find.descendant(
        of: find.byKey(const ValueKey('landmark_marker_colosseum')),
        matching: find.byType(LandmarkImageBadge),
      ),
    );
    expect(badge.isCompact, isTrue);
  });
}
