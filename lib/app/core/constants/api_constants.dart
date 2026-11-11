/// Centralized API configuration and endpoints.
abstract class ApiConstants {
  ApiConstants._();

  /// Centralized base URL for backend API.
  static const String baseUrl = String.fromEnvironment('COLOSSEUM_API_URL',
    defaultValue: 'http://187.126.3.18:3000');

  /// Local development server (active with adb reverse tcp:3000 tcp:3000).
  static const String localBaseUrl = 'http://localhost:3000';

  /// Fallback LAN address when running on local Wi-Fi without adb reverse.
  static const String lanBaseUrl = 'http://192.168.0.116:3000';

  /// Remote live production VPS server.
  static const String vpsBaseUrl = baseUrl;

  /// Development servers must be selected explicitly via COLOSSEUM_API_URL.
  static const List<String> candidateBaseUrls = [baseUrl];

  /// API version path prefix
  static const String apiV1 = '$baseUrl/api/v1';

  // Core tour endpoints
  static const String tourBundle = '$apiV1/tours/bundle';
  static const String syncManifest = '$apiV1/sync/manifest';
  static const String floors = '$apiV1/floors';
  static const String viewpoints = '$apiV1/viewpoints';
  static const String landmarks = '$apiV1/landmarks';
  static const String languages = '$apiV1/languages';
  static const String validateTicket = '$apiV1/tickets/validate';
  static const String pedestrianRoutes = '$apiV1/routes/pedestrian';

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
