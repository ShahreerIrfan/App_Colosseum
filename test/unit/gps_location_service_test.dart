import 'package:flutter_test/flutter_test.dart';
import 'package:colosseum_client/app/data/services/gps_location_service.dart';

void main() {
  group('GpsLocationService & Projection Math Unit Tests', () {
    late GpsLocationService gpsService;

    setUp(() {
      gpsService = GpsLocationService(positionSmoothingAlpha: 1.0); // Raw 1:1 for deterministic unit test
    });

    tearDown(() {
      gpsService.dispose();
    });

    test('1. calculateDistanceToCenter accurately measures metric distance to Colosseum center', () {
      // Exactly at center
      final distCenter = GpsLocationService.calculateDistanceToCenter(
        GpsLocationService.colosseumCenterLat,
        GpsLocationService.colosseumCenterLng,
      );
      expect(distCenter, closeTo(0.0, 0.001));

      // At Viewpoint 100 (inside arena east side)
      final dist100 = GpsLocationService.calculateDistanceToCenter(41.890250, 12.492820);
      expect(dist100, lessThan(GpsLocationService.geofenceRadiusMeters));
      expect(dist100, closeTo(49.0, 5.0));

      // Far away in Dhaka, Bangladesh
      final distDhaka = GpsLocationService.calculateDistanceToCenter(23.8103, 90.4125);
      expect(distDhaka, greaterThan(100000.0));
    });

    test('2. isWithinColosseum accurately validates 120m geofence boundary', () {
      // Inside Colosseum
      expect(GpsLocationService.isWithinColosseum(41.890210, 12.492231), isTrue); // Center
      expect(GpsLocationService.isWithinColosseum(41.890250, 12.492820), isTrue); // Stop 100
      expect(GpsLocationService.isWithinColosseum(41.890450, 12.492580), isTrue); // Stop 102

      // Outside Colosseum (> 120m)
      expect(GpsLocationService.isWithinColosseum(41.893000, 12.495000), isFalse); // Nearby Roman street ~380m
      expect(GpsLocationService.isWithinColosseum(23.8103, 90.4125), isFalse); // Dhaka
    });

    test('3. projectGpsToCanvas maps center and viewpoints onto normalized [0.0, 1.0] floor canvas', () {
      // 1. Center maps to (0.50, 0.50)
      final centerCanvas = GpsLocationService.projectGpsToCanvas(
        GpsLocationService.colosseumCenterLat,
        GpsLocationService.colosseumCenterLng,
      );
      expect(centerCanvas.dx, closeTo(0.50, 0.01));
      expect(centerCanvas.dy, closeTo(0.50, 0.01));

      // 2. Stop 100 (East side of underground arena)
      final vp100Canvas = GpsLocationService.projectGpsToCanvas(41.890250, 12.492820);
      expect(vp100Canvas.dx, greaterThan(0.70));
      expect(vp100Canvas.dy, inInclusiveRange(0.20, 0.80));

      // 3. Out-of-bounds coordinates clamp smoothly within [0.02, 0.98]
      final clampedFar = GpsLocationService.projectGpsToCanvas(23.8103, 90.4125);
      expect(clampedFar.dx, inInclusiveRange(0.02, 0.98));
      expect(clampedFar.dy, inInclusiveRange(0.02, 0.98));
    });

    test('4. setMockPosition updates isInLocation and emits location model for in-bounds coordinates', () async {
      final results = <GpsLocationResult>[];
      final sub = gpsService.locationStream.listen(results.add);

      // 1. Set position at Stop 100 (In-bounds)
      gpsService.setMockPosition(latitude: 41.890250, longitude: 12.492820, accuracy: 1.5);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(gpsService.currentResult.isInLocation, isTrue);
      expect(gpsService.currentResult.userLocation, isNotNull);
      expect(gpsService.currentResult.userLocation!.accuracyMeters, equals(1.5));
      expect(results.length, equals(1));

      // 2. Set position outside Colosseum (Dhaka, Bangladesh)
      gpsService.setMockPosition(latitude: 23.8103, longitude: 90.4125, accuracy: 2.0);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(gpsService.currentResult.isInLocation, isFalse);
      expect(gpsService.currentResult.userLocation, isNull);
      expect(results.length, equals(2));

      await sub.cancel();
    });

    test('5. Discards noisy GPS fixes with accuracy > 15m', () async {
      final results = <GpsLocationResult>[];
      final sub = gpsService.locationStream.listen(results.add);

      // Inaccurate fix (accuracy = 35m)
      gpsService.setMockPosition(latitude: 41.890250, longitude: 12.492820, accuracy: 35.0);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(results, isEmpty); // Discarded!

      await sub.cancel();
    });
  });
}
