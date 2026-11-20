import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:colosseum_client/app/data/datasources/local/landmark_onboarding_data.dart';
import 'package:colosseum_client/app/data/models/landmark_onboarding_model.dart';
import 'package:colosseum_client/app/modules/home/controllers/home_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LandmarkOnboardingData & Model Verification', () {
    test('all 5 canonical monuments exist and have authentic data', () {
      final monuments = LandmarkOnboardingData.all;
      expect(monuments.length, 5);

      final ids = monuments.map((m) => m.landmarkId).toSet();
      expect(
        ids,
        containsAll([
          'colosseum',
          'arch_of_constantine',
          'ludus_magnus',
          'temple_venus_rome',
          'roman_forum',
        ]),
      );
    });

    test('verifies architectural outer radii specifications', () {
      expect(HomeController.getLandmarkOuterRadius('colosseum'), 65.0);
      expect(HomeController.getLandmarkOuterRadius('arch_of_constantine'), 18.0);
      expect(HomeController.getLandmarkOuterRadius('ludus_magnus'), 35.0);
      expect(HomeController.getLandmarkOuterRadius('temple_venus_rome'), 55.0);
      expect(HomeController.getLandmarkOuterRadius('temple_of_venus_and_rome'), 55.0);
      expect(HomeController.getLandmarkOuterRadius('roman_forum'), 50.0);
      expect(HomeController.getLandmarkOuterRadius('unknown_site'), 40.0);
    });

    test('verifies Colosseum onboarding details and security rules', () {
      final colosseum = LandmarkOnboardingModel.forLandmark('colosseum');
      expect(colosseum.outerRadiusMeters, 65.0);
      expect(colosseum.era, contains('70 – 80 AD'));
      expect(colosseum.builders, contains('Vespasian'));
      expect(colosseum.historicalSummary, isNotEmpty);
      expect(colosseum.securityGuidelines.length, greaterThanOrEqualTo(4));
      expect(colosseum.levelHighlights.length, greaterThanOrEqualTo(4));
      expect(colosseum.audioIntroText, contains('Flavian Amphitheatre'));
    });

    test('handles landmark ID normalization properly', () {
      final normalized = LandmarkOnboardingModel.forLandmark('temple_of_venus_and_rome');
      expect(normalized.landmarkId, 'temple_venus_rome');
      expect(normalized.outerRadiusMeters, 55.0);

      final italianNormalized = LandmarkOnboardingModel.forLandmark('colosseo');
      expect(italianNormalized.landmarkId, 'colosseum');
    });
  });

  group('HomeController Landmark Proximity Math & State Machine Tests', () {
    late HomeController controller;

    setUp(() {
      Get.reset();
      Get.testMode = true;
      controller = HomeController();
      controller.onInit();
    });

    tearDown(() {
      controller.onClose();
      Get.reset();
    });

    test('exterior approach at 70m triggers landmark onboarding pop-up with auto-play audio', () {
      expect(controller.isLandmarkCardVisible.value, isFalse);
      expect(controller.activeLandmarkForCard.value, isNull);

      // Colosseum center is (41.890210, 12.492231).
      // A delta of +0.00063 degrees latitude ~ 70.05 meters away.
      // Colosseum outer radius is 65m, trigger range is 65.0m - 75.0m.
      const nearColosseum = LatLng(41.890840, 12.492231);
      final distance = const Distance().as(
        LengthUnit.Meter,
        nearColosseum,
        HomeController.colosseumCoordinates,
      );
      expect(distance, greaterThanOrEqualTo(65.0));
      expect(distance, lessThanOrEqualTo(75.0));

      controller.setUserLocation(nearColosseum);

      expect(controller.isLandmarkCardVisible.value, isTrue);
      expect(controller.activeLandmarkForCard.value, isNotNull);
      expect(controller.activeLandmarkForCard.value!.id, 'colosseum');
      expect(controller.isLandmarkCardCollapsed.value, isFalse);
      expect(controller.isLandmarkAudioPlaying.value, isTrue);
    });

    test('outside buffer (>75m) does NOT trigger landmark onboarding card', () {
      expect(controller.isLandmarkCardVisible.value, isFalse);

      // User at 85m from Colosseum center (+0.000765 lat)
      const outsideBuffer = LatLng(41.890975, 12.492231);
      final distance = const Distance().as(
        LengthUnit.Meter,
        outsideBuffer,
        HomeController.colosseumCoordinates,
      );
      expect(distance, greaterThan(75.0));

      controller.setUserLocation(outsideBuffer);

      expect(controller.isLandmarkCardVisible.value, isFalse);
      expect(controller.activeLandmarkForCard.value, isNull);
    });

    test('user can pause and resume landmark audio briefing', () {
      const nearColosseum = LatLng(41.890840, 12.492231);
      controller.setUserLocation(nearColosseum);

      expect(controller.isLandmarkAudioPlaying.value, isTrue);

      // User pauses audio
      controller.toggleLandmarkAudio();
      expect(controller.isLandmarkAudioPlaying.value, isFalse);
      expect(controller.isLandmarkCardVisible.value, isTrue);

      // User resumes audio
      controller.toggleLandmarkAudio();
      expect(controller.isLandmarkAudioPlaying.value, isTrue);
    });

    test('user can collapse and expand landmark detail card', () {
      const nearColosseum = LatLng(41.890840, 12.492231);
      controller.setUserLocation(nearColosseum);

      expect(controller.isLandmarkCardCollapsed.value, isFalse);

      // User collapses to mini-player
      controller.toggleLandmarkCardCollapse();
      expect(controller.isLandmarkCardCollapsed.value, isTrue);
      // Audio remains playing in background
      expect(controller.isLandmarkAudioPlaying.value, isTrue);

      // User expands back
      controller.toggleLandmarkCardCollapse();
      expect(controller.isLandmarkCardCollapsed.value, isFalse);
    });

    test('tapping directions generates walking route and minimizes card to collapsed view', () {
      const nearColosseum = LatLng(41.890840, 12.492231);
      controller.setUserLocation(nearColosseum);
      expect(controller.isLandmarkCardCollapsed.value, isFalse);

      final colosseum = controller.landmarkMarkers.firstWhere((m) => m.id == 'colosseum');
      controller.getDirectionsToLandmark(colosseum);

      // Card is minimized to smaller version so map and route are visible
      expect(controller.isLandmarkCardCollapsed.value, isTrue);
      expect(controller.landmarkDirectionsRoute, isNotEmpty);
    });

    test('departure hysteresis: moving past radius + 25m auto-dismisses card', () {
      // 1. Enter buffer zone at 70m
      const nearColosseum = LatLng(41.890840, 12.492231);
      controller.setUserLocation(nearColosseum);
      expect(controller.isLandmarkCardVisible.value, isTrue);

      // 2. Walk slightly away to 80m (still under 65 + 25 = 90m hysteresis limit)
      const stillNear = LatLng(41.890930, 12.492231);
      controller.setUserLocation(stillNear);
      expect(controller.isLandmarkCardVisible.value, isTrue);

      // 3. Walk past 90m (e.g. 96m at +0.00086 lat)
      const walkedAway = LatLng(41.891070, 12.492231);
      final distAway = const Distance().as(
        LengthUnit.Meter,
        walkedAway,
        HomeController.colosseumCoordinates,
      );
      expect(distAway, greaterThan(90.0));

      controller.setUserLocation(walkedAway);
      expect(controller.isLandmarkCardVisible.value, isFalse);
      expect(controller.activeLandmarkForCard.value, isNull);
      expect(controller.isLandmarkAudioPlaying.value, isFalse);
    });

    test('manual pin tap opens landmark onboarding card without auto-playing', () {
      final arch = controller.landmarkMarkers.firstWhere((m) => m.id == 'arch_of_constantine');
      controller.showLandmarkOnboarding(arch, autoTriggered: false, autoPlayAudio: false);

      expect(controller.isLandmarkCardVisible.value, isTrue);
      expect(controller.activeLandmarkForCard.value?.id, 'arch_of_constantine');
      expect(controller.isLandmarkCardCollapsed.value, isFalse);
      expect(controller.isLandmarkAudioPlaying.value, isFalse);
    });

    test('dismissLandmarkCard closes card and stops audio', () {
      final colosseum = controller.landmarkMarkers.firstWhere((m) => m.id == 'colosseum');
      controller.showLandmarkOnboarding(colosseum, autoTriggered: true, autoPlayAudio: true);

      expect(controller.isLandmarkCardVisible.value, isTrue);
      expect(controller.isLandmarkAudioPlaying.value, isTrue);

      controller.dismissLandmarkCard();

      expect(controller.isLandmarkCardVisible.value, isFalse);
      expect(controller.activeLandmarkForCard.value, isNull);
      expect(controller.isLandmarkAudioPlaying.value, isFalse);
    });

    test('starting itinerary tour shows pedestrian route over map and does NOT pop up landmark card', () {
      // User is located near Colosseum (99m away)
      const nearColosseum = LatLng(41.890840, 12.492231);
      controller.setUserLocation(nearColosseum);

      // Onboarding card was triggered by free-roam approach
      expect(controller.isLandmarkCardVisible.value, isTrue);

      // User taps "Show Itinerary" (starts tour)
      controller.startTour();

      // Card is dismissed so the full map and pedestrian itinerary route are clearly visible
      expect(controller.isTourActive.value, isTrue);
      expect(controller.isLandmarkCardVisible.value, isFalse);
      expect(controller.activeLandmarkForCard.value, isNull);
      expect(controller.currentTourRoutePoints, isNotEmpty);

      // Subsequent GPS updates at the same position do NOT pop up the card again
      controller.setUserLocation(nearColosseum);
      expect(controller.isLandmarkCardVisible.value, isFalse);

      // But user can still explicitly tap any landmark marker to view its card
      final arch = controller.landmarkMarkers.firstWhere((m) => m.id == 'arch_of_constantine');
      controller.showLandmarkOnboarding(arch);
      expect(controller.isLandmarkCardVisible.value, isTrue);
      expect(controller.activeLandmarkForCard.value?.id, 'arch_of_constantine');
    });

    test('during active tour, approaching a new landmark automatically shows card with audio', () {
      // Tour is active
      controller.startTour();
      expect(controller.isLandmarkCardVisible.value, isFalse);

      // User walks to Arch of Constantine (~50m away from Arch center: 41.889762, 12.490667)
      const nearArch = LatLng(41.889900, 12.490700);
      controller.setUserLocation(nearArch);

      // Automatically triggers onboarding card and plays audio
      expect(controller.isLandmarkCardVisible.value, isTrue);
      expect(controller.activeLandmarkForCard.value?.id, 'arch_of_constantine');
      expect(controller.isLandmarkAudioPlaying.value, isTrue);
    });
  });
}
