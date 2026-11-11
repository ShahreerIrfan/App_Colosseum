import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';

class LanguageCatalogService {
  static const cacheKey = 'language_catalog_v1';
  static const selectionKey = 'selected_tour_language';
  static const ttsLocaleKey = 'selected_tour_tts_locale';

  Future<List<Map<String, dynamic>>?> loadCached() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(cacheKey);
      return raw == null ? null : _decodeList(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> refresh() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return null;
    final client = http.Client();
    try {
      for (final base in ApiConstants.candidateBaseUrls) {
        try {
          final response = await client.get(Uri.parse('$base/api/v1/languages/catalog'))
              .timeout(const Duration(seconds: 3));
          if (response.statusCode != 200) continue;
          final data = _decodeList((jsonDecode(response.body) as Map)['data']);
          final preferences = await SharedPreferences.getInstance();
          await preferences.setString(cacheKey, jsonEncode(data));
          return data;
        } catch (_) {
          // Try the next configured host.
        }
      }
      return null;
    } finally {
      client.close();
    }
  }

  List<Map<String, dynamic>> _decodeList(Object? raw) {
    final entries = (raw as List).map((entry) => Map<String, dynamic>.from(entry as Map)).toList();
    if (entries.any((entry) => entry['code'] is! String ||
        entry['name'] is! String || entry['nativeName'] is! String)) {
      throw const FormatException('Invalid language catalog');
    }
    return entries;
  }
}
