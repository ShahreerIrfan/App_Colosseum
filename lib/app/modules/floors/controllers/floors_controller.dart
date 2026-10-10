import 'package:get/get.dart';

import '../../../data/models/floor_model.dart';
import '../../../data/repositories/i_tour_repository.dart';
import '../../../data/repositories/tour_repository_impl.dart';
import '../../../data/services/visited_viewpoints_service.dart';
import '../../../routes/app_pages.dart';

class FloorsController extends GetxController {
  final landmarkName = 'Colosseum'.obs;
  final selectedFloorId = 'floor_underground'.obs;

  late final VisitedViewpointsService visitedService;
  final ITourRepository tourRepository;
  Worker? _visitedWorker;

  FloorsController({
    VisitedViewpointsService? visitedService,
    ITourRepository? tourRepository,
  }) : tourRepository = tourRepository ??
            (Get.isRegistered<ITourRepository>()
                ? Get.find<ITourRepository>()
                : TourRepositoryImpl()) {
    this.visitedService = visitedService ??
        (Get.isRegistered<VisitedViewpointsService>()
            ? Get.find<VisitedViewpointsService>()
            : Get.put(VisitedViewpointsService()));
  }

  final floors = <FloorModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args.containsKey('landmarkName')) {
      final customName = args['landmarkName']?.toString();
      if (customName != null && customName.isNotEmpty) {
        landmarkName.value = customName;
      }
    }

    refreshFloors();
    _loadRepositoryFloors();

    // Dynamically react whenever any viewpoint is visited / unvisited
    _visitedWorker = ever(
      visitedService.visitedViewpointIds,
      (_) => refreshFloors(),
    );
  }

  Future<void> _loadRepositoryFloors() async {
    try {
      final repoFloors = await tourRepository.getFloors();
      if (repoFloors.isNotEmpty) {
        final models = repoFloors.map((f) {
          final completed = visitedService.getCompletedCountForFloor(
              f.id, f.viewpoints.map((v) => v.id));
          return FloorModel(
            id: f.id,
            floorName: f.id == 'floor_underground'
                ? 'Underground (Hypogeum)'
                : (f.floorNumberLabel.isNotEmpty
                    ? f.floorNumberLabel
                    : f.displayName),
            viewpointCount: f.viewpoints.length,
            completedCount: completed,
          );
        }).toList();
        floors.assignAll(models);
        return;
      }
    } catch (_) {}

    floors.assignAll([
      _buildFloorModel('floor_underground', 'Underground (Hypogeum)'),
      _buildFloorModel('floor_1', 'Floor 1'),
      _buildFloorModel('floor_2', 'Floor 2'),
      _buildFloorModel('floor_3', 'Floor 3'),
    ]);
  }

  @override
  void onReady() {
    super.onReady();
    refreshFloors();
  }

  @override
  void onClose() {
    _visitedWorker?.dispose();
    super.onClose();
  }

  /// Refreshes all floor models with live viewpoint counts and completed visited counts.
  void refreshFloors() {
    floors.assignAll([
      _buildFloorModel('floor_underground', 'Underground (Hypogeum)'),
      _buildFloorModel('floor_1', 'Floor 1'),
      _buildFloorModel('floor_2', 'Floor 2'),
      _buildFloorModel('floor_3', 'Floor 3'),
    ]);
    _loadRepositoryFloors();
  }

  FloorModel _buildFloorModel(String id, String name, [int? customCount]) {
    final count = customCount ?? _getDefaultViewpointCount(id);
    final completed = visitedService.getCompletedCountForFloor(id);
    return FloorModel(
      id: id,
      floorName: name,
      viewpointCount: count,
      completedCount: completed,
    );
  }

  static int _getDefaultViewpointCount(String id) {
    if (id.contains('underground') || id == '0') return 7;
    if (id.contains('2')) return 7;
    if (id.contains('3')) return 5;
    return 9;
  }

  void selectFloor(String id) {
    selectedFloorId.value = id;
    final floor = floors.firstWhereOrNull((f) => f.id == id);
    Get.toNamed(
      Routes.floorMap,
      arguments: {
        'landmarkName': landmarkName.value,
        'floorId': id,
        'floorName': floor?.floorName ?? 'Floor 1',
      },
    );
  }
}
