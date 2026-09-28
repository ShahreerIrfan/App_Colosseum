import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Immutable POI model representing historical landmarks and georeferenced architectural overlays.
class PoiModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String assetPath;
  final String? overlayAssetPath;
  final String description;
  final double minZoom;
  final double baseMarkerSize;
  final LatLngBounds? bounds;
  final double overlayMinZoom;
  final List<LatLng>? footprintPolygon;

  const PoiModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.assetPath,
    this.overlayAssetPath,
    this.description = '',
    this.minZoom = 13.0,
    this.baseMarkerSize = 68.0,
    this.bounds,
    this.overlayMinZoom = 15.5,
    this.footprintPolygon,
  });

  bool get hasGroundOverlay => bounds != null;

  /// Checks if a tapped geographic coordinate falls inside this landmark's footprint or proximity area
  bool containsPoint(LatLng point) {
    if (bounds != null && bounds!.contains(point)) {
      return true;
    }
    const distance = Distance();
    return distance(LatLng(latitude, longitude), point) <= 35.0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PoiModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
