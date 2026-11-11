import 'package:flutter_test/flutter_test.dart';
import 'package:colosseum_client/app/data/models/floor_definition.dart';

void main() {
  group('FloorDefinition Multi-Monument Resolution Tests', () {
    test('initialFloorForLandmark resolves correct entrance floor for each monument', () {
      final colosseumFloor = FloorDefinition.initialFloorForLandmark('colosseum');
      expect(colosseumFloor.id, 'floor_underground');
      expect(colosseumFloor.landmarkId, 'colosseum');

      final archFloor = FloorDefinition.initialFloorForLandmark('arch_of_constantine');
      expect(archFloor.id, 'arch_ground');
      expect(archFloor.landmarkId, 'arch_of_constantine');

      final ludusFloor = FloorDefinition.initialFloorForLandmark('ludus_magnus');
      expect(ludusFloor.id, 'ludus_arena');
      expect(ludusFloor.landmarkId, 'ludus_magnus');

      final templeFloor = FloorDefinition.initialFloorForLandmark('temple_venus_rome');
      expect(templeFloor.id, 'temple_east');
      expect(templeFloor.landmarkId, 'temple_venus_rome');

      final forumFloor = FloorDefinition.initialFloorForLandmark('roman_forum');
      expect(forumFloor.id, 'forum_via_sacra');
      expect(forumFloor.landmarkId, 'roman_forum');
    });

    test('initialFloorForLandmark handles naming variations and aliases correctly', () {
      final templeAlias = FloorDefinition.initialFloorForLandmark('temple_of_venus_and_rome');
      expect(templeAlias.id, 'temple_east');
      expect(templeAlias.landmarkId, 'temple_venus_rome');

      final archAlias = FloorDefinition.initialFloorForLandmark('arch');
      expect(archAlias.id, 'arch_ground');
      expect(archAlias.landmarkId, 'arch_of_constantine');
    });

    test('floorsForLandmark returns only floors belonging to that specific monument', () {
      final archFloors = FloorDefinition.floorsForLandmark('arch_of_constantine');
      expect(archFloors.every((f) => f.landmarkId == 'arch_of_constantine'), isTrue);
      expect(archFloors.map((f) => f.id), containsAll(['arch_ground', 'arch_attic']));

      final templeFloors = FloorDefinition.floorsForLandmark('temple_venus_rome');
      expect(templeFloors.every((f) => f.landmarkId == 'temple_venus_rome'), isTrue);
      expect(templeFloors.map((f) => f.id), containsAll(['temple_east', 'temple_west']));

      final ludusFloors = FloorDefinition.floorsForLandmark('ludus_magnus');
      expect(ludusFloors.every((f) => f.landmarkId == 'ludus_magnus'), isTrue);
      expect(ludusFloors.map((f) => f.id), containsAll(['ludus_arena', 'ludus_tunnel']));

      final forumFloors = FloorDefinition.floorsForLandmark('roman_forum');
      expect(forumFloors.every((f) => f.landmarkId == 'roman_forum'), isTrue);
      expect(forumFloors.map((f) => f.id), containsAll(['forum_via_sacra', 'forum_senate_rostra']));
    });

    test('fromId correctly resolves monument specific floors and does not fallback to Colosseum', () {
      expect(FloorDefinition.fromId('arch_ground').landmarkId, 'arch_of_constantine');
      expect(FloorDefinition.fromId('arch_attic').landmarkId, 'arch_of_constantine');
      expect(FloorDefinition.fromId('ludus_arena').landmarkId, 'ludus_magnus');
      expect(FloorDefinition.fromId('ludus_tunnel').landmarkId, 'ludus_magnus');
      expect(FloorDefinition.fromId('temple_east').landmarkId, 'temple_venus_rome');
      expect(FloorDefinition.fromId('temple_west').landmarkId, 'temple_venus_rome');
      expect(FloorDefinition.fromId('forum_via_sacra').landmarkId, 'roman_forum');
      expect(FloorDefinition.fromId('forum_senate_rostra').landmarkId, 'roman_forum');
    });

    test('stopsCount returns accurate calibrated stops for all monument levels', () {
      expect(FloorDefinition.fromId('forum_via_sacra').stopsCount, 4);
      expect(FloorDefinition.fromId('forum_senate_rostra').stopsCount, 3);
      expect(FloorDefinition.fromId('temple_east').stopsCount, 3);
      expect(FloorDefinition.fromId('temple_west').stopsCount, 2);
      expect(FloorDefinition.fromId('arch_ground').stopsCount, 4);
      expect(FloorDefinition.fromId('arch_attic').stopsCount, 2);
      expect(FloorDefinition.fromId('ludus_arena').stopsCount, 3);
      expect(FloorDefinition.fromId('ludus_tunnel').stopsCount, 2);
      expect(FloorDefinition.fromId('floor_underground').stopsCount, 7);
      expect(FloorDefinition.fromId('floor_1').stopsCount, 9);
      expect(FloorDefinition.fromId('floor_2').stopsCount, 7);
      expect(FloorDefinition.fromId('floor_3').stopsCount, 5);
    });

    test('parseFloorsFromBundleJson correctly attaches root viewpoints to floor objects', () {
      final mockBundle = {
        'floors': [
          {
            'floorId': 'forum_via_sacra',
            'landmarkCode': 'roman_forum',
            'displayName': 'Via Sacra',
          },
          {
            'floorId': 'forum_senate_rostra',
            'landmarkCode': 'roman_forum',
            'displayName': 'Senate & Rostra',
          }
        ],
        'viewpoints': [
          {
            'id': 'vp_500',
            'floorId': 'forum_via_sacra',
            'order': 500,
            'title': 'Via Sacra Stop 1',
            'latitude': 41.891,
            'longitude': 12.487,
          },
          {
            'id': 'vp_501',
            'floorId': 'forum_via_sacra',
            'order': 501,
            'title': 'Via Sacra Stop 2',
            'latitude': 41.892,
            'longitude': 12.488,
          },
          {
            'id': 'vp_504',
            'floorId': 'forum_senate_rostra',
            'order': 504,
            'title': 'Senate Stop 1',
            'latitude': 41.893,
            'longitude': 12.489,
          },
        ]
      };

      final parsed = FloorDefinition.parseFloorsFromBundleJson(mockBundle);
      expect(parsed.length, 2);

      final viaSacra = parsed.firstWhere((f) => f.id == 'forum_via_sacra');
      expect(viaSacra.viewpoints.length, 2);
      expect(viaSacra.stopsCount, 2);

      final senate = parsed.firstWhere((f) => f.id == 'forum_senate_rostra');
      expect(senate.viewpoints.length, 1);
      expect(senate.stopsCount, 1);
    });

    test('keeps a published empty floor under its explicit landmark code', () {
      final floor = FloorDefinition.parseFloorsFromBundleJson({
        'floors': [
          {
            'id': 'floor_3',
            'landmarkCode': 'ludus_magnus',
            'displayName': 'Shaeakhs floor',
            'viewpoints': [],
          },
        ],
      }).single;
      final restored = FloorDefinition.fromJson(floor.toJson());
      expect(restored.landmarkId, 'ludus_magnus');
      expect(restored.viewpoints, isEmpty);
      expect(FloorDefinition.floorsForLandmark('ludus_magnus', [restored]), [restored]);
    });

    test('overrides corrupted landmarkId (e.g. colosseum) when floor ID prefix clearly belongs to another monument', () {
      final corruptedArch = FloorDefinition.fromJson({
        'id': 'arch_ground',
        'landmarkId': 'colosseum',
        'displayName': 'Plaza & Constantinian Reliefs',
      });
      expect(corruptedArch.landmarkId, 'arch_of_constantine');

      final corruptedLudus = FloorDefinition.fromJson({
        'id': 'ludus_arena',
        'landmarkId': 'colosseum',
        'displayName': 'Gladiator Arena & Cavea',
      });
      expect(corruptedLudus.landmarkId, 'ludus_magnus');

      final corruptedTemple = FloorDefinition.fromJson({
        'id': 'temple_east',
        'landmarkId': 'colosseum',
        'displayName': 'Venus Cella & East Terrace',
      });
      expect(corruptedTemple.landmarkId, 'temple_venus_rome');

      final corruptedForum = FloorDefinition.fromJson({
        'id': 'forum_via_sacra',
        'landmarkId': 'colosseum',
        'displayName': 'Via Sacra & Triumphal Way',
      });
      expect(corruptedForum.landmarkId, 'roman_forum');

      final legitimateColosseum = FloorDefinition.fromJson({
        'id': 'floor_underground',
        'landmarkId': 'colosseum',
        'displayName': 'Underground (Hypogeum)',
      });
      expect(legitimateColosseum.landmarkId, 'colosseum');

      // Test that floorsForLandmark('colosseum') filters out all corrupted floors
      final allWithCorrupted = [
        corruptedArch,
        corruptedLudus,
        corruptedTemple,
        corruptedForum,
        legitimateColosseum,
      ];
      final colosseumOnly = FloorDefinition.floorsForLandmark('colosseum', allWithCorrupted);
      expect(colosseumOnly.length, 1);
      expect(colosseumOnly.first.id, 'floor_underground');
    });
  });
}
