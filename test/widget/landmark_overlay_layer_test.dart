import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:colosseum_client/app/data/models/landmark_overlay_model.dart';
import 'package:colosseum_client/app/modules/home/widgets/landmark_overlay_layer.dart';

import '../helpers/mock_http_overrides.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  const testOverlays = [
    MapLandmarkOverlay(
      id: 'colosseum',
      name: 'Colosseum',
      assetPath: 'assets/logo/Colosseum.png',
      center: LatLng(41.890210, 12.492231),
      widthMeters: 190.0,
      heightMeters: 155.0,
      rotationDegrees: -20.0,
      minZoom: 13.0,
      maxZoom: 21.0,
    ),
    MapLandmarkOverlay(
      id: 'arch_of_constantine',
      name: 'Arch of Constantine',
      assetPath: 'assets/logo/Arch of Constantine.png',
      center: LatLng(41.889762, 12.490667),
      widthMeters: 26.0,
      heightMeters: 12.0,
      rotationDegrees: -28.0,
      minZoom: 14.5,
      maxZoom: 21.0,
    ),
    MapLandmarkOverlay(
      id: 'ludus_magnus',
      name: 'Ludus Magnus',
      assetPath: 'assets/logo/Ludus Magnus.png',
      center: LatLng(41.889950, 12.495050),
      widthMeters: 75.0,
      heightMeters: 55.0,
      rotationDegrees: 12.0,
      minZoom: 14.0,
      maxZoom: 21.0,
    ),
    MapLandmarkOverlay(
      id: 'roman_forum',
      name: 'Roman Forum',
      assetPath: 'assets/logo/Roman Forum.png',
      center: LatLng(41.892050, 12.486600),
      widthMeters: 180.0,
      heightMeters: 110.0,
      rotationDegrees: -42.0,
      minZoom: 13.0,
      maxZoom: 21.0,
    ),
    MapLandmarkOverlay(
      id: 'temple_venus_rome',
      name: 'Temple of Venus and Rome',
      assetPath: 'assets/logo/Temple of Venus and Rome.png',
      center: LatLng(41.890880, 12.489700),
      widthMeters: 145.0,
      heightMeters: 100.0,
      rotationDegrees: -30.0,
      minZoom: 14.0,
      maxZoom: 21.0,
    ),
  ];

  testWidgets('LandmarkOverlayLayer renders all 5 overlays at default zoom 16.5', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(41.890320, 12.492180),
              initialZoom: 16.5,
            ),
            children: const [
              LandmarkOverlayLayer(
                overlays: testOverlays,
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
    final overlays = testOverlays.map((o) {
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
    // At zoom 13.2: Only Roman Forum and Colosseum should be visible
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(41.890320, 12.492180),
              initialZoom: 13.2,
            ),
            children: const [
              LandmarkOverlayLayer(
                overlays: testOverlays,
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
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(41.890320, 12.492180),
              initialZoom: 16.5,
            ),
            children: const [
              LandmarkOverlayLayer(
                overlays: testOverlays,
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
