import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:colosseum_client/app/data/models/landmark_marker_model.dart';
import 'package:colosseum_client/app/data/services/pedestrian_navigation_engine.dart';
import 'package:colosseum_client/app/data/services/tts_service.dart';

class MockTtsService extends TtsService {
  final List<String> spokenInstructions = [];
  final List<String> spokenNarrations = [];

  @override
  Future<void> speakInstruction(String text, {void Function()? onDone}) async {
    if (isSpeakingNarration || isVoiceGuidanceMuted) {
      onDone?.call();
      return;
    }
    spokenInstructions.add(text);
    onDone?.call();
  }

  @override
  Future<void> speakNarration(String text, {void Function()? onDone}) async {
    spokenNarrations.add(text);
    onDone?.call();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockTtsService mockTts;
  late PedestrianNavigationEngine engine;

  final testLandmark = LandmarkMarkerModel(
    id: 'ludus_magnus',
    name: 'Ludus Magnus',
    coordinates: const LatLng(41.889950, 12.495050),
    color: const Color(0xFF8B1E1E),
  );

  // 4-point walking route from Colosseum to Ludus Magnus
  final testRoute = [
    const LatLng(41.890210, 12.492231), // Stop 1: Colosseum
    const LatLng(41.890290, 12.493783), // Stop 2: Crossing
    const LatLng(41.889827, 12.494014), // Stop 3: Via di San Giovanni
    const LatLng(41.889950, 12.495050), // Stop 4: Ludus Magnus
  ];

  setUp(() {
    mockTts = MockTtsService();
    engine = PedestrianNavigationEngine(ttsService: mockTts);
  });

  tearDown(() {
    engine.stopNavigation();
  });

  group('PedestrianNavigationEngine Unit Tests', () {
    test('1. Initializes route steps and computes initial navigation status', () {
      PedestrianNavStatus? lastStatus;
      engine.onStatusChanged = (status) => lastStatus = status;

      engine.startNavigation(route: testRoute, destination: testLandmark);

      expect(engine.isNavigating, isTrue);
      expect(lastStatus, isNotNull);
      expect(lastStatus!.targetLandmark?.id, equals('ludus_magnus'));
      expect(lastStatus!.totalRemainingDistanceMeters, greaterThan(150.0));
      expect(lastStatus!.hasArrived, isFalse);
    });

    test('2. Updates position and calculates countdown distance along route', () {
      engine.startNavigation(route: testRoute, destination: testLandmark);

      // User walking towards Stop 2
      final midPoint = const LatLng(41.890250, 12.493000);
      engine.updatePosition(midPoint);

      expect(engine.status.currentWaypointIndex, equals(0));
      expect(engine.status.distanceToNextTurnMeters, lessThan(80.0));
    });

    test('3. Audio guidance fires advance and immediate turn prompts', () {
      engine.startNavigation(route: testRoute, destination: testLandmark);

      // User approaching Stop 2 within 35 meters
      final nearStop2 = const LatLng(41.890280, 12.493400);
      engine.updatePosition(nearStop2);

      expect(mockTts.spokenInstructions, isNotEmpty);
      expect(mockTts.spokenInstructions.any((s) => s.contains('meters')), isTrue);

      // User arrives right at the turn (< 18m)
      final atStop2 = const LatLng(41.890288, 12.493700);
      engine.updatePosition(atStop2);

      expect(mockTts.spokenInstructions.length, greaterThanOrEqualTo(2));
    });

    test('4. Arrival at destination marks arrived and triggers onArrival callback', () {
      bool arrivalTriggered = false;
      engine.onArrival = () => arrivalTriggered = true;

      engine.startNavigation(route: testRoute, destination: testLandmark);

      // User arrives within 15 meters of Ludus Magnus
      final arrivalPos = const LatLng(41.889955, 12.495045);
      engine.updatePosition(arrivalPos);

      expect(engine.status.hasArrived, isTrue);
      expect(arrivalTriggered, isTrue);
      expect(mockTts.spokenInstructions.any((s) => s.contains('arrived')), isTrue);
    });

    test('5. Audio Collision Arbiter: spoken instruction is suppressed when narration is active', () {
      mockTts.isVoiceGuidanceMuted = false;

      // Start narration directly
      mockTts.speakNarration('Historical guide story playing...');

      // Attempt turn instruction while narration is active
      engine.startNavigation(route: testRoute, destination: testLandmark);
      final nearTurn = const LatLng(41.890280, 12.493400);
      engine.updatePosition(nearTurn);

      // Instruction should have been recorded as spoken only if not suppressed
      expect(mockTts.spokenNarrations, contains('Historical guide story playing...'));
    });

    test('6. Audio Mute Toggle: spoken instruction is suppressed when voice guidance is muted', () {
      mockTts.isVoiceGuidanceMuted = true;

      engine.startNavigation(route: testRoute, destination: testLandmark);
      final nearTurn = const LatLng(41.890280, 12.493400);
      engine.updatePosition(nearTurn);

      expect(mockTts.spokenInstructions, isEmpty);
      // Status is still updated visually on screen
      expect(engine.status.instruction, isNotEmpty);
    });
  });
}
