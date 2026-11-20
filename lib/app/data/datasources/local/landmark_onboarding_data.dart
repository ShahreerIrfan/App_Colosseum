import '../../models/landmark_onboarding_model.dart';

/// Pre-populated, authentic onboarding and historical orientation data for outdoor park monuments.
class LandmarkOnboardingData {
  LandmarkOnboardingData._();

  static const Map<String, LandmarkOnboardingModel> _data = {
    'colosseum': LandmarkOnboardingModel(
      landmarkId: 'colosseum',
      title: 'Colosseum',
      subtitle: 'Flavian Amphitheatre',
      era: '70 – 80 AD (Flavian Dynasty)',
      builders: 'Emperor Vespasian, completed by Titus',
      historicalSummary:
          'Commissioned in 70 AD by Emperor Vespasian and inaugurated in 80 AD by Titus with 100 days of games. The largest stone amphitheatre in the Roman Empire, engineered with travertine limestone, tufa, and concrete to seat over 50,000 spectators for gladiatorial battles and public spectacles.',
      securityGuidelines: [
        'Valid ticket and official government photo ID must match and be presented at the gate.',
        'Backpacks and bags exceeding 30×30×15 cm are strictly prohibited (no luggage storage on site).',
        'Glass bottles, alcoholic beverages, sharp objects, and selfie sticks are not permitted.',
        'All visitors must pass through security screening and metal detectors prior to entry.',
      ],
      levelHighlights: [
        'Level 0: Hypogeum (Subterranean staging area, animal cages, and elevator lifts)',
        'Level 1: Arena Floor & Lower Cavea (Imperial box and equestrian seating tiers)',
        'Level 2: Museum & Exhibition Galleries (Historical artifacts, models, and Colosseum history)',
        'Level 3: Upper Belvedere (Panoramic terraces overlooking the Roman Forum and city)',
      ],
      audioIntroText:
          'Welcome to the Flavian Amphitheatre, universally known as the Colosseum. Commissioned in 70 AD by Emperor Vespasian and inaugurated in 80 AD by his son Titus, this marvel seated over 50,000 Romans. Before entering the security gates, please ensure your photo ID and ticket voucher are ready. Large bags exceeding 30 centimeters are strictly prohibited. Once inside, you can explore the subterranean Hypogeum, the grand Arena floor, and the panoramic exhibition galleries.',
      audioAssetPath: 'assets/audio/colosseum_welcome.mp3',
      outerRadiusMeters: 65.0,
    ),
    'arch_of_constantine': LandmarkOnboardingModel(
      landmarkId: 'arch_of_constantine',
      title: 'Arch of Constantine',
      subtitle: 'Triumphal Arch of Emperor Constantine',
      era: '315 AD (Late Roman Empire)',
      builders: 'Roman Senate, dedicated to Emperor Constantine I',
      historicalSummary:
          'A monumental triumphal arch erected to celebrate Constantine I’s victory over Maxentius at the Battle of the Milvian Bridge in 312 AD. Incorporates relief sculptures and architectural spolia from earlier monuments of Trajan, Hadrian, and Marcus Aurelius.',
      securityGuidelines: [
        'Outdoor open-air monument located on Via Triumphalis; open access with no entry fee.',
        'Do not cross low preservation barriers or touch ancient marble reliefs.',
        'Commercial photography and drone flights require authorized park permits.',
      ],
      levelHighlights: [
        'Attic Inscription: Dedication to Emperor Constantine and divine inspiration',
        'Central Archway: Massive marble vault spanning the historic triumphal processional route',
        'Spolia Medallions: Hadrianic hunting roundels and Trajanic battle reliefs',
      ],
      audioIntroText:
          'Standing before you is the Arch of Constantine, erected by the Roman Senate in 315 AD to commemorate Constantine’s triumph at the Milvian Bridge. Notice the intricate marble panels reused from the monuments of emperors Trajan, Hadrian, and Marcus Aurelius, symbolizing imperial continuity. Respect preservation cordons while admiring this triumphal gateway.',
      audioAssetPath: 'assets/audio/arch_constantine_welcome.mp3',
      outerRadiusMeters: 18.0,
    ),
    'ludus_magnus': LandmarkOnboardingModel(
      landmarkId: 'ludus_magnus',
      title: 'Ludus Magnus',
      subtitle: 'Gladiatorial Training Barracks',
      era: '81 – 96 AD (Flavian Dynasty)',
      builders: 'Emperor Domitian',
      historicalSummary:
          'The premier gladiatorial training school of ancient Rome, directly connected to the Colosseum subterranean levels via an underground tunnel. Features living quarters for gladiators surrounding an elliptical practice arena matching the Colosseum’s curve.',
      securityGuidelines: [
        'Viewable from the elevated pedestrian walkway on Via di San Giovanni in Laterano.',
        'Climbing down into the archaeological excavation pit is strictly prohibited.',
        'Watch your step along the sidewalk barrier and keep personal belongings secure.',
      ],
      levelHighlights: [
        'Miniature Arena: Scaled practice arena reproducing the exact Colosseum oval curve',
        'Gladiator Cells: Brick-faced living quarters arranged around a travertine portico',
        'Underground Tunnel: Subterranean corridor linking directly to the Colosseum Hypogeum',
      ],
      audioIntroText:
          'You are looking at the Ludus Magnus, Rome’s premier gladiatorial academy built by Emperor Domitian. Here, elite fighters trained in a miniature arena that matched the Colosseum’s curvature. An underground tunnel once linked these barracks straight into the Colosseum hypogeum, allowing gladiators to march unseen to their arena entrance.',
      audioAssetPath: 'assets/audio/ludus_magnus_welcome.mp3',
      outerRadiusMeters: 35.0,
    ),
    'temple_venus_rome': LandmarkOnboardingModel(
      landmarkId: 'temple_venus_rome',
      title: 'Temple of Venus and Rome',
      subtitle: 'Sanctuary of Venus Felix and Roma Aeterna',
      era: '121 – 141 AD (Hadrianic Era)',
      builders: 'Emperor Hadrian, dedicated by Antoninus Pius',
      historicalSummary:
          'The largest known temple in ancient Rome, personally designed by Emperor Hadrian. Dedicated to Venus Felix (ancestor of the Roman people) and Roma Aeterna (personification of the eternal city), featuring two back-to-back cellae facing East and West.',
      securityGuidelines: [
        'Included with Colosseum and Roman Forum archaeological park admission ticket.',
        'Baggage inspection and security screening required at archaeological park entrances.',
        'Flat, comfortable walking shoes recommended for the elevated travertine podium.',
      ],
      levelHighlights: [
        'Cella of Roma Aeterna: West-facing sanctuary overlooking the Roman Forum',
        'Cella of Venus Felix: East-facing apse overlooking the Colosseum plaza',
        'Coffered Concrete Apse: Preserved vaulted ceiling with diamond-patterned stucco coffers',
      ],
      audioIntroText:
          'Welcome to the Temple of Venus and Rome, designed by Emperor Hadrian himself in 121 AD as Rome’s grandest sacred sanctuary. Its back-to-back temples honored Venus facing the Colosseum and eternal Rome facing the Forum. Walk carefully across the elevated stone platform to view the magnificent coffered ceiling of the preserved apse.',
      audioAssetPath: 'assets/audio/temple_venus_rome_welcome.mp3',
      outerRadiusMeters: 55.0,
    ),
    'roman_forum': LandmarkOnboardingModel(
      landmarkId: 'roman_forum',
      title: 'Roman Forum',
      subtitle: 'Via Sacra & Civic Center of Ancient Rome',
      era: '6th Century BC – 4th Century AD',
      builders: 'Kings of Rome, Republic Magistrates, and Imperial Emperors',
      historicalSummary:
          'The political, commercial, and religious epicenter of the Roman world for over a millennium. Flanked by the Senate House (Curia), triumphal arches, sacred temples, and the ancient triumphal route of the Via Sacra.',
      securityGuidelines: [
        'Access requires a combined Colosseum-Forum-Palatine archaeological pass.',
        'Entry through the dedicated gate turnstiles with barcode ticket scanning and bag checks.',
        'No large wheeled luggage; drinkable water fountains (nasoni) are located inside.',
      ],
      levelHighlights: [
        'Via Sacra: The sacred main street trodden by triumphal processions',
        'Curia Julia: The historic meeting place of the Roman Senate',
        'Temple of Saturn & Rostra: Ancient state treasury and public orator podium',
        'Arch of Septimius Severus: Tri-vaulted monumental triumphal arch from 203 AD',
      ],
      audioIntroText:
          'You are approaching the Roman Forum, the beating heart of ancient Roman politics, commerce, and religion for over a thousand years. Through this gate, the Via Sacra leads past the Senate House, sacred temples, and triumphal monuments. Please have your admission pass scanned at the turnstile and stay on designated stone paths.',
      audioAssetPath: 'assets/audio/roman_forum_welcome.mp3',
      outerRadiusMeters: 50.0,
    ),
  };

  static final Map<String, LandmarkOnboardingModel> _dynamicOverrides = {};

  /// Registers or overrides onboarding content dynamically (e.g. from backend API).
  static void registerOnboarding(LandmarkOnboardingModel model) {
    _dynamicOverrides[_normalizeId(model.landmarkId)] = model;
  }

  /// Clears dynamic overrides (useful for testing).
  static void clearOverrides() {
    _dynamicOverrides.clear();
  }

  /// Retrieves onboarding content for the specified monument ID.
  /// Handles ID normalization (e.g. temple_of_venus_and_rome -> temple_venus_rome).
  static LandmarkOnboardingModel getForLandmark(
    String id, {
    String language = 'en',
  }) {
    final normalized = _normalizeId(id);
    return _dynamicOverrides[normalized] ??
        _data[normalized] ??
        _createFallbackModel(id);
  }

  static String _normalizeId(String id) {
    switch (id.toLowerCase().trim()) {
      case 'colosseum':
      case 'colosseo':
        return 'colosseum';
      case 'arch_of_constantine':
      case 'arco_di_costantino':
      case 'arch-of-constantine':
        return 'arch_of_constantine';
      case 'ludus_magnus':
      case 'ludus-magnus':
        return 'ludus_magnus';
      case 'temple_venus_rome':
      case 'temple_of_venus_and_rome':
      case 'temple-venus-rome':
      case 'tempio_di_venere_e_roma':
        return 'temple_venus_rome';
      case 'roman_forum':
      case 'foro_romano':
      case 'roman-forum':
        return 'roman_forum';
      default:
        return id;
    }
  }

  static LandmarkOnboardingModel _createFallbackModel(String id) {
    return LandmarkOnboardingModel(
      landmarkId: id,
      title: id,
      subtitle: 'Archaeological Monument',
      era: 'Ancient Roman Era',
      builders: 'Roman Architects and Engineers',
      historicalSummary:
          'An iconic monument of the Colosseum Archaeological Park, bearing witness to centuries of Roman history, culture, and architecture.',
      securityGuidelines: const [
        'Valid ticket required for entry.',
        'Follow park security instructions and preserve archaeological structures.',
      ],
      levelHighlights: const [
        'Main Monument Viewpoint',
      ],
      audioIntroText:
          'Welcome to this ancient Roman monument. Please review entry requirements before stepping inside.',
      outerRadiusMeters: 40.0,
    );
  }

  /// All 5 canonical onboarding datasets.
  static List<LandmarkOnboardingModel> get all => _data.values.toList();
}
