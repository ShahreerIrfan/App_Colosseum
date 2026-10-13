import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/landmark_marker_model.dart';

/// Offline-first pedestrian routing service for the Colosseum archaeological zone.
///
/// Instead of connecting landmarks with straight lines across buildings or cutting
/// across grass fields, this service routes pedestrians with high accuracy along
/// real roads, streets, sidewalks, and historic pathways (Via Sacra, Via Celio Vibenna,
/// Piazza del Colosseo promenade, Via di San Gregorio, Via di San Giovanni in Laterano,
/// Via Claudia, Clivo di Venere Felice, Via dei Fori Imperiali).
class PedestrianStreetRouter {
  PedestrianStreetRouter._() {
    _initializeGraph();
  }

  static final PedestrianStreetRouter instance = PedestrianStreetRouter._();

  /// Mapped high-precision pedestrian and street segments around the Colosseum archaeological zone.
  static const List<List<LatLng>> _streetSegments = [
    // Via Sacra (Arch of Constantine to Roman Forum)
    [
      LatLng(41.890141, 12.490481),
      LatLng(41.890205, 12.490257),
      LatLng(41.890206, 12.490251),
      LatLng(41.890303, 12.489910),
      LatLng(41.890441, 12.489426),
      LatLng(41.890497, 12.489230),
      LatLng(41.890551, 12.489022),
      LatLng(41.890572, 12.488940),
      LatLng(41.890628, 12.488718),
      LatLng(41.890654, 12.488645),
      LatLng(41.890661, 12.488622),
      LatLng(41.890683, 12.488546),
      LatLng(41.890687, 12.488535),
      LatLng(41.890691, 12.488519),
      LatLng(41.890761, 12.488572),
      LatLng(41.890814, 12.488584),
      LatLng(41.890882, 12.488577),
      LatLng(41.890909, 12.488533),
      LatLng(41.890953, 12.488459),
      LatLng(41.890991, 12.488404),
      LatLng(41.891025, 12.488373),
      LatLng(41.891096, 12.488346),
      LatLng(41.891112, 12.488334),
      LatLng(41.891123, 12.488316),
      LatLng(41.891151, 12.488248),
      LatLng(41.891169, 12.488224),
      LatLng(41.891185, 12.488209),
      LatLng(41.891208, 12.488190),
      LatLng(41.891224, 12.488170),
      LatLng(41.891254, 12.488132),
      LatLng(41.891297, 12.488079),
      LatLng(41.891327, 12.488043),
      LatLng(41.891361, 12.487998),
      LatLng(41.891397, 12.487948),
      LatLng(41.891419, 12.487908),
      LatLng(41.891434, 12.487878),
      LatLng(41.891453, 12.487844),
      LatLng(41.891473, 12.487802),
      LatLng(41.891495, 12.487748),
      LatLng(41.891515, 12.487684),
      LatLng(41.891585, 12.487512),
      LatLng(41.891630, 12.487392),
      LatLng(41.891641, 12.487361),
      LatLng(41.891654, 12.487329),
      LatLng(41.891717, 12.487121),
      LatLng(41.891797, 12.486856),
      LatLng(41.891836, 12.486756),
      LatLng(41.891957, 12.486594),
      LatLng(41.891988, 12.486532),
      LatLng(41.892071, 12.486367),
      LatLng(41.892088, 12.486331),
      LatLng(41.892108, 12.486287),
      LatLng(41.892298, 12.485906),
      LatLng(41.892370, 12.485743),
      LatLng(41.892606, 12.485214),
      LatLng(41.892614, 12.485195),
    ],

    // Via Celio Vibenna Curve
    [
      LatLng(41.889299, 12.493247),
      LatLng(41.889280, 12.493151),
      LatLng(41.889261, 12.493045),
      LatLng(41.889246, 12.492913),
      LatLng(41.889241, 12.492781),
      LatLng(41.889243, 12.492546),
      LatLng(41.889258, 12.491908),
      LatLng(41.889258, 12.491832),
      LatLng(41.889253, 12.491754),
      LatLng(41.889246, 12.491684),
      LatLng(41.889237, 12.491612),
      LatLng(41.889227, 12.491541),
      LatLng(41.889214, 12.491469),
      LatLng(41.889201, 12.491411),
      LatLng(41.889180, 12.491326),
      LatLng(41.889158, 12.491258),
      LatLng(41.889135, 12.491185),
      LatLng(41.889111, 12.491121),
      LatLng(41.889080, 12.491046),
      LatLng(41.889047, 12.490970),
      LatLng(41.889007, 12.490897),
      LatLng(41.888960, 12.490825),
      LatLng(41.888913, 12.490756),
      LatLng(41.888704, 12.490476),
      LatLng(41.888670, 12.490434),
    ],

    // Via di San Gregorio & Promenade to Arch
    [
      LatLng(41.888670, 12.490434),
      LatLng(41.888747, 12.490365),
      LatLng(41.889000, 12.490430),
      LatLng(41.889300, 12.490500),
      LatLng(41.889519, 12.490567),
      LatLng(41.889656, 12.490395),
      LatLng(41.889753, 12.490363),
      LatLng(41.889762, 12.490667),
    ],

    // Arch of Constantine to Colosseum West Promenade
    [
      LatLng(41.889762, 12.490667),
      LatLng(41.889656, 12.490750),
      LatLng(41.889705, 12.491021),
      LatLng(41.889810, 12.491116),
      LatLng(41.889867, 12.491208),
      LatLng(41.890028, 12.491132),
      LatLng(41.890183, 12.491101),
      LatLng(41.890307, 12.491094),
      LatLng(41.890431, 12.491109),
      LatLng(41.890510, 12.491131),
      LatLng(41.890648, 12.491204),
      LatLng(41.890210, 12.492231),
    ],

    // Colosseo Outer Pedestrian Ring
    [
      LatLng(41.889848, 12.493564),
      LatLng(41.889991, 12.493636),
      LatLng(41.890083, 12.493680),
      LatLng(41.890132, 12.493703),
      LatLng(41.890160, 12.493717),
      LatLng(41.890307, 12.493741),
      LatLng(41.890429, 12.493693),
      LatLng(41.890501, 12.493629),
      LatLng(41.890571, 12.493529),
      LatLng(41.890738, 12.493200),
      LatLng(41.890749, 12.493175),
      LatLng(41.890846, 12.492954),
      LatLng(41.890906, 12.492744),
      LatLng(41.890942, 12.492520),
      LatLng(41.890964, 12.492358),
      LatLng(41.890971, 12.492242),
      LatLng(41.890966, 12.492103),
      LatLng(41.890944, 12.491915),
      LatLng(41.890912, 12.491679),
      LatLng(41.890885, 12.491499),
      LatLng(41.890837, 12.491412),
      LatLng(41.890763, 12.491309),
      LatLng(41.890648, 12.491204),
      LatLng(41.890594, 12.491173),
      LatLng(41.890510, 12.491131),
      LatLng(41.890431, 12.491109),
      LatLng(41.890307, 12.491094),
      LatLng(41.890183, 12.491101),
      LatLng(41.890028, 12.491132),
      LatLng(41.889867, 12.491208),
      LatLng(41.889739, 12.491349),
      LatLng(41.889599, 12.491572),
      LatLng(41.889520, 12.491793),
      LatLng(41.889472, 12.491962),
      LatLng(41.889409, 12.491931),
    ],

    // Via di San Giovanni in Laterano to Ludus Magnus
    [
      LatLng(41.890035, 12.494030),
      LatLng(41.890147, 12.494228),
      LatLng(41.890100, 12.494367),
      LatLng(41.890250, 12.494700),
      LatLng(41.890400, 12.495000),
      LatLng(41.890450, 12.495100),
    ],

    // Via Claudia (Parco Celio East to Piazza del Colosseo)
    [
      LatLng(41.887200, 12.494500),
      LatLng(41.887800, 12.494300),
      LatLng(41.888455, 12.494015),
      LatLng(41.889072, 12.493715),
      LatLng(41.889138, 12.493681),
      LatLng(41.889299, 12.493247),
    ],

    // Parco Celio Walkway Exit to Via Celio Vibenna
    [
      LatLng(41.888500, 12.492500),
      LatLng(41.888800, 12.492500),
      LatLng(41.889062, 12.492493),
      LatLng(41.889169, 12.492597),
    ],

    // Clivo di Venere Felice Promenade
    [
      LatLng(41.891123, 12.488316),
      LatLng(41.891203, 12.490416),
      LatLng(41.891369, 12.490520),
      LatLng(41.891150, 12.491950),
    ],

    // Via dei Fori Imperiali
    [
      LatLng(41.891150, 12.491950),
      LatLng(41.891412, 12.490395),
      LatLng(41.891500, 12.490900),
      LatLng(41.892260, 12.488908),
      LatLng(41.892991, 12.487407),
      LatLng(41.893470, 12.486677),
    ],

    // Arch of Constantine Plaza to Via Sacra Entrance
    [
      LatLng(41.889762, 12.490667),
      LatLng(41.889930, 12.490377),
      LatLng(41.890141, 12.490481),
    ],

    // Colosseum Ring East to Via di San Giovanni in Laterano
    [
      LatLng(41.889848, 12.493564),
      LatLng(41.889445, 12.493737),
      LatLng(41.890035, 12.494030),
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

    // Connect close intersection nodes and pedestrian crossings (< 12 meters)
    for (var i = 0; i < _nodes.length; i++) {
      for (var j = i + 1; j < _nodes.length; j++) {
        final d = _calculateDistanceMeters(_nodes[i], _nodes[j]);
        if (d < 12.0) {
          if (!_adjacency[i].any((e) => e.targetIndex == j)) {
            _adjacency[i].add(_Edge(targetIndex: j, distance: d));
            _adjacency[j].add(_Edge(targetIndex: i, distance: d));
          }
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
    final result = <LatLng>[];
    if (_calculateDistanceMeters(start, _nodes[startNodeIdx]) > 3.0) {
      result.add(start);
    }
    for (final pt in streetPath) {
      if (result.isEmpty || result.last != pt) {
        result.add(pt);
      }
    }
    if (_calculateDistanceMeters(result.last, destination) > 3.0) {
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

    final result = <LatLng>[];
    final unvisited = List<LandmarkMarkerModel>.from(landmarks);
    var currentPos = userLocation;

    while (unvisited.isNotEmpty) {
      // Sort unvisited landmarks by real walking street distance from currentPos
      unvisited.sort((a, b) {
        final distA = walkingDistance(currentPos, a.coordinates);
        final distB = walkingDistance(currentPos, b.coordinates);
        return distA.compareTo(distB);
      });

      final nextLandmark = unvisited.removeAt(0);
      final leg = routeBetween(currentPos, nextLandmark.coordinates);

      for (final pt in leg) {
        if (result.isEmpty || result.last != pt) {
          result.add(pt);
        }
      }

      currentPos = nextLandmark.coordinates;
    }

    return result;
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
