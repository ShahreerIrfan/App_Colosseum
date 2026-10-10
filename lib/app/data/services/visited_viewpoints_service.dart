import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized persistent service that tracks and synchronizes visited viewpoints
/// across all Colosseum floors, backed by device local storage (SharedPreferences).
class VisitedViewpointsService extends GetxService {
  static const String storageKey = 'colosseum_visited_viewpoint_ids';

  SharedPreferences? _prefs;

  /// Observable set of all viewpoint IDs marked as visited across the entire monument.
  final RxSet<String> visitedViewpointIds = <String>{}.obs;

  /// Initializes the service and restores persisted visited viewpoints from disk.
  Future<VisitedViewpointsService> init({SharedPreferences? prefs}) async {
    try {
      _prefs = prefs ?? await SharedPreferences.getInstance();
      final savedList = _prefs?.getStringList(storageKey) ?? [];
      visitedViewpointIds.assignAll(savedList);
      debugPrint('VisitedViewpointsService loaded ${visitedViewpointIds.length} visited viewpoints.');
    } catch (e) {
      debugPrint('VisitedViewpointsService init error: $e');
    }
    return this;
  }

  /// Checks whether a specific viewpoint has been marked as visited.
  bool isVisited(String viewpointId) {
    return visitedViewpointIds.contains(viewpointId);
  }

  /// Marks a viewpoint as visited and persists the change to storage.
  Future<void> markVisited(String viewpointId) async {
    if (!visitedViewpointIds.contains(viewpointId)) {
      visitedViewpointIds.add(viewpointId);
      await _persist();
    }
  }

  /// Unmarks a viewpoint as visited and persists the change to storage.
  Future<void> unmarkVisited(String viewpointId) async {
    if (visitedViewpointIds.contains(viewpointId)) {
      visitedViewpointIds.remove(viewpointId);
      await _persist();
    }
  }

  /// Toggles the visited state for a viewpoint.
  Future<void> toggleVisited(String viewpointId) async {
    if (isVisited(viewpointId)) {
      await unmarkVisited(viewpointId);
    } else {
      await markVisited(viewpointId);
    }
  }

  final Map<String, Set<String>> _floorViewpointMap = {};

  /// Dynamically registers viewpoint IDs for a floor from repository / Hive data.
  void registerFloorViewpoints(String floorId, Iterable<String> viewpointIds) {
    _floorViewpointMap[floorId] = viewpointIds.toSet();
  }

  /// Returns the set of visited viewpoint IDs belonging to the given floor.
  Set<String> getVisitedForFloor(String floorId, [Iterable<String>? knownViewpointIds]) {
    if (knownViewpointIds != null) {
      registerFloorViewpoints(floorId, knownViewpointIds);
    }
    final floorIds = _floorViewpointMap[floorId] ?? _getFallbackViewpointIds(floorId);
    return visitedViewpointIds.intersection(floorIds);
  }

  /// Returns the total count of completed (visited) viewpoints on a given floor.
  int getCompletedCountForFloor(String floorId, [Iterable<String>? knownViewpointIds]) {
    return getVisitedForFloor(floorId, knownViewpointIds).length;
  }

  /// Clears visited viewpoints belonging to a specific floor level.
  Future<void> clearFloor(String floorId, [Iterable<String>? knownViewpointIds]) async {
    final floorIds = _floorViewpointMap[floorId] ??
        knownViewpointIds?.toSet() ??
        _getFallbackViewpointIds(floorId);
    visitedViewpointIds.removeAll(floorIds);
    await _persist();
  }

  /// Default heuristic fallback for viewpoint IDs per floor
  static Set<String> _getFallbackViewpointIds(String floorId) {
    if (floorId.contains('underground') || floorId == '0') {
      return {
        'vp_100', 'vp_101', 'vp_102', 'vp_103', 'vp_104', 'vp_105', 'vp_106'
      };
    } else if (floorId.contains('2') || floorId == 'floor_2') {
      return {
        'vp_300', 'vp_301', 'vp_302', 'vp_303', 'vp_304', 'vp_305', 'vp_306'
      };
    } else if (floorId.contains('3') || floorId == 'floor_3') {
      return {'vp_400', 'vp_401', 'vp_402', 'vp_403', 'vp_404'};
    } else {
      return {
        'vp_200', 'vp_201', 'vp_202', 'vp_203', 'vp_204', 'vp_205', 'vp_206',
        'vp_207', 'vp_208'
      };
    }
  }

  /// Clears all visited viewpoints across all floors.
  Future<void> clearAll() async {
    visitedViewpointIds.clear();
    await _persist();
  }

  /// Test helper to synchronously populate visited IDs in headless test environments.
  @visibleForTesting
  void setVisitedIdsForTesting(Iterable<String> ids) {
    visitedViewpointIds.assignAll(ids);
  }

  Future<void> _persist() async {
    try {
      if (_prefs != null) {
        await _prefs!.setStringList(storageKey, visitedViewpointIds.toList());
      }
    } catch (e) {
      debugPrint('VisitedViewpointsService persist error: $e');
    }
  }
}
