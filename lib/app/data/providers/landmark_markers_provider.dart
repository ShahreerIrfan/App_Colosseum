import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/landmark_marker_model.dart';

/// Centralized configuration provider for archaeological landmarks in the Colosseum zone.
///
/// Each landmark is configured with:
/// - Real-world geographic anchor coordinates (latitude, longitude)
/// - Distinct, high-contrast theme color
/// - Architectural category and icon
/// - Strategic anti-collision labelOffset preventing badge overlap when zooming out
/// - Visibility zoom thresholds
abstract class LandmarkMarkersProvider {
  LandmarkMarkersProvider._();

  /// 1. Colosseum (Flavian Amphitheatre)
  /// Rome's iconic elliptical amphitheatre — centered as the anchor point.
  static const colosseum = LandmarkMarkerModel(
    id: 'colosseum',
    name: 'Colosseum',
    coordinates: LatLng(41.890210, 12.492231),
    color: Color(0xFFDD1110), // Imperial Red (app primary theme)
    category: 'Amphitheatre',
    icon: Icons.stadium_rounded,
    imagePath: 'assets/logo/Colosseum.png',
    labelOffset: Offset(0, 0),
    minZoom: 13.0,
    maxZoom: 21.0,
  );

  /// 2. Arch of Constantine (Arco di Costantino)
  /// Triumphal arch standing between the Colosseum and Palatine Hill.
  /// Offset southward to prevent overlap with Colosseum badge.
  static const archOfConstantine = LandmarkMarkerModel(
    id: 'arch_of_constantine',
    name: 'Arch of Constantine',
    coordinates: LatLng(41.889762, 12.490667),
    color: Color(0xFFFF8F00), // Vibrant Amber Orange
    category: 'Triumphal Arch',
    icon: Icons.foundation_rounded,
    imagePath: 'assets/logo/Arch of Constantine.png',
    labelOffset: Offset(-18, 28),
    minZoom: 13.0,
    maxZoom: 21.0,
  );

  /// 3. Ludus Magnus (The Great Gladiatorial School)
  /// Ancient gladiator training school northeast/east of the Colosseum.
  /// Offset eastward to avoid overlap with Colosseum's right boundary.
  static const ludusMagnus = LandmarkMarkerModel(
    id: 'ludus_magnus',
    name: 'Ludus Magnus',
    coordinates: LatLng(41.889950, 12.495050),
    color: Color(0xFF1E88E5), // Mediterranean Blue
    category: 'Gladiator School',
    icon: Icons.fitness_center_rounded,
    imagePath: 'assets/logo/Ludus Magnus.png',
    labelOffset: Offset(36, 14),
    minZoom: 13.0,
    maxZoom: 21.0,
  );

  /// 4. Roman Forum (Forum Romanum / Via Sacra)
  /// The historic heart of civic, political, and commercial Roman life.
  static const romanForum = LandmarkMarkerModel(
    id: 'roman_forum',
    name: 'Roman Forum',
    coordinates: LatLng(41.892050, 12.486600),
    color: Color(0xFF2E7D32), // Roman Laurel Green
    category: 'Forum',
    icon: Icons.account_balance_rounded,
    imagePath: 'assets/logo/Roman Forum.png',
    labelOffset: Offset(0, -6),
    minZoom: 13.0,
    maxZoom: 21.0,
  );

  /// 5. Temple of Venus and Rome (Tempio di Venere e Roma)
  /// Largest known temple in ancient Rome, situated between the Forum and Colosseum.
  /// Offset northwest to prevent overlap with Arch of Constantine & Colosseum.
  static const templeOfVenusAndRome = LandmarkMarkerModel(
    id: 'temple_venus_rome',
    name: 'Temple of Venus and Rome',
    coordinates: LatLng(41.890830, 12.489720),
    color: Color(0xFF8E24AA), // Royal Imperial Purple
    category: 'Ancient Temple',
    icon: Icons.temple_buddhist_rounded,
    imagePath: 'assets/logo/Temple of Venus and Rome.png',
    labelOffset: Offset(-26, -22),
    minZoom: 13.0,
    maxZoom: 21.0,
  );

  /// Centralized list of all 5 landmarks.
  static List<LandmarkMarkerModel> get all => [
        colosseum,
        archOfConstantine,
        ludusMagnus,
        romanForum,
        templeOfVenusAndRome,
      ];

  /// Fast lookup map by landmark ID.
  static Map<String, LandmarkMarkerModel> get asMap => {
        for (final marker in all) marker.id: marker,
      };

  /// Returns marker by ID, or null if not found.
  static LandmarkMarkerModel? getById(String id) => asMap[id];

  /// Architecture-ready legend metadata for optional UI display.
  static List<Map<String, dynamic>> get legendEntries => all
      .map((m) => {
            'id': m.id,
            'name': m.name,
            'color': m.color,
            'category': m.category,
          })
      .toList();
}
