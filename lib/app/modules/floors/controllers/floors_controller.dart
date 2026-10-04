import 'package:get/get.dart';

import '../../../data/models/floor_model.dart';
import '../../../data/providers/colosseum_tour_data.dart';
import '../../../data/services/visited_viewpoints_service.dart';
import '../../../routes/app_pages.dart';

class FloorsController extends GetxController {
  final landmarkName = 'Colosseum'.obs;
  final selectedFloorId = 'floor_underground'.obs;

  late final VisitedViewpointsService visitedService;
  Worker? _visitedWorker;

  FloorsController({VisitedViewpointsService? visitedService}) {
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

    // Dynamically react whenever any viewpoint is visited / unvisited
    _visitedWorker = ever(
      visitedService.visitedViewpointIds,
      (_) => refreshFloors(),
    );
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
  }

  FloorModel _buildFloorModel(String id, String name) {
    final vps = ColosseumTourData.getViewpointsForFloor(id);
    final count = vps.length;
    final completed = visitedService.getCompletedCountForFloor(id);
    return FloorModel(
      id: id,
      floorName: name,
      viewpointCount: count,
      completedCount: completed,
    );
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
