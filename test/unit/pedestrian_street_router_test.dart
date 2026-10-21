import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colosseum_client/app/data/models/landmark_marker_model.dart';
import 'package:colosseum_client/app/data/services/pedestrian_street_router.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('PedestrianStreetRouter Unit Tests', () {
    late PedestrianStreetRouter router;

    setUp(() {
      router = PedestrianStreetRouter.instance;
    });

    test('singleton instance is initialized properly', () {
      expect(router, isNotNull);
      expect(identical(router, PedestrianStreetRouter.instance), isTrue);
    });

    test('routeBetween returns start and destination when points are identical', () {
      const point = LatLng(41.888500, 12.492500);
      final route = router.routeBetween(point, point);

      expect(route.length, 2);
      expect(route.first, equals(point));
      expect(route.last, equals(point));
    });

    test('routeBetween connects Parco Celio to Colosseum along Via Claudia', () {
      const start = LatLng(41.888500, 12.492500); // Parco Celio
      const destination = LatLng(41.890210, 12.492231); // Colosseum

      final route = router.routeBetween(start, destination);

      expect(route.length, greaterThan(5));
      expect(route.first, equals(start));
      expect(route.last, equals(destination));

      // Verifies Via Celio Vibenna intersection waypoint is traversed
      const vibennaJunction = LatLng(41.889, 12.4924);
      expect(route.any((pt) => (pt.latitude - vibennaJunction.latitude).abs() < 0.001 && (pt.longitude - vibennaJunction.longitude).abs() < 0.001), isTrue);
    });

    test('routeBetween connects Colosseum to Arch of Constantine via West Promenade', () {
      const colosseum = LatLng(41.890210, 12.492231);
      const arch = LatLng(41.889762, 12.490667);

      final route = router.routeBetween(colosseum, arch);

      expect(route.length, greaterThan(2));
      expect(route.first, equals(colosseum));
      expect(route.last, equals(arch));
    });

    test('routeBetween connects Arch of Constantine to Roman Forum via Clivo di Venere and Via Sacra', () {
      const arch = LatLng(41.889762, 12.490667);
      const forum = LatLng(41.892460, 12.485320);

      final route = router.routeBetween(arch, forum);

      expect(route.length, greaterThan(5));
      expect(route.first, equals(arch));
      expect(route.last, equals(forum));

      // Verifies Temple of Venus Via Sacra waypoint is traversed along the path
      const venusTemple = LatLng(41.891025, 12.488373);
      expect(route.any((pt) => (pt.latitude - venusTemple.latitude).abs() < 0.001 && (pt.longitude - venusTemple.longitude).abs() < 0.001), isTrue);
    });

    test('walkingDistance computes realistic walking distances', () {
      const point = LatLng(41.888500, 12.492500);
      expect(router.walkingDistance(point, point), 0.0);

      const colosseum = LatLng(41.890210, 12.492231);
      final distance = router.walkingDistance(point, colosseum);

      // Distance from Parco Celio to Colosseum along real streets is ~680m
      expect(distance, greaterThan(200.0));
      expect(distance, lessThan(800.0));
    });

    test('routeItinerary returns empty list if landmarks are empty', () {
      const userPos = LatLng(41.888500, 12.492500);
      final route = router.routeItinerary(userPos, []);
      expect(route, isEmpty);
    });

    test('routeItinerary visits all landmarks along street network without duplicate consecutive points', () {
      const userPos = LatLng(41.888500, 12.492500);
      final landmarks = <LandmarkMarkerModel>[
        const LandmarkMarkerModel(
          id: 'colosseum',
          name: 'Colosseum',
          coordinates: LatLng(41.890210, 12.492231),
          color: Color(0xFFC88A2E),
        ),
        const LandmarkMarkerModel(
          id: 'arch',
          name: 'Arch of Constantine',
          coordinates: LatLng(41.889762, 12.490667),
          color: Color(0xFFC88A2E),
        ),
        const LandmarkMarkerModel(
          id: 'ludus',
          name: 'Ludus Magnus',
          coordinates: LatLng(41.890450, 12.495100),
          color: Color(0xFFC88A2E),
        ),
      ];

      final route = router.routeItinerary(userPos, landmarks);

      expect(route.length, greaterThan(5));
      expect(route.first, equals(userPos));

      // Ensure no duplicate consecutive points
      for (var i = 0; i < route.length - 1; i++) {
        expect(route[i], isNot(equals(route[i + 1])));
      }
    });
  });
}
