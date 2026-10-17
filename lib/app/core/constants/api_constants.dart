/// Centralized API configuration and endpoints.
/// Single source of truth: change [baseUrl] to point to VPS or local server.
abstract class ApiConstants {
  ApiConstants._();

  /// Centralized base URL for backend API.
  /// To update endpoint after deployment, modify only this string.
  static const String baseUrl = 'http://187.126.3.18:3000';

  /// API version path prefix
  static const String apiV1 = '$baseUrl/api/v1';

  // Core tour endpoints
  static const String tourBundle = '$apiV1/tours/bundle';
  static const String syncManifest = '$apiV1/sync/manifest';
  static const String floors = '$apiV1/floors';
  static const String landmarks = '$apiV1/landmarks';
  static const String languages = '$apiV1/languages';
  static const String validateTicket = '$apiV1/tickets/validate';
  static const String pedestrianRoutes = '$apiV1/routes/pedestrian';
  static const String parkConfig = '$apiV1/park/config';

  /// Helper to get tour bundle URL with language parameter
  static String tourBundleUrl({String lang = 'en'}) =>
      '$tourBundle?lang=$lang';

  /// Helper to get floor detail URL
  static String floorDetail(String floorId, {String lang = 'en'}) =>
      '$floors/$floorId?lang=$lang';

  /// Helper to get landmark detail URL
  static String landmarkDetail(String landmarkId) =>
      '$landmarks/$landmarkId';
}
