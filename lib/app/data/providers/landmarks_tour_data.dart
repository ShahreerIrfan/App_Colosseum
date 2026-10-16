import 'dart:ui' show Offset;

import '../models/itinerary_segment_model.dart';
import '../models/viewpoint_model.dart';

/// Centralized authentic tour data provider for the other 4 monumental landmarks in the
/// Colosseum Archaeological Park:
/// - Arch of Constantine (Arco di Costantino)
/// - Ludus Magnus (The Great Gladiatorial Training School)
/// - Temple of Venus and Rome (Tempio di Venere e Roma)
/// - Roman Forum (Forum Romanum / Via Sacra)
///
/// Grounded in official archaeological surveys and historical records of the Parco archeologico del Colosseo.
class LandmarksTourData {
  LandmarksTourData._();

  // ===========================================================================
  // 1. ARCH OF CONSTANTINE (ARCO DI COSTANTINO)
  // ===========================================================================

  // Level 1: Plaza & Constantinian Reliefs (Ground Level)
  static const List<ViewpointModel> archGroundViewpoints = [
    ViewpointModel(
      id: 'vp_arch_200',
      floorId: 'arch_ground',
      title: 'South Facade: The Battle of the Milvian Bridge & Siege of Verona',
      order: 200,
      normalizedX: 0.50,
      normalizedY: 0.82,
      latitude: 41.889650,
      longitude: 12.490667,
      imageAsset: 'assets/logo/Arch of Constantine.png',
      audioDuration: '4 min 15s',
      isVisited: false,
      description:
          'Standing before the magnificent southern facade facing the Palatine Hill, you are looking at the great narrative frieze carved specifically for Constantine’s victory celebrations in 315 AD.\n\n'
          'The frieze depicts the decisive campaign of 312 AD against Emperor Maxentius. On the far left, Constantine’s armies depart from Milan and begin the grueling siege of Verona. Notice how the figures are carved in bold, frontal relief, departing from classical naturalism into late antique symbolic clarity.\n\n'
          'The central sequence depicts the climactic Battle of the Milvian Bridge at Saxa Rubra. Maxentius’s cavalry is thrown into panic as the bridge of boats collapses under their weight. Maxentius himself is seen tumbling into the swirling waters of the Tiber River, drowning beneath his heavy iron armour, an event that handed undisputed control of the western Roman Empire to Constantine.',
    ),
    ViewpointModel(
      id: 'vp_arch_201',
      floorId: 'arch_ground',
      title: 'The Central Fornix & Inscription: "Instinctu Divinitatis"',
      order: 201,
      normalizedX: 0.50,
      normalizedY: 0.50,
      latitude: 41.889762,
      longitude: 12.490667,
      imageAsset: 'assets/logo/Arch of Constantine.png',
      audioDuration: '3 min 50s',
      isVisited: false,
      description:
          'Step beneath the soaring 11.5-meter central archway (fornix). Flanked on either side by fluted Corinthian columns of yellow Numidian marble (giallo antico), the monument commemorates Constantine’s decennalia—ten years of reign—dedicated by the Senate and People of Rome (SPQR).\n\n'
          'Look up at the monumental bronze-inlaid inscription carved into the attic: "IMP · CAES · FL · CONSTANTINO · MAXIMO · P · F · AVGUSTO · S · P · Q · R · QUOD · INSTINCTU · DIVINITATIS · MENTIS · MAGNITUDINE...".\n\n'
          'The crucial phrase is "instinctu divinitatis" ("by divine inspiration"). Roman senatorial scribes deliberately chose this ambiguous phrasing to honor Constantine’s Christian vision of the cross before battle without overtly offending the traditional pagan conservative senators of Rome.',
    ),
    ViewpointModel(
      id: 'vp_arch_202',
      floorId: 'arch_ground',
      title: 'North Facade: Trajanic Dacian Prisoners & Marcus Aurelius Panels',
      order: 202,
      normalizedX: 0.50,
      normalizedY: 0.18,
      latitude: 41.889870,
      longitude: 12.490667,
      imageAsset: 'assets/logo/Arch of Constantine.png',
      audioDuration: '4 min 45s',
      isVisited: false,
      description:
          'On the northern facade facing the Colosseum plaza stands a masterclass in ancient architectural recycling, known as "spolia". Rather than carving the entire monument anew, Constantine’s architects harvested masterwork sculptures from monuments of the "Good Emperors" of Rome’s 2nd-century Golden Age.\n\n'
          'Perched atop the projecting entablatures are eight colossal freestanding statues of Dacian prisoners, carved from purple-veined pavonazzetto marble, taken directly from the Forum of Trajan. Their downcast gazes and folded hands symbolize subjugated provincial might.\n\n'
          'Beside them, large rectangular relief panels salvaged from a monument to Emperor Marcus Aurelius show the emperor conducting the solemn lustrum purification ritual, granting clemency to kneeling barbarian chieftains, and receiving foreign ambassadors in peace.',
    ),
    ViewpointModel(
      id: 'vp_arch_203',
      floorId: 'arch_ground',
      title: 'Lateral Medallions: Hadrianic Hunts, Sol and Luna Chariots',
      order: 203,
      normalizedX: 0.15,
      normalizedY: 0.50,
      latitude: 41.889762,
      longitude: 12.490520,
      imageAsset: 'assets/logo/Arch of Constantine.png',
      audioDuration: '3 min 20s',
      isVisited: false,
      description:
          'Observe the eight circular roundels (tondi) mounted in pairs above the lateral archways, salvaged from an architectural complex built by Emperor Hadrian. They celebrate imperial virtus (courage in the hunt) and pietas (religious piety).\n\n'
          'You can see Hadrian hunting a bear, a wild boar, and a lion, followed by solemn sacrifices to Apollo, Diana, and Silvanus. Under Constantine, the heads of Hadrian were recarved to resemble Constantine and his co-emperor Licinius.\n\n'
          'On the narrow eastern and western ends of the arch, examine the circular medallions depicting Sol, the Invincible Sun God, driving his fiery chariot upward from the ocean, while Luna, the Moon Goddess, sinks downward into the waves—proclaiming the eternal, cosmic scope of Roman dominion.',
    ),
  ];

  static const List<ItinerarySegmentModel> archGroundItinerary = [
    ItinerarySegmentModel(
      fromId: 'vp_arch_200',
      toId: 'vp_arch_201',
      points: [Offset(0.50, 0.82), Offset(0.50, 0.65), Offset(0.50, 0.50)],
    ),
    ItinerarySegmentModel(
      fromId: 'vp_arch_201',
      toId: 'vp_arch_202',
      points: [Offset(0.50, 0.50), Offset(0.50, 0.35), Offset(0.50, 0.18)],
    ),
    ItinerarySegmentModel(
      fromId: 'vp_arch_202',
      toId: 'vp_arch_203',
      points: [Offset(0.50, 0.18), Offset(0.25, 0.25), Offset(0.15, 0.50)],
    ),
  ];

  // Level 2: Attic & Upper Chamber (Attic Level)
  static const List<ViewpointModel> archAtticViewpoints = [
    ViewpointModel(
      id: 'vp_arch_204',
      floorId: 'arch_attic',
      title: 'The Interior Stairway & Brick Vaulted Attic Chambers',
      order: 204,
      normalizedX: 0.40,
      normalizedY: 0.50,
      latitude: 41.889762,
      longitude: 12.490667,
      imageAsset: 'assets/logo/Arch of Constantine.png',
      audioDuration: '3 min 15s',
      isVisited: false,
      description:
          'Hidden within the south-western pier of the arch lies a narrow spiral staircase carved directly into the travertine and tufa masonry, leading up to the great hollow attic.\n\n'
          'The attic consists of several interconnected vaulted brick rooms that were built to lighten the immense load bearing down on the fornices below. During the Middle Ages, the powerful Frangipani baronial family incorporated this attic into their private fortress, adding battlements to control the pilgrimage route through Rome.',
    ),
    ViewpointModel(
      id: 'vp_arch_205',
      floorId: 'arch_attic',
      title: 'Panoramic Vista: The Via Triumphalis & Palatine Flank',
      order: 205,
      normalizedX: 0.65,
      normalizedY: 0.50,
      latitude: 41.889800,
      longitude: 12.490720,
      imageAsset: 'assets/logo/Arch of Constantine.png',
      audioDuration: '3 min 40s',
      isVisited: false,
      description:
          'From this elevated vantage point atop the arch, you trace the exact triumphal parade route followed by victorious Roman generals.\n\n'
          'Generals in gold-embroidered togas entered through the Porta Triumphalis, processed through the Circus Maximus, rounded the Palatine Hill along Via di San Gregorio, passed right beneath this Arch, and ascended the Clivus Palatinus towards the Temple of Jupiter Optimus Maximus on the Capitoline.',
    ),
  ];

  static const List<ItinerarySegmentModel> archAtticItinerary = [
    ItinerarySegmentModel(
      fromId: 'vp_arch_204',
      toId: 'vp_arch_205',
      points: [Offset(0.40, 0.50), Offset(0.52, 0.50), Offset(0.65, 0.50)],
    ),
  ];

  // ===========================================================================
  // 2. LUDUS MAGNUS (THE GREAT GLADIATORIAL TRAINING SCHOOL)
  // ===========================================================================

  // Level 1: Training Arena & Barracks (Arena Floor)
  static const List<ViewpointModel> ludusArenaViewpoints = [
    ViewpointModel(
      id: 'vp_ludus_300',
      floorId: 'ludus_arena',
      title: 'The Miniature Elliptical Practice Arena & Curved Cavea',
      order: 300,
      normalizedX: 0.50,
      normalizedY: 0.50,
      latitude: 41.889950,
      longitude: 12.495050,
      imageAsset: 'assets/logo/Ludus Magnus.png',
      audioDuration: '4 min 10s',
      isVisited: false,
      description:
          'You are looking down into the excavated heart of the Ludus Magnus, the largest of the four gladiatorial training colleges founded in ancient Rome.\n\n'
          'At the center lies an exact miniature scaled replica of the Colosseum arena floor, measuring 63 meters long by 42 meters wide. It was constructed on a precise 1:2.5 ratio with the main amphitheatre so gladiators could practice timing, footwork, and tactical positioning under real arena conditions.\n\n'
          'Surrounding the arena are the surviving travertine foundations of the cavea—small spectator grandstands that held up to 3,000 citizens, scouts, and elite patrons who gathered to watch private combat rehearsals.',
    ),
    ViewpointModel(
      id: 'vp_ludus_301',
      floorId: 'ludus_arena',
      title: 'The Quadriporticus Arcades & Gladiator Cells (Cubicula)',
      order: 301,
      normalizedX: 0.28,
      normalizedY: 0.35,
      latitude: 41.890080,
      longitude: 12.494750,
      imageAsset: 'assets/logo/Ludus Magnus.png',
      audioDuration: '3 min 45s',
      isVisited: false,
      description:
          'Enclosing the central arena was a monumental two-story colonnade (quadriporticus) supported by travertine Tuscan columns. Behind the portico were 14 small living quarters (cubicula) on each of the long sides.\n\n'
          'Up to two gladiators lived in each small cell, segregated rigorously by combat discipline: Murmillones with heavy crested helmets, nimble net-wielding Retiarii, and Thraeces with curved sica swords. Living conditions were strictly monitored by the lanista (gladiatorial manager) and imperial doctors to preserve valuable fighters.',
    ),
    ViewpointModel(
      id: 'vp_ludus_302',
      floorId: 'ludus_arena',
      title: 'Imperial Domitianic Brickwork & Drainage Conduits',
      order: 302,
      normalizedX: 0.72,
      normalizedY: 0.65,
      latitude: 41.889820,
      longitude: 12.495250,
      imageAsset: 'assets/logo/Ludus Magnus.png',
      audioDuration: '3 min 20s',
      isVisited: false,
      description:
          'Commissioned by Emperor Domitian (reigned 81–96 AD) and finished by Trajan, the school was built from durable Roman brickwork (opus latericium).\n\n'
          'Notice the curved brick drainage channel running around the perimeter of the arena. Ancient runoff systems collected sand and blood washed down after combat exercises, channeling wastewater into the main subterranean cloaca that connected into the Fosso Labicano valley stream.',
    ),
  ];

  static const List<ItinerarySegmentModel> ludusArenaItinerary = [
    ItinerarySegmentModel(
      fromId: 'vp_ludus_300',
      toId: 'vp_ludus_301',
      points: [
        Offset(41.889950, 12.495050),
        Offset(41.890020, 12.494880),
        Offset(41.890080, 12.494750),
      ],
    ),
    ItinerarySegmentModel(
      fromId: 'vp_ludus_301',
      toId: 'vp_ludus_302',
      points: [
        Offset(41.890080, 12.494750),
        Offset(41.889950, 12.495050),
        Offset(41.889820, 12.495250),
      ],
    ),
  ];

  // Level 2: Subterranean Tunnel & Wings (Tunnel Level)
  static const List<ViewpointModel> ludusSubterraneanViewpoints = [
    ViewpointModel(
      id: 'vp_ludus_303',
      floorId: 'ludus_tunnel',
      title: 'The Cryptoporticus Tunnel to the Colosseum Underground',
      order: 303,
      normalizedX: 0.20,
      normalizedY: 0.50,
      latitude: 41.889900,
      longitude: 12.494500,
      imageAsset: 'assets/logo/Ludus Magnus.png',
      audioDuration: '4 min 30s',
      isVisited: false,
      description:
          'Directly beneath the south-western corner of the Ludus Magnus begins one of the most famous secret corridors of antiquity: the subterranean Cryptoporticus.\n\n'
          'This vaulted tunnel ran straight under the modern Piazza del Colosseo for nearly 100 meters, connecting directly into the Colosseum’s Hypogeum (corridor vp_100 and vp_101). Gladiators dressed in full armour marched invisibly beneath the crowded city streets, avoiding disorderly mobs and arriving directly onto the lift machinery below the arena floor.',
    ),
    ViewpointModel(
      id: 'vp_ludus_304',
      floorId: 'ludus_tunnel',
      title: 'The Saniarium (Infirmary) & Spoliarium (Morgue) Wings',
      order: 304,
      normalizedX: 0.80,
      normalizedY: 0.50,
      latitude: 41.889920,
      longitude: 12.495350,
      imageAsset: 'assets/logo/Ludus Magnus.png',
      audioDuration: '3 min 35s',
      isVisited: false,
      description:
          'Adjacent to the school’s main training perimeter were specialized auxiliary wings essential to gladiator operations.\n\n'
          'The Saniarium was an advanced hospital staffed by Greek-trained physicians who specialized in trauma surgery, bone setting, and blood clotting. Across the courtyard lay the Spoliarium—the grim morgue where fighters mortally wounded in the Colosseum arena were brought, stripped of their weapons and armor, and verified dead before burial.',
    ),
  ];

  static const List<ItinerarySegmentModel> ludusSubterraneanItinerary = [
    ItinerarySegmentModel(
      fromId: 'vp_ludus_303',
      toId: 'vp_ludus_304',
      points: [
        Offset(41.889900, 12.494500),
        Offset(41.889950, 12.495050),
        Offset(41.889920, 12.495350),
      ],
    ),
  ];

  // ===========================================================================
  // 3. TEMPLE OF VENUS AND ROME (TEMPIO DI VENERE E ROMA)
  // ===========================================================================

  // Level 1: Venus Cella & East Terrace (Facing Colosseum)
  static const List<ViewpointModel> templeEastViewpoints = [
    ViewpointModel(
      id: 'vp_tvr_400',
      floorId: 'temple_east',
      title: 'Hadrian’s Gigantic Stylobate & Monolithic Colonnade',
      order: 400,
      normalizedX: 0.50,
      normalizedY: 0.50,
      latitude: 41.890830,
      longitude: 12.489950,
      imageAsset: 'assets/logo/Temple of Venus and Rome.png',
      audioDuration: '4 min 20s',
      isVisited: false,
      description:
          'You are standing atop the largest temple built in ancient Rome, measuring an astonishing 145 meters long by 100 meters wide. Emperor Hadrian designed the temple himself in 121 AD, showcasing his bold Hellenistic architectural taste.\n\n'
          'To clear space on the Velian Ridge, Hadrian had Nero’s luxurious Golden House vestibule leveled and enlisted architect Decrianus to move the colossal 30-meter bronze statue of the Colossus using a team of 24 elephants.\n\n'
          'The temple was raised on a gigantic artificial podium and enclosed by an outer colonnade of over 100 monolithic gray granite and white marble columns imported from imperial quarries across Egypt and Greece.',
    ),
    ViewpointModel(
      id: 'vp_tvr_401',
      floorId: 'temple_east',
      title: 'The Eastern Cella: Venus Felix & Mother of Rome',
      order: 401,
      normalizedX: 0.75,
      normalizedY: 0.50,
      latitude: 41.890800,
      longitude: 12.490400,
      imageAsset: 'assets/logo/Temple of Venus and Rome.png',
      audioDuration: '3 min 50s',
      isVisited: false,
      description:
          'The building’s signature architectural innovation was its twin back-to-back sanctuaries (cellae). This eastern sanctuary faced toward the Colosseum and was dedicated to Venus Felix, mother of Aeneas and divine ancestor of the Roman people.\n\n'
          'Newlywed couples from all strata of Roman society came to this altar to offer sacrifices and pray for marital fidelity and prosperity, watched over by a monumental seated cult statue of Venus sculpted in chryselephantine and gilded marble.',
    ),
    ViewpointModel(
      id: 'vp_tvr_402',
      floorId: 'temple_east',
      title: 'Maxentian Apse & Rhomboid Diamond Coffering',
      order: 402,
      normalizedX: 0.62,
      normalizedY: 0.35,
      latitude: 41.890760,
      longitude: 12.490180,
      imageAsset: 'assets/logo/Temple of Venus and Rome.png',
      audioDuration: '3 min 30s',
      isVisited: false,
      description:
          'Look closely at the magnificent surviving apse. After a devastating fire destroyed Hadrian’s timber-roofed original in 307 AD, Emperor Maxentius lavishly restored the monument with a concrete barrel-vaulted ceiling.\n\n'
          'The interior semi-dome features deeply recessed rhomboid (diamond-shaped) stucco coffers, framed by niches that once held porphyry columns and bronze statues. The symmetry and dramatic lighting deeply influenced Renaissance architects, including Donato Bramante when designing the new St. Peter’s Basilica.',
    ),
  ];

  static const List<ItinerarySegmentModel> templeEastItinerary = [
    ItinerarySegmentModel(
      fromId: 'vp_tvr_400',
      toId: 'vp_tvr_401',
      points: [
        Offset(41.890830, 12.489950),
        Offset(41.890815, 12.490180),
        Offset(41.890800, 12.490400),
      ],
    ),
    ItinerarySegmentModel(
      fromId: 'vp_tvr_401',
      toId: 'vp_tvr_402',
      points: [
        Offset(41.890800, 12.490400),
        Offset(41.890780, 12.490280),
        Offset(41.890760, 12.490180),
      ],
    ),
  ];

  // Level 2: Roma Cella & Forum Belvedere (Facing Forum)
  static const List<ViewpointModel> templeWestViewpoints = [
    ViewpointModel(
      id: 'vp_tvr_403',
      floorId: 'temple_west',
      title: 'The Western Cella: Roma Aeterna & The Eternal City',
      order: 403,
      normalizedX: 0.35,
      normalizedY: 0.50,
      latitude: 41.890850,
      longitude: 12.489350,
      imageAsset: 'assets/logo/Temple of Venus and Rome.png',
      audioDuration: '3 min 40s',
      isVisited: false,
      description:
          'Now explore the western half of the monument. In a clever literary and conceptual pun, Hadrian paired "AMOR" (Love, represented by Venus) with its perfect palindrome "ROMA" (Rome).\n\n'
          'This sanctuary was consecrated to Roma Aeterna, the personification of Rome as an eternal divine protector. The colossal seated goddess held a miniature Winged Victory in one hand and a spear in the other, symbolizing supreme imperial authority extending to the ends of the known world.',
    ),
    ViewpointModel(
      id: 'vp_tvr_404',
      floorId: 'temple_west',
      title: 'Forum Belvedere: Grand Overlook of Via Sacra & Titus',
      order: 404,
      normalizedX: 0.15,
      normalizedY: 0.50,
      latitude: 41.890900,
      longitude: 12.488950,
      imageAsset: 'assets/logo/Temple of Venus and Rome.png',
      audioDuration: '4 min 05s',
      isVisited: false,
      description:
          'Step onto the western terrace balustrade for one of the most breathtaking panoramas in Rome.\n\n'
          'Directly in front of you, the paved stones of the Via Sacra descend into the Roman Forum. To your immediate left rises the Arch of Titus; to your right stand the colossal brick vaults of the Basilica of Maxentius. Far in the distance, you can see the Senate House (Curia) and the Capitoline Hill framing the horizon.',
    ),
  ];

  static const List<ItinerarySegmentModel> templeWestItinerary = [
    ItinerarySegmentModel(
      fromId: 'vp_tvr_403',
      toId: 'vp_tvr_404',
      points: [
        Offset(41.890850, 12.489350),
        Offset(41.890875, 12.489150),
        Offset(41.890900, 12.488950),
      ],
    ),
  ];

  // ===========================================================================
  // 4. ROMAN FORUM (FORUM ROMANUM / VIA SACRA)
  // ===========================================================================

  // Level 1: Via Sacra & Triumphal Way (Sacred Way)
  static const List<ViewpointModel> forumViaSacraViewpoints = [
    ViewpointModel(
      id: 'vp_forum_500',
      floorId: 'forum_via_sacra',
      title: 'The Arch of Titus & The Spoils of Jerusalem',
      order: 500,
      normalizedX: 0.85,
      normalizedY: 0.80,
      latitude: 41.890650,
      longitude: 12.488600,
      imageAsset: 'assets/logo/Roman Forum.png',
      audioDuration: '4 min 50s',
      isVisited: false,
      description:
          'Erected in 81 AD by Emperor Domitian, this triumphal single arch commemorates the deification of his older brother Titus and their victory in the Jewish War.\n\n'
          'Look directly inside the archway at the south inner relief panel: you see Roman soldiers crowned with laurel wreaths triumphantly carrying the sacred treasures looted from the Temple of Jerusalem in 70 AD—the monumental seven-branched solid gold Menorah, the Table of Showbread, and the silver trumpets of Jubilee.\n\n'
          'On the opposite panel, Emperor Titus rides in a four-horse triumphal chariot, crowned by the Winged Goddess of Victory as they pass through Rome’s triumphant gates.',
    ),
    ViewpointModel(
      id: 'vp_forum_501',
      floorId: 'forum_via_sacra',
      title: 'The Basilica of Maxentius and Constantine',
      order: 501,
      normalizedX: 0.70,
      normalizedY: 0.40,
      latitude: 41.891600,
      longitude: 12.487950,
      imageAsset: 'assets/logo/Roman Forum.png',
      audioDuration: '4 min 15s',
      isVisited: false,
      description:
          'Dominating the north side of the Via Sacra stand the colossal brick-faced concrete vaults of the Basilica of Maxentius, begun in 308 AD and completed by Constantine.\n\n'
          'This was the largest building in the entire Forum, covering an area of 6,500 square meters. The three surviving northern coffered barrel vaults span 24 meters across. The central nave rose to an astounding 39 meters—taller than most medieval cathedrals.\n\n'
          'In its western apse once sat the Colossus of Constantine, an eight-times life-size statue whose massive surviving marble head, hand, and foot are now exhibited in the Capitoline Museums.',
    ),
    ViewpointModel(
      id: 'vp_forum_502',
      floorId: 'forum_via_sacra',
      title: 'Temple of Antoninus and Faustina (San Lorenzo in Miranda)',
      order: 502,
      normalizedX: 0.45,
      normalizedY: 0.35,
      latitude: 41.891950,
      longitude: 12.486800,
      imageAsset: 'assets/logo/Roman Forum.png',
      audioDuration: '3 min 40s',
      isVisited: false,
      description:
          'Built in 141 AD by Emperor Antoninus Pius to honor his deceased, beloved empress Faustina, this temple features six soaring monolithic cipollino marble columns, each 17 meters tall.\n\n'
          'Notice the deep horizontal grooves near the top of the columns: during the Middle Ages, ropes were tied around them in failed attempts to pull down the temple for building stones.\n\n'
          'The building survived almost completely intact because it was consecrated as the Christian Church of San Lorenzo in Miranda in the 7th century, preserving this ancient pagan masterpiece for posterity.',
    ),
    ViewpointModel(
      id: 'vp_forum_503',
      floorId: 'forum_via_sacra',
      title: 'Temple of Vesta & The House of the Vestal Virgins (Atrium Vestae)',
      order: 503,
      normalizedX: 0.35,
      normalizedY: 0.60,
      latitude: 41.891650,
      longitude: 12.486250,
      imageAsset: 'assets/logo/Roman Forum.png',
      audioDuration: '4 min 30s',
      isVisited: false,
      description:
          'Before you lies the spiritual heart of ancient Rome. The circular Temple of Vesta housed Rome’s most sacred symbol: the eternal flame, which was never permitted to go out.\n\n'
          'The flame was tended by the six Vestal Virgins, aristocratic women selected between ages 6 and 10 who took a strict 30-year vow of chastity. They enjoyed extraordinary civic privileges, including front-row seats at the Colosseum, legal autonomy, and the power to pardon condemned prisoners on sight.\n\n'
          'Directly behind the temple lies the Atrium Vestae, an opulent three-story, 50-room palace featuring a central courtyard with three reflecting pools and statues honoring Chief Vestals (Virgines Vestales Maximae).',
    ),
  ];

  static const List<ItinerarySegmentModel> forumViaSacraItinerary = [
    ItinerarySegmentModel(
      fromId: 'vp_forum_500',
      toId: 'vp_forum_501',
      points: [
        Offset(41.890650, 12.488600),
        Offset(41.891100, 12.488350),
        Offset(41.891600, 12.487950),
      ],
    ),
    ItinerarySegmentModel(
      fromId: 'vp_forum_501',
      toId: 'vp_forum_502',
      points: [
        Offset(41.891600, 12.487950),
        Offset(41.891780, 12.487400),
        Offset(41.891950, 12.486800),
      ],
    ),
    ItinerarySegmentModel(
      fromId: 'vp_forum_502',
      toId: 'vp_forum_503',
      points: [
        Offset(41.891950, 12.486800),
        Offset(41.891820, 12.486550),
        Offset(41.891650, 12.486250),
      ],
    ),
  ];

  // Level 2: Curia, Senate & Rostra (Political Core)
  static const List<ViewpointModel> forumSenateViewpoints = [
    ViewpointModel(
      id: 'vp_forum_504',
      floorId: 'forum_senate_rostra',
      title: 'Curia Julia: The Roman Senate House',
      order: 504,
      normalizedX: 0.65,
      normalizedY: 0.25,
      latitude: 41.892700,
      longitude: 12.485300,
      imageAsset: 'assets/logo/Roman Forum.png',
      audioDuration: '4 min 40s',
      isVisited: false,
      description:
          'You are gazing upon the epicenter of Roman political power: the Curia Julia, commissioned by Julius Caesar in 44 BC and dedicated by Augustus in 29 BC.\n\n'
          'Remarkably preserved, the building retains its original brick facade, tall bronze doorway, and rich interior floor of polychrome marble in opus sectile patterns. Along the stepped side tiers sat the 300 Senators who debated foreign treaties, declared wars against Carthage, and governed provinces from Britain to Mesopotamia.',
    ),
    ViewpointModel(
      id: 'vp_forum_505',
      floorId: 'forum_senate_rostra',
      title: 'The Rostra: The Imperial Speaker’s Platform',
      order: 505,
      normalizedX: 0.42,
      normalizedY: 0.45,
      latitude: 41.892400,
      longitude: 12.484900,
      imageAsset: 'assets/logo/Roman Forum.png',
      audioDuration: '4 min 10s',
      isVisited: false,
      description:
          'This curved red brick platform was the world’s most influential public podium. Named the Rostra because it was decorated with the bronze ramming prows (rostra) of captured enemy warships from the battle of Antium in 338 BC.\n\n'
          'From this platform, Cicero delivered his fiery Philippics against Mark Antony, Julius Caesar introduced laws bypassing senatorial vetoes, and Mark Antony delivered the famous funeral oration over Caesar’s bloodstained toga that ignited the fall of the Roman Republic.',
    ),
    ViewpointModel(
      id: 'vp_forum_506',
      floorId: 'forum_senate_rostra',
      title: 'Temple of Saturn & The State Treasury (Aerarium)',
      order: 506,
      normalizedX: 0.20,
      normalizedY: 0.60,
      latitude: 41.892200,
      longitude: 12.484500,
      imageAsset: 'assets/logo/Roman Forum.png',
      audioDuration: '3 min 50s',
      isVisited: false,
      description:
          'Standing proudly at the foot of the Capitoline Hill are the eight surviving Ionic granite columns of the Temple of Saturn, first consecrated in 497 BC.\n\n'
          'In its massive subterranean chambers lay the Aerarium Saturni—the official gold and silver treasury of the Roman Republic, along with the bronze tablets of Roman law and the state banners (aquilae).\n\n'
          'Each December 17th, the steps of this temple hosted the opening sacrifices for Saturnalia, the beloved Roman festival where slaves and masters exchanged places, gifts were given, and Rome celebrated in joyous revelry.',
    ),
  ];

  static const List<ItinerarySegmentModel> forumSenateItinerary = [
    ItinerarySegmentModel(
      fromId: 'vp_forum_504',
      toId: 'vp_forum_505',
      points: [
        Offset(41.892700, 12.485300),
        Offset(41.892550, 12.485100),
        Offset(41.892400, 12.484900),
      ],
    ),
    ItinerarySegmentModel(
      fromId: 'vp_forum_505',
      toId: 'vp_forum_506',
      points: [
        Offset(41.892400, 12.484900),
        Offset(41.892300, 12.484700),
        Offset(41.892200, 12.484500),
      ],
    ),
  ];
}
