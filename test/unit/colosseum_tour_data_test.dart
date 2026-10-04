import 'package:flutter_test/flutter_test.dart';
import 'package:colosseum_client/app/data/providers/colosseum_tour_data.dart';

void main() {
  group('ColosseumTourData Dataset Verification Tests', () {
    test('verifies all 28 viewpoints across all 4 levels are uniquely identified', () {
      final allViewpoints = [
        ...ColosseumTourData.undergroundViewpoints,
        ...ColosseumTourData.level1Viewpoints,
        ...ColosseumTourData.level2Viewpoints,
        ...ColosseumTourData.level3Viewpoints,
      ];

      expect(allViewpoints.length, 28);

      final uniqueIds = allViewpoints.map((vp) => vp.id).toSet();
      expect(uniqueIds.length, 28, reason: 'Every viewpoint ID across all floors must be unique');

      for (final vp in allViewpoints) {
        expect(vp.title.isNotEmpty, isTrue, reason: '${vp.id} title must not be empty');
        expect(vp.description.isNotEmpty, isTrue, reason: '${vp.id} description must not be empty');
        expect(vp.latLng.latitude, inInclusiveRange(41.888, 41.892), reason: '${vp.id} lat out of Colosseum range');
        expect(vp.latLng.longitude, inInclusiveRange(12.490, 12.495), reason: '${vp.id} lon out of Colosseum range');
        expect(vp.audioDuration.isNotEmpty, isTrue, reason: '${vp.id} audioDuration must be defined');
        expect(vp.order, greaterThan(0), reason: '${vp.id} order must be positive');
      }
    });

    test('verifies Level Underground has 7 viewpoints (100-106) and 6 itinerary segments', () {
      final vps = ColosseumTourData.undergroundViewpoints;
      expect(vps.length, 7);
      expect(vps.first.order, 100);
      expect(vps.last.order, 106);

      final itinerary = ColosseumTourData.undergroundItinerary;
      expect(itinerary.length, 6);
      expect(itinerary.first.fromId, 'vp_100');
      expect(itinerary.first.toId, 'vp_101');
      expect(itinerary.last.fromId, 'vp_105');
      expect(itinerary.last.toId, 'vp_106');
    });

    test('verifies Level 1 has 9 viewpoints (200-208) and 8 itinerary segments', () {
      final vps = ColosseumTourData.level1Viewpoints;
      expect(vps.length, 9);
      expect(vps.first.order, 200);
      expect(vps.last.order, 208);

      final itinerary = ColosseumTourData.level1Itinerary;
      expect(itinerary.length, 8);
      expect(itinerary.first.fromId, 'vp_200');
      expect(itinerary.first.toId, 'vp_201');
      expect(itinerary.last.fromId, 'vp_207');
      expect(itinerary.last.toId, 'vp_208');
    });

    test('verifies Level 2 has 7 viewpoints (300-306) and 6 itinerary segments', () {
      final vps = ColosseumTourData.level2Viewpoints;
      expect(vps.length, 7);
      expect(vps.first.order, 300);
      expect(vps.last.order, 306);

      final itinerary = ColosseumTourData.level2Itinerary;
      expect(itinerary.length, 6);
      expect(itinerary.first.fromId, 'vp_300');
      expect(itinerary.first.toId, 'vp_301');
      expect(itinerary.last.fromId, 'vp_305');
      expect(itinerary.last.toId, 'vp_306');
    });

    test('verifies Level 3 has 5 viewpoints (400-404) and 4 itinerary segments', () {
      final vps = ColosseumTourData.level3Viewpoints;
      expect(vps.length, 5);
      expect(vps.first.order, 400);
      expect(vps.last.order, 404);

      final itinerary = ColosseumTourData.level3Itinerary;
      expect(itinerary.length, 4);
      expect(itinerary.first.fromId, 'vp_400');
      expect(itinerary.first.toId, 'vp_401');
      expect(itinerary.last.fromId, 'vp_403');
      expect(itinerary.last.toId, 'vp_404');
    });
  });
}
