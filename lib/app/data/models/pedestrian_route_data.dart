import 'package:latlong2/latlong.dart';

class PedestrianRouteData {
  final List<LatLng> waypoints;
  final bool isOneWay;
  final String instruction;
  final String? fromLandmarkCode;
  final String? toLandmarkCode;

  const PedestrianRouteData(this.waypoints, {
    this.isOneWay = false,
    this.instruction = '',
    this.fromLandmarkCode,
    this.toLandmarkCode,
  });

  static List<PedestrianRouteData> parseList(Object? raw) => (raw as List? ?? [])
      .map((value) {
        final route = value as Map;
        return PedestrianRouteData(
          (route['waypoints'] as List).map(_pointFromJson).toList(),
          isOneWay: route['isOneWay'] == true,
          instruction: route['instruction'] as String? ?? '',
          fromLandmarkCode: route['fromLandmarkCode'] as String?,
          toLandmarkCode: route['toLandmarkCode'] as String?,
        );
      }).where((route) => route.waypoints.length >= 2).toList();

  static LatLng _pointFromJson(Object? raw) {
    final point = raw as Map;
    final latitude = (point['latitude'] as num).toDouble();
    final longitude = (point['longitude'] as num).toDouble();
    if (!latitude.isFinite || !longitude.isFinite ||
        latitude.abs() > 90 || longitude.abs() > 180) {
      throw const FormatException('Invalid walking point');
    }
    return LatLng(latitude, longitude);
  }

  Map<String, dynamic> toJson() => {
    'waypoints': waypoints.map((point) => {'latitude': point.latitude, 'longitude': point.longitude}).toList(),
    'isOneWay': isOneWay,
    'instruction': instruction,
    'fromLandmarkCode': fromLandmarkCode,
    'toLandmarkCode': toLandmarkCode,
  };
}
