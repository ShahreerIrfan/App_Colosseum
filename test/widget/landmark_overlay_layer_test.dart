import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:colosseum_client/app/data/providers/colosseum_landmark_overlays.dart';
import 'package:colosseum_client/app/modules/home/widgets/landmark_overlay_layer.dart';

import '../helpers/mock_http_overrides.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  testWidgets('LandmarkOverlayLayer renders all 5 overlays at default zoom 16.5', (WidgetTester tester) async {
    final overlays = ColosseumLandmarkOverlays.all;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(41.890320, 12.492180),
              initialZoom: 16.5,
            ),
            children: [
              LandmarkOverlayLayer(
                overlays: overlays,
                currentZoom: 16.5,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify 5 GeoLandmarkOverlayImageWidget exist (one for each landmark)
    expect(find.byType(GeoLandmarkOverlayImageWidget), findsNWidgets(5));
    expect(find.byKey(const ValueKey('landmark_overlay_colosseum')), findsOneWidget);
    expect(find.byKey(const ValueKey('landmark_overlay_arch_of_constantine')), findsOneWidget);
    expect(find.byKey(const ValueKey('landmark_overlay_ludus_magnus')), findsOneWidget);
    expect(find.byKey(const ValueKey('landmark_overlay_roman_forum')), findsOneWidget);
    expect(find.byKey(const ValueKey('landmark_overlay_temple_venus_rome')), findsOneWidget);

    // Verify IgnorePointer wraps non-tappable overlays
    final ignorePointerFinder = find.byKey(const Key('landmark_overlay_ignore_pointer'));
    expect(ignorePointerFinder, findsWidgets);
  });

  testWidgets('Clickable overlay triggers onTap when tapped', (WidgetTester tester) async {
    bool wasTapped = false;
    final overlays = ColosseumLandmarkOverlays.all.map((o) {
      if (o.id == 'colosseum') {
        return o.copyWith(onTap: () => wasTapped = true);
      }
      return o;
    }).toList();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(41.890250, 12.492230),
              initialZoom: 16.5,
            ),
            children: [
              LandmarkOverlayLayer(
                overlays: overlays,
                currentZoom: 16.5,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final tapFinder = find.byKey(const ValueKey('landmark_tap_colosseum'));
    expect(tapFinder, findsOneWidget);

    await tester.tap(tapFinder);
    await tester.pump();

    expect(wasTapped, isTrue);
  });

  testWidgets('LandmarkOverlayLayer filters overlays by minZoom and maxZoom', (WidgetTester tester) async {
    final overlays = ColosseumLandmarkOverlays.all;

    // At zoom 13.2: Only Roman Forum and Colosseum should be visible
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(41.890320, 12.492180),
              initialZoom: 13.2,
            ),
            children: [
              LandmarkOverlayLayer(
                overlays: overlays,
                currentZoom: 13.2,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    // Arch of Constantine (minZoom 14.5) and Ludus Magnus (minZoom 14.0) should be hidden
    expect(find.byKey(const ValueKey('landmark_overlay_arch_of_constantine')), findsNothing);
    expect(find.byKey(const ValueKey('landmark_overlay_ludus_magnus')), findsNothing);
    // Colosseum and Roman Forum (minZoom 13.0) should be visible
    expect(find.byKey(const ValueKey('landmark_overlay_colosseum')), findsOneWidget);
    expect(find.byKey(const ValueKey('landmark_overlay_roman_forum')), findsOneWidget);
  });

  testWidgets('LandmarkOverlayLayer renders debug polygon outlines in debug mode', (WidgetTester tester) async {
    final overlays = ColosseumLandmarkOverlays.all;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(41.890320, 12.492180),
              initialZoom: 16.5,
            ),
            children: [
              LandmarkOverlayLayer(
                overlays: overlays,
                currentZoom: 16.5,
                isDebug: true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PolygonLayer), findsOneWidget);
  });
}
