import 'dart:ui' show Offset;
import '../models/itinerary_segment_model.dart';
import '../models/viewpoint_model.dart';

/// Centralized data provider containing all 28 authentic historical viewpoints and walking itineraries
/// across all 4 levels of the Colosseum monument (Underground, Level 1, Level 2, Level 3).
/// Grounded in official documentation from the Parco archeologico del Colosseo.
class ColosseumTourData {
  // ===========================================================================
  // LEVEL UNDERGROUND (HYPOGEUM) — 7 VIEWPOINTS (100 - 106)
  // ===========================================================================

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

  static const List<ItinerarySegmentModel> undergroundItinerary = [
    ItinerarySegmentModel(
      fromId: 'vp_100',
      toId: 'vp_101',
      points: [
        Offset(0.80, 0.50),
        Offset(0.83, 0.44),
        Offset(0.88, 0.38),
      ],
    ),
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
    ItinerarySegmentModel(
      fromId: 'vp_102',
      toId: 'vp_103',
      points: [
        Offset(0.68, 0.30),
        Offset(0.58, 0.24),
        Offset(0.48, 0.22),
      ],
    ),
    ItinerarySegmentModel(
      fromId: 'vp_103',
      toId: 'vp_104',
      points: [
        Offset(0.48, 0.22),
        Offset(0.48, 0.36),
        Offset(0.48, 0.50),
      ],
    ),
    ItinerarySegmentModel(
      fromId: 'vp_104',
      toId: 'vp_105',
      points: [
        Offset(0.48, 0.50),
        Offset(0.49, 0.61),
        Offset(0.50, 0.72),
      ],
    ),
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
  ];

  // ===========================================================================
  // LEVEL 1 (ARENA & CAVEA) — 9 VIEWPOINTS (200 - 208)
  // ===========================================================================

  static const List<ViewpointModel> level1Viewpoints = [
    ViewpointModel(
      id: 'vp_200',
      floorId: 'floor_1',
      title: 'Northern Imperial Entrance & Arch 38',
      order: 200,
      normalizedX: 0.50,
      normalizedY: 0.16,
      audioDuration: '3 min 45s',
      isVisited: false,
      description:
          'Welcome to Level 1 of the Colosseum. You are standing at the monumental Northern Imperial Entrance, situated directly between arches 38 and 39 along the monument’s short north-south axis.\n\n'
          'Unlike the other 76 numbered perimeter arches through which everyday spectators passed, this grand axial entrance bore no Roman numerals. It was reserved exclusively for the Roman Emperor, high magistrates, and the sacred College of Vestal Virgins. It opened directly onto a private vaulted passageway leading straight to the Imperial Box without having to mix with the public crowds.\n\n'
          'Look closely at the underside of the surviving barrel vaulting overhead. Here you can admire some of the only surviving original Flavian stucco reliefs in the entire Colosseum. Dating to the late 1st century CE, these exquisite white and polychrome plaster reliefs depict geometric panels, mythological figures, and delicate acanthus leaf motifs that once covered all VIP corridors in gleaming Roman opulence.',
    ),
    ViewpointModel(
      id: 'vp_201',
      floorId: 'floor_1',
      title: 'Entrance Arches & Roman Crowd-Control System',
      order: 201,
      normalizedX: 0.72,
      normalizedY: 0.22,
      audioDuration: '3 min 30s',
      isVisited: false,
      description:
          'Step out toward the outer perimeter arcade on the northeastern quadrant. Look up at the travertine keystones crowning the monumental ground-level arches.\n\n'
          'Engraved deeply into the stone above each arch, you can still see ancient Roman numerals carved over two millennia ago. The 76 public entrance arches were numbered consecutively from I to LXXVI (1 to 76). Every Roman spectator held a small clay ticket token called a tessera, which functioned exactly like a modern stadium ticket.\n\n'
          'The tessera specified four crucial pieces of information: the arch number through which to enter (fornix), the seating wedge (cuneus), the horizontal tier (gradus), and the specific bench number (locus). Through this masterfully conceived crowd-control architecture, between 50,000 and 70,000 spectators could enter and take their assigned places in less than 20 minutes without riots or bottlenecks.',
    ),
    ViewpointModel(
      id: 'vp_202',
      floorId: 'floor_1',
      title: 'Vomitoria & Circulation Passages',
      order: 202,
      normalizedX: 0.86,
      normalizedY: 0.44,
      audioDuration: '3 min 15s',
      isVisited: false,
      description:
          'You are now traversing the wide annular ambulatory corridor on the eastern perimeter, supported by massive travertine piers and groin-vaulted concrete ceilings.\n\n'
          'Branching inward from this circular gallery are dozens of steep radial staircases and exit portals known in Latin as vomitoria—from the Latin verb vomere, meaning "to spew forth or discharge rapidly." The term described how the building seemed to miraculously discharge tens of thousands of citizens out onto the surrounding piazza in just a matter of minutes.\n\n'
          'Roman architects designed overlapping concentric rings and independent one-way staircases so that senators ascending to the podium never crossed paths with plebeians climbing to the upper wooden bleachers. This architectural segregation ensured complete civic order and social separation at all times.',
    ),
    ViewpointModel(
      id: 'vp_203',
      floorId: 'floor_1',
      title: 'Arena & Hypogeum Overview',
      order: 203,
      normalizedX: 0.74,
      normalizedY: 0.50,
      audioDuration: '4 min 10s',
      isVisited: false,
      description:
          'Step onto the eastern viewing balcony bordering the arena floor. From this elevated vantage point, you have a direct panoramic view down into the hypogeum and across the modern partial wooden arena reconstruction.\n\n'
          'The ancient arena measured 86 meters in length by 54 meters in width. It consisted of heavy wooden planks resting on masonry arches, covered with fine yellow sand imported from the mouth of the Tiber. During the morning spectacles, called venationes, the arena was transformed into living landscapes with exotic trees, rocky crags, and painted hills brought up from below.\n\n'
          'Separating the spectators from the deadly combatants was a 4-meter-high sheer marble podium wall, crowned by revolving ivory or bronze rollers that prevented leopards and lions from gaining traction to leap into the crowd. Heavily armed archers and spear-wielding guards were stationed at intervals behind safety netting to guarantee the safety of Rome’s ruling elite.',
    ),
    ViewpointModel(
      id: 'vp_204',
      floorId: 'floor_1',
      title: 'Senatorial Seating — Loca',
      order: 204,
      normalizedX: 0.64,
      normalizedY: 0.60,
      audioDuration: '3 min 50s',
      isVisited: false,
      description:
          'You are now standing at the edge of the podium—the lowest, most prestigious seating zone in the entire Colosseum, directly bordering the arena rim.\n\n'
          'This exclusive level was reserved entirely for Roman senators, foreign ambassadors, and senior religious magistrates. Unlike the upper tiers where spectators sat crowded on shared stone bleachers, senators sat on wide, low marble terraces in personal portable folding chairs made of bronze and ivory, called subsellia, carried in by their private enslaved attendants.\n\n'
          'Look closely at the marble revetment blocks on the podium parapet. You will see deep Latin inscriptions cut into the marble. These are the loca—official assigned seat reservations. Whenever a senator died or lost his seat, stonecutters chiseled out the old name and recarved the new senator’s name over the depression (palimpsest). Most surviving inscriptions here date to the 5th and 6th centuries CE, commemorating senators of late antiquity.',
    ),
    ViewpointModel(
      id: 'vp_205',
      floorId: 'floor_1',
      title: 'Imperial Box / Pulvinar',
      order: 205,
      normalizedX: 0.50,
      normalizedY: 0.68,
      audioDuration: '4 min 20s',
      isVisited: false,
      description:
          'You are standing at the southern short axis of the arena—the location of the imperial box, known in antiquity as the pulvinar or cubiculum.\n\n'
          'From this prime elevated pavilion, the Roman Emperor sat crowned with gold laurels, surrounded by his praetorian bodyguards, the empress, and the high magistrates of Rome. Across from him on the northern axis sat the six Vestal Virgins, the sacred priestesses of Vesta who held the highest religious honor in the Roman state.\n\n'
          'The pulvinar gave the Emperor direct visual dominance over the arena spectacles. It was here that victorious gladiators stood looking upward, awaiting the emperor’s verdict: missio (spared life) or pollice verso (the turned thumb directing death). Attending the Colosseum was essential imperial politics—it was the only venue where the ordinary people of Rome could collectively address the Emperor directly with cheers, petitions, or demands.',
    ),
    ViewpointModel(
      id: 'vp_206',
      floorId: 'floor_1',
      title: 'Maenianum Primum — Knights\' Seating',
      order: 206,
      normalizedX: 0.38,
      normalizedY: 0.64,
      audioDuration: '3 min 20s',
      isVisited: false,
      description:
          'Behind the senatorial podium, elevated by a high marble balustrade (balteus), lies the maenianum primum—the first tier of seating.\n\n'
          'Under the Lex Roscia Theatralis and Augustus’s moral legislation, the fourteen lower tiers of marble benches directly behind the senators were legally reserved for the equites (the equestrian order, or Roman knights). These were the wealthy business leaders, financiers, and high military officers of the Empire who possessed an estate of at least 400,000 sesterces.\n\n'
          'Seated here in bright white wool togas adorned with narrow purple stripes (angusticlavia), the equites enjoyed unimpeded sightlines of the arena action while being clearly visible to the entire amphitheatre as a testament to their elite socioeconomic status.',
    ),
    ViewpointModel(
      id: 'vp_207',
      floorId: 'floor_1',
      title: 'Cavea Social Hierarchy',
      order: 207,
      normalizedX: 0.26,
      normalizedY: 0.50,
      audioDuration: '3 min 40s',
      isVisited: false,
      description:
          'From this western cavea section, gaze upward along the sweeping slope of the tiered seating tiers.\n\n'
          'The cavea was not merely a venue for entertainment; it was a physical, monumental diagram of Roman class hierarchy, codified by Emperor Augustus in the Lex Iulia Theatralis. Every Roman sat precisely where his legal identity dictated:\n\n'
          '• The Podium: Senators and Vestal Virgins in ivory chairs\n'
          '• Maenianum Primum: Knights and military tribunes in white togas\n'
          '• Maenianum Secundum Imum: Wealthy male Roman citizens (toga wearers)\n'
          '• Maenianum Secundum Summum: Poorer Roman plebeians dressed in dark wool cloaks (pullati)\n'
          '• Maenianum Summum in Ligneis: The highest wooden bleachers under the portico for day-laborers, foreigners, enslaved people, and women.\n\n'
          'To sit in the wrong section was a criminal offence punished with heavy fines and public disgrace. The Colosseum displayed Roman society to itself in rigid order.',
    ),
    ViewpointModel(
      id: 'vp_208',
      floorId: 'floor_1',
      title: 'Arena Spectacles Viewpoint',
      order: 208,
      normalizedX: 0.36,
      normalizedY: 0.32,
      audioDuration: '4 min 45s',
      isVisited: false,
      description:
          'You are standing at the northwestern vantage point looking down directly across the arena axis.\n\n'
          'Imagine a full day of games in the Flavian era. The spectacles unfolded in three distinct acts across the day:\n\n'
          '1. Morning (Venationes): Exotic wild animal hunts. Thousands of animals imported from Africa, Asia, and northern Europe—lions, tigers, elephants, rhinoceroses, and bears—faced trained hunters (venatores) amidst theatrical scenery.\n\n'
          '2. Midday (Meridiani / Ludi Meridiani): Public executions of convicted criminals (damnati ad bestias or damnati ad gladium), often dramatizing gruesome mythological tales before the spectators.\n\n'
          '3. Afternoon (Munera): The climax of the day—gladiatorial combats. Accompanied by trumpets (tubae), horns (cornua), and water organs (hydraulis), matched pairs of professional fighters clashed under strict rules overseen by referees (summa rudis).\n\n'
          'Gladiators were not indiscriminate killers; they were elite, highly trained athlete-performers. When a fight concluded, the crowd roared with approval, waving linen cloths to celebrate bravery and martial virtue.',
    ),
  ];

  static const List<ItinerarySegmentModel> level1Itinerary = [
    // 1. Arch 38 (vp_200) -> Numbered Arches (vp_201)
    ItinerarySegmentModel(
      fromId: 'vp_200',
      toId: 'vp_201',
      points: [
        Offset(0.50, 0.16),
        Offset(0.60, 0.18),
        Offset(0.72, 0.22),
      ],
    ),
    // 2. Numbered Arches (vp_201) -> Vomitoria (vp_202)
    ItinerarySegmentModel(
      fromId: 'vp_201',
      toId: 'vp_202',
      points: [
        Offset(0.72, 0.22),
        Offset(0.80, 0.32),
        Offset(0.86, 0.44),
      ],
    ),
    // 3. Vomitoria (vp_202) -> Arena Edge (vp_203)
    ItinerarySegmentModel(
      fromId: 'vp_202',
      toId: 'vp_203',
      points: [
        Offset(0.86, 0.44),
        Offset(0.80, 0.48),
        Offset(0.74, 0.50),
      ],
    ),
    // 4. Arena Edge (vp_203) -> Senatorial Seating (vp_204)
    ItinerarySegmentModel(
      fromId: 'vp_203',
      toId: 'vp_204',
      points: [
        Offset(0.74, 0.50),
        Offset(0.70, 0.56),
        Offset(0.64, 0.60),
      ],
    ),
    // 5. Senatorial Seating (vp_204) -> Imperial Pulvinar (vp_205)
    ItinerarySegmentModel(
      fromId: 'vp_204',
      toId: 'vp_205',
      points: [
        Offset(0.64, 0.60),
        Offset(0.58, 0.65),
        Offset(0.50, 0.68),
      ],
    ),
    // 6. Imperial Pulvinar (vp_205) -> Knights' Seating (vp_206)
    ItinerarySegmentModel(
      fromId: 'vp_205',
      toId: 'vp_206',
      points: [
        Offset(0.50, 0.68),
        Offset(0.44, 0.66),
        Offset(0.38, 0.64),
      ],
    ),
    // 7. Knights' Seating (vp_206) -> Cavea Hierarchy (vp_207)
    ItinerarySegmentModel(
      fromId: 'vp_206',
      toId: 'vp_207',
      points: [
        Offset(0.38, 0.64),
        Offset(0.31, 0.58),
        Offset(0.26, 0.50),
      ],
    ),
    // 8. Cavea Hierarchy (vp_207) -> Arena Spectacles (vp_208)
    ItinerarySegmentModel(
      fromId: 'vp_207',
      toId: 'vp_208',
      points: [
        Offset(0.26, 0.50),
        Offset(0.30, 0.40),
        Offset(0.36, 0.32),
      ],
    ),
  ];

  // ===========================================================================
  // LEVEL 2 (MUSEUM & PROMENADE) — 7 VIEWPOINTS (300 - 306)
  // ===========================================================================

  static const List<ViewpointModel> level2Viewpoints = [
    ViewpointModel(
      id: 'vp_300',
      floorId: 'floor_2',
      title: 'Second-Level Cavea Panorama',
      order: 300,
      normalizedX: 0.50,
      normalizedY: 0.24,
      audioDuration: '3 min 50s',
      isVisited: false,
      description:
          'Welcome to Level 2. You have emerged onto the sweeping circular promenade of the second tier of the Colosseum.\n\n'
          'From this elevated height of approximately 18 meters above the arena floor, the full elliptical geometry of the amphitheatre reveals itself. The outer circumference of 527 meters and the towering inner retaining walls demonstrate the sheer scale of Flavian engineering.\n\n'
          'Look down across the interior: you can clearly distinguish the dividing balustrades separating the social tiers, the radiating barrel-vaulted access passages, and the subterranean corridors of the hypogeum exposed to the open sky. During the ancient games, thousands of spectators walked along this very promenade to reach their seats or buy snacks from street vendors stationed in the vaulted bays.',
    ),
    ViewpointModel(
      id: 'vp_301',
      floorId: 'floor_2',
      title: 'Maenianum Secundum',
      order: 301,
      normalizedX: 0.68,
      normalizedY: 0.30,
      audioDuration: '3 min 15s',
      isVisited: false,
      description:
          'You are standing within the middle seating tier, known historically as the maenianum secundum.\n\n'
          'This massive section was subdivided into two horizontal zones: the lower tier (maenianum secundum imum), made of smooth white travertine benches reserved for respectable Roman citizens, and the upper tier (maenianum secundum summum), constructed of rougher tufa stone for poorer plebeians.\n\n'
          'Notice the steep pitch of the staircases (scalae) that divide the seating wedges (cunei). Roman engineers designed the slope to become progressively steeper as one ascended—rising from 30 degrees at the podium to over 37 degrees in the upper tiers—ensuring that every single spectator, even those seated high above, had an unobstructed, direct line of sight down to the arena action.',
    ),
    ViewpointModel(
      id: 'vp_302',
      floorId: 'floor_2',
      title: 'Panoramic Terrace & Archaeological Landscape',
      order: 302,
      normalizedX: 0.85,
      normalizedY: 0.50,
      audioDuration: '3 min 40s',
      isVisited: false,
      description:
          'Step out onto the outer panoramic terrace facing east toward the Roman archaeological park.\n\n'
          'From here, you are rewarded with an extraordinary panoramic vista of ancient Rome. Directly beneath you stands the monumental Arch of Constantine, erected in 315 CE to celebrate Constantine’s victory at the Battle of the Milvian Bridge. Beyond it lies the foundation of the Meta Sudans, the ancient conical sweating fountain.\n\n'
          'Looking west along the ancient Via Sacra, you can trace the triumphal procession route winding past the Temple of Venus and Roma toward the Arch of Titus and the Roman Forum, flanked by the lush green slopes of the Palatine Hill where Roman emperors built their sprawling imperial palaces.',
    ),
    ViewpointModel(
      id: 'vp_303',
      floorId: 'floor_2',
      title: 'Colosseum Museum — Spectators & Seating',
      order: 303,
      normalizedX: 0.70,
      normalizedY: 0.68,
      audioDuration: '4 min 15s',
      isVisited: false,
      description:
          'Enter the southern gallery of Level 2, which houses the permanent Museum of the Colosseum. This first exhibition hall is devoted to the spectators who populated the amphitheatre.\n\n'
          'Exhibited here are authentic inscribed marble seat blocks (loca) discovered during excavations. Notice the deeply carved Latin names of distinguished 5th-century Roman senators such as Messius Phoebus and Decius Marius Venantius Basilius, who financed games after the catastrophic earthquakes of 443 and 508 CE.\n\n'
          'Alongside the official inscriptions, examine the informal ancient graffiti etched into the marble by ordinary spectators waiting for the games: sketches of hunting hounds, caricatures of popular gladiators with their weapon tallies, and board games (tabulae lusoriae) carved into the steps to pass the long hours between spectacles.',
    ),
    ViewpointModel(
      id: 'vp_304',
      floorId: 'floor_2',
      title: 'Colosseum Museum — Marble & Sculptural Decoration',
      order: 304,
      normalizedX: 0.50,
      normalizedY: 0.76,
      audioDuration: '3 min 30s',
      isVisited: false,
      description:
          'Continue through the museum into the room displaying surviving architectural and sculptural elements that once adorned the amphitheatre.\n\n'
          'Although today the Colosseum appears primarily as exposed travertine, tufa, and brick-faced concrete, in antiquity it was encrusted with dazzling white Luna marble and colorful polychrome stones. Displayed here are monumental Corinthian and Composite capitals, intricately carved marble barrier screens (transennae) with geometric openwork, and gutter spouts carved in the form of roaring lion heads.\n\n'
          'Also featured are fragments of figurative relief friezes depicting scenes of animal hunts and gladiatorial combat, which once decorated the podium balustrades and the ceremonial imperial entrances.',
    ),
    ViewpointModel(
      id: 'vp_305',
      floorId: 'floor_2',
      title: 'Colosseum Through the Middle Ages',
      order: 305,
      normalizedX: 0.32,
      normalizedY: 0.66,
      audioDuration: '4 min 00s',
      isVisited: false,
      description:
          'This gallery chronicles the fascinating medieval and post-classical afterlife of the Colosseum.\n\n'
          'Following the cessation of spectacles in the 6th century, the monument was dramatically repurposed. In the 12th and 13th centuries, the noble Frangipane family fortified the Colosseum, transforming the ancient ruin into a private castle complete with battlements and fortified gates.\n\n'
          'The arcade bays were rented out to shoemakers, blacksmiths, glue-makers, and tavern keepers. Lime kilns (calcarae) were built right inside the arena to melt down ancient marble statues and revetments into construction mortar for medieval Rome.\n\n'
          'The destruction was finally halted in 1749 when Pope Benedict XIV declared the Colosseum a sacred martyrium consecrated to the passion of Jesus and the Christian martyrs, erecting the Stations of the Cross that stood in the arena for over a century.',
    ),
    ViewpointModel(
      id: 'vp_306',
      floorId: 'floor_2',
      title: 'Lucangeli Model & Reconstruction',
      order: 306,
      normalizedX: 0.24,
      normalizedY: 0.48,
      audioDuration: '4 min 30s',
      isVisited: false,
      description:
          'You have reached the centerpiece of the Colosseum Museum: the magnificent historic wooden architectural model created by master artisan Carlo Lucangeli.\n\n'
          'Constructed between 1790 and 1812 at a precise 1:60 scale using cork, wood, and plaster, this celebrated masterpiece took over twenty years of meticulous survey and craft. Lucangeli worked directly alongside leading Roman antiquarians, measuring surviving masonry block by block to reconstruct the intact appearance of the ancient amphitheatre.\n\n'
          'Look closely at the cutaway sections: the model reveals the entire four-tiered exterior facade with its statues nestled in the arches, the interior radial staircases, the sloping cavea tiers, the imperial boxes, and the complete velum awning rigging system. It remains to this day one of the most accurate, evocative physical reconstructions of the Colosseum ever made.',
    ),
  ];

  static const List<ItinerarySegmentModel> level2Itinerary = [
    // 1. Level 2 Cavea Panorama (vp_300) -> Maenianum Secundum (vp_301)
    ItinerarySegmentModel(
      fromId: 'vp_300',
      toId: 'vp_301',
      points: [
        Offset(0.50, 0.24),
        Offset(0.60, 0.26),
        Offset(0.68, 0.30),
      ],
    ),
    // 2. Maenianum Secundum (vp_301) -> Panoramic Terrace (vp_302)
    ItinerarySegmentModel(
      fromId: 'vp_301',
      toId: 'vp_302',
      points: [
        Offset(0.68, 0.30),
        Offset(0.78, 0.40),
        Offset(0.85, 0.50),
      ],
    ),
    // 3. Panoramic Terrace (vp_302) -> Museum Spectators (vp_303)
    ItinerarySegmentModel(
      fromId: 'vp_302',
      toId: 'vp_303',
      points: [
        Offset(0.85, 0.50),
        Offset(0.78, 0.60),
        Offset(0.70, 0.68),
      ],
    ),
    // 4. Museum Spectators (vp_303) -> Museum Marble (vp_304)
    ItinerarySegmentModel(
      fromId: 'vp_303',
      toId: 'vp_304',
      points: [
        Offset(0.70, 0.68),
        Offset(0.60, 0.73),
        Offset(0.50, 0.76),
      ],
    ),
    // 5. Museum Marble (vp_304) -> Medieval History (vp_305)
    ItinerarySegmentModel(
      fromId: 'vp_304',
      toId: 'vp_305',
      points: [
        Offset(0.50, 0.76),
        Offset(0.40, 0.72),
        Offset(0.32, 0.66),
      ],
    ),
    // 6. Medieval History (vp_305) -> Lucangeli Model (vp_306)
    ItinerarySegmentModel(
      fromId: 'vp_305',
      toId: 'vp_306',
      points: [
        Offset(0.32, 0.66),
        Offset(0.26, 0.58),
        Offset(0.24, 0.48),
      ],
    ),
  ];

  // ===========================================================================
  // LEVEL 3 (ATTIC & BELVEDERE) — 5 VIEWPOINTS (400 - 404)
  // ===========================================================================

  static const List<ViewpointModel> level3Viewpoints = [
    ViewpointModel(
      id: 'vp_400',
      floorId: 'floor_3',
      title: 'Intermediate Gallery — Approach to Level 3',
      order: 400,
      normalizedX: 0.28,
      normalizedY: 0.36,
      audioDuration: '3 min 15s',
      isVisited: false,
      description:
          'Welcome to the upper realm of the Colosseum. You are standing inside the monumental intermediate gallery connecting the second and third levels, recently reopened to the public after comprehensive architectural restoration.\n\n'
          'Notice the sheer soaring height of the vaulted brick-and-mortar ceilings. To support the tremendous weight of the upper masonry and thousands of spectators above, Roman master engineers designed intersecting barrel vaults reinforced with brick ribs (bipedales).\n\n'
          'Examine the brick surfaces: many still bear factory stamps (bolli laterizi) specifying the brickworks owner, kiln master, and consular dating stamps from the reigns of Domitian and Trajan. This gallery formed the main circulatory artery through which upper-tier spectators moved toward the high stairways.',
    ),
    ViewpointModel(
      id: 'vp_401',
      floorId: 'floor_3',
      title: 'Roman Water Management System',
      order: 401,
      normalizedX: 0.38,
      normalizedY: 0.22,
      audioDuration: '3 min 45s',
      isVisited: false,
      description:
          'At this station along the northern gallery wall, examine the remarkable surviving evidence of the Colosseum’s hydraulic engineering.\n\n'
          'Managing torrential rainfall across a 2-hectare open-air amphitheatre was a monumental technical challenge. Water falling onto the upper tiers was collected by lead-lined travertine gutters and channeled through vertical terracotta and lead pipes (fistulae) concealed inside the core of the concrete piers.\n\n'
          'These vertical downspouts discharged into four giant underground vaulted sewer collectors ringing the perimeter of the building, which in turn carried the stormwater out into the ancient municipal drainage network leading to the Tiber River. Notice the vertical recessed conduits and travertine catch-basins still clearly visible in the wall masonry beside you.',
    ),
    ViewpointModel(
      id: 'vp_402',
      floorId: 'floor_3',
      title: 'Tituli Picti — Ancient Red Inscriptions',
      order: 402,
      normalizedX: 0.54,
      normalizedY: 0.18,
      audioDuration: '3 min 30s',
      isVisited: false,
      description:
          'Look closely at the travertine pillar surfaces in this protected upper ambulatory section.\n\n'
          'Under specialized museum lighting, you can see faint traces of ancient red ochre paint: these are the famous tituli picti (painted inscriptions). Preserved sheltered from rain and sunlight for two millennia, these red brush-painted inscriptions were practical quarry and stonemason tallies marking shipment batches from the travertine quarries of Tivoli (Tibur).\n\n'
          'Beside the official shipping marks, archaeologists discovered spontaneous graffiti left by ancient visitors and workmen: tally marks recording gladiator bouts, small sketches of helmets and palm fronds, phallic symbols carved as apotropaic charms to ward off the evil eye, and personal names of late-antique Roman citizens.',
    ),
    ViewpointModel(
      id: 'vp_403',
      floorId: 'floor_3',
      title: 'Third-Level Cavea / Upper Seating',
      order: 403,
      normalizedX: 0.70,
      normalizedY: 0.28,
      audioDuration: '3 min 50s',
      isVisited: false,
      description:
          'Step out onto the high viewing platform of the third level cavea, elevated more than 30 meters above the arena.\n\n'
          'In antiquity, this uppermost seating tier—the maenianum summum in ligneis—consisted of steep wooden bleachers sheltered beneath a continuous covered colonnade of slender marble columns. Commissioned under Emperor Domitian, this was the zone assigned to the humblest members of Roman society: day laborers, non-citizen freedmen, enslaved people, and women.\n\n'
          'Seated so high above the arena, the gladiators appeared like miniature figurines, and the roar of the lower crowd rose up as a thunderous roar. Yet even here, spectators were protected from the Mediterranean sun by the giant linen velum awning, suspended from 240 wooden masts anchored to the external attic cornices.',
    ),
    ViewpointModel(
      id: 'vp_404',
      floorId: 'floor_3',
      title: 'Upper Levels & Belvedere View',
      order: 404,
      normalizedX: 0.80,
      normalizedY: 0.44,
      audioDuration: '4 min 20s',
      isVisited: false,
      description:
          'You have reached the highest accessible point of the Colosseum: the world-famous Belvedere panoramic terrace, perched 48 meters above the valley floor near the monument’s attic.\n\n'
          'Take a moment to absorb the breathtaking 360-degree vista before you. Looking inward, you command an unmatched bird’s-eye perspective across the entire amphitheatre: the curved rows of cavea tiers falling away toward the arena, the labyrinth of hypogeum walls below, and the monumental outer structural arches.\n\n'
          'Looking outward over the attic parapet, Rome unfolds around you: the green summit of the Oppian Hill, the Esquiline neighborhood, the gardens of the Domus Aurea, and the distant dome of Saint Peter’s on the horizon. Here, standing between the sky and the stone, you experience the timeless majesty of the Flavian Amphitheatre—a testament to human ambition that has endured for nearly two thousand years.',
    ),
  ];

  static const List<ItinerarySegmentModel> level3Itinerary = [
    // 1. Intermediate Gallery (vp_400) -> Water Management (vp_401)
    ItinerarySegmentModel(
      fromId: 'vp_400',
      toId: 'vp_401',
      points: [
        Offset(0.28, 0.36),
        Offset(0.32, 0.28),
        Offset(0.38, 0.22),
      ],
    ),
    // 2. Water Management (vp_401) -> Tituli Picti (vp_402)
    ItinerarySegmentModel(
      fromId: 'vp_401',
      toId: 'vp_402',
      points: [
        Offset(0.38, 0.22),
        Offset(0.46, 0.19),
        Offset(0.54, 0.18),
      ],
    ),
    // 3. Tituli Picti (vp_402) -> Upper Cavea Seating (vp_403)
    ItinerarySegmentModel(
      fromId: 'vp_402',
      toId: 'vp_403',
      points: [
        Offset(0.54, 0.18),
        Offset(0.62, 0.22),
        Offset(0.70, 0.28),
      ],
    ),
    // 4. Upper Cavea Seating (vp_403) -> Belvedere Panorama (vp_404)
    ItinerarySegmentModel(
      fromId: 'vp_403',
      toId: 'vp_404',
      points: [
        Offset(0.70, 0.28),
        Offset(0.76, 0.36),
        Offset(0.80, 0.44),
      ],
    ),
  ];

  /// Returns all viewpoints belonging to a given floor level.
  static List<ViewpointModel> getViewpointsForFloor(String floorId) {
    final fid = floorId.toLowerCase();
    if (fid.contains('underground')) return undergroundViewpoints;
    if (fid.contains('2')) return level2Viewpoints;
    if (fid.contains('3')) return level3Viewpoints;
    return level1Viewpoints;
  }

  /// Returns total viewpoint count for a given floor level.
  static int getViewpointCountForFloor(String floorId) {
    return getViewpointsForFloor(floorId).length;
  }
}
