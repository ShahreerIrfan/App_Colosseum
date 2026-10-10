import 'package:latlong2/latlong.dart';

import '../models/landmark_overlay_model.dart';

/// Calibrated configurations for all five archaeological landmarks in the Colosseum zone.
///
/// Each overlay is calibrated with:
/// - Real-world geographic center coordinate
/// - Ground-contact footprint anchor offsets [anchorX, anchorY]
/// - Physical dimensions in meters matching real architectural footprints
/// - Calibrated orientation angle aligned to real-world ground features
/// - Zoom level thresholds
abstract class ColosseumLandmarkOverlays {
  ColosseumLandmarkOverlays._();

  static const String assetFolder = 'assets/logo';

  /// Geographic center of the entire archaeological park containing all 5 landmarks.
  static const LatLng archaeologicalParkCenter = LatLng(41.891000, 12.490500);

  /// 1. Colosseum (Flavian Amphitheatre)
  ///
  /// Real footprint: Ellipse of 189m x 156m.
  /// The illustration is drawn with the arena already in geographic orientation
  /// (outer wall at NE, arena entrance at SW), aligned with rotation 0.0°.
  static final colosseum = MapLandmarkOverlay(
    id: 'colosseum',
    name: 'Colosseum',
    assetPath: '$assetFolder/Colosseum.png',
    center: const LatLng(41.890250, 12.492230),
    widthMeters: 190.0,
    heightMeters: 158.0,
    rotationDegrees: 0.0,
    anchorX: 0.50,
    anchorY: 0.52,
    zIndex: 1,
    minZoom: 13.0,
    maxZoom: 21.0,
  );

  /// 2. Arch of Constantine (Arco di Costantino)
  ///
  /// Real footprint: Frontal elevation of triumphal arch southwest of Colosseum.
  /// Aligned upright on the paved plaza along Via Triumphalis.
  static final archOfConstantine = MapLandmarkOverlay(
    id: 'arch_of_constantine',
    name: 'Arch of Constantine',
    assetPath: '$assetFolder/Arch of Constantine.png',
    center: const LatLng(41.889762, 12.490667),
    widthMeters: 34.0,
    heightMeters: 30.0,
    rotationDegrees: 0.0,
    anchorX: 0.50,
    anchorY: 0.75,
    zIndex: 2,
    minZoom: 14.5,
    maxZoom: 21.0,
  );

  /// 3. Ludus Magnus (The Great Gladiatorial Training School)
  ///
  /// Real footprint: Excavated gladiator barracks and arena courtyard between Via Labicana
  /// and Via di San Giovanni in Laterano. Walls aligned parallel with the Roman street grid.
  static final ludusMagnus = MapLandmarkOverlay(
    id: 'ludus_magnus',
    name: 'Ludus Magnus',
    assetPath: '$assetFolder/Ludus Magnus.png',
    center: const LatLng(41.890450, 12.495100),
    widthMeters: 82.0,
    heightMeters: 68.0,
    rotationDegrees: 0.0,
    anchorX: 0.52,
    anchorY: 0.55,
    zIndex: 2,
    minZoom: 14.0,
    maxZoom: 21.0,
  );

  /// 4. Temple of Venus and Rome (Tempio di Venere e Roma)
  ///
  /// Real footprint: Hadrian's elevated podium platform. The colonnade and steps align
  /// with the rectangular terrace facing Piazza del Colosseo and Via Sacra.
  static final templeOfVenusAndRome = MapLandmarkOverlay(
    id: 'temple_venus_rome',
    name: 'Temple of Venus and Rome',
    assetPath: '$assetFolder/Temple of Venus and Rome.png',
    center: const LatLng(41.890900, 12.489100),
    widthMeters: 135.0,
    heightMeters: 95.0,
    rotationDegrees: -3.0,
    anchorX: 0.52,
    anchorY: 0.60,
    zIndex: 1,
    minZoom: 13.5,
    maxZoom: 21.0,
  );

  /// 5. Roman Forum (Temple of Antoninus & Faustina / San Lorenzo in Miranda)
  ///
  /// Real footprint: Iconic temple on the north side of the Via Sacra.
  /// Its steps face directly south onto the Via Sacra opposite the Regia.
  static final romanForum = MapLandmarkOverlay(
    id: 'roman_forum',
    name: 'Roman Forum',
    assetPath: '$assetFolder/Roman Forum.png',
    center: const LatLng(41.892050, 12.486600),
    widthMeters: 58.0,
    heightMeters: 52.0,
    rotationDegrees: 0.0,
    anchorX: 0.50,
    anchorY: 0.78,
    zIndex: 0,
    minZoom: 13.0,
    maxZoom: 21.0,
  );

  /// List of all 5 landmarks ordered by default rendering stack (zIndex).
  static List<MapLandmarkOverlay> get all => [
        romanForum,
        templeOfVenusAndRome,
        colosseum,
        ludusMagnus,
        archOfConstantine,
      ];
}
