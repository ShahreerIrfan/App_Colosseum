/// Centralized API configuration and endpoints.
/// Single source of truth: change [baseUrl] to point to VPS or local server.
abstract class ApiConstants {
  ApiConstants._();

  /// Centralized base URL for backend API.
  /// To update endpoint after deployment, modify only this string.
  static const String baseUrl = 'http://187.126.3.18:3000';

  /// Local development server (active with adb reverse tcp:3000 tcp:3000).
  static const String localBaseUrl = 'http://localhost:3000';

  /// Fallback LAN address when running on local Wi-Fi without adb reverse.
  static const String lanBaseUrl = 'http://192.168.0.116:3000';

  /// Remote live production VPS server.
  static const String vpsBaseUrl = baseUrl;

  /// Priority list of candidate backend hosts for resilient connectivity.
  /// Local LAN IP is prioritized so physical device over Wi-Fi connects instantly (<10ms).
  static const List<String> candidateBaseUrls = [
    lanBaseUrl,
    localBaseUrl,
    baseUrl,
  ];

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
