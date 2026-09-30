import 'package:get/get.dart';

import '../controllers/floor_map_controller.dart';

/// Binding initializing the FloorMapController.
class FloorMapBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FloorMapController>(
      () => FloorMapController(),
    );
  }
}
