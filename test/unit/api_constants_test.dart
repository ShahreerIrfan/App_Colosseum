import 'package:flutter_test/flutter_test.dart';
import 'package:colosseum_client/app/core/constants/api_constants.dart';

void main() {
  group('ApiConstants Tests', () {
    test('baseUrl matches configured fixed IP endpoint', () {
      expect(ApiConstants.baseUrl, equals('http://192.168.0.116:3000'));
    });

    test('apiV1 prepends baseUrl correctly', () {
      expect(ApiConstants.apiV1, equals('http://192.168.0.116:3000/api/v1'));
    });

    test('core API endpoints are properly defined', () {
      expect(ApiConstants.tourBundle,
          equals('http://192.168.0.116:3000/api/v1/tours/bundle'));
      expect(ApiConstants.syncManifest,
          equals('http://192.168.0.116:3000/api/v1/sync/manifest'));
      expect(ApiConstants.floors,
          equals('http://192.168.0.116:3000/api/v1/floors'));
      expect(ApiConstants.landmarks,
          equals('http://192.168.0.116:3000/api/v1/landmarks'));
      expect(ApiConstants.languages,
          equals('http://192.168.0.116:3000/api/v1/languages'));
      expect(ApiConstants.validateTicket,
          equals('http://192.168.0.116:3000/api/v1/tickets/validate'));
    });

    test('dynamic URL helpers format parameters accurately', () {
      expect(
        ApiConstants.tourBundleUrl(lang: 'it'),
        equals('http://192.168.0.116:3000/api/v1/tours/bundle?lang=it'),
      );
      expect(
        ApiConstants.floorDetail('floor_1', lang: 'fr'),
        equals('http://192.168.0.116:3000/api/v1/floors/floor_1?lang=fr'),
      );
      expect(
        ApiConstants.landmarkDetail('colosseum'),
        equals('http://192.168.0.116:3000/api/v1/landmarks/colosseum'),
      );
    });
  });
}
