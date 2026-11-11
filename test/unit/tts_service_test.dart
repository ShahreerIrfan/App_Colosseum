import 'package:colosseum_client/app/data/services/tts_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tts');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const installedVoice = {
    'locale': 'en-US',
    'name': 'local-english',
    'network_required': '0',
  };

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('uses an installed offline voice from another Android engine', () async {
    var engine = 'default-engine';
    final spoken = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'getVoices':
          return engine == 'default-engine'
              ? [
                  {...installedVoice, 'network_required': '1'},
                  {...installedVoice, 'features': 'notInstalled'},
                ]
              : [installedVoice];
        case 'getDefaultEngine':
          return 'default-engine';
        case 'getEngines':
          return ['default-engine', 'alternate-engine'];
        case 'setEngine':
          engine = call.arguments as String;
          return 1;
        case 'setVoice':
          expect(engine, 'alternate-engine');
          expect(call.arguments['name'], installedVoice['name']);
          return 1;
        case 'speak':
          final arguments = call.arguments;
          spoken.add(
            arguments is Map
                ? arguments['text'] as String
                : arguments as String,
          );
          return 1;
        default:
          return 1;
      }
    });
    final offline = TtsService();
    await offline.init(offlineOnly: true);
    await offline.speakNarration('Welcome to the Colosseum.');
    expect(spoken, ['Welcome to the Colosseum.']);

    await TtsService().init();
    expect(engine, 'default-engine');
  });

  test('rechecks the offline voice when the visitor retries', () async {
    var voiceInstalled = false;
    final errors = <Object?>[];
    var plays = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'getVoices':
          return voiceInstalled ? [installedVoice] : [];
        case 'getDefaultEngine':
          return 'default-engine';
        case 'getEngines':
          return ['default-engine'];
        case 'speak':
          plays++;
          return 1;
        default:
          return 1;
      }
    });
    final service = TtsService()..onError = errors.add;
    await service.init(offlineOnly: true);
    await service.speakNarration('Welcome.');
    expect(errors.single, isA<OfflineVoiceUnavailable>());
    expect(plays, 0);

    voiceInstalled = true;
    await service.speakNarration('Welcome.');
    expect(plays, 1);
  });
}
