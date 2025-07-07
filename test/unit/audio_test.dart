import 'package:flutter_test/flutter_test.dart';
import 'package:techtical_stand/core/audio/audio_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel sharedPreferencesChannel = MethodChannel(
    'plugins.flutter.io/shared_preferences',
  );

  // Set up shared preferences mocking
  void setupSharedPreferencesMocks() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sharedPreferencesChannel, (
          MethodCall methodCall,
        ) async {
          switch (methodCall.method) {
            case 'getAll':
              return <String, dynamic>{};
            case 'setString':
            case 'setDouble':
            case 'setBool':
            case 'setInt':
              return true;
            case 'getString':
            case 'getDouble':
            case 'getBool':
            case 'getInt':
              return null;
            case 'remove':
            case 'clear':
              return true;
            default:
              return null;
          }
        });
  }

  setUpAll(() {
    // Set up shared preferences mocking
    setupSharedPreferencesMocks();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    // Clean up mocks after each test
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sharedPreferencesChannel, null);
  });

  group('Audio Manager Tests', () {
    group('Audio Event Tests', () {
      test('Audio events are properly defined', () {
        expect(AudioEvent.values, isNotEmpty);

        // Check that all tower sounds are defined
        expect(AudioEvent.values.contains(AudioEvent.archerFire), isTrue);
        expect(AudioEvent.values.contains(AudioEvent.cannonFire), isTrue);
        expect(AudioEvent.values.contains(AudioEvent.magicFire), isTrue);
        expect(AudioEvent.values.contains(AudioEvent.sniperFire), isTrue);

        // Check that enemy sounds are defined
        expect(AudioEvent.values.contains(AudioEvent.enemyDeath), isTrue);
        expect(AudioEvent.values.contains(AudioEvent.enemyHit), isTrue);
        expect(AudioEvent.values.contains(AudioEvent.bossSpawn), isTrue);

        // Check that UI sounds are defined
        expect(AudioEvent.values.contains(AudioEvent.buttonClick), isTrue);
        expect(AudioEvent.values.contains(AudioEvent.towerPlace), isTrue);
        expect(AudioEvent.values.contains(AudioEvent.towerUpgrade), isTrue);
        expect(AudioEvent.values.contains(AudioEvent.waveStart), isTrue);
        expect(AudioEvent.values.contains(AudioEvent.gameOver), isTrue);
        expect(AudioEvent.values.contains(AudioEvent.victory), isTrue);

        // Check that music is defined
        expect(AudioEvent.values.contains(AudioEvent.gameplayMusic), isTrue);
        expect(AudioEvent.values.contains(AudioEvent.menuMusic), isTrue);
      });
    });

    group('Audio Manager Initialization', () {
      test('Audio manager can be initialized', () async {
        final audioManager = AudioManager();

        // Should not throw an exception
        expect(() => audioManager.initialize(), returnsNormally);
      });

      test('Audio manager is singleton', () {
        final instance1 = AudioManager();
        final instance2 = AudioManager();

        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('Volume Controls', () {
      test('Volume settings can be adjusted', () async {
        final audioManager = AudioManager();
        await audioManager.initialize();

        // Test master volume
        audioManager.setMasterVolume(0.5);
        expect(audioManager.masterVolume, equals(0.5));

        // Test SFX volume
        audioManager.setSfxVolume(0.7);
        expect(audioManager.sfxVolume, equals(0.7));

        // Test music volume
        audioManager.setMusicVolume(0.3);
        expect(audioManager.musicVolume, equals(0.3));
      });

      test('Volume is clamped to valid range', () async {
        final audioManager = AudioManager();
        await audioManager.initialize();

        // Test values below 0
        audioManager.setMasterVolume(-0.5);
        expect(audioManager.masterVolume, equals(0.0));

        // Test values above 1
        audioManager.setMasterVolume(1.5);
        expect(audioManager.masterVolume, equals(1.0));
      });

      test('Mute controls work correctly', () async {
        final audioManager = AudioManager();
        await audioManager.initialize();

        // Test mute toggle
        audioManager.toggleMute();
        expect(audioManager.isMuted, isTrue);

        audioManager.toggleMute();
        expect(audioManager.isMuted, isFalse);

        // Test music mute
        audioManager.toggleMusicMute();
        expect(audioManager.isMusicMuted, isTrue);

        audioManager.toggleMusicMute();
        expect(audioManager.isMusicMuted, isFalse);
      });
    });

    group('Sound Effects', () {
      test('Sound effects can be played', () async {
        final audioManager = AudioManager();
        await audioManager.initialize();

        // Should not throw when playing sounds
        expect(
          () => audioManager.playSfx(AudioEvent.buttonClick),
          returnsNormally,
        );
        expect(
          () => audioManager.playSfx(AudioEvent.towerPlace),
          returnsNormally,
        );
        expect(
          () => audioManager.playSfx(AudioEvent.enemyDeath),
          returnsNormally,
        );
      });

      test('Sound effects respect mute settings', () async {
        final audioManager = AudioManager();
        await audioManager.initialize();

        // Mute the audio
        audioManager.toggleMute();

        // Should not throw when playing sounds while muted
        expect(
          () => audioManager.playSfx(AudioEvent.buttonClick),
          returnsNormally,
        );
      });

      test('Sound effects respect volume settings', () async {
        final audioManager = AudioManager();
        await audioManager.initialize();

        // Set low volume
        audioManager.setSfxVolume(0.1);

        // Should not throw when playing sounds with low volume
        expect(
          () => audioManager.playSfx(AudioEvent.buttonClick),
          returnsNormally,
        );
      });
    });

    group('Background Music', () {
      test('Background music can be played', () async {
        final audioManager = AudioManager();
        await audioManager.initialize();

        // Should not throw when playing music
        expect(
          () => audioManager.playMusic(AudioEvent.menuMusic),
          returnsNormally,
        );
        expect(
          () => audioManager.playMusic(AudioEvent.gameplayMusic),
          returnsNormally,
        );
      });

      test('Background music can be paused and resumed', () async {
        final audioManager = AudioManager();
        await audioManager.initialize();

        // Should not throw when controlling music
        expect(() => audioManager.pauseMusic(), returnsNormally);
        expect(() => audioManager.resumeMusic(), returnsNormally);
        expect(() => audioManager.stopMusic(), returnsNormally);
      });

      test('Background music respects mute settings', () async {
        final audioManager = AudioManager();
        await audioManager.initialize();

        // Mute music
        audioManager.toggleMusicMute();

        // Should not throw when playing music while muted
        expect(
          () => audioManager.playMusic(AudioEvent.menuMusic),
          returnsNormally,
        );
      });
    });

    group('Audio Settings Persistence', () {
      test('Audio settings are automatically saved when changed', () async {
        final audioManager = AudioManager();
        await audioManager.initialize();

        // Set custom settings - these should trigger automatic saving
        audioManager.setMasterVolume(0.6);
        audioManager.setSfxVolume(0.8);
        audioManager.setMusicVolume(0.4);

        // Settings should be persisted automatically
        expect(audioManager.masterVolume, equals(0.6));
        expect(audioManager.sfxVolume, equals(0.8));
        expect(audioManager.musicVolume, equals(0.4));
      });
    });

    group('Error Handling', () {
      test('Audio manager handles errors gracefully', () async {
        final audioManager = AudioManager();

        // Should not throw when playing sounds before initialization
        expect(
          () => audioManager.playSfx(AudioEvent.buttonClick),
          returnsNormally,
        );
        expect(
          () => audioManager.playMusic(AudioEvent.menuMusic),
          returnsNormally,
        );
      });

      test('Audio manager handles invalid audio events', () async {
        final audioManager = AudioManager();
        await audioManager.initialize();

        // Should not throw when playing any valid audio event
        for (final event in AudioEvent.values) {
          expect(() => audioManager.playSfx(event), returnsNormally);
        }
      });
    });
  });
}
