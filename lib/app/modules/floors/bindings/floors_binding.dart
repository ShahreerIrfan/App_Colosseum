import 'package:get/get.dart';

import '../controllers/floors_controller.dart';

class FloorsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FloorsController>(() => FloorsController());
  }
}
