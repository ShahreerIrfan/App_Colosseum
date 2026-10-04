import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosseum_client/app/data/services/visited_viewpoints_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VisitedViewpointsService Unit Tests', () {
    late VisitedViewpointsService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = VisitedViewpointsService();
      await service.init();
    });

    test('initializes with empty visited viewpoints', () {
      expect(service.visitedViewpointIds, isEmpty);
      expect(service.isVisited('vp_100'), isFalse);
      expect(service.getCompletedCountForFloor('floor_underground'), equals(0));
    });

    test('markVisited adds viewpoint and persists to storage', () async {
      await service.markVisited('vp_100');
      expect(service.isVisited('vp_100'), isTrue);
      expect(service.visitedViewpointIds, contains('vp_100'));
      expect(service.getCompletedCountForFloor('floor_underground'), equals(1));

      // Mark another viewpoint on same floor
      await service.markVisited('vp_101');
      expect(service.getCompletedCountForFloor('floor_underground'), equals(2));

      // Mark viewpoint on another floor
      await service.markVisited('vp_200');
      expect(service.getCompletedCountForFloor('floor_1'), equals(1));
      expect(service.getCompletedCountForFloor('floor_underground'), equals(2));
    });

    test('unmarkVisited removes viewpoint and updates count', () async {
      await service.markVisited('vp_100');
      await service.markVisited('vp_101');
      expect(service.getCompletedCountForFloor('floor_underground'), equals(2));

      await service.unmarkVisited('vp_100');
      expect(service.isVisited('vp_100'), isFalse);
      expect(service.isVisited('vp_101'), isTrue);
      expect(service.getCompletedCountForFloor('floor_underground'), equals(1));
    });

    test('toggleVisited flips visited status', () async {
      expect(service.isVisited('vp_102'), isFalse);

      await service.toggleVisited('vp_102');
      expect(service.isVisited('vp_102'), isTrue);

      await service.toggleVisited('vp_102');
      expect(service.isVisited('vp_102'), isFalse);
    });

    test('getVisitedForFloor correctly returns only viewpoints for that floor', () async {
      await service.markVisited('vp_100');
      await service.markVisited('vp_101');
      await service.markVisited('vp_200');
      await service.markVisited('vp_300');

      final undergroundVisited = service.getVisitedForFloor('floor_underground');
      expect(undergroundVisited, equals({'vp_100', 'vp_101'}));

      final floor1Visited = service.getVisitedForFloor('floor_1');
      expect(floor1Visited, equals({'vp_200'}));

      final floor2Visited = service.getVisitedForFloor('floor_2');
      expect(floor2Visited, equals({'vp_300'}));

      final floor3Visited = service.getVisitedForFloor('floor_3');
      expect(floor3Visited, isEmpty);
    });

    test('clearFloor removes only viewpoints belonging to that floor', () async {
      await service.markVisited('vp_100');
      await service.markVisited('vp_101');
      await service.markVisited('vp_200');

      await service.clearFloor('floor_underground');
      expect(service.getCompletedCountForFloor('floor_underground'), equals(0));
      expect(service.isVisited('vp_100'), isFalse);
      expect(service.isVisited('vp_101'), isFalse);
      expect(service.isVisited('vp_200'), isTrue);
      expect(service.getCompletedCountForFloor('floor_1'), equals(1));
    });

    test('restores saved visited viewpoints from SharedPreferences on init', () async {
      SharedPreferences.setMockInitialValues({
        VisitedViewpointsService.storageKey: ['vp_100', 'vp_102', 'vp_104', 'vp_105', 'vp_106'],
      });

      final newService = VisitedViewpointsService();
      await newService.init();

      expect(newService.visitedViewpointIds.length, equals(5));
      expect(newService.getCompletedCountForFloor('floor_underground'), equals(5));
      expect(newService.isVisited('vp_100'), isTrue);
      expect(newService.isVisited('vp_101'), isFalse);
      expect(newService.isVisited('vp_102'), isTrue);
    });
  });
}
