import 'dart:convert';

import 'package:colosseum_client/app/data/services/tour_analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('analytics queues only opted-in activity and withdrawal clears pending events', () async {
    SharedPreferences.setMockInitialValues({});
    final analytics = TourAnalyticsService();
    final preferences = await SharedPreferences.getInstance();
    final sessionId = TourAnalyticsService.newId();
    Future<void> record() => analytics.record(
      sessionId: sessionId, type: 'tour_started', tourKind: 'floor',
      language: 'en', floorId: 'floor_1',
    );

    await record();
    expect(preferences.getKeys(), isEmpty);
    await analytics.setConsent(true);
    await record();
    final queue = preferences.getStringList('tour_analytics_queue_v1')!;
    final event = jsonDecode(queue.single) as Map;
    expect(event['eventId'], matches(RegExp(r'^[a-f0-9]{32}$')));
    expect(event['sessionId'], sessionId);
    expect(event.containsKey('latitude'), isFalse);
    await analytics.setConsent(false);
    await record();
    expect(preferences.getStringList('tour_analytics_queue_v1'), isNull);
    expect(await analytics.consent, isFalse);
  });
}
