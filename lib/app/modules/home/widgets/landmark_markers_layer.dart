import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../data/models/landmark_marker_model.dart';
import 'landmark_map_marker.dart';

/// FlutterMap layer widget that renders geo-anchored classic landmark pin markers and labels.
///
/// Features:
/// - Exact geographic anchoring tied to real-world coordinates ([Alignment.topCenter] with pin tip at bottom)
/// - Zoom level visibility filtering ([minZoom] .. [maxZoom])
/// - Selection-aware Z-indexing: The selected marker renders last to stay on top of adjacent markers
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

    // 3. Build MarkerLayer with exact geographic anchoring
    return MarkerLayer(
      key: const Key('landmark_markers_layer'),
      alignment: Alignment.topCenter,
      markers: visibleMarkers.map((landmark) {
        final isSelected = landmark.id == selectedLandmarkId;
        final markerHeight = isSelected ? 86.0 : 76.0;

        return Marker(
          key: ValueKey('landmark_marker_${landmark.id}'),
          point: landmark.coordinates,
          width: 160.0,
          height: markerHeight,
          alignment: Alignment.topCenter,
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
