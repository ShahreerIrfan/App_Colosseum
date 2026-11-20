import 'package:flutter_test/flutter_test.dart';
import 'package:colosseum_client/app/data/models/floor_definition.dart';
import 'package:colosseum_client/app/data/services/tour_navigation_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('All Landmarks Tour Data Dataset Verification Tests', () {
    test('verifies each of the 5 landmarks has authentic floors and initial floors', () {
      final colosseumFloors = FloorDefinition.floorsForLandmark('colosseum');
      expect(colosseumFloors.length, 4);
      expect(FloorDefinition.initialFloorForLandmark('colosseum').id, 'floor_underground');

      final archFloors = FloorDefinition.floorsForLandmark('arch_of_constantine');
      expect(archFloors.length, 2);
      expect(FloorDefinition.initialFloorForLandmark('arch_of_constantine').id, 'arch_ground');

      final ludusFloors = FloorDefinition.floorsForLandmark('ludus_magnus');
      expect(ludusFloors.length, 2);
      expect(FloorDefinition.initialFloorForLandmark('ludus_magnus').id, 'ludus_arena');

      final templeFloors = FloorDefinition.floorsForLandmark('temple_venus_rome');
      expect(templeFloors.length, 2);
      expect(FloorDefinition.initialFloorForLandmark('temple_venus_rome').id, 'temple_east');

      final forumFloors = FloorDefinition.floorsForLandmark('roman_forum');
      expect(forumFloors.length, 2);
      expect(FloorDefinition.initialFloorForLandmark('roman_forum').id, 'forum_via_sacra');
    });

    test('verifies Arch of Constantine viewpoints and itineraries', () {
      final archGround = FloorDefinition.fromId('arch_ground');
      final groundVps = archGround.viewpoints;
      expect(groundVps.length, 4);
      expect(groundVps.every((v) => v.floorId == 'arch_ground'), isTrue);
      expect(archGround.itinerary.length, 3);

      final archAttic = FloorDefinition.fromId('arch_attic');
      final atticVps = archAttic.viewpoints;
      expect(atticVps.length, 2);
      expect(atticVps.every((v) => v.floorId == 'arch_attic'), isTrue);
      expect(archAttic.itinerary.length, 1);
    });

    test('verifies Ludus Magnus viewpoints and itineraries', () {
      final ludusArena = FloorDefinition.fromId('ludus_arena');
      final arenaVps = ludusArena.viewpoints;
      expect(arenaVps.length, 3);
      expect(arenaVps.every((v) => v.floorId == 'ludus_arena'), isTrue);
      expect(ludusArena.itinerary.length, 2);

      final ludusTunnel = FloorDefinition.fromId('ludus_tunnel');
      final tunnelVps = ludusTunnel.viewpoints;
      expect(tunnelVps.length, 2);
      expect(tunnelVps.every((v) => v.floorId == 'ludus_tunnel'), isTrue);
      expect(ludusTunnel.itinerary.length, 1);
    });

    test('verifies Temple of Venus and Rome viewpoints and itineraries', () {
      final templeEast = FloorDefinition.fromId('temple_east');
      final eastVps = templeEast.viewpoints;
      expect(eastVps.length, 3);
      expect(eastVps.every((v) => v.floorId == 'temple_east'), isTrue);
      expect(templeEast.itinerary.length, 2);

      final templeWest = FloorDefinition.fromId('temple_west');
      final westVps = templeWest.viewpoints;
      expect(westVps.length, 2);
      expect(westVps.every((v) => v.floorId == 'temple_west'), isTrue);
      expect(templeWest.itinerary.length, 1);
    });

    test('verifies Roman Forum viewpoints and itineraries', () {
      final forumViaSacra = FloorDefinition.fromId('forum_via_sacra');
      final viaSacraVps = forumViaSacra.viewpoints;
      expect(viaSacraVps.length, 4);
      expect(viaSacraVps.every((v) => v.floorId == 'forum_via_sacra'), isTrue);
      expect(forumViaSacra.itinerary.length, 3);

      final forumSenate = FloorDefinition.fromId('forum_senate_rostra');
      final senateVps = forumSenate.viewpoints;
      expect(senateVps.length, 3);
      expect(senateVps.every((v) => v.floorId == 'forum_senate_rostra'), isTrue);
      expect(forumSenate.itinerary.length, 2);
    });

    test('verifies FloorDefinition.fromId resolves correctly for every floor across all 5 monuments', () {
      expect(FloorDefinition.fromId('floor_underground').landmarkId, 'colosseum');
      expect(FloorDefinition.fromId('floor_1').landmarkId, 'colosseum');
      expect(FloorDefinition.fromId('arch_ground').landmarkId, 'arch_of_constantine');
      expect(FloorDefinition.fromId('arch_attic').landmarkId, 'arch_of_constantine');
      expect(FloorDefinition.fromId('ludus_arena').landmarkId, 'ludus_magnus');
      expect(FloorDefinition.fromId('ludus_tunnel').landmarkId, 'ludus_magnus');
      expect(FloorDefinition.fromId('temple_east').landmarkId, 'temple_venus_rome');
      expect(FloorDefinition.fromId('temple_west').landmarkId, 'temple_venus_rome');
      expect(FloorDefinition.fromId('forum_via_sacra').landmarkId, 'roman_forum');
      expect(FloorDefinition.fromId('forum_senate_rostra').landmarkId, 'roman_forum');
    });

    test('verifies TourNavigationEngine speaks authentic landmark greetings for each monument', () {
      final engine = TourNavigationEngine();
      final spoken = <String>[];
      engine.onSpeakInstruction = (text, {onDone}) {
        spoken.add(text);
        onDone?.call();
      };

      // 1. Roman Forum
      final forumDef = FloorDefinition.fromId('forum_via_sacra');
      engine.startTour(
        floorId: forumDef.id,
        landmarkName: forumDef.landmarkName,
        floorName: forumDef.displayName,
        viewpoints: forumDef.viewpoints,
      );
      expect(
        spoken.last,
        'Welcome to the Roman Forum. Proceed to Viewpoint 500: The Arch of Titus & The Spoils of Jerusalem.',
      );

      // 2. Arch of Constantine
      final archDef = FloorDefinition.fromId('arch_ground');
      engine.startTour(
        floorId: archDef.id,
        landmarkName: archDef.landmarkName,
        floorName: archDef.displayName,
        viewpoints: archDef.viewpoints,
      );
      expect(
        spoken.last,
        'Welcome to the Arch of Constantine. Proceed to Viewpoint 200: South Facade: The Battle of the Milvian Bridge & Siege of Verona.',
      );

      // 3. Ludus Magnus
      final ludusDef = FloorDefinition.fromId('ludus_arena');
      engine.startTour(
        floorId: ludusDef.id,
        landmarkName: ludusDef.landmarkName,
        floorName: ludusDef.displayName,
        viewpoints: ludusDef.viewpoints,
      );
      expect(
        spoken.last,
        'Welcome to the Ludus Magnus. Proceed to Viewpoint 300: The Miniature Elliptical Practice Arena & Curved Cavea.',
      );

      // 4. Temple of Venus and Rome
      final templeDef = FloorDefinition.fromId('temple_east');
      engine.startTour(
        floorId: templeDef.id,
        landmarkName: templeDef.landmarkName,
        floorName: templeDef.displayName,
        viewpoints: templeDef.viewpoints,
      );
      expect(
        spoken.last,
        'Welcome to the Temple of Venus and Rome. Proceed to Viewpoint 400: Hadrian’s Gigantic Stylobate & Monolithic Colonnade.',
      );

      // 5. Colosseum (preserves original tour format)
      final colosseumDef = FloorDefinition.fromId('floor_underground');
      engine.startTour(
        floorId: colosseumDef.id,
        landmarkName: colosseumDef.landmarkName,
        floorName: colosseumDef.displayName,
        viewpoints: colosseumDef.viewpoints,
      );
      expect(
        spoken.last,
        'Begin the Underground tour. Proceed toward Viewpoint 100.',
      );
    });

    test('verifies all surrounding landmark viewpoints have authentic GPS coordinates in their monument bounds', () {
      // Temple of Venus and Rome
      for (final vp in FloorDefinition.fromId('temple_east').viewpoints) {
        expect(vp.latLng.latitude, inInclusiveRange(41.890, 41.892));
        expect(vp.latLng.longitude, inInclusiveRange(12.488, 12.491));
      }

      // Arch of Constantine
      for (final vp in FloorDefinition.fromId('arch_ground').viewpoints) {
        expect(vp.latLng.latitude, inInclusiveRange(41.889, 41.891));
        expect(vp.latLng.longitude, inInclusiveRange(12.490, 12.492));
      }

      // Ludus Magnus
      for (final vp in FloorDefinition.fromId('ludus_arena').viewpoints) {
        expect(vp.latLng.latitude, inInclusiveRange(41.889, 41.892));
        expect(vp.latLng.longitude, inInclusiveRange(12.494, 12.496));
      }

      // Roman Forum
      for (final vp in FloorDefinition.fromId('forum_via_sacra').viewpoints) {
        expect(vp.latLng.latitude, inInclusiveRange(41.890, 41.894));
        expect(vp.latLng.longitude, inInclusiveRange(12.484, 12.490));
      }
    });

    test('verifies Colosseum floor viewpoints distribute around the arena and do NOT overlap', () {
      final floor1 = FloorDefinition.fromId('floor_1');
      final viewpoints = floor1.viewpoints;
      expect(viewpoints.length, 9);

      // Verify each viewpoint evaluates to a distinct coordinate around the arena ring
      final coordinates = viewpoints.map((vp) => vp.latLng).toList();
      for (var i = 0; i < coordinates.length; i++) {
        for (var j = i + 1; j < coordinates.length; j++) {
          final p1 = coordinates[i];
          final p2 = coordinates[j];
          final isSame = (p1.latitude - p2.latitude).abs() < 0.00001 &&
              (p1.longitude - p2.longitude).abs() < 0.00001;
          expect(isSame, isFalse,
              reason: 'Viewpoint ${viewpoints[i].order} and ${viewpoints[j].order} should not overlap');
        }
      }
    });
  });
}
