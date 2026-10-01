import 'dart:async';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colosseum_client/app/data/models/user_orientation_state.dart';
import 'package:colosseum_client/app/data/services/compass_service.dart';

void main() {
  group('CompassService & Angular Math Unit Tests', () {
    late CompassService compassService;

    setUp(() {
      compassService = CompassService(smoothingAlpha: 0.5);
    });

    tearDown(() {
      compassService.dispose();
    });

    test('1. Shortest angle delta calculates correct direct rotation in [-180, 180]', () {
      // 10° to 30° -> +20°
      expect(CompassService.shortestAngleDelta(10.0, 30.0), closeTo(20.0, 0.001));

      // 30° to 10° -> -20°
      expect(CompassService.shortestAngleDelta(30.0, 10.0), closeTo(-20.0, 0.001));

      // 358° to 2° -> +4° (Shortest path across 0° North, NOT -356°)
      expect(CompassService.shortestAngleDelta(358.0, 2.0), closeTo(4.0, 0.001));

      // 2° to 358° -> -4°
      expect(CompassService.shortestAngleDelta(2.0, 358.0), closeTo(-4.0, 0.001));

      // 350° to 10° -> +20°
      expect(CompassService.shortestAngleDelta(350.0, 10.0), closeTo(20.0, 0.001));

      // 90° East to 270° West -> 180°
      expect(CompassService.shortestAngleDelta(90.0, 270.0).abs(), closeTo(180.0, 0.001));
    });

    test('2. smoothHeadingAngle smoothly moves toward target angle without wrapping error', () {
      // Current = 358°, Target = 2°, alpha = 0.5 -> delta = +4° -> next = 358 + 2 = 360 = 0°
      final smoothed = CompassService.smoothHeadingAngle(358.0, 2.0, alpha: 0.5);
      expect(smoothed, closeTo(0.0, 0.001));

      // Moving from 0° toward 90° East with alpha = 0.25 -> 22.5°
      final step1 = CompassService.smoothHeadingAngle(0.0, 90.0, alpha: 0.25);
      expect(step1, closeTo(22.5, 0.001));

      // Negative angles normalize into [0, 360)
      final stepNegative = CompassService.smoothHeadingAngle(10.0, 350.0, alpha: 0.5);
      expect(stepNegative, closeTo(0.0, 0.001));
    });

    test('3. setMockHeading updates currentState and emits to orientationStream', () async {
      final emitted = <UserOrientationState>[];
      final sub = compassService.orientationStream.listen(emitted.add);

      compassService.setMockHeading(90.0, accuracy: 5.0);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(compassService.currentState.headingDegrees, closeTo(90.0, 0.001));
      expect(compassService.currentState.sensorAccuracy, equals(5.0));
      expect(compassService.currentState.isCalibrating, isFalse);
      expect(compassService.currentState.isAvailable, isTrue);
      expect(emitted.length, equals(1));

      // Update to 180° South
      compassService.setMockHeading(180.0);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(compassService.currentState.headingDegrees, closeTo(180.0, 0.001));
      expect(emitted.length, equals(2));

      // Set to null (unavailable / lost)
      compassService.setMockHeading(null);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(compassService.currentState.headingDegrees, isNull);
      expect(emitted.length, equals(3));

      await sub.cancel();
    });

    test('4. Flags isCalibrating true when sensor accuracy is poor (> 30°)', () {
      compassService.setMockHeading(45.0, accuracy: 45.0);
      expect(compassService.currentState.isCalibrating, isTrue);

      compassService.setMockHeading(45.0, accuracy: 8.0);
      expect(compassService.currentState.isCalibrating, isFalse);
    });

    test('5. customStream processes live CompassEvent correctly', () async {
      final controller = StreamController<CompassEvent>.broadcast();
      final service = CompassService(smoothingAlpha: 1.0); // No lag for raw test
      service.startListening(customStream: controller.stream);

      final events = <UserOrientationState>[];
      final sub = service.orientationStream.listen(events.add);

      // Raw event at 270° West
      controller.add(CompassEvent.fromList([270.0, 270.0, 3.0]));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(service.currentState.headingDegrees, closeTo(270.0, 0.001));
      expect(service.currentState.hasValidHeading, isTrue);

      await sub.cancel();
      await controller.close();
      service.dispose();
    });
  });
}
