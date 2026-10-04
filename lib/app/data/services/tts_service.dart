import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsSpeechType {
  none,
  instruction,
  narration,
}

/// Service managing Text-to-Speech audio guide playback using device native engines.
class TtsService {
  final FlutterTts _flutterTts;
  bool _isInitialized = false;

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

        _flutterTts.setCompletionHandler(handleNativeCompletion);

        _flutterTts.setCancelHandler(() {
          _currentSpeechType = TtsSpeechType.none;
          _activeInstructionOnDone = null;
          _activeNarrationOnDone = null;
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
          _currentSpeechType = TtsSpeechType.none;
          _activeInstructionOnDone = null;
          _activeNarrationOnDone = null;
          onError?.call(msg);
        });
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('TtsService init error: $e');
    }
  }

  Timer? _instructionSafetyTimer;

  /// Internal / test handler for native TTS completion events.
  @visibleForTesting
  void handleNativeCompletion() {
    _instructionSafetyTimer?.cancel();
    _instructionSafetyTimer = null;

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
    _instructionSafetyTimer?.cancel();
    _instructionSafetyTimer = null;
    try {
      if (!_isInitialized) {
        await init();
      }
      if (text.trim().isNotEmpty) {
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          _currentSpeechType = TtsSpeechType.none;
          _activeInstructionOnDone = null;
          _activeNarrationOnDone = null;
          try {
            await _flutterTts.stop();
          } catch (_) {}
        }

        _currentSpeechType = TtsSpeechType.instruction;
        _activeInstructionOnDone = onDone;
        _activeNarrationOnDone = null;

        // In test environments or desktop headless runners, complete immediately without scheduling background timers
        if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
          handleNativeCompletion();
          return;
        }

        // Safety fallback timer: ensure onDone always executes even if native TTS drops completion event
        final estimatedMs = ((text.length / 10.0) * 1000).toInt().clamp(2000, 4500);
        _instructionSafetyTimer = Timer(Duration(milliseconds: estimatedMs), () {
          if (_currentSpeechType == TtsSpeechType.instruction && _activeInstructionOnDone != null) {
            handleNativeCompletion();
          }
        });

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
    _instructionSafetyTimer?.cancel();
    _instructionSafetyTimer = null;
    try {
      if (!_isInitialized) {
        await init();
      }
      if (text.trim().isNotEmpty) {
        // Stop any previous speech first while _currentSpeechType is none on mobile devices,
        // so that any native flush/abort completion event from previous speech
        // is discarded and cannot trigger premature onNarrationComplete events.
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          _currentSpeechType = TtsSpeechType.none;
          _activeInstructionOnDone = null;
          _activeNarrationOnDone = null;
          try {
            await _flutterTts.stop();
          } catch (_) {}
        }

        _currentSpeechType = TtsSpeechType.narration;
        _activeNarrationOnDone = onDone;
        _activeInstructionOnDone = null;
        await _flutterTts.speak(text);
      } else {
        _currentSpeechType = TtsSpeechType.none;
        onNarrationComplete?.call();
        onDone?.call();
      }
    } catch (e) {
      _currentSpeechType = TtsSpeechType.none;
      debugPrint('TtsService speakNarration error: $e');
      onNarrationComplete?.call();
      onDone?.call();
    }
  }

  /// Speaks the provided text (defaults to narration).
  Future<void> speak(String text, {VoidCallback? onDone}) async {
    return speakNarration(text, onDone: onDone);
  }

  /// Speaks text and returns a Future that completes when playback genuinely finishes.
  Future<void> speakWithCompletion(String text, {Duration timeout = const Duration(seconds: 10)}) async {
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
    _instructionSafetyTimer?.cancel();
    _instructionSafetyTimer = null;
    _currentSpeechType = TtsSpeechType.none;
    _activeInstructionOnDone = null;
    _activeNarrationOnDone = null;
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
    _instructionSafetyTimer?.cancel();
    _instructionSafetyTimer = null;
    try {
      _flutterTts.stop().catchError((_) => 0);
    } catch (_) {}
  }
}
