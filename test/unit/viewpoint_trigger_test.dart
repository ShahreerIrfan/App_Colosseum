import 'package:flutter_test/flutter_test.dart';
import 'package:colosseum_client/app/data/models/viewpoint_model.dart';
import 'package:colosseum_client/app/data/models/user_location_model.dart';
import 'package:colosseum_client/app/data/services/tour_navigation_engine.dart';

void main() {
  const viewpoint = ViewpointModel(id: 'stop', floorId: 'test', title: 'Stop',
    order: 1, normalizedX: 0.5, normalizedY: 0.5,
    triggerRadiusMeters: 2, targetGazeHeadingDegrees: 0);

  test('trigger settings survive caching and visited-state copies', () {
    final restored = ViewpointModel.fromJson(viewpoint.toJson()).copyWith(isVisited: true);
    expect(restored.triggerRadiusMeters, 2);
    expect(restored.targetGazeHeadingDegrees, 0);
  });

  test('radius and heading both gate automatic narration with north wraparound', () {
    var played = 0;
    final engine = TourNavigationEngine(onAutoPlayViewpoint: (_) => played++);
    engine.startTour(floorId: 'test', viewpoints: [viewpoint], isVoiceGuidanceEnabled: false);
    void move(double x, double? heading) => engine.updateLocation(
      UserLocationModel(floorId: 'test', normalizedX: x, normalizedY: 0.5,
        headingDegrees: heading), isSimulated: true);
    move(0.55, 355);
    expect(played, 0);
    move(0.5, null);
    expect(played, 0);
    move(0.5, 180);
    expect(played, 0);
    move(0.5, 355);
    expect(played, 1);
    move(0.5, 5);
    expect(played, 1);
  });

  test('saved geographic position takes precedence over matching canvas coordinates', () {
    final stop = viewpoint.copyWith(floorId: 'floor_1', latitude: 41.89, longitude: 12.49);
    expect(stop.latLng.latitude, 41.89);
    expect(stop.latLng.longitude, 12.49);
    var played = 0;
    final engine = TourNavigationEngine(onAutoPlayViewpoint: (_) => played++);
    engine.startTour(floorId: 'floor_1', viewpoints: [stop], isVoiceGuidanceEnabled: false);
    engine.updateLocation(const UserLocationModel(
      floorId: 'floor_1', normalizedX: 0.5, normalizedY: 0.5,
      latitude: 41.891, longitude: 12.49, headingDegrees: 0,
    ), isSimulated: true);
    expect(played, 0);
    expect(engine.state.distanceToTarget, greaterThan(100));
  });

  test('compass updates can confirm arrival while stationary using a fresh fix', () {
    var played = 0;
    final engine = TourNavigationEngine(onAutoPlayViewpoint: (_) => played++);
    engine.startTour(floorId: 'test', viewpoints: [viewpoint], isVoiceGuidanceEnabled: false);
    final fixTime = DateTime.utc(2026);
    final fix = UserLocationModel(floorId: 'test', normalizedX: 0.5,
      normalizedY: 0.5, headingDegrees: 180, timestamp: fixTime);
    engine.updateLocation(fix, now: fixTime);
    engine.updateHeading(0, now: fixTime.add(const Duration(seconds: 6)));
    expect(played, 0);
    final nextFixTime = fixTime.add(const Duration(seconds: 7));
    engine.updateLocation(fix.copyWith(timestamp: nextFixTime), now: nextFixTime);
    engine.updateHeading(0, now: nextFixTime);
    expect(played, 0);
    engine.updateHeading(0, now: nextFixTime.add(const Duration(seconds: 2)));
    expect(played, 1);
  });
}
