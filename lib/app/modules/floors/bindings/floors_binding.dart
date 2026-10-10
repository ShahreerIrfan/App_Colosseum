import 'package:get/get.dart';

import '../../../data/repositories/i_tour_repository.dart';
import '../../../data/repositories/tour_repository_impl.dart';
import '../controllers/floors_controller.dart';

class FloorsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ITourRepository>()) {
      Get.lazyPut<ITourRepository>(() => TourRepositoryImpl());
    }
    Get.lazyPut<FloorsController>(() => FloorsController());
  }
}
