import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../data/models/landmark_marker_model.dart';
import 'landmark_map_marker.dart';

/// FlutterMap layer widget that renders geo-anchored landmark location name badges (tooltips).
///
/// Features:
/// - Geographic anchoring centered on real-world coordinates ([Alignment.center])
/// - Zoom level visibility filtering ([minZoom] .. [maxZoom])
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
        final markerHeight = isSelected ? 38.0 : 34.0;

        return Marker(
          key: ValueKey('landmark_marker_${landmark.id}'),
          point: landmark.coordinates,
          width: 170.0,
          height: markerHeight,
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
