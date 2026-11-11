import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// A north-up aerial image with its original Web Mercator bounds.
class OfflineAerialMap {
  static const attribution = 'AGEA Ortofoto 2023 · CC BY 4.0';
  static const licenseUrl = 'https://creativecommons.org/licenses/by/4.0/';
  static const sourceUrl =
      'https://geodati.gov.it/geoportale/visualizzazione-metadati/scheda-metadati?metadataid=agea%3AOI%3AORTOIMMAGINI%3Am004+-++-+2026-09-25+13%3A18%3A27';
  static const _projection = SphericalMercator();
  static const _halfSizeMeters = 700.0;
  static const _worldEdge = 20037508.342789244;
  static const _zoom = 17;
  static const _tileSpan = 2 * _worldEdge / (1 << _zoom);
  static const _source = 'agea-wmts-z17';
  static const tilePixels = 256;

  final String imagePath;
  final double west;
  final double south;
  final double east;
  final double north;

  const OfflineAerialMap({
    required this.imagePath,
    required this.west,
    required this.south,
    required this.east,
    required this.north,
  });

  LatLngBounds get bounds => LatLngBounds(
    _projection.unprojectXY(west, south),
    _projection.unprojectXY(east, north),
  );

  // Limit this source to Rome, where AGEA's 2023 Lazio imagery is available.
  static bool covers(LatLng center) =>
      center.latitude >= 41.6 &&
      center.latitude <= 42.2 &&
      center.longitude >= 12.1 &&
      center.longitude <= 12.9;

  static OfflineAerialMap? forLandmark(LatLng center) {
    if (!covers(center)) return null;
    final point = _projection.project(center);
    final left = ((point.x - _halfSizeMeters + _worldEdge) / _tileSpan).floor();
    final right = ((point.x + _halfSizeMeters + _worldEdge) / _tileSpan).ceil();
    final top = ((_worldEdge - point.y - _halfSizeMeters) / _tileSpan).floor();
    final bottom = ((_worldEdge - point.y + _halfSizeMeters) / _tileSpan)
        .ceil();
    return OfflineAerialMap(
      imagePath: _tileUrl(top, left).toString(),
      west: left * _tileSpan - _worldEdge,
      south: _worldEdge - bottom * _tileSpan,
      east: right * _tileSpan - _worldEdge,
      north: _worldEdge - top * _tileSpan,
    );
  }

  static Uri _tileUrl(int row, int column) => Uri.https(
    'geoportale.agea.gov.it',
    '/image/rest/services/AgEA/Ortofoto_AgEA_2023/ImageServer/WMTS/tile/'
        '1.0.0/AgEA_Ortofoto_AgEA_2023/default/GoogleMapsCompatible/'
        '$_zoom/$row/$column',
  );

  int get tileColumns => ((east - west) / _tileSpan).round();
  int get tileRows => ((north - south) / _tileSpan).round();

  Uri tileUrl(int row, int column) => _tileUrl(
    ((_worldEdge - north) / _tileSpan).round() + row,
    ((west + _worldEdge) / _tileSpan).round() + column,
  );

  OfflineAerialMap withImagePath(String path) => OfflineAerialMap(
    imagePath: path,
    west: west,
    south: south,
    east: east,
    north: north,
  );

  static OfflineAerialMap? fromJson(Map<String, dynamic> json) =>
      json['source'] != _source
      ? null
      : OfflineAerialMap(
          imagePath: json['imagePath'] as String,
          west: (json['west'] as num).toDouble(),
          south: (json['south'] as num).toDouble(),
          east: (json['east'] as num).toDouble(),
          north: (json['north'] as num).toDouble(),
        );

  Map<String, dynamic> toJson() => {
    'source': _source,
    'imagePath': imagePath,
    'west': west,
    'south': south,
    'east': east,
    'north': north,
  };
}
