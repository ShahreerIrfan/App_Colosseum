import 'dart:math' as math;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:colosseum_client/app/core/utils/contain_circle_camera_constraint.dart';

void main() {
  group('ContainCircleCameraConstraint Tests', () {
    const colosseum = LatLng(41.890210, 12.492231);
    const radiusMeters = 600.0;
    const constraint = ContainCircleCameraConstraint(
      circleCenter: colosseum,
      circleRadiusMeters: radiusMeters,
      padding: 12.0,
    );

    MapCamera createCamera({
      required LatLng center,
      required double zoom,
      math.Point<double> size = const math.Point(400.0, 800.0),
    }) {
      return MapCamera(
        crs: const Epsg3857(),
        minZoom: 10.0,
        maxZoom: 20.0,
        center: center,
        zoom: zoom,
        rotation: 0.0,
        nonRotatedSize: size,
      );
    }

    test('Leaves camera unchanged when center is already at circle center', () {
      final camera = createCamera(center: colosseum, zoom: 16.5);
      final constrained = constraint.constrain(camera);

      expect(constrained.center.latitude, closeTo(colosseum.latitude, 0.00001));
      expect(constrained.center.longitude, closeTo(colosseum.longitude, 0.00001));
    });

    test('Prevents camera from panning far north away from circle', () {
      // 5km North of Colosseum
      const farNorth = LatLng(41.935000, 12.492231);
      final camera = createCamera(center: farNorth, zoom: 14.0);
      final constrained = constraint.constrain(camera);

      // Camera center must be clamped closer to Colosseum
      expect(constrained.center.latitude, lessThan(farNorth.latitude));

      // In the resulting constrained camera, the circle center MUST be on screen!
      final circlePix = constrained.project(colosseum);
      final cameraPix = constrained.project(constrained.center);
      final screenX = 400.0 / 2 + (circlePix.x - cameraPix.x);
      final screenY = 800.0 / 2 + (circlePix.y - cameraPix.y);

      expect(screenX, greaterThanOrEqualTo(0.0));
      expect(screenX, lessThanOrEqualTo(400.0));
      expect(screenY, greaterThanOrEqualTo(0.0));
      expect(screenY, lessThanOrEqualTo(800.0));
    });

    test('Prevents camera from panning far south away from circle', () {
      // 5km South of Colosseum
      const farSouth = LatLng(41.845000, 12.492231);
      final camera = createCamera(center: farSouth, zoom: 14.0);
      final constrained = constraint.constrain(camera);

      expect(constrained.center.latitude, greaterThan(farSouth.latitude));

      final circlePix = constrained.project(colosseum);
      final cameraPix = constrained.project(constrained.center);
      final screenX = 400.0 / 2 + (circlePix.x - cameraPix.x);
      final screenY = 800.0 / 2 + (circlePix.y - cameraPix.y);

      expect(screenX, inInclusiveRange(0.0, 400.0));
      expect(screenY, inInclusiveRange(0.0, 800.0));
    });

    test('Prevents camera from panning far east or west away from circle', () {
      // 5km East of Colosseum
      const farEast = LatLng(41.890210, 12.550000);
      final cameraEast = createCamera(center: farEast, zoom: 14.0);
      final constrainedEast = constraint.constrain(cameraEast);

      expect(constrainedEast.center.longitude, lessThan(farEast.longitude));

      // 5km West of Colosseum
      const farWest = LatLng(41.890210, 12.430000);
      final cameraWest = createCamera(center: farWest, zoom: 14.0);
      final constrainedWest = constraint.constrain(cameraWest);

      expect(constrainedWest.center.longitude, greaterThan(farWest.longitude));
    });
  });
}
