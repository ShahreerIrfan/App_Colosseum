import 'package:flutter_test/flutter_test.dart';
import 'package:colosseum_client/app/data/models/floor_definition.dart';
import 'package:colosseum_client/app/data/providers/landmarks_tour_data.dart';
import 'package:colosseum_client/app/data/services/tour_navigation_engine.dart';

void main() {
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
      final groundVps = LandmarksTourData.archGroundViewpoints;
      expect(groundVps.length, 4);
      expect(groundVps.every((v) => v.floorId == 'arch_ground'), isTrue);
      expect(LandmarksTourData.archGroundItinerary.length, 3);

      final atticVps = LandmarksTourData.archAtticViewpoints;
      expect(atticVps.length, 2);
      expect(atticVps.every((v) => v.floorId == 'arch_attic'), isTrue);
      expect(LandmarksTourData.archAtticItinerary.length, 1);
    });

    test('verifies Ludus Magnus viewpoints and itineraries', () {
      final arenaVps = LandmarksTourData.ludusArenaViewpoints;
      expect(arenaVps.length, 3);
      expect(arenaVps.every((v) => v.floorId == 'ludus_arena'), isTrue);
      expect(LandmarksTourData.ludusArenaItinerary.length, 2);

      final tunnelVps = LandmarksTourData.ludusSubterraneanViewpoints;
      expect(tunnelVps.length, 2);
      expect(tunnelVps.every((v) => v.floorId == 'ludus_tunnel'), isTrue);
      expect(LandmarksTourData.ludusSubterraneanItinerary.length, 1);
    });

    test('verifies Temple of Venus and Rome viewpoints and itineraries', () {
      final eastVps = LandmarksTourData.templeEastViewpoints;
      expect(eastVps.length, 3);
      expect(eastVps.every((v) => v.floorId == 'temple_east'), isTrue);
      expect(LandmarksTourData.templeEastItinerary.length, 2);

      final westVps = LandmarksTourData.templeWestViewpoints;
      expect(westVps.length, 2);
      expect(westVps.every((v) => v.floorId == 'temple_west'), isTrue);
      expect(LandmarksTourData.templeWestItinerary.length, 1);
    });

    test('verifies Roman Forum viewpoints and itineraries', () {
      final viaSacraVps = LandmarksTourData.forumViaSacraViewpoints;
      expect(viaSacraVps.length, 4);
      expect(viaSacraVps.every((v) => v.floorId == 'forum_via_sacra'), isTrue);
      expect(LandmarksTourData.forumViaSacraItinerary.length, 3);

      final senateVps = LandmarksTourData.forumSenateViewpoints;
      expect(senateVps.length, 3);
      expect(senateVps.every((v) => v.floorId == 'forum_senate_rostra'), isTrue);
      expect(LandmarksTourData.forumSenateItinerary.length, 2);
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
  });
}
