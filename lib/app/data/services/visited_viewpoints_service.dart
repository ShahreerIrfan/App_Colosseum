import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/colosseum_tour_data.dart';

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

  /// Returns the set of visited viewpoint IDs belonging to the given floor.
  Set<String> getVisitedForFloor(String floorId) {
    final floorVps = ColosseumTourData.getViewpointsForFloor(floorId);
    final floorIds = floorVps.map((vp) => vp.id).toSet();
    return visitedViewpointIds.intersection(floorIds);
  }

  /// Returns the total count of completed (visited) viewpoints on a given floor.
  int getCompletedCountForFloor(String floorId) {
    return getVisitedForFloor(floorId).length;
  }

  /// Clears visited viewpoints belonging to a specific floor level.
  Future<void> clearFloor(String floorId) async {
    final floorVps = ColosseumTourData.getViewpointsForFloor(floorId);
    final floorIds = floorVps.map((vp) => vp.id).toSet();
    visitedViewpointIds.removeAll(floorIds);
    await _persist();
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
