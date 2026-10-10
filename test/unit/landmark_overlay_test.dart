import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:colosseum_client/app/core/utils/geodesic_utils.dart';
import 'package:colosseum_client/app/data/providers/colosseum_landmark_overlays.dart';

void main() {
  group('MapLandmarkOverlay and Geodesic Anchoring Tests', () {
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

    test('All 5 ColosseumLandmarkOverlays have valid calibrated configurations', () {
      final all = ColosseumLandmarkOverlays.all;
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
        expect(overlay.assetPath.endsWith('.png'), isTrue);
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

      // Proportional sizing check: Arch of Constantine must be smaller than Colosseum
      expect(
        ColosseumLandmarkOverlays.archOfConstantine.widthMeters,
        lessThan(ColosseumLandmarkOverlays.colosseum.widthMeters),
      );

      // Roman Forum Temple (Antoninus & Faustina) is a specific monument smaller than the Colosseum
      expect(
        ColosseumLandmarkOverlays.romanForum.widthMeters,
        lessThan(ColosseumLandmarkOverlays.colosseum.widthMeters),
      );
    });

    test('MapLandmarkOverlay copyWith works as expected', () {
      final original = ColosseumLandmarkOverlays.colosseum;
      final copied = original.copyWith(isVisible: false, opacity: 0.5);

      expect(copied.id, original.id);
      expect(copied.isVisible, isFalse);
      expect(copied.opacity, 0.5);
      expect(original.isVisible, isTrue);
    });
  });
}
