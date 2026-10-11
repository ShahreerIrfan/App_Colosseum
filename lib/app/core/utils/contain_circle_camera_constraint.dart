import 'dart:math' as math show Point;

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Camera constraint that ensures a circle centered at [circleCenter] with radius [circleRadiusMeters]
/// is ALWAYS kept on screen (inside the viewport) at any zoom level, preventing user scrolling from losing it.
class ContainCircleCameraConstraint extends CameraConstraint {
  final LatLng circleCenter;
  final double circleRadiusMeters;
  final double padding;

  static const _distance = Distance();

  const ContainCircleCameraConstraint({
    required this.circleCenter,
    required this.circleRadiusMeters,
    this.padding = 12.0,
  });

  @override
  MapCamera constrain(MapCamera camera) {
    if (camera.size.x <= 0 || camera.size.y <= 0) {
      return camera;
    }

    final testZoom = camera.zoom;
    final viewWidth = camera.size.x;
    final viewHeight = camera.size.y;

    // Projected circle center in CRS pixels
    final circlePix = camera.project(circleCenter, testZoom);

    // Calculate radius in CRS pixels at current zoom
    final edgePoint = _distance.offset(circleCenter, circleRadiusMeters, 90.0);
    final edgePix = camera.project(edgePoint, testZoom);
    final radiusPix = (edgePix.x - circlePix.x).abs();

    // Allowable range for circle center in screen coordinates:
    // - If circle width (2 * radiusPix) <= viewWidth:
    //     the whole circle must stay within [radiusPix + padding, viewWidth - radiusPix - padding]
    // - If circle width > viewWidth (zoomed in):
    //     the viewport remains within the circle boundary [viewWidth - radiusPix - padding, radiusPix + padding]
    double minScreenX;
    double maxScreenX;
    if (2 * radiusPix <= viewWidth) {
      minScreenX = radiusPix + padding;
      maxScreenX = viewWidth - radiusPix - padding;
      if (minScreenX > maxScreenX) {
        minScreenX = maxScreenX = viewWidth / 2;
      }
    } else {
      minScreenX = viewWidth - radiusPix - padding;
      maxScreenX = radiusPix + padding;
      if (minScreenX > maxScreenX) {
        minScreenX = maxScreenX = viewWidth / 2;
      }
    }

    double minScreenY;
    double maxScreenY;
    if (2 * radiusPix <= viewHeight) {
      minScreenY = radiusPix + padding;
      maxScreenY = viewHeight - radiusPix - padding;
      if (minScreenY > maxScreenY) {
        minScreenY = maxScreenY = viewHeight / 2;
      }
    } else {
      minScreenY = viewHeight - radiusPix - padding;
      maxScreenY = radiusPix + padding;
      if (minScreenY > maxScreenY) {
        minScreenY = maxScreenY = viewHeight / 2;
      }
    }

    final cameraPix = camera.project(camera.center, testZoom);
    final currentScreenX = viewWidth / 2 + (circlePix.x - cameraPix.x);
    final currentScreenY = viewHeight / 2 + (circlePix.y - cameraPix.y);

    final clampedScreenX = currentScreenX.clamp(minScreenX, maxScreenX);
    final clampedScreenY = currentScreenY.clamp(minScreenY, maxScreenY);

    if (clampedScreenX == currentScreenX && clampedScreenY == currentScreenY) {
      return camera;
    }

    // Solve for new camera projection center
    final newCameraPixX = circlePix.x + viewWidth / 2 - clampedScreenX;
    final newCameraPixY = circlePix.y + viewHeight / 2 - clampedScreenY;

    final newCenter = camera.unproject(
      math.Point(newCameraPixX, newCameraPixY),
      testZoom,
    );

    return camera.withPosition(center: newCenter);
  }

  @override
  bool operator ==(Object other) {
    return other is ContainCircleCameraConstraint &&
        other.circleCenter == circleCenter &&
        other.circleRadiusMeters == circleRadiusMeters &&
        other.padding == padding;
  }

  @override
  int get hashCode => Object.hash(circleCenter, circleRadiusMeters, padding);
}
