import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../data/models/landmark_overlay_model.dart';

/// Reusable FlutterMap layer widget that renders geo-anchored landmark ground overlays.
///
/// Features:
/// - Exact geographic anchoring tied to real-world coordinates and metric dimensions
/// - Support for ground-contact footprint anchor offsets [anchorX, anchorY]
/// - Real-world orientation / rotation
/// - Dynamic per-landmark zoom visibility thresholds ([minZoom] .. [maxZoom])
/// - Z-Index layering
/// - Interactive overlays: Overlays with [onTap] are clickable; overlays without [onTap]
///   are wrapped in [IgnorePointer] so map pan, zoom, pinch gestures remain responsive.
/// - Static [prewarm] utility to pre-cache all PNGs into Flutter's in-memory image cache
class LandmarkOverlayLayer extends StatelessWidget {
  /// The collection of configured landmark overlays.
  final List<MapLandmarkOverlay> overlays;

  /// The active map camera zoom level.
  final double currentZoom;

  /// Optional debug mode to display alignment outlines and footprint labels.
  final bool isDebug;

  const LandmarkOverlayLayer({
    super.key,
    required this.overlays,
    required this.currentZoom,
    this.isDebug = false,
  });

  /// Pre-warms Flutter's memory image cache with the transparent landmark PNGs.
  static void prewarm(BuildContext context, Iterable<MapLandmarkOverlay> overlays) {
    for (final overlay in overlays) {
      precacheImage(AssetImage(overlay.assetPath), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Filter visible overlays based on master toggle and per-landmark zoom thresholds
    final visibleOverlays = overlays.where((overlay) {
      if (!overlay.isVisible) return false;
      return currentZoom >= overlay.minZoom && currentZoom <= overlay.maxZoom;
    }).toList();

    if (visibleOverlays.isEmpty) {
      return const SizedBox.shrink();
    }

    // 2. Sort by zIndex so lower layers render beneath higher layers
    visibleOverlays.sort((a, b) => a.zIndex.compareTo(b.zIndex));

    // 3. Build GeoLandmarkOverlayImageWidget instances anchored to real geographic coordinates
    final overlayWidgets = visibleOverlays.map<Widget>((overlay) {
      return GeoLandmarkOverlayImageWidget(
        key: ValueKey('landmark_overlay_${overlay.id}'),
        overlay: overlay,
      );
    }).toList();

    final imageLayer = MobileLayerTransformer(
      child: ClipRect(
        child: Stack(
          key: const Key('landmark_overlay_stack'),
          children: overlayWidgets,
        ),
      ),
    );

    if (!isDebug) {
      return imageLayer;
    }

    // Debug mode: Render visual footprint outlines and center labels
    final debugPolygons = visibleOverlays.map((overlay) {
      final corners = overlay.rotatedCorners;
      return Polygon(
        points: [
          corners.topLeft,
          corners.topRight,
          corners.bottomRight,
          corners.bottomLeft,
        ],
        borderColor: Colors.redAccent,
        borderStrokeWidth: 2.0,
        color: Colors.redAccent.withValues(alpha: 0.15),
      );
    }).toList();

    return Stack(
      children: [
        imageLayer,
        IgnorePointer(
          ignoring: true,
          child: PolygonLayer(polygons: debugPolygons),
        ),
      ],
    );
  }
}

/// An individual geo-anchored landmark overlay projected onto the map.
class GeoLandmarkOverlayImageWidget extends StatelessWidget {
  final MapLandmarkOverlay overlay;

  const GeoLandmarkOverlayImageWidget({super.key, required this.overlay});

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final corners = overlay.rotatedCorners;

    final pxTopLeft = camera.getOffsetFromOrigin(corners.topLeft);
    final pxBottomRight = camera.getOffsetFromOrigin(corners.bottomRight);
    final pxBottomLeft = camera.getOffsetFromOrigin(corners.bottomLeft);
    final pxTopRight = pxTopLeft - pxBottomLeft + pxBottomRight;

    final minX = [pxTopLeft.dx, pxBottomRight.dx, pxTopRight.dx, pxBottomLeft.dx].reduce(math.min);
    final maxX = [pxTopLeft.dx, pxBottomRight.dx, pxTopRight.dx, pxBottomLeft.dx].reduce(math.max);
    final minY = [pxTopLeft.dy, pxBottomRight.dy, pxTopRight.dy, pxBottomLeft.dy].reduce(math.min);
    final maxY = [pxTopLeft.dy, pxBottomRight.dy, pxTopRight.dy, pxBottomLeft.dy].reduce(math.max);
    final bounds = Rect.fromLTRB(minX, minY, maxX, maxY);

    final vectorX = (pxTopRight - pxTopLeft) / bounds.size.width;
    final vectorY = (pxBottomLeft - pxTopLeft) / bounds.size.height;
    final offset = pxTopLeft - bounds.topLeft;

    final a = vectorX.dx;
    final b = vectorX.dy;
    final c = vectorY.dx;
    final d = vectorY.dy;
    final tx = offset.dx;
    final ty = offset.dy;

    Widget imageWidget = Image(
      image: AssetImage(overlay.assetPath),
      fit: BoxFit.fill,
      opacity: AlwaysStoppedAnimation(overlay.opacity),
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );

    if (overlay.onTap != null) {
      imageWidget = GestureDetector(
        key: ValueKey('landmark_tap_${overlay.id}'),
        behavior: HitTestBehavior.deferToChild,
        onTap: overlay.onTap,
        child: imageWidget,
      );
    } else {
      imageWidget = IgnorePointer(
        key: const Key('landmark_overlay_ignore_pointer'),
        ignoring: true,
        child: imageWidget,
      );
    }

    return Positioned(
      left: bounds.topLeft.dx,
      top: bounds.topLeft.dy,
      width: bounds.size.width,
      height: bounds.size.height,
      child: Transform(
        transform: Matrix4(a, b, 0, 0, c, d, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1),
        filterQuality: FilterQuality.medium,
        child: imageWidget,
      ),
    );
  }
}
