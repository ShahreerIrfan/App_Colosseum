import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:colosseum_client/app/core/utils/geodesic_utils.dart';
import 'package:colosseum_client/app/data/datasources/local/tour_local_data_source.dart';
import 'package:colosseum_client/app/data/models/landmark_overlay_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapLandmarkOverlay and Geodesic Anchoring Tests', () {
    late TourLocalDataSource localDataSource;

    setUp(() {
      localDataSource = TourLocalDataSource();
    });

    test('Calculates rotated corners correctly from metric dimensions and orientation', () {
      const center = LatLng(41.890320, 12.492180);
      final corners = GeodesicUtils.calculateRotatedCorners(
        center: center,
        widthMeters: 195.0,
        heightMeters: 165.0,
        rotationDegrees: -34.0,
      );

      expect(corners.topLeft.latitude, greaterThan(41.8900));
      expect(corners.bottomRight.latitude, lessThan(corners.topLeft.latitude));
      expect(corners.bottomRight.longitude, greaterThan(corners.topLeft.longitude));

      final bounds = corners.bounds;
      expect(bounds.north, greaterThan(center.latitude));
      expect(bounds.south, lessThan(center.latitude));
      expect(bounds.east, greaterThan(center.longitude));
      expect(bounds.west, lessThan(center.longitude));
    });

    test('All 5 MapLandmarkOverlays loaded from seed have valid calibrated configurations', () async {
      final all = await localDataSource.getCachedLandmarkOverlays();
      expect(all.length, 5);

      final ids = all.map((o) => o.id).toSet();
      expect(ids, {
        'roman_forum',
        'temple_venus_rome',
        'colosseum',
        'ludus_magnus',
        'arch_of_constantine',
      });

      for (final overlay in all) {
        expect(overlay.name.isNotEmpty, isTrue);
        expect(overlay.center.latitude, closeTo(41.89, 0.01));
        expect(overlay.center.longitude, closeTo(12.49, 0.01));
        expect(overlay.widthMeters, greaterThan(0));
        expect(overlay.heightMeters, greaterThan(0));
        expect(overlay.minZoom, lessThan(overlay.maxZoom));
        expect(overlay.isVisible, isTrue);

        final corners = overlay.rotatedCorners;
        expect(corners.topLeft, isNotNull);
        expect(corners.bottomLeft, isNotNull);
        expect(corners.bottomRight, isNotNull);
        expect(corners.topRight, isNotNull);

        final bounds = overlay.geographicBounds;
        expect(bounds.north, greaterThan(bounds.south));
        expect(bounds.east, greaterThan(bounds.west));
      }

      final colosseum = all.firstWhere((o) => o.id == 'colosseum');
      final arch = all.firstWhere((o) => o.id == 'arch_of_constantine');
      final romanForum = all.firstWhere((o) => o.id == 'roman_forum');

      // Proportional sizing check: Arch of Constantine must be smaller than Colosseum
      expect(arch.widthMeters, lessThan(colosseum.widthMeters));

      // Roman Forum archaeological complex is larger than the Colosseum
      expect(colosseum.widthMeters, lessThan(romanForum.widthMeters));
    });

    test('MapLandmarkOverlay copyWith works as expected', () {
      const original = MapLandmarkOverlay(
        id: 'colosseum',
        name: 'Colosseum',
        assetPath: 'assets/floor_map/floor_level_1.svg',
        center: LatLng(41.89021, 12.492231),
        widthMeters: 190.0,
        heightMeters: 155.0,
      );
      final copied = original.copyWith(isVisible: false, opacity: 0.5);

      expect(copied.id, original.id);
      expect(copied.isVisible, isFalse);
      expect(copied.opacity, 0.5);
      expect(original.isVisible, isTrue);
    });
  });
}
