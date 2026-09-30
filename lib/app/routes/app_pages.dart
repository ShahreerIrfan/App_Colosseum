// ignore_for_file: constant_identifier_names

import 'package:get/get.dart';

import '../modules/floor_map/bindings/floor_map_binding.dart';
import '../modules/floor_map/views/floor_map_view.dart';
import '../modules/floors/bindings/floors_binding.dart';
import '../modules/floors/views/floors_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/language/bindings/language_binding.dart';
import '../modules/language/views/language_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.splash;

  static final routes = [
    GetPage(
      name: _Paths.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: _Paths.language,
      page: () => const LanguageView(),
      binding: LanguageBinding(),
    ),
    GetPage(
      name: _Paths.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.floors,
      page: () => const FloorsView(),
      binding: FloorsBinding(),
    ),
    GetPage(
      name: _Paths.floorMap,
      page: () => const FloorMapView(),
      binding: FloorMapBinding(),
    ),
  ];


  static List<GetPage> get pages => routes;
}
