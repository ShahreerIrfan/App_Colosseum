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

    test('4. projectPlaygroundToCanvas maps local ground displacement relative to ENTRY gate', () {
      const originLat = 23.810300;
      const originLng = 90.412500;

      // 1. At local origin (0m displacement) -> maps exactly to ENTRY (0.92, 0.50)
      final originCanvas = GpsLocationService.projectPlaygroundToCanvas(
        currentLat: originLat,
        currentLng: originLng,
        originLat: originLat,
        originLng: originLng,
      );
      expect(originCanvas.dx, closeTo(0.92, 0.001));
      expect(originCanvas.dy, closeTo(0.50, 0.001));

      // 2. Walking West in local field (Lng decreases by ~10.3 meters: 10.3 / (111139 * cos(23.8°)))
      const metersPerLng = 111139.0 * 0.91496;
      final movedWestLng = originLng - (10.3 / metersPerLng);

      final westCanvas = GpsLocationService.projectPlaygroundToCanvas(
        currentLat: originLat,
        currentLng: movedWestLng,
        originLat: originLat,
        originLng: originLng,
      );
      // Moves westward from Entry (0.92) toward Stop 100 (~0.82)
      expect(westCanvas.dx, lessThan(0.92));
      expect(westCanvas.dx, closeTo(0.82, 0.05));
    });

    test('5. Local Playground Field-Test mode allows tracking anywhere in the world', () async {
      final results = <GpsLocationResult>[];
      final sub = gpsService.locationStream.listen(results.add);

      // Enable Playground Field Test Mode
      gpsService.setTrackingMode(GpsTrackingMode.localPlayground);
      expect(gpsService.isPlaygroundMode, isTrue);

      // First GPS fix in Dhaka, Bangladesh (becomes origin at Entry)
      gpsService.setMockPosition(latitude: 23.810300, longitude: 90.412500, accuracy: 2.0);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(gpsService.currentResult.isInLocation, isTrue);
      expect(gpsService.currentResult.userLocation, isNotNull);
      expect(gpsService.currentResult.userLocation!.normalizedX, closeTo(0.92, 0.01));
      expect(gpsService.currentResult.isPlaygroundMode, isTrue);

      // Walk 15 meters West in the local field
      const metersPerLng = 111139.0 * 0.91496;
      final nextLng = 90.412500 - (15.0 / metersPerLng);
      gpsService.setMockPosition(latitude: 23.810300, longitude: nextLng, accuracy: 2.0);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(gpsService.currentResult.userLocation!.normalizedX, lessThan(0.92));
      expect(results.length, equals(2));

      await sub.cancel();
    });

    test('6. setMockPosition updates isInLocation and emits location model for in-bounds coordinates', () async {
      final results = <GpsLocationResult>[];
      final sub = gpsService.locationStream.listen(results.add);

      // 1. Set position at Stop 100 (In-bounds)
      gpsService.setMockPosition(latitude: 41.890250, longitude: 12.492820, accuracy: 1.5);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(gpsService.currentResult.isInLocation, isTrue);
      expect(gpsService.currentResult.userLocation, isNotNull);
      expect(gpsService.currentResult.userLocation!.accuracyMeters, equals(1.5));
      expect(results.length, equals(1));

      // 2. Set position outside Colosseum (Dhaka, Bangladesh) in Geofence mode
      gpsService.setMockPosition(latitude: 23.8103, longitude: 90.4125, accuracy: 2.0);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(gpsService.currentResult.isInLocation, isFalse);
      expect(gpsService.currentResult.userLocation, isNull);
      expect(results.length, equals(2));

      await sub.cancel();
    });

    test('7. Dynamic accuracy filter allows moderate fixes (<= 30m) and discards severe outliers (> 30m)', () async {
      final results = <GpsLocationResult>[];
      final sub = gpsService.locationStream.listen(results.add);

      // Moderate accuracy fix (20m) -> allowed
      gpsService.setMockPosition(latitude: 41.890250, longitude: 12.492820, accuracy: 20.0);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(results.length, equals(1));

      // Severe outlier (accuracy = 35m) -> discarded
      gpsService.setMockPosition(latitude: 41.890250, longitude: 12.492820, accuracy: 35.0);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(results.length, equals(1)); // Remained 1!

      await sub.cancel();
    });

    test('8. pauseDisplacement freezes canvas position and resumeDisplacement re-anchors to new physical spot', () async {
      gpsService.setTrackingMode(GpsTrackingMode.localPlayground);

      // 1. Initial fix at origin (maps to Entry 0.92, 0.50)
      gpsService.setMockPosition(latitude: 23.810300, longitude: 90.412500, accuracy: 2.0);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(gpsService.currentResult.userLocation!.normalizedX, closeTo(0.92, 0.01));

      // 2. Pause walking displacement (e.g. user reached a road dead-end)
      gpsService.pauseDisplacement();
      expect(gpsService.isDisplacementPaused, isTrue);
      expect(gpsService.currentResult.isDisplacementPaused, isTrue);
      final frozenX = gpsService.currentResult.userLocation!.normalizedX;

      // 3. User physically walks back 30 meters on road while paused -> puck must NOT move!
      const metersPerLng = 111139.0 * 0.91496;
      final relocatedLng = 90.412500 + (30.0 / metersPerLng);
      gpsService.setMockPosition(latitude: 23.810300, longitude: relocatedLng, accuracy: 2.0);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(gpsService.currentResult.userLocation!.normalizedX, equals(frozenX));

      // 4. User hits Resume at new physical spot -> displacement unfreezes smoothly from frozenX
      gpsService.resumeDisplacement();
      expect(gpsService.isDisplacementPaused, isFalse);

      // First fix after resume re-anchors origin to relocatedLng
      gpsService.setMockPosition(latitude: 23.810300, longitude: relocatedLng, accuracy: 2.0);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(gpsService.currentResult.userLocation!.normalizedX, closeTo(frozenX, 0.01));

      // Walking westward from new relocated origin moves forward on canvas
      final nextStepLng = relocatedLng - (10.0 / metersPerLng);
      gpsService.setMockPosition(latitude: 23.810300, longitude: nextStepLng, accuracy: 2.0);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(gpsService.currentResult.userLocation!.normalizedX, lessThan(frozenX));
    });

    test('9. snapToCanvasOffset sets anchor directly to viewpoint and emits immediate update', () {
      gpsService.setTrackingMode(GpsTrackingMode.localPlayground);

      const vp100Offset = Offset(0.80, 0.50);
      gpsService.snapToCanvasOffset(vp100Offset);

      expect(gpsService.currentResult.isInLocation, isTrue);
      expect(gpsService.currentResult.userLocation!.normalizedX, equals(0.80));
      expect(gpsService.currentResult.userLocation!.normalizedY, equals(0.50));
      expect(gpsService.playgroundAnchorCanvas, equals(vp100Offset));
    });
  });
}
