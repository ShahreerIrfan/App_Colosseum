import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/itinerary_segment_model.dart';
import '../../../data/models/user_location_model.dart';
import '../../../data/models/viewpoint_model.dart';
import '../../../data/services/tts_service.dart';

/// Controller managing floor map state, camera transformations, viewpoints, and audio playback.
class FloorMapController extends GetxController {
  final TtsService ttsService;

  FloorMapController({TtsService? ttsService})
      : ttsService = ttsService ?? TtsService();

  final landmarkName = 'Colosseum'.obs;
  final floorName = 'Underground (Hypogeum)'.obs;
  final floorId = 'floor_underground'.obs;

  late final TransformationController transformationController;

  /// User's real-time indoor location beacon on this floor
  final userLocation = const UserLocationModel(
    floorId: 'floor_underground',
    normalizedX: 0.92,
    normalizedY: 0.50,
    headingDegrees: 270.0,
    accuracyMeters: 2.0,
  ).obs;

  /// Observable list of architectural viewpoints / audio stops
  final viewpoints = <ViewpointModel>[].obs;

  /// Currently selected / active viewpoint (null when none selected)
  final selectedViewpoint = Rxn<ViewpointModel>();

  /// Audio guide playing state
  final isPlayingAudio = false.obs;

  /// Audio narration progress (0.0 to 1.0)
  final audioProgress = 0.0.obs;

  /// Whether the bottom detail card is collapsed to show maximum map area
  final isCardCollapsed = false.obs;

  /// Normalized walking route points connecting user to active viewpoint
  final routePoints = <Offset>[].obs;

  /// Architectural Guided Itinerary Segments for the current floor
  final itinerarySegments = <ItinerarySegmentModel>[].obs;

  /// Underground Entry and Exit locations
  static const Offset undergroundEntryLocation = Offset(0.92, 0.50);
  static const Offset undergroundExitLocation = Offset(0.10, 0.50);

  /// 7 Detailed Underground Level (Hypogeum) Viewpoints (Stops 100 - 106)
  static const List<ViewpointModel> undergroundViewpoints = [
    ViewpointModel(
      id: 'vp_100',
      floorId: 'floor_underground',
      title: 'Spectacles in the Colosseum Arena Floor. The Superstars',
      order: 100,
      normalizedX: 0.80,
      normalizedY: 0.50,
      latitude: 41.890250,
      longitude: 12.492820,
      imageAsset: 'assets/images/vp_100_arena_spectacles.jpg',
      audioDuration: '4 min 30s',
      isVisited: false,
      description:
          'The exhibition entitled Spectacles in the Colosseum Arena Floor. The Superstars occupies the initial path of the visit of the underground levels and aims at illustrating the operation and use of the "behind the scenes" of the Colosseum with the support of multimedia devices, reconstructions, models, and original finds.\n\n'
          'The first stop is the Corridor of the Gladiators, the underground service corridor that connected the amphitheatre with the main training gymnasium, the Ludus Magnus. From this corridor the animals were probably led for the hunting shows, but above all the gladiators proceeded before performing in the arena. A holographic projection gives an image of the march of the gladiators and 3D reconstructions show what the landscape around the Colosseum looked like 2000 years ago.\n\n'
          'The tour continues with some excellent artefacts: the mosaic from the Castra Pretoria with men and animals at the end of a combat show (the theta nigrum symbol indicates that the animal has been killed) and the armour of the main fixed pairs of gladiators. Among others, one can recognise the Thracian against the Murmillo and the Retiarius against the Secutor, exhibited together with a selection of original artefacts that allow the visitor to appreciate the original armour and the combat poses: among all, a fragment of a step from the cavea of the Colosseum in which the Retiarius armed with a net and trident and the Secutor with his head protected by a completely smooth helmet are graffitied.\n\n'
          'Gladiators were normally people who had fallen into dishonour (even intentionally) and were therefore legitimised to shed blood outside the military sacrament and to be judged by the people, like prisoners of war, slaves or infames, and wore the armour of peoples defeated by the Romans: Samnites, Gauls, Thracians. For the purposes of atoning for faults or recovering lost rights or gaining fame and notoriety, they had to accept the risk of death by swearing an oath to the deity:\n\n'
          'Iuro... me uri vinciri verberari virgis ferroque necari et quidquid aliud iusseris vel invitum me pati passurum.\n\n'
          'The combat between gladiators was the most anticipated moment of the entire day’s spectacles: considered the heroes of the time, they were also immortalised on everyday objects, as shown by some oil lamps displayed in the showcase at the end of the corridor. They made their appearance in the arena in the afternoon, after the performance of the animal hunts in the morning.\n\n'
          'The whole scenic apparatus was designed to impress and amaze the people seated on the cavea: lifts and platforms, as illustrated by the model exhibited in the museum, were used to make the protagonists of the performances appear from the darkness of the underground.',
    ),
    ViewpointModel(
      id: 'vp_101',
      floorId: 'floor_underground',
      title:
          'Access to the Underground Levels: East & West Ramps, Ludus Magnus Tunnels & Fosso Labicano Ditch',
      order: 101,
      normalizedX: 0.88,
      normalizedY: 0.38,
      latitude: 41.890320,
      longitude: 12.493050,
      imageAsset: 'assets/images/vp_101_ludus_magnus_tunnel.jpg',
      audioDuration: '5 min 15s',
      isVisited: false,
      description:
          'Below the arena floor, in the pitch-black darkness, surrounded by the pungent smell of men and animals, shrouded by smoke from the torches used to illuminate the space, the machinery of the spectacle was being readied to make an appearance.\n\n'
          'You are now standing along the cryptoporticus which crosses the long axis of the oval of the Amphitheatre, from east to west. The protagonists of the games walked along this very pathway, coming directly from the nearby neighbourhood of the Amphitheatre, which is behind you, partially visible today between Via Labicana and Via di San Giovanni in Laterano.\n\n'
          'If we try to make the walls which now block our passage disappear, we can imagine the corridor which led to the Ludus Magnus, one of the 4 barracks where the gladiators trained and got ready for battle. Originally, the Ludus was part of a broader complex which included a hospital (saniarium) and a morgue (spoliarium), in addition to the more famous and well-known castra misenatium, the barracks for the sailors of the Miseno fleet who were tasked with extending and retracting the velum, the large awning that shaded spectators in the Colosseum on sunny days.\n\n'
          'On the opposite side, to the west, the cryptoporticus reached what originally was the vestibule of the Domus Aurea, which Emperor Hadrian later turned into the Temple of Venus and Roma.\n\n'
          'Both of these corridors are only partially open today: the first one, to the east, where you’re standing, was cut off in the 19th century by the sewer built for the new Esquiline neighbourhood, while the other one was truncated by the construction of the Metro B line in 1939.\n\n'
          'Continuing along the corridor towards the centre of the underground area, you can still hear the sound of running water underfoot. It’s coming from the Fosso Labicano, a small river tributary of the Tiber which passes under part of the Colosseum’s foundation.\n\n'
          'The valley of the Amphitheatre was originally a lake surrounded by houses, destroyed by Nero to build an artificial basin as part of the Domus Aurea, though it was never completed. To fill his man-made lake, water was to be taken from the extension of the Aqua Claudia aqueduct located on the Caelian Hill, and built by Nero.\n\n'
          'The repurposing of Nero’s structures by the Flavian dynasty explains how it was possible to quickly flood the underground levels as early as the inauguration of the Colosseum in 80 CE. According to historical sources, at the time, some of the most eagerly awaited spectacles were the naumachiae, or naval battles. To that end, they used what were called darsene: two L-shaped tunnels, one of which you are crossing as you walk on the passageway. On each side, symmetrical spaces opened up, placed higher up and used as docking slots for the boats.\n\n'
          'All that is left of them are the words of the many sources which cite the inaugural naumachiae. After 80 CE, naval battles were no longer held at the Amphitheatre and the tunnels were used to move stage decorations along the central corridor thanks to a complex system of winches. In the floor of each of the four L-shaped tunnels, both east and west, you can still see the rows of 6 blocks of travertine (24 in all), which in some cases still have the round bronze ‘collar’ which held the vertical wood pole that moved the capstan winch. Further ahead in the path, you can see the indentations of the ramps which were used to bring stage decorations up to the arena floor via counterweights, thereby providing an appropriate backdrop for the animal hunts in the mornings and executions which came before the afternoon gladiator fights.',
    ),
    ViewpointModel(
      id: 'vp_102',
      floorId: 'floor_underground',
      title:
          'General Introduction to the Underground Levels & Different Phases of Development',
      order: 102,
      normalizedX: 0.68,
      normalizedY: 0.30,
      latitude: 41.890450,
      longitude: 12.492580,
      imageAsset: 'assets/images/vp_102_hypogeum_phases.jpg',
      audioDuration: '4 min 45s',
      isVisited: false,
      description:
          'When we refer to the ‘underground levels’, we are referring to the 76 x 44 meter space below the ancient arena of the Amphitheatre. These spaces contained the rooms used as service facilities for the shows.\n\n'
          'The layout of the spaces and structures, which you are visiting, changed many times, even from the very beginning, due to the three emperors of the Flavian dynasty: Vespasian, Titus and Domitian. When the Amphitheatre was being built, before its inauguration in 80 CE, the underground spaces were completely empty. They had a dual role: they housed the wooden pillars which made up the complex supporting structure of the arena, in turn affixed to travertine blocks; and as a water basin for aquatic spectacles.\n\n'
          'Only after the inauguration, which historical sources say lasted 100 days, did work begin on the construction of the walls which would support the new floor of the arena, part of Domitian’s plan, to whom we owe the completion of the Amphitheatre. The rows of blocks in tufa stone on an east-west axis belong to this phase.\n\n'
          'During Imperial age and up to late antiquity, the underground levels underwent many changes. The Flavian structures in stone blocks were flanked by other walls, mostly in brick and without foundations. The main changes took place under Trajan, Septimius Severus and in late antiquity (between the 5th and 6th centuries).\n\n'
          'Today, the underground levels are marked by walls which create a series of corridors: 9 longitudinal and 6 rings. The corridors are today identified by a letter (A, B, C, D, E, F, G, H) and the sector (North and South). The central corridor, H, coincides with the longer east-west axis. As you can see, the walls were built according to different methods and with different materials:\n'
          '• In Roman concrete with course-laid brickwork (opus caementicium and opus latericium)\n'
          '• Walls in tuff blocks (gabino tuff, yellow tuff and peperino tuff) and blocks of travertine\n'
          '• Mixed masonry, with the extensive use of reclaimed materials (travertine, tuff, brick, marble)\n\n'
          'The surviving antique paving, made in small bricks arranged in a herringbone motif (opus spicatum), provides insight into changes to the floor which can be assigned to at least three different phases: Flavian, Antonine and Severan (respectively in the 1st, 2nd, and 3rd centuries CE). There are only a few small fragments left of the original Flavian floor: the Antonine plan, which defines much of the underground area, involved placing a new floor directly on the old one or, in a few cases, filling in its gaps. In Corridors G north and G south, you can see a raised section of about 0.60 meters, completed sometime between 90 and 140 CE. In the central Corridor H, just next to the north and south walls, the floor was rebuilt with salvaged opus spicatum brick, placed on the long cut side, or flat to form a sort of lateral gutter.\n\n'
          'The socio-economic crisis in the Roman Empire led to the gradual disappearance of gladiatorial games and, from the 5th century onwards, only performances similar to today’s circuses were held in the Amphitheatre, for which the imposing scenery equipment that was originally moved about in the underground levels was no longer necessary. As a result, the underground levels were essentially untouched from then on, progressively filled in with dirt. The definitive filling in came in the aftermath of the last venationes, animal hunts, mentioned by historical sources, held in 523 by the senator Maximus to celebrate his consulate.',
    ),
    ViewpointModel(
      id: 'vp_103',
      floorId: 'floor_underground',
      title: 'The Hoists: The Flavian Phase with Large Perimetral Lifts',
      order: 103,
      normalizedX: 0.48,
      normalizedY: 0.22,
      latitude: 41.890520,
      longitude: 12.492150,
      imageAsset: 'assets/images/vp_103_flavian_hoists.jpg',
      audioDuration: '5 min 40s',
      isVisited: false,
      description:
          'From Domitian (81-96 CE), the last emperor of the Flavian dynasty, up to Macrinus (217-218 CE), 28 hoists were placed around the perimeter of the arena to create a unique, surprising spectacle, unlike any other in the Roman Empire. These hoists were hidden from view, suddenly sending animals of all species, exotic or domestic, bursting onto the arena floor, to enliven animal hunts or as part of death sentences (damnatio ad bestias). Another 20 ramps at the centre of the underground area raised large sets onto the arena floor.\n\n'
          'After the terrible fire of 217, the hoists for animals were placed in the central corridors and the lateral ones were abandoned.\n\n'
          'You are now standing before one of the initial 28 hoists, here rebuilt as an experimental archaeology project. The size of the machine was deduced from the traces which remained in the walls, such as the vertical grooving in the tuff which you can see as you look around you. The structure was composed by two elements in wood, coupled with two different functions: the cage, which measured about 180 x 140 cm and was 90 cm high, and the capstan winch lifting system. The central shaft of the capstan, with a diameter compatible with the original bronze collars which are still found in the Amphitheatre’s underground levels, rotated around its own vertical axis to gather the ropes that raised the cage upwards. Elements such as ball bearings, pulleys, hemp cables, winches, and blocks and tackles multiplied the force of the winch and made it possible to lift the 6,000-7,000 kilos of the animals and cage combined.\n\n'
          'These devices worked by human traction alone. To reach the arena floor, about 7 meters up, the winch had to be turned 15 times. The men who provided the driving force were placed on two levels, one over the other: 4 above and 4 below. That means that at least 224 people were needed just for the contemporary operation of the 28 hoists.\n\n'
          'Raising the cage tensioned a system of ropes that gradually lowered a trapdoor on the arena floor and at the same time opened one side of the cage. Once it reached the endpoint, the animal inside would see its way out, an inclined plank that led directly to the arena floor. The animals, which weren’t fed before the hunts and which were scared and ready to attack, were kept in the niches to your left. When the trapdoor was opened, they were struck by the blinding glare of daylight and the clamour of thousands of spectators. Animals weighing up to 300 kilos could be lifted, including large felines, bears, ostriches, boars, deer and wolves. Some of their remains, excavated from the underground area, are on display in the exhibition located in the 2nd level of the Colosseum.\n\n'
          'The Roman numeral ‘VIII’ is etched on one of the bronze compartments of the powerful winches. This is the only remaining original compartment, each of which had a progressive number, indicating the ability to programme simultaneous openings in different places in the arena, shifting the audience’s attention from one point on the stage to another. It isn’t hard to imagine what was going on under the arena during the show: to make these attractions possible, there had to be a clever, precise organisation, capable of overseeing an enormous underground area, teeming with animals and men spread over two floors.',
    ),
    ViewpointModel(
      id: 'vp_104',
      floorId: 'floor_underground',
      title:
          'Corridor H: Large Ramps and the Four Galleries to the North, South, East & West',
      order: 104,
      normalizedX: 0.48,
      normalizedY: 0.50,
      latitude: 41.890210,
      longitude: 12.492230,
      imageAsset: 'assets/images/vp_104_corridor_h.jpg',
      audioDuration: '4 min 50s',
      isVisited: false,
      description:
          'Called pegmata in ancient times, the system which raised the stage decorations was concentrated in the central corridor, that is, Corridor H, where you are now, and in nearby Corridor F. It consisted of 20 mobile platforms measuring about 5 by 4 meters, carved out of the wood floor of the arena. These platforms could be unhooked and slowly lowered along slots set at a 30-degree angle in the walls of the corridor. You can still see their traces today. When the platforms reached the bottom of the corridor, they were loaded with the stage settings. They then were brought back up to the arena floor, suddenly reappearing before the audience. This system guaranteed a delightful surprise each time it was used, never failing to impress the crowd.\n\n'
          'The platforms were lifted through a system of cables which were coiled around the vertical pole of each winch, pushed by people. Ample traces of these winches can be seen on the floors. The underground levels were connected to corridors called ‘cryptoporticos’, which you’ve already visited. They led to the exterior of the Amphitheatre and they were used to carry stage decorations and animals.\n\n'
          'At first the sets were made and stored in the vestibule of the Domus Aurea, which Hadrian later turned into the Temple of Venus and Roma. Subsequently they were moved to a special building called the Summum Choragium, and then they were most likely moved again to the podium of the Temple to Venus and Roma, as Hadrian’s architect, Apollodorus of Damascus, suggested. That way, they could be brought to the Amphitheatre without being seen beforehand.\n\n'
          'The stages were ‘moveable structures of wood, scaffolding towers like houses on wheels, covered with lively paintings, ornate cages for savage creatures’, as Apuleius tells in his Metamorphoses.\n\n'
          'In brick arranged in a herringbone pattern (opus spicatum), the floors and their furnishings were seen for the first time at the end of the dig carried out by Pietro Rosa in 1874-75 in the eastern half of the underground area.\n\n'
          'English archaeologist John Henry Parker described and illustrated what he saw at the end of Corridor H upon the completion of that dig: wooden tracks, probably used to transport stage decorations; low walls; and tuff blocks in an upside-down U shape. It is likely that they supported service galleries used by servants as they assembled and composed the stage decorations.\n\n'
          'Well preserved at the time of their discovery, the wooden tracks have since been lost, probably corroded due to contact with stagnant water at the bottom of the underground levels and the air. All that remains are drawings and photographs from when they were discovered. The upside-down-U elements in tuff, on the other hand, are today still on site and in good conditions.',
    ),
    ViewpointModel(
      id: 'vp_105',
      floorId: 'floor_underground',
      title: 'The Hoists After the Fire of 217 CE',
      order: 105,
      normalizedX: 0.50,
      normalizedY: 0.72,
      latitude: 41.889980,
      longitude: 12.492320,
      imageAsset: 'assets/images/vp_105_severan_hoists.jpg',
      audioDuration: '5 min 10s',
      isVisited: false,
      description:
          'You are now on the short axis of the oval of the underground area. From here, you can see all the corridors in a row and observe their different construction materials and methods. You can verify how, over the centuries, the original structures had been bolstered by reinforcing walls, and how raised and intermediate floors had been created.\n\n'
          'The original system remained untouched for only a few decades. The stress and weight of the loads on the floor of the arena made it necessary to reinforce the tuff structures with brick walls, which progressively narrowed the corridors and caused the 28 lifts in the B corridors to be decommissioned by the early 2nd century.\n\n'
          'Even more drastic changes were implemented later on, under the Severan dynasty, following a particularly intense fire that erupted in the Amphitheatre in 217, damaging it so badly that it had to be closed until 222. All the wooden structures of the attic, the floor of the arena and all the wooden rigging in the underground levels were destroyed. Five years of intense work followed, leaving visible traces in the underground area of detailed and frenetic efforts to recover and refit the walls which had also been damaged in the fire.\n\n'
          'Once the work was done, an entirely redesigned lifting system was in place, with an impressive 60 new hoists. This time they were placed at the centre of the underground area, in Corridors E and G.\n\n'
          'The machinery for the spectacles simultaneously became larger and better performing: the lifting points were scattered about instead of clustered thanks to the use of smaller lifts, operated simultaneously through a large winch. You can see what is left of this system to the left of central corridor H: 40 lifts were in the G Corridors, 20 to the north and 20 to the south, and another 20 were to the right of the central corridor, in the E Corridors, 10 to the north and 10 to the south. The view of the sequence of these small lifts is very impressive, and provides insight into the frenzy that would have defined that area while shows were in progress.\n\n'
          'Those wood hoists lifted men and small to medium animals and they were housed in rectangular ‘pits’. Closed by flaps carved out of the floor of the arena, each one was crowned by four small travertine pillars. If you look slightly up, you can see them, at the top of the still-plastered walls. The pillars still bear the grooving of the cables which were attached to lead counterweights, while on the cross walls of the ‘pits’ you can see the plaster facing and also the grooves and incisions made to ensure that the wooden pieces fit perfectly into the walls.\n\n'
          'Compared to the first lifting system, the distance travelled by these hoists was shortened. They no longer started from the underground floor, but from a wooden gallery that was over 3 meters above the floor. This left the slaves and workers free to move about and thereby maximise the available space on the lower level of the corridors.\n\n'
          'To impress the audience during games and spectacles, every detail had to be thought out and tended to. In fact, the success of the shows began right here, thanks to the perfect functioning of this equipment. Over time, the small lifts had to be repaired more than once, until only the 40 hoists in Corridor G remained.',
    ),
    ViewpointModel(
      id: 'vp_106',
      floorId: 'floor_underground',
      title:
          'Archaeological Excavations and Restorations in the 19th & 20th Centuries',
      order: 106,
      normalizedX: 0.24,
      normalizedY: 0.50,
      latitude: 41.890180,
      longitude: 12.491550,
      imageAsset: 'assets/images/vp_106_excavations_restorations.jpg',
      audioDuration: '5 min 30s',
      isVisited: false,
      description:
          'As we previously mentioned, the underground levels of the Colosseum were filled in with dirt as of 523. For over 13 centuries, its structures were buried, known only through numerous literary sources in Latin.\n\n'
          'The archaeological discoveries of Herculaneum and Pompei and the subsequent spread of Neoclassicism in the early 1800s sparked a renewed interest in archaeological sites. In this cultural framework, numerous archaeological excavations and studies began, involving the underground levels of the Colosseum in particular.\n\n'
          'Surveys of the Amphitheatre’s arena floor began in 1811, during the French occupation of the Papal State. The excavation in the arena was a decision which held great symbolic value. Since 1750, the arena had been used as a site of martyr worship: moving the central cross and the shrines of the Stations of the Cross, by that time suspended on their exposed foundations, signified the secularisation of a sacred area.\n\n'
          'The dig involved the western half of the floor, with the creation of deep trenches that ran along the walls. Work was slow, in part due to the problems caused by flooding groundwater. At this time, a heated debate began over the age of the underground structures, but by mid century ‘it was agreed to recognise in them the receptacles that the ancients used to contain the beasts destined for the spectacle of daily hunts’.\n\n'
          'With the return of the Pope to Italy from France, in 1814, the excavated area was filled in with dirt again, not so much for problems with groundwater, but out of a desire to restore the chapels of the Stations of the Cross.\n\n'
          'Archaeological digs began again after the Unification of Italy with Rome as the capital city, from 1874 to 1875. They were led by Pietro Rosa and this time they focused on the eastern half of the underground levels, finally reaching the flooring in opus spicatum with the removal of that which remained of the infill from the late 5th-early 6th centuries.\n\n'
          'A notable amount of wooden structures was found, though none survive today. Thanks to the photographs and descriptions of H.J. Parker, we know that parts of machinery, long oak beams, sections of poles that supported the winches, and tracks to move stage decorations had been found. Elements that composed the cavea also came to light, such as the colonnade found on its top, the railings of the vomitoria, the facings of the tiered seating, and epigraphs: essentially everything which had first accidentally collapsed due to an earthquake, and which had later intentionally been thrown into the underground area.\n\n'
          'The discovery of the existence of underground spaces in the amphitheatres of Capua and Pozzuoli, both in Campanian near Naples, have confirmed the role of those at the Colosseum.\n\n'
          'In 1938, the continuation and complete excavation of the arena was entrusted to an entrepreneur, an engineer named Giuseppe Cozzo, who demolished a sizeable quantity of structures which he deemed to be hazardous.\n\n'
          'The dilapidated state of the structures to the west, where you are now standing, was presented as evidence of the extensive damage caused to this part of the Amphitheatre by the earthquakes of 443 and 508. Cozzo completely destroyed that which remained, including the large vaulted spaces under the west entry to the underground area. He then proceeded to rebuild it, meticulously documenting his work, extending even into the niches along the perimeter and the wall of the podium.',
    ),
  ];

  /// 9 Level 1 Viewpoints
  static const List<ViewpointModel> floor1Viewpoints = [
    ViewpointModel(
      id: 'vp_1',
      floorId: 'floor_1',
      title: 'North Imperial Entrance',
      order: 1,
      normalizedX: 0.50,
      normalizedY: 0.14,
      description:
          'The grand ceremonial portal historically reserved for Roman dignitaries and emperors.',
      audioDuration: '2 min 40s',
      isVisited: false,
    ),
    ViewpointModel(
      id: 'vp_2',
      floorId: 'floor_1',
      title: 'Porta Libitinensis',
      order: 2,
      normalizedX: 0.76,
      normalizedY: 0.28,
      description:
          'The solemn gate through which fallen gladiators and combatants were carried out.',
      audioDuration: '3 min 10s',
      isVisited: false,
    ),
    ViewpointModel(
      id: 'vp_3',
      floorId: 'floor_1',
      title: 'East Ambulatory Corridor',
      order: 3,
      normalizedX: 0.88,
      normalizedY: 0.50,
      description:
          'Sweeping vaulted passages framed by ancient Roman travertine brickwork and arches.',
      audioDuration: '1 min 50s',
      isVisited: false,
    ),
    ViewpointModel(
      id: 'vp_4',
      floorId: 'floor_1',
      title: "Emperor's Podium Overlook",
      order: 4,
      normalizedX: 0.72,
      normalizedY: 0.68,
      description:
          'Direct panoramic viewpoint over the arena floor and imperial magistrate seating box.',
      audioDuration: '4 min 15s',
      isVisited: false,
    ),
    ViewpointModel(
      id: 'vp_5',
      floorId: 'floor_1',
      title: 'South Tribune & Vomitoria',
      order: 5,
      normalizedX: 0.50,
      normalizedY: 0.86,
      description:
          'Vantage point overlooking subterranean chambers and ancient spectator crowd corridors.',
      audioDuration: '2 min 25s',
      isVisited: false,
    ),
    ViewpointModel(
      id: 'vp_6',
      floorId: 'floor_1',
      title: 'West Arena Overlook',
      order: 6,
      normalizedX: 0.28,
      normalizedY: 0.68,
      description:
          'Unobstructed view of the reconstructed wooden arena floor and hypogeum labyrinth.',
      audioDuration: '3 min 00s',
      isVisited: false,
    ),
    ViewpointModel(
      id: 'vp_7',
      floorId: 'floor_1',
      title: 'Porta Sanivivaria (Gate of Life)',
      order: 7,
      normalizedX: 0.12,
      normalizedY: 0.50,
      description:
          'The triumphant exit gate through which spared and victorious gladiators departed.',
      audioDuration: '2 min 10s',
      isVisited: false,
    ),
    ViewpointModel(
      id: 'vp_8',
      floorId: 'floor_1',
      title: 'North-West Radial Arches',
      order: 8,
      normalizedX: 0.24,
      normalizedY: 0.28,
      description:
          'Engineering marvel of 80 radial barrel arches supporting the upper cavea tiers.',
      audioDuration: '2 min 45s',
      isVisited: false,
    ),
    ViewpointModel(
      id: 'vp_9',
      floorId: 'floor_1',
      title: 'Central Hypogeum Overlook',
      order: 9,
      normalizedX: 0.50,
      normalizedY: 0.50,
      description:
          'The complex two-level subterranean network of animal cages, trapdoors, and winches.',
      audioDuration: '5 min 00s',
      isVisited: false,
    ),
  ];

  /// Architectural corridor-following itinerary route for Underground (Hypogeum):
  /// ENTRY -> 100 -> 101 -> 102 -> 103 -> 104 -> 105 -> 106 -> EXIT
  static const List<ItinerarySegmentModel> undergroundItinerary = [
    // 1. ENTRY -> Stop 100 (Arena Spectacles)
    ItinerarySegmentModel(
      fromId: 'ENTRY',
      toId: 'vp_100',
      points: [
        Offset(0.92, 0.50),
        Offset(0.80, 0.50),
      ],
    ),
    // 2. Stop 100 -> Stop 101 (Ludus Magnus Tunnel)
    ItinerarySegmentModel(
      fromId: 'vp_100',
      toId: 'vp_101',
      points: [
        Offset(0.80, 0.50),
        Offset(0.83, 0.44),
        Offset(0.88, 0.38),
      ],
    ),
    // 3. Stop 101 -> Stop 102 (Hypogeum Phases)
    ItinerarySegmentModel(
      fromId: 'vp_101',
      toId: 'vp_102',
      points: [
        Offset(0.88, 0.38),
        Offset(0.82, 0.32),
        Offset(0.75, 0.30),
        Offset(0.68, 0.30),
      ],
    ),
    // 4. Stop 102 -> Stop 103 (Flavian Hoists)
    ItinerarySegmentModel(
      fromId: 'vp_102',
      toId: 'vp_103',
      points: [
        Offset(0.68, 0.30),
        Offset(0.58, 0.24),
        Offset(0.48, 0.22),
      ],
    ),
    // 5. Stop 103 -> Stop 104 (Corridor H)
    ItinerarySegmentModel(
      fromId: 'vp_103',
      toId: 'vp_104',
      points: [
        Offset(0.48, 0.22),
        Offset(0.48, 0.36),
        Offset(0.48, 0.50),
      ],
    ),
    // 6. Stop 104 -> Stop 105 (Severan Hoists)
    ItinerarySegmentModel(
      fromId: 'vp_104',
      toId: 'vp_105',
      points: [
        Offset(0.48, 0.50),
        Offset(0.49, 0.61),
        Offset(0.50, 0.72),
      ],
    ),
    // 7. Stop 105 -> Stop 106 (Excavations & Restorations)
    ItinerarySegmentModel(
      fromId: 'vp_105',
      toId: 'vp_106',
      points: [
        Offset(0.50, 0.72),
        Offset(0.40, 0.72),
        Offset(0.30, 0.64),
        Offset(0.24, 0.56),
        Offset(0.24, 0.50),
      ],
    ),
    // 8. Stop 106 -> EXIT
    ItinerarySegmentModel(
      fromId: 'vp_106',
      toId: 'EXIT',
      points: [
        Offset(0.24, 0.50),
        Offset(0.10, 0.50),
      ],
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    transformationController = TransformationController();

    // Parse navigation arguments if passed
    final args = Get.arguments;
    if (args is Map) {
      if (args.containsKey('landmarkName') && args['landmarkName'] != null) {
        landmarkName.value = args['landmarkName'].toString();
      }
      if (args.containsKey('floorName') && args['floorName'] != null) {
        floorName.value = args['floorName'].toString();
      }
      if (args.containsKey('floorId') && args['floorId'] != null) {
        floorId.value = args['floorId'].toString();
      }
    }

    // Load viewpoints according to selected floor
    _loadFloorData();

    // Initialize Text-to-Speech service
    _initTts();
  }

  void _initTts() {
    ttsService.init();
    ttsService.onStart = () {
      isPlayingAudio.value = true;
    };
    ttsService.onComplete = () {
      isPlayingAudio.value = false;
      audioProgress.value = 0.0;
    };
    ttsService.onStop = () {
      isPlayingAudio.value = false;
      audioProgress.value = 0.0;
    };
    ttsService.onPause = () {
      isPlayingAudio.value = false;
    };
    ttsService.onProgress = (start, end, word) {
      final vp = selectedViewpoint.value;
      if (vp != null && vp.description.isNotEmpty) {
        audioProgress.value = (end / vp.description.length).clamp(0.0, 1.0);
      }
    };
  }

  void _loadFloorData() {
    if (floorId.value == 'floor_underground' ||
        floorId.value == 'underground') {
      floorName.value = 'Underground (Hypogeum)';
      viewpoints.assignAll(undergroundViewpoints);
      userLocation.value = const UserLocationModel(
        floorId: 'floor_underground',
        normalizedX: 0.92,
        normalizedY: 0.50,
        headingDegrees: 270.0,
        accuracyMeters: 2.0,
      );
      _refreshItinerarySegments();
    } else {
      floorName.value = 'Floor 1';
      viewpoints.assignAll(floor1Viewpoints);
      userLocation.value = const UserLocationModel(
        floorId: 'floor_1',
        normalizedX: 0.50,
        normalizedY: 0.24,
        headingDegrees: 135.0,
        accuracyMeters: 2.5,
      );
      itinerarySegments.clear();
    }
  }

  /// Recalculates completed status on itinerary walking segments based on visited viewpoints.
  void _refreshItinerarySegments() {
    if (floorId.value == 'floor_underground' ||
        floorId.value == 'underground') {
      final updated = undergroundItinerary.map((segment) {
        final toVp = viewpoints.firstWhereOrNull((vp) => vp.id == segment.toId);
        final isCompleted = segment.toId == 'EXIT'
            ? (viewpoints.isNotEmpty && viewpoints.every((vp) => vp.isVisited))
            : (toVp?.isVisited ?? false);
        return segment.copyWith(isCompleted: isCompleted);
      }).toList();
      itinerarySegments.assignAll(updated);
    } else {
      itinerarySegments.clear();
    }
  }

  @override
  void onClose() {
    ttsService.dispose();
    transformationController.dispose();
    super.onClose();
  }

  /// Selects a viewpoint, calculates route, and marks it active.
  void selectViewpoint(ViewpointModel viewpoint) {
    final previous = selectedViewpoint.value;
    selectedViewpoint.value = viewpoint;
    _computeRoute(viewpoint);

    // When choosing another viewpoint, automatically pause / stop TTS playback
    if (previous?.id != viewpoint.id) {
      if (isPlayingAudio.value) {
        isPlayingAudio.value = false;
        ttsService.stop();
      }
    }
  }

  /// Toggles collapsed / expanded presentation for the bottom detail card.
  void toggleCardCollapse() {
    isCardCollapsed.toggle();
  }

  /// Expands bottom detail card to show full description and media.
  void expandCard() {
    isCardCollapsed.value = false;
  }

  /// Collapses bottom detail card to maximize map visibility.
  void collapseCard() {
    isCardCollapsed.value = true;
  }

  /// Deselects active viewpoint and clears navigation route.
  void deselectViewpoint() {
    selectedViewpoint.value = null;
    isPlayingAudio.value = false;
    ttsService.stop();
    routePoints.clear();
  }

  /// Toggles the visited status for a viewpoint (defaults to currently selected viewpoint).
  void toggleVisited([String? viewpointId]) {
    final targetId = viewpointId ?? selectedViewpoint.value?.id;
    if (targetId == null) return;

    final index = viewpoints.indexWhere((vp) => vp.id == targetId);
    if (index != -1) {
      final current = viewpoints[index];
      final updated = current.copyWith(isVisited: !current.isVisited);
      viewpoints[index] = updated;

      if (selectedViewpoint.value?.id == targetId) {
        selectedViewpoint.value = updated;
      }
      _refreshItinerarySegments();
    }
  }

  /// Toggles audio guide speech playback for the active viewpoint.
  void toggleAudio() async {
    if (isPlayingAudio.value) {
      isPlayingAudio.value = false;
      await ttsService.stop();
    } else {
      final vp = selectedViewpoint.value;
      if (vp != null && vp.description.isNotEmpty) {
        isPlayingAudio.value = true;
        await ttsService.speak(vp.description);
      }
    }
  }

  /// Zoom In helper for floating map controls.
  void zoomIn() {
    final currentScale = transformationController.value.getMaxScaleOnAxis();
    if (currentScale < 3.2) {
      final targetScale = currentScale * 1.25;
      transformationController.value = Matrix4.diagonal3Values(
        targetScale,
        targetScale,
        1.0,
      );
    }
  }

  /// Zoom Out helper for floating map controls.
  void zoomOut() {
    final currentScale = transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 0.85) {
      final targetScale = currentScale * 0.8;
      transformationController.value = Matrix4.diagonal3Values(
        targetScale,
        targetScale,
        1.0,
      );
    }
  }

  /// Recenter floor map to default scale and origin.
  void recenter() {
    transformationController.value = Matrix4.identity();
  }

  /// Generates a smooth architectural walking route along the corridor.
  void _computeRoute(ViewpointModel target) {
    final user = userLocation.value;
    final start = Offset(user.normalizedX, user.normalizedY);
    final end = Offset(target.normalizedX, target.normalizedY);

    // If start and end are practically identical, direct single segment
    final dist = (end - start).distance;
    if (dist < 0.05) {
      routePoints.value = [start, end];
      return;
    }

    // Generate corridor waypoints interpolating along the elliptical arch / central corridor
    final points = <Offset>[start];

    const center = Offset(0.5, 0.5);
    final startAngle = math.atan2(start.dy - center.dy, start.dx - center.dx);
    final endAngle = math.atan2(end.dy - center.dy, end.dx - center.dx);

    var deltaAngle = endAngle - startAngle;
    if (deltaAngle > math.pi) deltaAngle -= 2 * math.pi;
    if (deltaAngle < -math.pi) deltaAngle += 2 * math.pi;

    final steps = (deltaAngle.abs() / (math.pi / 8)).ceil().clamp(2, 8);
    for (int i = 1; i < steps; i++) {
      final t = i / steps;
      final currentAngle = startAngle + (deltaAngle * t);
      final rStart = (start - center).distance;
      final rEnd = (end - center).distance;
      final r = rStart + (rEnd - rStart) * t;

      final wx = center.dx + math.cos(currentAngle) * r;
      final wy = center.dy + math.sin(currentAngle) * r;
      points.add(Offset(wx, wy));
    }

    points.add(end);
    routePoints.value = points;
  }
}
