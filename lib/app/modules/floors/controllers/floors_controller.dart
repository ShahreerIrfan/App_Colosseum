import 'package:get/get.dart';

import '../../../data/models/floor_model.dart';
import '../../../routes/app_pages.dart';

class FloorsController extends GetxController {
  final landmarkName = 'Colosseum'.obs;
  final selectedFloorId = 'floor_underground'.obs;

  final floors = <FloorModel>[
    const FloorModel(
      id: 'floor_underground',
      floorName: 'Underground (Hypogeum)',
      viewpointCount: 7,
      isCompleted: true,
    ),
    const FloorModel(
      id: 'floor_1',
      floorName: 'Floor 1',
      viewpointCount: 9,
    ),
    const FloorModel(
      id: 'floor_2',
      floorName: 'Floor 2',
      viewpointCount: 7,
    ),
    const FloorModel(
      id: 'floor_3',
      floorName: 'Floor 3',
      viewpointCount: 5,
    ),
  ].obs;

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
