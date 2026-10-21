import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/landmark_marker_model.dart';

/// Dynamic pedestrian routing service for the Colosseum archaeological zone.
///
/// Routes pedestrians along real roads, streets, sidewalks, and historic pathways
/// using street segments dynamically fetched from the database / tour repository.
class PedestrianStreetRouter {
  PedestrianStreetRouter._();

  static final PedestrianStreetRouter instance = PedestrianStreetRouter._();

  List<List<LatLng>> _streetSegments = [];
  final List<LatLng> _nodes = [];
  final List<List<_Edge>> _adjacency = [];

  bool get isInitialized => _nodes.isNotEmpty;

  /// Loads initial street segments from seed if not initialized
  static void ensureInitialized() {
    if (instance.isInitialized) return;
    try {
      final file = File('assets/data/colosseum_seed.json');
      if (file.existsSync()) {
        final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final rawRoutes = json['pedestrianRoutes'] as List<dynamic>? ?? [];
        final List<List<LatLng>> streetSegments = [];
        for (final r in rawRoutes) {
          if (r is Map && r['waypoints'] is List) {
            final pts = (r['waypoints'] as List).map<LatLng>((w) {
              final wm = w as Map;
              return LatLng(
                (wm['latitude'] as num).toDouble(),
                (wm['longitude'] as num).toDouble(),
              );
            }).toList();
            if (pts.length >= 2) {
              streetSegments.add(pts);
            }
          }
        }
        if (streetSegments.isNotEmpty) {
          instance.initializeGraph(streetSegments);
        }
      }
    } catch (_) {}
  }

  /// Initializes or updates the routing graph with segments from the repository.
  void initializeGraph([List<List<LatLng>>? segments]) {
    if (segments != null) {
      _streetSegments = segments;
    }
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
          }
          if (!_adjacency[j].any((e) => e.targetIndex == i)) {
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
    if (_nodes.isEmpty) return 0;
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
    if (_nodes.isEmpty) {
      ensureInitialized();
      if (_nodes.isEmpty) {
        return [start, destination];
      }
    }

    final startNodeIdx = _findNearestNodeIndex(start);
    final endNodeIdx = _findNearestNodeIndex(destination);

    if (startNodeIdx == endNodeIdx) {
      return [start, destination];
    }

    // Dijkstra's algorithm for shortest path
    final distances = List<double>.filled(_nodes.length, double.infinity);
    final previous = List<int?>.filled(_nodes.length, null);
    final visited = List<bool>.filled(_nodes.length, false);

    distances[startNodeIdx] = 0;

    for (var count = 0; count < _nodes.length; count++) {
      var minDistance = double.infinity;
      var u = -1;

      for (var i = 0; i < _nodes.length; i++) {
        if (!visited[i] && distances[i] < minDistance) {
          minDistance = distances[i];
          u = i;
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

    if (distances[endNodeIdx] == double.infinity) {
      // Fallback: direct line if no network path connects
      return [start, destination];
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
