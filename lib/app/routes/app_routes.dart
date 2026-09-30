// ignore_for_file: constant_identifier_names

part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const splash = _Paths.splash;
  static const language = _Paths.language;
  static const home = _Paths.home;
  static const floors = _Paths.floors;
  static const floorMap = _Paths.floorMap;

  // Compatibility aliases
  static const SPLASH = _Paths.splash;
  static const LANGUAGE = _Paths.language;
  static const HOME = _Paths.home;
  static const FLOORS = _Paths.floors;
  static const FLOOR_MAP = _Paths.floorMap;
}

abstract class _Paths {
  _Paths._();
  static const splash = '/splash';
  static const language = '/language';
  static const home = '/home';
  static const floors = '/floors';
  static const floorMap = '/floor-map';
}

