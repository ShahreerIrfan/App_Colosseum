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

  /// IDs of landmarks currently excluded from the itinerary.
  final Set<String> excludedLandmarkIds;

  /// Styling configuration for pins and bubbles.
  final LandmarkMarkerStyle style;

  const LandmarkMarkersLayer({
    super.key,
    required this.markers,
    this.selectedLandmarkId,
    required this.currentZoom,
    this.onLandmarkTap,
    this.excludedLandmarkIds = const {},
    this.style = const LandmarkMarkerStyle(),
  });

  /// Pre-warms Flutter's memory image cache with the landmark badge images.
  static void prewarm(BuildContext context, Iterable<LandmarkMarkerModel> markers) {
    for (final marker in markers) {
      if (marker.isNetworkImage) {
        precacheImage(NetworkImage(marker.assetPath), context).catchError((_) {});
      } else {
        precacheImage(AssetImage(marker.assetPath), context).catchError((_) {});
      }
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

    // 3. Calculate collision offsets for markers at nearly identical coordinates (<0.0004 deg / ~35m)
    final collisionOffsets = <String, Offset>{};
    final collisionGroups = <List<LandmarkMarkerModel>>[];

    for (final marker in visibleMarkers) {
      bool placed = false;
      for (final group in collisionGroups) {
        if ((group.first.latitude - marker.latitude).abs() < 0.0004 &&
            (group.first.longitude - marker.longitude).abs() < 0.0004) {
          group.add(marker);
          placed = true;
          break;
        }
      }
      if (!placed) {
        collisionGroups.add([marker]);
      }
    }

    for (final group in collisionGroups) {
      if (group.length <= 1) continue;
      // Sort so built-in landmarks come first (stay anchored closest to center)
      group.sort((a, b) {
        if (a.isBuiltIn && !b.isBuiltIn) return -1;
        if (!a.isBuiltIn && b.isBuiltIn) return 1;
        return a.id.compareTo(b.id);
      });

      for (int index = 0; index < group.length; index++) {
        final item = group[index];
        if (index == 0 && item.isBuiltIn) {
          // Primary built-in stays at natural anchor
          collisionOffsets[item.id] = Offset.zero;
        } else {
          // Spread other overlapping markers upward / downward alternating
          final step = (index + 1) ~/ 2;
          final direction = (index % 2 == 1) ? -1.0 : 1.0;
          collisionOffsets[item.id] = Offset(
            (index % 2 == 1 ? -12.0 : 12.0) * step,
            direction * 50.0 * step,
          );
        }
      }
    }

    // 4. Build MarkerLayer with geographic anchoring centered on coordinate
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
        final extraOffset = collisionOffsets[landmark.id] ?? Offset.zero;
        final isExcluded = excludedLandmarkIds.contains(landmark.id);

        return Marker(
          key: ValueKey('landmark_marker_${landmark.id}'),
          point: landmark.coordinates,
          width: markerWidth + 30.0,
          height: markerHeight + 30.0,
          alignment: Alignment.center,
          child: Transform.translate(
            offset: extraOffset,
            child: Opacity(
              opacity: isExcluded ? 0.45 : 1.0,
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
            ),
          ),
        );
      }).toList(),
    );
  }
}
