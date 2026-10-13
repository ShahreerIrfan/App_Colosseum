import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:colosseum_client/app/core/theme/app_theme.dart';
import 'package:colosseum_client/app/data/providers/landmark_markers_provider.dart';
import 'package:colosseum_client/app/modules/home/widgets/landmark_map_marker.dart';
import 'package:colosseum_client/app/modules/home/widgets/landmark_markers_layer.dart';

import '../helpers/mock_http_overrides.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  Widget buildTestMap({
    required List markers,
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
              markers: LandmarkMarkersProvider.all,
              selectedLandmarkId: selectedLandmarkId,
              currentZoom: zoom,
              onLandmarkTap: onLandmarkTap,
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('LandmarkMarkersLayer renders all 5 landmark pins and labels at zoom 16.5', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildTestMap(
        markers: LandmarkMarkersProvider.all,
        zoom: 16.5,
      ),
    );
    await tester.pump();

    // Verify all 5 markers and pins exist
    expect(find.byType(LandmarkMapMarker), findsNWidgets(5));
    expect(find.byKey(const ValueKey('landmark_marker_colosseum')), findsOneWidget);
    expect(find.byKey(const ValueKey('landmark_marker_arch_of_constantine')), findsOneWidget);
    expect(find.byKey(const ValueKey('landmark_marker_ludus_magnus')), findsOneWidget);
    expect(find.byKey(const ValueKey('landmark_marker_roman_forum')), findsOneWidget);
    expect(find.byKey(const ValueKey('landmark_marker_temple_venus_rome')), findsOneWidget);

    // Verify text labels
    expect(find.text('Colosseum'), findsOneWidget);
    expect(find.text('Arch of Constantine'), findsOneWidget);
    expect(find.text('Ludus Magnus'), findsOneWidget);
    expect(find.text('Roman Forum'), findsOneWidget);
    expect(find.text('Temple of Venus\nand Rome'), findsOneWidget);
  });

  testWidgets('Tapping marker invokes onLandmarkTap with landmark ID', (
    WidgetTester tester,
  ) async {
    String? tappedId;

    await tester.pumpWidget(
      buildTestMap(
        markers: LandmarkMarkersProvider.all,
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
        markers: LandmarkMarkersProvider.all,
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
}
