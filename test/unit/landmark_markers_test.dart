import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:colosseum_client/app/data/datasources/local/tour_local_data_source.dart';
import 'package:colosseum_client/app/data/models/landmark_marker_model.dart';
import 'package:colosseum_client/app/modules/home/widgets/landmark_map_marker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LandmarkMarkerModel and Local Landmark Markers Tests', () {
    late TourLocalDataSource localDataSource;

    setUp(() {
      localDataSource = TourLocalDataSource();
    });

    test('LocalDataSource loads all 5 archaeological landmarks with distinct colors from seed', () async {
      final all = await localDataSource.getCachedLandmarkMarkers();
      expect(all.length, 5);

      final ids = all.map((m) => m.id).toSet();
      expect(ids, {
        'colosseum',
        'arch_of_constantine',
        'ludus_magnus',
        'roman_forum',
        'temple_venus_rome',
      });

      // Verify each location has a distinct, unique color
      final colors = all.map((m) => m.color.toARGB32()).toSet();
      expect(colors.length, 5, reason: 'Each landmark must have a distinct color');

      // Verify each landmark has valid geo coordinates and non-empty name
      for (final landmark in all) {
        expect(landmark.name.isNotEmpty, isTrue);
        expect(landmark.latitude, greaterThan(41.88));
        expect(landmark.latitude, lessThan(41.90));
        expect(landmark.longitude, greaterThan(12.48));
        expect(landmark.longitude, lessThan(12.50));
        expect(landmark.minZoom, lessThan(landmark.maxZoom));
        expect(landmark.category, isNotNull);
      }
    });

    test('LandmarkMarkerModel serialization roundtrip (toJson and fromJson)', () {
      const model = LandmarkMarkerModel(
        id: 'test_marker',
        name: 'Test Monument',
        coordinates: LatLng(41.8905, 12.4920),
        color: Color(0xFF1E88E5),
        category: 'Monument',
        labelOffset: Offset(0, -5),
        minZoom: 14.0,
        maxZoom: 20.0,
      );

      final json = model.toJson();
      expect(json['id'], 'test_marker');
      expect(json['name'], 'Test Monument');
      expect(json['latitude'], 41.8905);
      expect(json['longitude'], 12.4920);

      final reconstructed = LandmarkMarkerModel.fromJson(json);
      expect(reconstructed.id, model.id);
      expect(reconstructed.name, model.name);
      expect(reconstructed.latitude, model.latitude);
      expect(reconstructed.longitude, model.longitude);
      expect(reconstructed.color.toARGB32(), model.color.toARGB32());
      expect(reconstructed.labelOffset.dy, -5.0);
    });

    test('LandmarkMarkerModel copyWith updates fields cleanly', () {
      const original = LandmarkMarkerModel(
        id: 'colosseum',
        name: 'Colosseum',
        coordinates: LatLng(41.89021, 12.492231),
        color: Color(0xFFDD1110),
        category: 'Amphitheatre',
      );
      final copied = original.copyWith(name: 'Flavian Colosseum', color: Colors.amber);

      expect(copied.id, original.id);
      expect(copied.name, 'Flavian Colosseum');
      expect(copied.color, Colors.amber);
      expect(copied.coordinates, original.coordinates);
    });

    test('LandmarkLabelBubble.formatName splits names with >3 words into two lines and preserves <=3 words', () {
      // 1 to 3 words: remains on 1 line
      expect(LandmarkLabelBubble.formatName('Colosseum'), 'Colosseum');
      expect(LandmarkLabelBubble.formatName('Roman Forum'), 'Roman Forum');
      expect(LandmarkLabelBubble.formatName('Arch of Constantine'), 'Arch of Constantine');

      // More than 3 words: split into two lines
      expect(
        LandmarkLabelBubble.formatName('Temple of Venus and Rome'),
        'Temple of Venus\nand Rome',
      );
      expect(
        LandmarkLabelBubble.formatName('Four Word Landmark Here'),
        'Four Word\nLandmark Here',
      );
    });
  });
}
