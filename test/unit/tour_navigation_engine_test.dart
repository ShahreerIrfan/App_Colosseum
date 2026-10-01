import 'package:flutter_test/flutter_test.dart';
import 'package:colosseum_client/app/data/models/tour_navigation_state.dart';
import 'package:colosseum_client/app/data/models/user_location_model.dart';
import 'package:colosseum_client/app/data/models/viewpoint_model.dart';
import 'package:colosseum_client/app/data/services/tour_navigation_engine.dart';

void main() {
  group('TourNavigationEngine Unit Tests', () {
    late TourNavigationEngine engine;
    late List<String> spokenInstructions;
    late List<String> autoPlayedIds;

    const testViewpoints = [
      ViewpointModel(
        id: 'vp_100',
        floorId: 'floor_underground',
        title: 'Arena Spectacles',
        order: 100,
        normalizedX: 0.80,
        normalizedY: 0.50,
        description: 'Spectacles description text',
        audioDuration: '4 min',
      ),
      ViewpointModel(
        id: 'vp_101',
        floorId: 'floor_underground',
        title: 'Ludus Magnus Tunnel',
        order: 101,
        normalizedX: 0.88,
        normalizedY: 0.38,
        description: 'Tunnel description text',
        audioDuration: '5 min',
      ),
      ViewpointModel(
        id: 'vp_102',
        floorId: 'floor_underground',
        title: 'Hypogeum Phases',
        order: 102,
        normalizedX: 0.68,
        normalizedY: 0.30,
        description: 'Phases description text',
        audioDuration: '4 min',
      ),
    ];

    setUp(() {
      spokenInstructions = [];
      autoPlayedIds = [];

      engine = TourNavigationEngine(
        config: const TourConfig(
          approachRadiusMeters: 8.0,
          arrivalRadiusMeters: 4.0,
          departureRadiusMeters: 7.0,
          arrivalDwellDuration: Duration(milliseconds: 2500),
          maxJumpDistanceMeters: 15.0,
          maxLocationAge: Duration(seconds: 5),
          maxAcceptableAccuracyMeters: 6.0,
          arenaWidthMeters: 86.0,
          arenaHeightMeters: 54.0,
        ),
        onSpeakInstruction: (text, {onDone}) {
          spokenInstructions.add(text);
          onDone?.call();
        },
        onAutoPlayViewpoint: (vp) {
          autoPlayedIds.add(vp.id);
        },
      );
    });

    test('1. Initial tour state targets vp_100 and arms it for auto-play', () {
      engine.startTour(
        floorId: 'floor_underground',
        viewpoints: testViewpoints,
        entryLocation: const Offset(0.92, 0.50),
        exitLocation: const Offset(0.10, 0.50),
      );

      expect(engine.state.navigationTargetId, equals('vp_100'));
      expect(engine.state.armedAutoPlayViewpointId, equals('vp_100'));
      expect(engine.state.navigationStatus, equals(TourNavigationStatus.navigating));
      expect(spokenInstructions, contains('Begin the Underground tour. Proceed toward Viewpoint 100.'));
    });

    test('2. Metric physical distance calculation uses Colosseum physical scale (86m x 54m)', () {
      final p1 = const Offset(0.92, 0.50);
      final p2 = const Offset(0.80, 0.50);
      final dist = engine.calculateMetricDistance(p1, p2);

      // (0.92 - 0.80) * 86 = 10.32 meters
      expect(dist, closeTo(10.32, 0.05));
    });

    test('3. Ignores location beacons on a different floor', () {
      engine.startTour(
        floorId: 'floor_underground',
        viewpoints: testViewpoints,
      );

      const wrongFloorLoc = UserLocationModel(
        floorId: 'floor_1',
        normalizedX: 0.80,
        normalizedY: 0.50,
        accuracyMeters: 2.0,
      );

      engine.updateLocation(wrongFloorLoc);
      expect(engine.state.userLocation, isNull);
      expect(engine.state.navigationStatus, equals(TourNavigationStatus.navigating));
    });

    test('4. Discards stale location older than maxLocationAge', () {
      engine.startTour(
        floorId: 'floor_underground',
        viewpoints: testViewpoints,
      );

      final now = DateTime.now();
      final staleLoc = UserLocationModel(
        floorId: 'floor_underground',
        normalizedX: 0.80,
        normalizedY: 0.50,
        accuracyMeters: 2.0,
        timestamp: now.subtract(const Duration(seconds: 15)),
      );

      engine.updateLocation(staleLoc, now: now);
      expect(engine.state.userLocation, isNull);
    });

    test('5. Flags locationUncertain when accuracy exceeds threshold and suppresses arrival trigger', () {
      engine.startTour(
        floorId: 'floor_underground',
        viewpoints: testViewpoints,
      );

      final poorAccuracyLoc = UserLocationModel(
        floorId: 'floor_underground',
        normalizedX: 0.80,
        normalizedY: 0.50, // Exactly at 100
        accuracyMeters: 12.0, // Exceeds 6.0m limit
        timestamp: DateTime.now(),
      );

      engine.updateLocation(poorAccuracyLoc);
      expect(engine.state.isLocationUncertain, isTrue);
      expect(engine.state.navigationStatus, equals(TourNavigationStatus.locationUncertain));
      expect(autoPlayedIds, isEmpty);
    });

    test('6. Rejects sudden impossible location jump (> 15m)', () {
      engine.startTour(
        floorId: 'floor_underground',
        viewpoints: testViewpoints,
      );

      final t0 = DateTime.now();
      final locEntry = UserLocationModel(
        floorId: 'floor_underground',
        normalizedX: 0.92,
        normalizedY: 0.50,
        accuracyMeters: 2.0,
        timestamp: t0,
      );
      engine.updateLocation(locEntry, now: t0);

      // Sudden jump from Entry (0.92, 0.50) to (0.40, 0.50) -> (0.52 * 86 = 44.7m jump)
      final locJump = UserLocationModel(
        floorId: 'floor_underground',
        normalizedX: 0.40,
        normalizedY: 0.50,
        accuracyMeters: 2.0,
        timestamp: t0.add(const Duration(milliseconds: 300)),
      );

      engine.updateLocation(locJump, now: t0.add(const Duration(milliseconds: 300)));
      expect(engine.state.arrivalDwellStartedAt, isNull);
      expect(autoPlayedIds, isEmpty);
    });

    test('7. Approach zone (<= 8m) transitions to approaching and speaks direction', () {
      engine.startTour(
        floorId: 'floor_underground',
        viewpoints: testViewpoints,
      );
      spokenInstructions.clear();

      final t0 = DateTime.now();
      // Distance from (0.87, 0.50) to (0.80, 0.50) is 0.07 * 86 = 6.02m (<= 8m and > 4m)
      final locApproach = UserLocationModel(
        floorId: 'floor_underground',
        normalizedX: 0.87,
        normalizedY: 0.50,
        accuracyMeters: 2.0,
        timestamp: t0,
      );

      engine.updateLocation(locApproach, now: t0);
      expect(engine.state.navigationStatus, equals(TourNavigationStatus.approaching));
      expect(spokenInstructions, contains('Viewpoint 100 is ahead.'));
    });

    test('8. Arrival zone (<= 4m) requires 2.5s sustained dwell before confirming arrival & auto-playing', () {
      engine.startTour(
        floorId: 'floor_underground',
        viewpoints: testViewpoints,
      );
      spokenInstructions.clear();

      final t0 = DateTime.now();
      // Distance from (0.82, 0.50) to (0.80, 0.50) is 0.02 * 86 = 1.72m (<= 4m)
      final locArrival = UserLocationModel(
        floorId: 'floor_underground',
        normalizedX: 0.82,
        normalizedY: 0.50,
        accuracyMeters: 1.5,
        timestamp: t0,
      );

      // Sample 1 at t0: Enters arrivalPending, starts dwell timer
      engine.updateLocation(locArrival, now: t0);
      expect(engine.state.navigationStatus, equals(TourNavigationStatus.arrivalPending));
      expect(engine.state.arrivalDwellStartedAt, equals(t0));
      expect(autoPlayedIds, isEmpty);

      // Sample 2 at t0 + 1.5s: Dwell not complete yet
      final t1 = t0.add(const Duration(milliseconds: 1500));
      engine.updateLocation(locArrival, now: t1);
      expect(engine.state.navigationStatus, equals(TourNavigationStatus.arrivalPending));
      expect(autoPlayedIds, isEmpty);

      // Sample 3 at t0 + 2.6s: Dwell satisfied (>= 2.5s) -> ARRIVAL CONFIRMED!
      final t2 = t0.add(const Duration(milliseconds: 2600));
      engine.updateLocation(locArrival, now: t2);

      expect(engine.state.navigationStatus, equals(TourNavigationStatus.viewpointAudioPlaying));
      expect(spokenInstructions, contains('You have arrived at Viewpoint 100.'));
      expect(autoPlayedIds, contains('vp_100'));
      expect(engine.state.armedAutoPlayViewpointId, isNull); // Disarmed!
    });

    test('9. Auto-play triggers once and does NOT duplicate on boundary location fluctuations', () {
      engine.startTour(
        floorId: 'floor_underground',
        viewpoints: testViewpoints,
      );

      final t0 = DateTime.now();
      final locAt100 = UserLocationModel(
        floorId: 'floor_underground',
        normalizedX: 0.80,
        normalizedY: 0.50,
        accuracyMeters: 1.0,
        timestamp: t0,
      );

      engine.updateLocation(locAt100, now: t0);
      engine.updateLocation(locAt100, now: t0.add(const Duration(milliseconds: 2600)));
      expect(autoPlayedIds.length, equals(1));

      // Fluctuates slightly
      final locFluctuate = UserLocationModel(
        floorId: 'floor_underground',
        normalizedX: 0.83,
        normalizedY: 0.50,
        accuracyMeters: 1.0,
        timestamp: t0.add(const Duration(seconds: 4)),
      );
      engine.updateLocation(locFluctuate, now: t0.add(const Duration(seconds: 4)));
      engine.updateLocation(locAt100, now: t0.add(const Duration(seconds: 8)));

      // Auto-play was not called a second time
      expect(autoPlayedIds.length, equals(1));
    });

    test('10. Marking stop 100 visited advances target to 101, but does not arm 101 until departure (>= 7m)', () {
      engine.startTour(
        floorId: 'floor_underground',
        viewpoints: testViewpoints,
      );

      final t0 = DateTime.now();
      final locAt100 = UserLocationModel(
        floorId: 'floor_underground',
        normalizedX: 0.80,
        normalizedY: 0.50,
        accuracyMeters: 1.0,
        timestamp: t0,
      );
      engine.updateLocation(locAt100, now: t0);
      engine.updateLocation(locAt100, now: t0.add(const Duration(milliseconds: 2600)));

      // User marks 100 as visited and narration finishes
      engine.markVisited('vp_100');
      engine.onAudioCompleted();

      expect(engine.state.visitedIds, contains('vp_100'));
      expect(engine.state.navigationTargetId, equals('vp_101'));
      expect(engine.state.armedAutoPlayViewpointId, isNull); // NOT armed yet!
      expect(engine.state.navigationStatus, equals(TourNavigationStatus.waitingForDeparture));

      spokenInstructions.clear();

      // User is still standing 3m from 100 -> departure condition not met
      final locStillNear100 = UserLocationModel(
        floorId: 'floor_underground',
        normalizedX: 0.83,
        normalizedY: 0.50,
        accuracyMeters: 1.0,
        timestamp: t0.add(const Duration(seconds: 10)),
      );
      engine.updateLocation(locStillNear100, now: t0.add(const Duration(seconds: 10)));
      expect(engine.state.armedAutoPlayViewpointId, isNull);

      // User physically walks >= 7m away from 100 toward 101: (0.88, 0.47) -> dist from 100 is sqrt((0.08*86)^2 + (0.03*54)^2) = 7.07m, dist to 101 is 4.86m (>4m)
      final locDeparted = UserLocationModel(
        floorId: 'floor_underground',
        normalizedX: 0.88,
        normalizedY: 0.47,
        accuracyMeters: 1.0,
        timestamp: t0.add(const Duration(seconds: 15)),
      );
      engine.updateLocation(locDeparted, now: t0.add(const Duration(seconds: 15)));

      expect(engine.state.armedAutoPlayViewpointId, equals('vp_101'));
      expect(engine.state.navigationStatus, equals(TourNavigationStatus.approaching));
      expect(spokenInstructions, contains('Next, proceed toward Viewpoint 101.'));
    });

    test('11. User manual pause (pausedByUser) prevents proximity override', () {
      engine.startTour(
        floorId: 'floor_underground',
        viewpoints: testViewpoints,
      );

      engine.onUserPauseAudio();
      expect(engine.state.pausedByUser, isTrue);

      // Location update near target does not reset pausedByUser
      final loc = UserLocationModel(
        floorId: 'floor_underground',
        normalizedX: 0.80,
        normalizedY: 0.50,
        accuracyMeters: 1.0,
      );
      engine.updateLocation(loc);
      expect(engine.state.pausedByUser, isTrue);
    });

    test('12. User explicitly closing audio sets isExplicitlyClosed and prevents reopening', () {
      engine.startTour(
        floorId: 'floor_underground',
        viewpoints: testViewpoints,
      );

      engine.onUserStopOrCloseAudio();
      expect(engine.state.isExplicitlyClosed, isTrue);
      expect(engine.state.activeAudioViewpointId, isNull);
    });

    test('13. User manual selection of Viewpoint 102 does NOT modify navigationTargetId 100', () {
      engine.startTour(
        floorId: 'floor_underground',
        viewpoints: testViewpoints,
      );

      engine.selectViewpoint('vp_102');
      expect(engine.state.selectedViewpointId, equals('vp_102'));
      expect(engine.state.navigationTargetId, equals('vp_100')); // Unchanged!
    });

    test('14. Skipping a viewpoint advances navigation to the next available stop', () {
      engine.startTour(
        floorId: 'floor_underground',
        viewpoints: testViewpoints,
      );

      engine.skipViewpoint('vp_100');
      expect(engine.state.skippedIds, contains('vp_100'));
      expect(engine.state.navigationTargetId, equals('vp_101'));
    });

    test('15. Completing all stops guides user to EXIT portal', () {
      engine.startTour(
        floorId: 'floor_underground',
        viewpoints: testViewpoints,
        exitLocation: const Offset(0.10, 0.50),
      );

      engine.markVisited('vp_100');
      engine.markVisited('vp_101');
      engine.markVisited('vp_102');

      expect(engine.state.navigationTargetId, equals('EXIT'));
      spokenInstructions.clear();

      final t0 = DateTime.now();
      // Arriving at Exit (0.10, 0.50)
      final locExit = UserLocationModel(
        floorId: 'floor_underground',
        normalizedX: 0.10,
        normalizedY: 0.50,
        accuracyMeters: 1.0,
        timestamp: t0,
      );
      engine.updateLocation(locExit, now: t0);
      engine.updateLocation(locExit, now: t0.add(const Duration(milliseconds: 2600)));

      expect(engine.state.navigationStatus, equals(TourNavigationStatus.itineraryComplete));
      expect(spokenInstructions, contains('You have completed the Underground itinerary. The exit is here.'));
    });

    test('16. Two overlapping viewpoints: only armed target 100 triggers, not 101', () {
      engine.startTour(
        floorId: 'floor_underground',
        viewpoints: testViewpoints,
      );

      final t0 = DateTime.now();
      // User is at (0.84, 0.44), which is within 8m of both 100 and 101
      final locOverlap = UserLocationModel(
        floorId: 'floor_underground',
        normalizedX: 0.84,
        normalizedY: 0.44,
        accuracyMeters: 1.0,
        timestamp: t0,
      );

      engine.updateLocation(locOverlap, now: t0);
      expect(engine.state.navigationTargetId, equals('vp_100'));
      expect(engine.state.armedAutoPlayViewpointId, equals('vp_100'));
      expect(autoPlayedIds, isEmpty);
    });

    test('17. User manually marking 100 visited before arrival advances target to 101 without playing 100', () {
      engine.startTour(
        floorId: 'floor_underground',
        viewpoints: testViewpoints,
      );

      engine.markVisited('vp_100');
      expect(engine.state.visitedIds, contains('vp_100'));
      expect(engine.state.navigationTargetId, equals('vp_101'));
      expect(autoPlayedIds, isEmpty);
    });

    test('18. Re-entering already visited 100 is silent and does not auto-play', () {
      engine.startTour(
        floorId: 'floor_underground',
        viewpoints: testViewpoints,
      );

      final t0 = DateTime.now();
      final locAt100 = UserLocationModel(
        floorId: 'floor_underground',
        normalizedX: 0.80,
        normalizedY: 0.50,
        accuracyMeters: 1.0,
        timestamp: t0,
      );

      engine.updateLocation(locAt100, now: t0);
      engine.updateLocation(locAt100, now: t0.add(const Duration(milliseconds: 2600)));
      engine.markVisited('vp_100');
      engine.onAudioCompleted();

      autoPlayedIds.clear();

      // Return to 100
      engine.updateLocation(locAt100, now: t0.add(const Duration(seconds: 20)));
      engine.updateLocation(locAt100, now: t0.add(const Duration(seconds: 24)));

      expect(autoPlayedIds, isEmpty);
    });

    test('19. Audio focus interruption pauses and restores only when not paused by user', () {
      engine.startTour(
        floorId: 'floor_underground',
        viewpoints: testViewpoints,
      );

      // System interrupts (e.g. phone call)
      engine.onSystemAudioInterrupted();
      expect(engine.state.pausedBySystem, isTrue);

      // System restores
      engine.onSystemAudioRestored();
      expect(engine.state.pausedBySystem, isFalse);

      // But if user paused manually:
      engine.onUserPauseAudio();
      engine.onSystemAudioInterrupted();
      engine.onSystemAudioRestored();
      // Still paused because user initiated pause
      expect(engine.state.pausedByUser, isTrue);
    });

    test('20. Voice guidance setting toggles spoken directions independently', () {
      engine.startTour(
        floorId: 'floor_underground',
        viewpoints: testViewpoints,
      );
      spokenInstructions.clear();

      engine.toggleVoiceGuidance(false);
      expect(engine.state.isVoiceGuidanceEnabled, isFalse);

      final locApproach = UserLocationModel(
        floorId: 'floor_underground',
        normalizedX: 0.87,
        normalizedY: 0.50,
        accuracyMeters: 2.0,
      );
      engine.updateLocation(locApproach);
      expect(spokenInstructions, isEmpty); // Suppressed!
    });

    test('21. Auto-play setting toggles viewpoint narration start independently', () {
      engine.startTour(
        floorId: 'floor_underground',
        viewpoints: testViewpoints,
      );
      engine.toggleAutoPlay(false);
      expect(engine.state.isAutoPlayEnabled, isFalse);

      final t0 = DateTime.now();
      final locArrival = UserLocationModel(
        floorId: 'floor_underground',
        normalizedX: 0.80,
        normalizedY: 0.50,
        accuracyMeters: 1.0,
        timestamp: t0,
      );

      engine.updateLocation(locArrival, now: t0);
      engine.updateLocation(locArrival, now: t0.add(const Duration(milliseconds: 2600)));

      expect(engine.state.navigationStatus, equals(TourNavigationStatus.waitingAtViewpoint));
      expect(autoPlayedIds, isEmpty); // Not auto-played!
    });

    test('22. resetTour restores initial tour state and makes vp_100 eligible again', () {
      engine.startTour(
        floorId: 'floor_underground',
        viewpoints: testViewpoints,
      );

      engine.markVisited('vp_100');
      engine.markVisited('vp_101');
      expect(engine.state.visitedIds.length, equals(2));

      engine.resetTour();
      expect(engine.state.visitedIds, isEmpty);
      expect(engine.state.navigationTargetId, equals('vp_100'));
      expect(engine.state.armedAutoPlayViewpointId, equals('vp_100'));
    });

    test('23. unmarkVisited removes stop from visitedIds, updates target, and allows re-visiting', () {
      engine.startTour(
        floorId: 'floor_underground',
        viewpoints: testViewpoints,
      );

      engine.markVisited('vp_100');
      expect(engine.state.visitedIds, contains('vp_100'));
      expect(engine.state.navigationTargetId, equals('vp_101'));

      // User unmarks vp_100 (e.g. undo)
      engine.unmarkVisited('vp_100');
      expect(engine.state.visitedIds, isNot(contains('vp_100')));
      expect(engine.state.navigationTargetId, equals('vp_100'));
      expect(engine.state.armedAutoPlayViewpointId, equals('vp_100'));
      expect(engine.state.navigationStatus, equals(TourNavigationStatus.navigating));
    });
  });
}
