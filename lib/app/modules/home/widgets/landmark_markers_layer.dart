import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../data/models/landmark_marker_model.dart';
import 'landmark_map_marker.dart';

/// FlutterMap layer widget that renders geo-anchored landmark location name badges (tooltips).
///
/// Features:
/// - Geographic anchoring centered on real-world coordinates ([Alignment.center])
/// - Zoom level visibility filtering ([minZoom] .. [maxZoom])
/// - Multi-line adaptive height: dynamically expands for landmark names > 3 words
/// - Selection-aware Z-indexing: The selected marker renders last to stay on top
/// - Works seamlessly across both General and Satellite map views
class LandmarkMarkersLayer extends StatelessWidget {
  /// The collection of configured landmark markers.
  final List<LandmarkMarkerModel> markers;

  /// ID of the currently selected landmark, if any.
  final String? selectedLandmarkId;

  /// Current map camera zoom level.
  final double currentZoom;

  /// Callback when a landmark marker is tapped.
  final ValueChanged<String>? onLandmarkTap;

  /// Styling configuration for pins and bubbles.
  final LandmarkMarkerStyle style;

  const LandmarkMarkersLayer({
    super.key,
    required this.markers,
    this.selectedLandmarkId,
    required this.currentZoom,
    this.onLandmarkTap,
    this.style = const LandmarkMarkerStyle(),
  });

  /// Pre-warms Flutter's memory image cache with the transparent landmark badge PNGs.
  static void prewarm(BuildContext context, Iterable<LandmarkMarkerModel> markers) {
    for (final marker in markers) {
      precacheImage(AssetImage(marker.assetPath), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Filter markers based on zoom thresholds
    final visibleMarkers = markers.where((marker) {
      return currentZoom >= marker.minZoom && currentZoom <= marker.maxZoom;
    }).toList();

    if (visibleMarkers.isEmpty) {
      return const SizedBox.shrink();
    }

    // 2. Sort markers so selected marker is drawn last (highest z-index)
    visibleMarkers.sort((a, b) {
      if (a.id == selectedLandmarkId) return 1;
      if (b.id == selectedLandmarkId) return -1;
      return 0;
    });

    // 3. Build MarkerLayer with geographic anchoring centered on coordinate
    return MarkerLayer(
      key: const Key('landmark_markers_layer'),
      alignment: Alignment.center,
      markers: visibleMarkers.map((landmark) {
        final isSelected = landmark.id == selectedLandmarkId;
        final isCompact = currentZoom < 15.8;
        final markerWidth = isCompact
            ? (isSelected ? 132.0 : 120.0)
            : (isSelected ? 164.0 : 148.0);
        final markerHeight = isCompact
            ? (isSelected ? 48.0 : 44.0)
            : (isSelected ? 58.0 : 52.0);

        return Marker(
          key: ValueKey('landmark_marker_${landmark.id}'),
          point: landmark.coordinates,
          width: markerWidth + 20.0,
          height: markerHeight + 16.0,
          alignment: Alignment.center,
          child: LandmarkMapMarker(
            landmark: landmark,
            isSelected: isSelected,
            currentZoom: currentZoom,
            style: style,
            onTap: () {
              if (onLandmarkTap != null) {
                onLandmarkTap!(landmark.id);
              }
              landmark.onTap?.call();
            },
          ),
        );
      }).toList(),
    );
  }
}
