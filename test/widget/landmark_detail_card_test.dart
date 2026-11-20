import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:colosseum_client/app/core/theme/app_theme.dart';
import 'package:colosseum_client/app/data/models/landmark_marker_model.dart';
import 'package:colosseum_client/app/data/models/landmark_onboarding_model.dart';
import 'package:colosseum_client/app/modules/home/controllers/home_controller.dart';
import 'package:colosseum_client/app/modules/home/views/allPointsMap.dart';
import 'package:colosseum_client/app/modules/home/widgets/landmark_detail_card.dart';

import '../helpers/mock_http_overrides.dart';
import '../helpers/mock_tts.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
    setupMockTts();
  });

  setUp(() {
    Get.reset();
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  final testMarker = LandmarkMarkerModel(
    id: 'colosseum',
    name: 'Colosseum',
    coordinates: const LatLng(41.890210, 12.492231),
    color: const Color(0xFFDD1110),
    category: 'Amphitheatre',
    icon: Icons.account_balance_rounded,
    imagePath: 'assets/logo/Colosseum.png',
  );

  final testOnboarding = LandmarkOnboardingModel.forLandmark('colosseum');

  Widget buildTestCard({
    bool isPlaying = false,
    bool isCollapsed = false,
    double progress = 0.0,
    double? distanceMeters = 8.0,
    VoidCallback? onToggleAudio,
    VoidCallback? onToggleCollapse,
    VoidCallback? onClose,
    VoidCallback? onEnterMonument,
    VoidCallback? onDirections,
  }) {
    return GetMaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: LandmarkDetailCard(
              landmark: testMarker,
              onboarding: testOnboarding,
              isPlaying: isPlaying,
              isCollapsed: isCollapsed,
              progress: progress,
              distanceMeters: distanceMeters,
              onToggleAudio: onToggleAudio ?? () {},
              onToggleCollapse: onToggleCollapse ?? () {},
              onClose: onClose ?? () {},
              onEnterMonument: onEnterMonument ?? () {},
              onDirections: onDirections,
            ),
          ),
        ),
      ),
    );
  }

  group('LandmarkDetailCard Expanded View Tests', () {
    testWidgets('renders all visual elements, titles, era, security, and levels', (tester) async {
      await tester.pumpWidget(buildTestCard(distanceMeters: 8.4));
      await tester.pumpAndSettle();

      // Title & category
      expect(find.text('Colosseum'), findsWidgets);
      expect(find.text('Amphitheatre'), findsOneWidget);
      expect(find.text('8 m to entrance'), findsOneWidget);

      // Era & builders
      expect(find.textContaining('70 – 80 AD'), findsWidgets);
      expect(find.textContaining('Vespasian'), findsWidgets);

      // Historical summary section: At a glance
      expect(find.text('At a glance'), findsOneWidget);
      expect(
        find.textContaining('Commissioned in 70 AD by Emperor Vespasian'),
        findsWidgets,
      );

      // Security guidelines section: Before you enter
      expect(find.text('Before you enter'), findsOneWidget);
      expect(
        find.textContaining('Valid ticket and official government photo ID'),
        findsOneWidget,
      );

      // Accessible levels
      expect(find.text('Accessible Levels'), findsOneWidget);
      expect(
        find.textContaining('Level 0: Hypogeum'),
        findsOneWidget,
      );

      // Action buttons
      expect(find.byKey(const Key('landmark_card_enter_button')), findsOneWidget);
      expect(find.byKey(const Key('collapse_landmark_card_button')), findsOneWidget);
      expect(find.byKey(const Key('close_landmark_card')), findsOneWidget);
    });

    testWidgets('tap on Play/Pause audio button triggers onToggleAudio callback', (tester) async {
      var audioToggled = false;
      await tester.pumpWidget(
        buildTestCard(
          isPlaying: false,
          onToggleAudio: () => audioToggled = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('toggle_landmark_audio_expanded')));
      await tester.pump();

      expect(audioToggled, isTrue);
    });

    testWidgets('tap on Collapse button triggers onToggleCollapse callback', (tester) async {
      var collapseToggled = false;
      await tester.pumpWidget(
        buildTestCard(
          onToggleCollapse: () => collapseToggled = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('collapse_landmark_card_button')));
      await tester.pump();

      expect(collapseToggled, isTrue);
    });

    testWidgets('tap on Close button triggers onClose callback', (tester) async {
      var closed = false;
      await tester.pumpWidget(
        buildTestCard(
          onClose: () => closed = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('close_landmark_card')));
      await tester.pump();

      expect(closed, isTrue);
    });

    testWidgets('tap on Enter Monument button triggers onEnterMonument callback', (tester) async {
      var entered = false;
      await tester.pumpWidget(
        buildTestCard(
          onEnterMonument: () => entered = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('landmark_card_enter_button')));
      await tester.pump();

      expect(entered, isTrue);
    });

    testWidgets('renders Directions button when callback provided', (tester) async {
      var directionsClicked = false;
      await tester.pumpWidget(
        buildTestCard(
          onDirections: () => directionsClicked = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('landmark_card_directions_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('landmark_card_directions_button')));
      await tester.pump();

      expect(directionsClicked, isTrue);
    });

    testWidgets('shows LinearProgressIndicator when audio is playing or has progress', (tester) async {
      await tester.pumpWidget(buildTestCard(isPlaying: true, progress: 0.45));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('landmark_audio_progress_bar')), findsOneWidget);
    });
  });

  group('LandmarkDetailCard Collapsed Mini-Player View Tests', () {
    testWidgets('renders collapsed mini-player layout with controls', (tester) async {
      await tester.pumpWidget(
        buildTestCard(
          isCollapsed: true,
          isPlaying: true,
          distanceMeters: 7.8,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Colosseum'), findsWidgets);
      expect(find.text('8m'), findsOneWidget);
      expect(find.byKey(const Key('enter_monument_button_collapsed')), findsOneWidget);
      expect(find.byKey(const Key('toggle_landmark_audio_collapsed')), findsOneWidget);
      expect(find.byKey(const Key('expand_landmark_card_button')), findsOneWidget);
      expect(find.byKey(const Key('close_landmark_card_collapsed')), findsOneWidget);
    });

    testWidgets('tap on Expand button in collapsed mode triggers onToggleCollapse', (tester) async {
      var expandToggled = false;
      await tester.pumpWidget(
        buildTestCard(
          isCollapsed: true,
          onToggleCollapse: () => expandToggled = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('expand_landmark_card_button')));
      await tester.pump();

      expect(expandToggled, isTrue);
    });

    testWidgets('tap on Close button in collapsed mode triggers onClose', (tester) async {
      var closed = false;
      await tester.pumpWidget(
        buildTestCard(
          isCollapsed: true,
          onClose: () => closed = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('close_landmark_card_collapsed')));
      await tester.pump();

      expect(closed, isTrue);
    });
  });

  group('Map Integration with LandmarkDetailCard', () {
    testWidgets('AllPointsMapView displays LandmarkDetailCard when landmark card is active', (tester) async {
      final controller = Get.put(HomeController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const AllPointsMapView(),
        ),
      );
      await tester.pumpAndSettle();

      // Initially not visible
      expect(find.byType(LandmarkDetailCard), findsNothing);

      // Trigger landmark card
      final colosseum = controller.landmarkMarkers.firstWhere((m) => m.id == 'colosseum');
      controller.showLandmarkOnboarding(colosseum, autoTriggered: false, autoPlayAudio: false);
      await tester.pumpAndSettle();

      // Card is now rendered on map
      expect(find.byType(LandmarkDetailCard), findsOneWidget);
      expect(find.text('Colosseum'), findsWidgets);

      // Tap close button on card
      await tester.tap(find.byKey(const Key('close_landmark_card')));
      await tester.pumpAndSettle();

      expect(find.byType(LandmarkDetailCard), findsNothing);
      expect(controller.isLandmarkCardVisible.value, isFalse);

      controller.onClose();
    });

    testWidgets('tapping Colosseum pin marker on map opens LandmarkDetailCard', (tester) async {
      final controller = Get.put(HomeController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const AllPointsMapView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LandmarkDetailCard), findsNothing);

      // Tap Colosseum logo pin marker
      await tester.tap(find.byKey(const ValueKey('landmark_tap_colosseum')));
      await tester.pumpAndSettle();

      expect(find.byType(LandmarkDetailCard), findsOneWidget);
      expect(controller.isLandmarkCardVisible.value, isTrue);
      expect(controller.activeLandmarkForCard.value?.id, 'colosseum');

      controller.onClose();
    });
  });
}
