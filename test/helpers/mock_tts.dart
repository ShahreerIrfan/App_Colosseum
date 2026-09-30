import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sets up a mock MethodChannel for flutter_tts during unit and widget tests.
void setupMockTts() {
  const MethodChannel channel = MethodChannel('flutter_tts');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'speak':
      case 'stop':
      case 'pause':
      case 'setLanguage':
      case 'setSpeechRate':
      case 'setVolume':
      case 'setPitch':
      case 'setSharedInstance':
      case 'setIosAudioCategory':
        return 1;
      default:
        return 1;
    }
  });
}
