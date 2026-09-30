import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class HomeController extends GetxController {
  late final MapController mapController;

  static const LatLng colosseumCoordinates = LatLng(41.890210, 12.492231);
  static const double defaultZoom = 16.5;

  final currentZoom = defaultZoom.obs;

  @override
  void onInit() {
    super.onInit();
    mapController = MapController();
  }

  void onPositionChanged(MapCamera camera, bool hasGesture) {
    currentZoom.value = camera.zoom;
  }

  void centerOnColosseum() {
    try {
      mapController.move(colosseumCoordinates, defaultZoom);
    } catch (_) {
      // MapController is only attached when FlutterMap is rendered
    }
  }


  @override
  void onClose() {
    mapController.dispose();
    super.onClose();
  }
}

