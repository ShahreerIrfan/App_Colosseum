import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Service managing Text-to-Speech audio guide playback using device native engines.
class TtsService {
  final FlutterTts _flutterTts;
  bool _isInitialized = false;

  VoidCallback? onStart;
  VoidCallback? onComplete;
  VoidCallback? onPause;
  VoidCallback? onStop;
  void Function(int start, int end, String word)? onProgress;
  void Function(dynamic error)? onError;

  TtsService({FlutterTts? flutterTts})
      : _flutterTts = flutterTts ?? FlutterTts();

  /// Initialize TTS engine with language, rate, volume, and callbacks
  Future<void> init({String languageCode = 'en-US'}) async {
    if (_isInitialized) return;

    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await _flutterTts.setLanguage(languageCode);
        await _flutterTts.setSpeechRate(0.46); // Natural pacing for tours
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setPitch(1.0);

        if (Platform.isIOS) {
          await _flutterTts.setSharedInstance(true);
          await _flutterTts.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            [
              IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
              IosTextToSpeechAudioCategoryOptions.allowBluetooth,
              IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            ],
            IosTextToSpeechAudioMode.voicePrompt,
          );
        }

        _flutterTts.setStartHandler(() {
          onStart?.call();
        });

        _flutterTts.setCompletionHandler(() {
          onComplete?.call();
        });

        _flutterTts.setCancelHandler(() {
          onStop?.call();
        });

        _flutterTts.setPauseHandler(() {
          onPause?.call();
        });

        _flutterTts.setContinueHandler(() {
          onStart?.call();
        });

        _flutterTts.setProgressHandler((String text, int start, int end, String word) {
          onProgress?.call(start, end, word);
        });

        _flutterTts.setErrorHandler((msg) {
          onError?.call(msg);
        });
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('TtsService init error: $e');
    }
  }

  /// Speaks the provided text
  Future<void> speak(String text) async {
    try {
      if (!_isInitialized) {
        await init();
      }
      if (text.trim().isNotEmpty) {
        await _flutterTts.speak(text);
      }
    } catch (e) {
      debugPrint('TtsService speak error: $e');
    }
  }

  /// Pauses the current speech
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      debugPrint('TtsService pause error: $e');
    }
  }

  /// Stops the current speech
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('TtsService stop error: $e');
    }
  }

  /// Sets language (e.g. 'en-US', 'it-IT', 'fr-FR', 'es-ES', 'bn-BD')
  Future<void> setLanguage(String langCode) async {
    try {
      await _flutterTts.setLanguage(langCode);
    } catch (e) {
      debugPrint('TtsService setLanguage error: $e');
    }
  }

  /// Disposes TTS resources
  void dispose() {
    try {
      _flutterTts.stop().catchError((_) => 0);
    } catch (_) {}
  }
}
