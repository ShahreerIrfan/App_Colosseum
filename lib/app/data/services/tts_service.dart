import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsSpeechType { none, instruction, narration }

class OfflineVoiceUnavailable implements Exception {
  const OfflineVoiceUnavailable();
}

/// Service managing Text-to-Speech audio guide playback using device native engines.
class TtsService {
  static const _voiceTimeout = Duration(seconds: 3);
  static bool _usingAlternateEngine = false;
  final FlutterTts _flutterTts;
  bool _isInitialized = false;
  Future<void>? _initialization;
  bool _voiceAvailable = true;
  String? _offlineLocale;
  Future<bool>? _voiceSelection;

  static bool get _isAndroid =>
      !kIsWeb &&
      (debugDefaultTargetPlatformOverride == TargetPlatform.android ||
          (debugDefaultTargetPlatformOverride == null && Platform.isAndroid));
  static bool get _isIOS =>
      !kIsWeb &&
      (debugDefaultTargetPlatformOverride == TargetPlatform.iOS ||
          (debugDefaultTargetPlatformOverride == null && Platform.isIOS));

  int _generation = 0;
  bool _awaitingNativeStart = false;

  VoidCallback? onStart;
  VoidCallback? onComplete;
  VoidCallback? onNarrationComplete;
  VoidCallback? onPause;
  VoidCallback? onStop;
  void Function(int start, int end, String word)? onProgress;
  void Function(dynamic error)? onError;

  TtsSpeechType _currentSpeechType = TtsSpeechType.none;
  TtsSpeechType get currentSpeechType => _currentSpeechType;

  VoidCallback? _activeInstructionOnDone;
  VoidCallback? _activeNarrationOnDone;

  bool get isSpeakingNarration => _currentSpeechType == TtsSpeechType.narration;

  TtsService({FlutterTts? flutterTts})
    : _flutterTts = flutterTts ?? FlutterTts();

  /// Initialize TTS engine with language, rate, volume, and callbacks
  Future<void> init({String languageCode = 'en-US', bool offlineOnly = false}) {
    if (offlineOnly) _offlineLocale = languageCode;
    return _initialization ??= _initialize(languageCode);
  }

  Future<void> _initialize(String languageCode) async {
    try {
      if (_isAndroid || _isIOS) {
        if (_offlineLocale != null) {
          _voiceAvailable = false;
        } else {
          if (_isAndroid && _usingAlternateEngine) {
            await _restoreDefaultEngine();
          }
          await setLanguage(languageCode);
        }
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
          _awaitingNativeStart = false;
          onStart?.call();
        });

        _flutterTts.setCompletionHandler(() {
          // A completion that arrives before this utterance's onStart is left over
          // from a previous utterance, so drop it.
          if (_awaitingNativeStart) return;
          handleNativeCompletion();
        });

        _flutterTts.setCancelHandler(() {
          // Native cancel is an asynchronous echo of Dart's stop() or speak*().
          // Dart already cleans up its own state in stop() and speak*(),
          // so do NOT clear active callbacks or trigger onStop here to prevent stale cancels
          // from wiping out subsequent speech requests.
        });

        _flutterTts.setPauseHandler(() {
          onPause?.call();
        });

        _flutterTts.setContinueHandler(() {
          onStart?.call();
        });

        _flutterTts.setProgressHandler((
          String text,
          int start,
          int end,
          String word,
        ) {
          onProgress?.call(start, end, word);
        });

        _flutterTts.setErrorHandler((msg) {
          final instructionDone = _activeInstructionOnDone;
          final wasNarration = isSpeakingNarration;
          _instructionSafetyTimer?.cancel();
          _currentSpeechType = TtsSpeechType.none;
          _activeInstructionOnDone = null;
          _activeNarrationOnDone = null;
          if (wasNarration) {
            if (_offlineLocale != null) _voiceAvailable = false;
            onError?.call(msg);
          }
          instructionDone?.call();
        });
      }
      _isInitialized = true;
    } catch (e) {
      _voiceAvailable = false;
      debugPrint('TtsService init error: $e');
    }
  }

  Future<bool> _selectOfflineVoice(String locale) async {
    Future<bool> selectFromCurrentEngine() async {
      for (final voice in await _offlineVoices(locale, _flutterTts)) {
        try {
          final result = await _flutterTts
              .setVoice(voice)
              .timeout(_voiceTimeout);
          if (result == 1 || result == true) return true;
        } catch (_) {
          // Another installed voice for this language may still work.
        }
      }
      return false;
    }

    if (await selectFromCurrentEngine()) return true;
    if (!_isAndroid) return false;
    try {
      final defaultEngine = await _flutterTts.getDefaultEngine.timeout(
        _voiceTimeout,
      );
      final engines = await _flutterTts.getEngines.timeout(_voiceTimeout);
      if (defaultEngine is! String || engines is! List) return false;
      for (final engine in engines.whereType<String>()) {
        if (engine == defaultEngine) continue;
        _usingAlternateEngine = true;
        try {
          await _flutterTts.setEngine(engine).timeout(_voiceTimeout);
        } catch (_) {
          break;
        }
        if (await selectFromCurrentEngine()) {
          await _flutterTts.setSpeechRate(0.46).timeout(_voiceTimeout);
          await _flutterTts.setPitch(1.0).timeout(_voiceTimeout);
          return true;
        }
      }
      if (_usingAlternateEngine) await _restoreDefaultEngine();
    } catch (error) {
      debugPrint('Offline TTS engine selection failed: $error');
    }
    return false;
  }

  Future<void> _restoreDefaultEngine() async {
    final engine = await _flutterTts.getDefaultEngine.timeout(_voiceTimeout);
    if (engine is! String || engine.isEmpty) return;
    await _flutterTts.setEngine(engine).timeout(_voiceTimeout);
    _usingAlternateEngine = false;
  }

  static Future<Map<String, String>?> findOfflineVoice(
    String locale, {
    FlutterTts? tts,
  }) async => (await _offlineVoices(locale, tts ?? FlutterTts())).firstOrNull;

  Future<void> _ensureVoice() async {
    if (!_isInitialized) await init();
    final locale = _offlineLocale;
    if (!_voiceAvailable && locale != null) {
      final selection = _voiceSelection ??= _selectOfflineVoice(locale);
      try {
        _voiceAvailable = await selection;
      } finally {
        if (identical(_voiceSelection, selection)) _voiceSelection = null;
      }
    }
  }

  static Future<List<Map<String, String>>> _offlineVoices(
    String locale,
    FlutterTts tts,
  ) async {
    if (!_isAndroid && !_isIOS) return const [];
    try {
      final voices = await tts.getVoices.timeout(_voiceTimeout);
      if (voices is! List) return const [];
      String normalize(String tag) => tag.toLowerCase().replaceAll('_', '-');
      final preferred = normalize(locale);
      final language = preferred.split('-').first;
      final preferredVoices = <Map<String, String>>[];
      final fallbackVoices = <Map<String, String>>[];
      for (final entry in voices.whereType<Map>()) {
        final tag = entry['locale'];
        if (tag is! String || entry['name'] is! String) continue;
        if (_isAndroid &&
            (entry['network_required'] != '0' ||
                (entry['features'] as String? ?? '')
                    .split('\t')
                    .contains('notInstalled'))) {
          continue;
        }
        final normalized = normalize(tag);
        if (normalized.split('-').first != language) continue;
        final voice = <String, String>{
          'name': entry['name'] as String,
          'locale': tag,
        };
        if (entry['identifier'] case final String identifier) {
          voice['identifier'] = identifier;
        }
        (normalized == preferred ? preferredVoices : fallbackVoices).add(voice);
      }
      return [...preferredVoices, ...fallbackVoices];
    } catch (_) {
      return const [];
    }
  }

  Timer? _instructionSafetyTimer;

  /// Global mute toggle for spoken turn-by-turn navigation instructions.
  /// When true, instructions are suppressed from voice while remaining visual on screen.
  bool isVoiceGuidanceMuted = false;

  /// Internal / test handler for native TTS completion events.
  @visibleForTesting
  void handleNativeCompletion() {
    _instructionSafetyTimer?.cancel();
    _instructionSafetyTimer = null;
    _awaitingNativeStart = false;

    final type = _currentSpeechType;
    _currentSpeechType = TtsSpeechType.none;

    if (type == TtsSpeechType.instruction) {
      final cb = _activeInstructionOnDone;
      _activeInstructionOnDone = null;
      cb?.call();
    } else if (type == TtsSpeechType.narration) {
      final cb = _activeNarrationOnDone;
      _activeNarrationOnDone = null;
      onNarrationComplete?.call();
      cb?.call();
    }
    onComplete?.call();
  }

  /// Speaks a navigation voice instruction without triggering narration complete events.
  Future<void> speakInstruction(String text, {VoidCallback? onDone}) async {
    // Tier-1 Audio Collision Arbiter:
    // If narration (historical story) is actively playing, or if voice guidance is muted,
    // do NOT interrupt or talk over the narration. Directions remain visual on the map banner.
    if (isSpeakingNarration || isVoiceGuidanceMuted) {
      onDone?.call();
      return;
    }

    final myGen = ++_generation;
    _instructionSafetyTimer?.cancel();
    _instructionSafetyTimer = null;
    _currentSpeechType = TtsSpeechType.none;
    _activeInstructionOnDone = null;
    _activeNarrationOnDone = null;

    try {
      if (_offlineLocale != null) {
        await _ensureVoice();
      } else if (!_isInitialized) {
        await init();
      }
      if (myGen != _generation) return;
      if (!_voiceAvailable) {
        onDone?.call();
        return;
      }
      if (text.trim().isNotEmpty) {
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          try {
            await _flutterTts.stop();
          } catch (_) {}
          if (myGen != _generation) return;
        }

        _currentSpeechType = TtsSpeechType.instruction;
        _activeInstructionOnDone = onDone;
        _activeNarrationOnDone = null;
        _awaitingNativeStart = true;

        // In test environments or desktop headless runners, complete immediately without scheduling background timers
        if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
          handleNativeCompletion();
          return;
        }

        // Safety fallback timer: ensure onDone always executes even if native TTS drops completion event
        final estimatedMs = ((text.length / 8.0) * 1000).toInt().clamp(
          3000,
          7000,
        );
        _instructionSafetyTimer = Timer(
          Duration(milliseconds: estimatedMs),
          () {
            if (myGen == _generation &&
                _currentSpeechType == TtsSpeechType.instruction &&
                _activeInstructionOnDone != null) {
              handleNativeCompletion();
            }
          },
        );

        await _flutterTts.speak(text);
      } else {
        _currentSpeechType = TtsSpeechType.none;
        onDone?.call();
      }
    } catch (e) {
      _instructionSafetyTimer?.cancel();
      _currentSpeechType = TtsSpeechType.none;
      debugPrint('TtsService speakInstruction error: $e');
      onDone?.call();
    }
  }

  /// Speaks a viewpoint guide description narration and invokes [onNarrationComplete] when done.
  Future<void> speakNarration(String text, {VoidCallback? onDone}) async {
    // Cleanly complete any in-flight navigation prompt callback before taking over audio focus
    if (_currentSpeechType == TtsSpeechType.instruction && _activeInstructionOnDone != null) {
      final prevOnDone = _activeInstructionOnDone;
      _activeInstructionOnDone = null;
      prevOnDone?.call();
    }

    final myGen = ++_generation;
    _instructionSafetyTimer?.cancel();
    _instructionSafetyTimer = null;
    // Claim narration focus synchronously before any await so concurrent
    // speakInstruction() calls yield immediately instead of bumping _generation.
    _currentSpeechType = TtsSpeechType.narration;
    _activeInstructionOnDone = null;
    _activeNarrationOnDone = onDone;

    try {
      if (_offlineLocale != null) {
        await _ensureVoice();
      } else if (!_isInitialized) {
        await init();
      }
      if (myGen != _generation) return;
      if (!_voiceAvailable) {
        _currentSpeechType = TtsSpeechType.none;
        _activeNarrationOnDone = null;
        onError?.call(
          _offlineLocale != null
              ? const OfflineVoiceUnavailable()
              : 'A device voice for this language is unavailable.',
        );
        return;
      }
      if (text.trim().isNotEmpty) {
        // Stop any previous speech first while _currentSpeechType is none on mobile devices,
        // so that any native flush/abort completion event from previous speech
        // is discarded and cannot trigger premature onNarrationComplete events.
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          try {
            await _flutterTts.stop();
          } catch (_) {}
          if (myGen != _generation) return;
        }

        _currentSpeechType = TtsSpeechType.narration;
        _activeNarrationOnDone = onDone;
        _activeInstructionOnDone = null;
        _awaitingNativeStart = true;
        final playback = _flutterTts.speak(text);
        final result = _offlineLocale == null
            ? await playback
            : await playback.timeout(_voiceTimeout);
        if (result == 0 || result == false) {
          throw StateError('The TTS engine rejected playback');
        }
      } else {
        _currentSpeechType = TtsSpeechType.none;
        onNarrationComplete?.call();
        onDone?.call();
      }
    } catch (e) {
      if (myGen != _generation) return;
      if (_offlineLocale != null) _voiceAvailable = false;
      _currentSpeechType = TtsSpeechType.none;
      _activeNarrationOnDone = null;
      _awaitingNativeStart = false;
      debugPrint('TtsService speakNarration error: $e');
      onError?.call(e);
    }
  }

  /// Speaks the provided text (defaults to narration).
  Future<void> speak(String text, {VoidCallback? onDone}) async {
    return speakNarration(text, onDone: onDone);
  }

  /// Speaks text and returns a Future that completes when playback genuinely finishes.
  Future<void> speakWithCompletion(
    String text, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (text.trim().isEmpty) return;

    // In unit test environment or headless runners, fallback immediately
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }

    final completer = Completer<void>();
    VoidCallback? prevComplete;
    VoidCallback? prevCancel;
    void Function(dynamic)? prevError;

    void cleanup() {
      onComplete = prevComplete;
      onStop = prevCancel;
      onError = prevError;
    }

    prevComplete = onComplete;
    prevCancel = onStop;
    prevError = onError;

    onComplete = () {
      cleanup();
      prevComplete?.call();
      if (!completer.isCompleted) completer.complete();
    };

    onStop = () {
      cleanup();
      prevCancel?.call();
      if (!completer.isCompleted) completer.complete();
    };

    onError = (err) {
      cleanup();
      prevError?.call(err);
      if (!completer.isCompleted) completer.complete();
    };

    try {
      if (!_isInitialized) {
        await init();
      }
      await _flutterTts.speak(text);
      // Failsafe timeout in case native completion handler is delayed
      Future.delayed(timeout, () {
        if (!completer.isCompleted) {
          cleanup();
          completer.complete();
        }
      });
      await completer.future;
    } catch (e) {
      cleanup();
      debugPrint('speakWithCompletion error: $e');
      if (!completer.isCompleted) completer.complete();
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
    _generation++;
    _awaitingNativeStart = false;
    _instructionSafetyTimer?.cancel();
    _instructionSafetyTimer = null;
    _currentSpeechType = TtsSpeechType.none;
    _activeInstructionOnDone = null;
    _activeNarrationOnDone = null;
    onStop?.call();
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('TtsService stop error: $e');
    }
  }

  /// Sets language (e.g. 'en-US', 'it-IT', 'fr-FR', 'es-ES', 'bn-BD')
  Future<void> setLanguage(String langCode) async {
    try {
      final available = await _flutterTts.isLanguageAvailable(langCode);
      _voiceAvailable = available != false;
      if (_voiceAvailable) {
        final result = await _flutterTts.setLanguage(langCode);
        if (result == 0 || result == false) _voiceAvailable = false;
      }
    } catch (e) {
      _voiceAvailable = false;
      debugPrint('TtsService setLanguage error: $e');
    }
  }

  /// Disposes TTS resources
  void dispose() {
    _instructionSafetyTimer?.cancel();
    _instructionSafetyTimer = null;
    try {
      _flutterTts.stop().catchError((_) => 0);
    } catch (_) {}
  }
}
