import 'package:flutter_test/flutter_test.dart';
import 'package:colosseum_client/app/data/models/floor_definition.dart';
import 'package:colosseum_client/app/data/models/floor_transition_portal.dart';
import 'package:colosseum_client/app/data/services/floor_detection_engine.dart';

void main() {
  group('FloorDetectionEngine Tests', () {
    late FloorDefinition level1;
    late FloorDefinition level2;
    late FloorDetectionEngine engine;

    setUp(() {
      level1 = const FloorDefinition(
        id: 'floor_1',
        displayName: 'Level 1 - Arena Floor',
        shortName: 'Level 1',
        floorNumberLabel: '1',
        viewpoints: [],
        itinerary: [],
        mapAsset: 'assets/maps/level1.png',
        semanticLabel: 'Level 1',
        elevationMeters: 0.0,
        portals: [
          FloorTransitionPortal(
            id: 'stairs_1_to_2',
            name: 'Stairs to Level 2',
            fromFloorId: 'floor_1',
            toFloorId: 'floor_2',
            normalizedX: 0.50,
            normalizedY: 0.50,
            elevationDeltaMeters: 6.0,
            isAscending: true,
            triggerRadiusMeters: 8.0,
          ),
        ],
      );

      level2 = const FloorDefinition(
        id: 'floor_2',
        displayName: 'Level 2 - Colonnade',
        shortName: 'Level 2',
        floorNumberLabel: '2',
        viewpoints: [],
        itinerary: [],
        mapAsset: 'assets/maps/level2.png',
        semanticLabel: 'Level 2',
        elevationMeters: 6.0,
        portals: [
          FloorTransitionPortal(
            id: 'stairs_2_to_1',
            name: 'Stairs down to Level 1',
            fromFloorId: 'floor_2',
            toFloorId: 'floor_1',
            normalizedX: 0.50,
            normalizedY: 0.50,
            elevationDeltaMeters: -6.0,
            isAscending: false,
            triggerRadiusMeters: 8.0,
          ),
        ],
      );

      engine = FloorDetectionEngine(
        availableFloors: [level1, level2],
        currentFloorId: 'floor_1',
        isEnabled: true,
      );
    });

    test('Initializes with active floor and enabled state', () {
      expect(engine.currentFloorId, 'floor_1');
      expect(engine.isEnabled, isTrue);
    });

    test('Does not trigger transition when position is far from portal', () {
      FloorTransitionCandidate? candidate;
      engine.onFloorTransitionDetected = (c) => candidate = c;

      // Far away at (0.1, 0.1)
      for (int i = 0; i < 5; i++) {
        engine.updateLocation(canvasOffset: const Offset(0.1, 0.1));
      }

      expect(candidate, isNull);
    });

    test('Accumulates dwell score and triggers floor transition candidate near portal', () {
      FloorTransitionCandidate? candidate;
      engine.onFloorTransitionDetected = (c) => candidate = c;

      // Portal is at (0.50, 0.50). Update nearby multiple times to accumulate dwell.
      for (int i = 0; i < 4; i++) {
        engine.updateLocation(canvasOffset: const Offset(0.505, 0.50));
      }

      expect(candidate, isNotNull);
      expect(candidate!.targetFloor.id, 'floor_2');
      expect(candidate!.targetFloor.displayName, 'Level 2 - Colonnade');
      expect(candidate!.confidenceScore, greaterThanOrEqualTo(0.85));
    });

    test('IMU stair motion boosts confidence triggering faster transition', () {
      FloorTransitionCandidate? candidate;
      engine.onFloorTransitionDetected = (c) => candidate = c;

      // Feed vertical movement from IMU
      engine.recordStairMotion(isClimbingUp: true, isClimbingDown: false);

      // Near portal, should reach 0.85 confidence in 3 updates
      for (int i = 0; i < 3; i++) {
        engine.updateLocation(canvasOffset: const Offset(0.50, 0.50));
      }

      expect(candidate, isNotNull);
      expect(candidate!.targetFloor.id, 'floor_2');
    });

    test('Triggering cooldown prevents immediate bounce between floors', () {
      FloorTransitionCandidate? candidate;
      engine.onFloorTransitionDetected = (c) => candidate = c;

      // Trigger transition
      for (int i = 0; i < 4; i++) {
        engine.updateLocation(canvasOffset: const Offset(0.50, 0.50));
      }
      expect(candidate, isNotNull);

      // Reset candidate and try immediate re-trigger
      candidate = null;
      for (int i = 0; i < 4; i++) {
        engine.updateLocation(canvasOffset: const Offset(0.50, 0.50));
      }
      // Should NOT re-trigger because pair cooldown is active
      expect(candidate, isNull);
    });

    test('User Undo applies strict cooldown and prevents re-triggering', () {
      FloorTransitionCandidate? candidate;
      engine.onFloorTransitionDetected = (c) => candidate = c;

      // User undoes a transition from floor_1 to floor_2
      engine.armCooldown('floor_1', 'floor_2', duration: const Duration(seconds: 90));

      // Now moving at the portal should be blocked by cooldown
      for (int i = 0; i < 10; i++) {
        engine.updateLocation(canvasOffset: const Offset(0.50, 0.50));
      }
      expect(candidate, isNull);
    });

    test('Barometer pressure drop contributes to ascent confidence', () {
      FloorTransitionCandidate? candidate;
      engine.onFloorTransitionDetected = (c) => candidate = c;

      // Baseline at level 1: 1013.25 hPa
      engine.recordBarometricPressure(1013.25);

      // User climbs up 6 meters (around 0.72 hPa drop at sea level)
      engine.recordBarometricPressure(1012.45);

      // Update location near portal
      for (int i = 0; i < 3; i++) {
        engine.updateLocation(canvasOffset: const Offset(0.50, 0.50));
      }

      expect(candidate, isNotNull);
      expect(candidate!.targetFloor.id, 'floor_2');
    });
  });
}
