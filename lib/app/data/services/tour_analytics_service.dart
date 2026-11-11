import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';

class TourAnalyticsService {
  static final instance = TourAnalyticsService();
  static const consentKey = 'tour_analytics_consent_v1';
  static const _installationKey = 'tour_analytics_installation_v1';
  static const _queueKey = 'tour_analytics_queue_v1';
  static const _queueLimit = 2000;
  static final _random = Random.secure();
  static String newId() => List.generate(16, (_) => _random.nextInt(256)
      .toRadixString(16).padLeft(2, '0')).join();

  Future<void> _writes = Future.value();
  bool _uploading = false;

  Future<void> _write(Future<void> Function(SharedPreferences) action) {
    final pending = _writes.then((_) async {
      final preferences = await SharedPreferences.getInstance();
      await action(preferences);
    });
    _writes = pending.catchError((Object _) {});
    return _writes;
  }

  Future<bool> get consent async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getBool(consentKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setConsent(bool enabled) async {
    await _write((preferences) async {
      await preferences.setBool(consentKey, enabled);
      if (!enabled) {
        await preferences.remove(_queueKey);
        await preferences.remove(_installationKey);
      }
    });
    if (enabled) unawaited(flush());
  }

  Future<void> record({
    required String sessionId,
    required String type,
    required String tourKind,
    required String language,
    String? landmarkId,
    String? floorId,
    String? viewpointId,
  }) async {
    final occurredAt = DateTime.now().toUtc();
    await _write((preferences) async {
      if (preferences.getBool(consentKey) != true) return;
      final queue = preferences.getStringList(_queueKey) ?? [];
      queue.add(jsonEncode({
        'eventId': newId(),
        'sessionId': sessionId,
        'type': type,
        'tourKind': tourKind,
        'language': language,
        'occurredAt': occurredAt.toIso8601String(),
        'landmarkId': ?landmarkId,
        'floorId': ?floorId,
        'viewpointId': ?viewpointId,
      }));
      if (queue.length > _queueLimit) queue.removeRange(0, queue.length - _queueLimit);
      await preferences.setStringList(_queueKey, queue);
    });
    unawaited(flush());
  }

  Future<void> flush() async {
    if (_uploading || Platform.environment.containsKey('FLUTTER_TEST')) return;
    _uploading = true;
    try {
      while (true) {
        var batch = <String>[];
        String? installation;
        await _write((preferences) async {
          if (preferences.getBool(consentKey) != true) return;
          batch = (preferences.getStringList(_queueKey) ?? []).take(50).toList();
          if (batch.isEmpty) return;
          installation = preferences.getString(_installationKey) ?? newId();
          await preferences.setString(_installationKey, installation!);
        });
        if (batch.isEmpty || installation == null || !await consent) return;
        if (!await _send(installation!, batch)) return;
        await _write((preferences) async {
          if (preferences.getString(_installationKey) != installation) return;
          final sent = batch.toSet();
          final pending = preferences.getStringList(_queueKey) ?? [];
          await preferences.setStringList(_queueKey, pending.where((event) => !sent.contains(event)).toList());
        });
      }
    } finally {
      _uploading = false;
    }
  }

  Future<bool> _send(String installation, List<String> batch) async {
    final client = http.Client();
    try {
      final body = jsonEncode({
        'installationId': installation,
        'events': batch.map(jsonDecode).toList(),
      });
      for (final base in ApiConstants.candidateBaseUrls) {
        if (!await consent) return false;
        try {
          final response = await client.post(Uri.parse('$base/api/v1/analytics/events'),
            headers: {'Content-Type': 'application/json'}, body: body)
            .timeout(const Duration(seconds: 3));
          if (response.statusCode == 200) return true;
        } catch (_) {
          // Leave the batch queued until connectivity returns.
        }
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }
}
