import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:colosseum_client/app/core/theme/app_theme.dart';
import 'package:colosseum_client/app/modules/home/controllers/home_controller.dart';
import 'package:colosseum_client/app/modules/home/views/home_view.dart';

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

  testWidgets('HomeView renders FlutterMap, layers, and controls', (
    WidgetTester tester,
  ) async {
    final controller = Get.put(HomeController());

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.lightTheme, home: const HomeView()),
    );

    // Verify FlutterMap and its overlay layers are rendered
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(OverlayImageLayer), findsOneWidget);
    expect(find.byType(MarkerLayer), findsOneWidget);

    // Verify Colosseum recenter button is visible
    expect(find.text('Colosseum'), findsOneWidget);
    expect(find.byIcon(Icons.center_focus_strong_rounded), findsOneWidget);

    // Select Colosseum programmatically and pump
    controller.selectPoi(controller.landmarks.first);
    await tester.pumpAndSettle();

    // Verify selected POI card details are displayed (Button + Card Title)
    expect(find.text('Colosseum'), findsNWidgets(2));
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });
}
