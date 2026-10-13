import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/landmark_marker_model.dart';

/// Offline-first pedestrian routing service for the Colosseum archaeological zone.
///
/// Instead of connecting landmarks with straight lines across buildings, this service
/// routes pedestrians along real roads, streets, sidewalks, and historic pathways
/// (Via Claudia, Via Celio Vibenna, Piazza del Colosseo, Via di San Giovanni in Laterano,
/// Clivo di Venere Felice, Via Sacra, Via dei Fori Imperiali, etc.).
class PedestrianStreetRouter {
  PedestrianStreetRouter._() {
    _initializeGraph();
  }

  static final PedestrianStreetRouter instance = PedestrianStreetRouter._();

  /// All mapped pedestrian and street segments around the Colosseum archaeological zone.
  static const List<List<LatLng>> _streetSegments = [
    // 1. Via Claudia (Parco Celio from south to Piazza del Colosseo junction)
    [
      LatLng(41.887200, 12.493800),
      LatLng(41.887650, 12.493350),
      LatLng(41.888100, 12.492900),
      LatLng(41.888500, 12.492500), // Default start anchor (Parco Celio)
      LatLng(41.888800, 12.492250),
      LatLng(41.889150, 12.492000),
      LatLng(41.889450, 12.491820),
      LatLng(41.889600, 12.491750), // Junction: Via Claudia / Via Celio Vibenna / Piazza
    ],

    // 2. Via Celio Vibenna (Via Claudia junction to Arch of Constantine)
    [
      LatLng(41.889600, 12.491750), // Junction
      LatLng(41.889650, 12.491400),
      LatLng(41.889700, 12.491000),
      LatLng(41.889762, 12.490667), // Arch of Constantine
    ],

    // 3. Piazza del Colosseo South-East Curve (Via Claudia junction to East junction)
    [
      LatLng(41.889600, 12.491750), // Junction
      LatLng(41.889650, 12.492300),
      LatLng(41.889750, 12.492800),
      LatLng(41.889900, 12.493250),
      LatLng(41.890120, 12.493650),
      LatLng(41.890400, 12.494100), // East junction (Via di S. Giovanni in Laterano)
    ],

    // 4. Via di San Giovanni in Laterano (to Ludus Magnus)
    [
      LatLng(41.890400, 12.494100), // East junction
      LatLng(41.890420, 12.494500),
      LatLng(41.890440, 12.494800),
      LatLng(41.890450, 12.495100), // Ludus Magnus
      LatLng(41.890470, 12.495600),
    ],

    // 5. Colosseum West Pedestrian Promenade (Arch of Constantine to West entrance & Metro)
    [
      LatLng(41.889762, 12.490667), // Arch of Constantine
      LatLng(41.889950, 12.490900),
      LatLng(41.890100, 12.491250),
      LatLng(41.890210, 12.491600), // West Entrance Plaza
      LatLng(41.890400, 12.491700),
      LatLng(41.890700, 12.491900),
      LatLng(41.891000, 12.492000),
      LatLng(41.891150, 12.491950), // Metro Colosseo / Largo Agnesi
    ],

    // 6. Colosseum North-East Promenade (East junction to Metro Colosseo)
    [
      LatLng(41.890400, 12.494100), // East junction
      LatLng(41.890650, 12.493700),
      LatLng(41.890850, 12.493200),
      LatLng(41.891050, 12.492600),
      LatLng(41.891150, 12.491950), // Metro Colosseo
    ],

    // 7. West Entrance Plaza to Colosseum Center Anchor
    [
      LatLng(41.890210, 12.491600), // West entrance
      LatLng(41.890210, 12.492231), // Colosseum Center Anchor
    ],

    // 8. Clivo di Venere Felice (from Arch of Constantine / Promenade to Temple of Venus & Rome)
    [
      LatLng(41.889762, 12.490667), // Arch of Constantine
      LatLng(41.890150, 12.490550),
      LatLng(41.890450, 12.490100),
      LatLng(41.890750, 12.489350),
      LatLng(41.890950, 12.488800),
      LatLng(41.891100, 12.488300), // Temple of Venus and Rome
    ],

    // 9. Via dei Fori Imperiali (from Metro Colosseo northwest)
    [
      LatLng(41.891150, 12.491950), // Metro Colosseo
      LatLng(41.891500, 12.490900),
      LatLng(41.891900, 12.489700),
      LatLng(41.892300, 12.488400),
      LatLng(41.892700, 12.487100),
    ],

    // 10. Connecting Via dei Fori Imperiali to Temple of Venus and Rome
    [
      LatLng(41.891500, 12.490900),
      LatLng(41.891200, 12.489600),
      LatLng(41.891100, 12.488300),
    ],

    // 11. Via Sacra (from Temple of Venus and Rome into Roman Forum)
    [
      LatLng(41.891100, 12.488300), // Temple of Venus and Rome
      LatLng(41.891250, 12.487800),
      LatLng(41.891450, 12.487100), // Arch of Titus
      LatLng(41.891750, 12.486400), // Along Basilica of Maxentius
      LatLng(41.892100, 12.485850), // Temple of Antoninus and Faustina
      LatLng(41.892460, 12.485320), // Roman Forum central plaza
    ],

    // 12. Rione Celio Streets (Via Celimontana & Via Capo d'Africa from Via Claudia to Ludus Magnus)
    [
      LatLng(41.888500, 12.492500), // Via Claudia
      LatLng(41.888750, 12.493300), // Via Celimontana
      LatLng(41.889200, 12.494000), // Via Capo d'Africa
      LatLng(41.889700, 12.494600), // Via Capo d'Africa
      LatLng(41.890100, 12.494900), // Via Capo d'Africa north
      LatLng(41.890450, 12.495100), // Ludus Magnus
    ],

    // 13. Via Ostilia (connecting Via Celimontana to Piazza del Colosseo East)
    [
      LatLng(41.888750, 12.493300), // Via Celimontana
      LatLng(41.889400, 12.493700), // Via Ostilia
      LatLng(41.890400, 12.494100), // Piazza del Colosseo East
    ],

    // 14. Via di San Gregorio (South of Arch of Constantine)
    [
      LatLng(41.889762, 12.490667), // Arch of Constantine
      LatLng(41.889100, 12.490400),
      LatLng(41.888300, 12.490100),
    ],
  ];

  final List<LatLng> _nodes = [];
  final List<List<_Edge>> _adjacency = [];

  void _initializeGraph() {
    _nodes.clear();
    _adjacency.clear();

    // Collect unique intersection nodes (within 2 meters threshold)
    for (final segment in _streetSegments) {
      for (final pt in segment) {
        if (!_nodes.any((n) => _calculateDistanceMeters(pt, n) < 2.0)) {
          _nodes.add(pt);
        }
      }
    }

    for (var i = 0; i < _nodes.length; i++) {
      _adjacency.add([]);
    }

    // Build bi-directional edges along street segments
    for (final segment in _streetSegments) {
      for (var k = 0; k < segment.length - 1; k++) {
        final u = _findNodeIndex(segment[k]);
        final v = _findNodeIndex(segment[k + 1]);
        if (u != -1 && v != -1 && u != v) {
          final dist = _calculateDistanceMeters(_nodes[u], _nodes[v]);
          _adjacency[u].add(_Edge(targetIndex: v, distance: dist));
          _adjacency[v].add(_Edge(targetIndex: u, distance: dist));
        }
      }
    }
  }

  int _findNodeIndex(LatLng point) {
    for (var i = 0; i < _nodes.length; i++) {
      if (_calculateDistanceMeters(point, _nodes[i]) < 2.0) {
        return i;
      }
    }
    return -1;
  }

  int _findNearestNodeIndex(LatLng point) {
    var bestIndex = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < _nodes.length; i++) {
      final d = _calculateDistanceMeters(point, _nodes[i]);
      if (d < bestDist) {
        bestDist = d;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  /// Calculates geodesic distance between two points in meters.
  double _calculateDistanceMeters(LatLng a, LatLng b) {
    final lat1 = a.latitude;
    final lon1 = a.longitude;
    final lat2 = b.latitude;
    final lon2 = b.longitude;
    final dLat = (lat2 - lat1) * 111139.0;
    final avgLatRad = ((lat1 + lat2) / 2.0) * math.pi / 180.0;
    final dLon = (lon2 - lon1) * 111139.0 * math.cos(avgLatRad);
    return math.sqrt(dLat * dLat + dLon * dLon);
  }

  /// Calculates estimated walking street distance between two points.
  double walkingDistance(LatLng start, LatLng destination) {
    final route = routeBetween(start, destination);
    if (route.length < 2) return 0.0;
    var total = 0.0;
    for (var i = 0; i < route.length - 1; i++) {
      total += _calculateDistanceMeters(route[i], route[i + 1]);
    }
    return total;
  }

  /// Computes the exact pedestrian walking path along real streets between [start] and [destination].
  List<LatLng> routeBetween(LatLng start, LatLng destination) {
    final startNodeIdx = _findNearestNodeIndex(start);
    final endNodeIdx = _findNearestNodeIndex(destination);

    if (startNodeIdx == endNodeIdx) {
      return [start, destination];
    }

    // Dijkstra shortest path on street graph
    final distances = List<double>.filled(_nodes.length, double.infinity);
    final previous = List<int?>.filled(_nodes.length, null);
    final visited = List<bool>.filled(_nodes.length, false);

    distances[startNodeIdx] = 0.0;

    for (var i = 0; i < _nodes.length; i++) {
      var minDistance = double.infinity;
      var u = -1;

      for (var j = 0; j < _nodes.length; j++) {
        if (!visited[j] && distances[j] < minDistance) {
          minDistance = distances[j];
          u = j;
        }
      }

      if (u == -1 || u == endNodeIdx) break;
      visited[u] = true;

      for (final edge in _adjacency[u]) {
        final v = edge.targetIndex;
        if (!visited[v]) {
          final newDist = distances[u] + edge.distance;
          if (newDist < distances[v]) {
            distances[v] = newDist;
            previous[v] = u;
          }
        }
      }
    }

    // Reconstruct path
    final path = <LatLng>[];
    int? current = endNodeIdx;
    while (current != null) {
      path.add(_nodes[current]);
      current = previous[current];
    }
    final streetPath = path.reversed.toList();

    // Assemble final route: start -> street path -> destination
    final result = <LatLng>[start];
    for (final pt in streetPath) {
      if (result.isEmpty || result.last != pt) {
        result.add(pt);
      }
    }
    if (result.isEmpty || result.last != destination) {
      result.add(destination);
    }

    return result;
  }

  /// Calculates the complete planned multi-stop tour itinerary following real streets.
  ///
  /// Dynamically orders unvisited landmarks by nearest walking street distance,
  /// then synthesizes a contiguous pedestrian path tracing every street and walkway.
  List<LatLng> routeItinerary(
    LatLng userLocation,
    List<LandmarkMarkerModel> landmarks,
  ) {
    if (landmarks.isEmpty) return const [];

    // Order remaining unvisited landmarks using nearest-neighbor street distance
    final unvisited = List<LandmarkMarkerModel>.from(landmarks);
    final orderedLandmarks = <LandmarkMarkerModel>[];
    var currentAnchor = userLocation;

    while (unvisited.isNotEmpty) {
      unvisited.sort((a, b) {
        final distA = walkingDistance(currentAnchor, a.coordinates);
        final distB = walkingDistance(currentAnchor, b.coordinates);
        return distA.compareTo(distB);
      });

      final next = unvisited.removeAt(0);
      orderedLandmarks.add(next);
      currentAnchor = next.coordinates;
    }

    // Connect each leg along real pedestrian streets
    final fullRoute = <LatLng>[];
    var fromPoint = userLocation;

    for (final landmark in orderedLandmarks) {
      final leg = routeBetween(fromPoint, landmark.coordinates);
      if (fullRoute.isEmpty) {
        fullRoute.addAll(leg);
      } else {
        // Skip duplicate point between consecutive legs
        if (leg.isNotEmpty && fullRoute.last == leg.first) {
          fullRoute.addAll(leg.skip(1));
        } else {
          fullRoute.addAll(leg);
        }
      }
      fromPoint = landmark.coordinates;
    }

    return fullRoute;
  }
}

class _Edge {
  final int targetIndex;
  final double distance;

  const _Edge({
    required this.targetIndex,
    required this.distance,
  });
}
