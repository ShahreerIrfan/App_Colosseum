// ignore_for_file: constant_identifier_names

part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const splash = _Paths.splash;
  static const language = _Paths.language;
  static const home = _Paths.home;

  // Compatibility aliases
  static const SPLASH = _Paths.splash;
  static const LANGUAGE = _Paths.language;
  static const HOME = _Paths.home;
}

abstract class _Paths {
  _Paths._();
  static const splash = '/splash';
  static const language = '/language';
  static const home = '/home';
}
