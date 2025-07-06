import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Audio event types for the game
enum AudioEvent {
  // Tower sounds
  archerFire,
  cannonFire,
  magicFire,
  sniperFire,

  // Enemy sounds
  enemyDeath,
  enemyHit,
  bossSpawn,

  // UI sounds
  buttonClick,
  towerPlace,
  towerUpgrade,
  waveStart,
  gameOver,
  victory,

  // Projectile sounds
  arrowHit,
  explosionHit,
  magicHit,

  // Background music
  gameplayMusic,
  menuMusic,
}

/// Audio manager that handles all game audio
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  // Audio players for different types of audio
  final Map<String, AudioPlayer> _soundPlayers = {};
  AudioPlayer? _musicPlayer;

  // Volume settings
  double _masterVolume = 1.0;
  double _sfxVolume = 1.0;
  double _musicVolume = 0.7;
  bool _isMuted = false;
  bool _isMusicMuted = false;

  // Audio cache for frequently used sounds
  final Map<AudioEvent, String> _audioCache = {};

  // Sound pool for managing multiple simultaneous sounds
  final Map<AudioEvent, List<AudioPlayer>> _soundPool = {};
  final int _maxPoolSize = 5;

  bool _isInitialized = false;

  /// Initialize the audio manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load saved audio settings
      await _loadAudioSettings();

      // Initialize audio cache with sound file paths
      _initializeAudioCache();

      // Create sound pools for frequently used sounds
      await _initializeSoundPools();

      // Initialize music player
      _musicPlayer = AudioPlayer();
      await _musicPlayer!.setReleaseMode(ReleaseMode.loop);

      _isInitialized = true;
      debugPrint('AudioManager initialized successfully');
    } catch (e) {
      debugPrint('AudioManager initialization failed: $e');
    }
  }

  /// Initialize audio file cache
  void _initializeAudioCache() {
    // For now, we'll use placeholder paths
    // In a real implementation, these would point to actual audio files
    _audioCache.addAll({
      // Tower sounds
      AudioEvent.archerFire: 'audio/sfx/archer_fire.wav',
      AudioEvent.cannonFire: 'audio/sfx/cannon_fire.wav',
      AudioEvent.magicFire: 'audio/sfx/magic_fire.wav',
      AudioEvent.sniperFire: 'audio/sfx/sniper_fire.wav',

      // Enemy sounds
      AudioEvent.enemyDeath: 'audio/sfx/enemy_death.wav',
      AudioEvent.enemyHit: 'audio/sfx/enemy_hit.wav',
      AudioEvent.bossSpawn: 'audio/sfx/boss_spawn.wav',

      // UI sounds
      AudioEvent.buttonClick: 'audio/sfx/button_click.wav',
      AudioEvent.towerPlace: 'audio/sfx/tower_place.wav',
      AudioEvent.towerUpgrade: 'audio/sfx/tower_upgrade.wav',
      AudioEvent.waveStart: 'audio/sfx/wave_start.wav',
      AudioEvent.gameOver: 'audio/sfx/game_over.wav',
      AudioEvent.victory: 'audio/sfx/victory.wav',

      // Projectile sounds
      AudioEvent.arrowHit: 'audio/sfx/arrow_hit.wav',
      AudioEvent.explosionHit: 'audio/sfx/explosion_hit.wav',
      AudioEvent.magicHit: 'audio/sfx/magic_hit.wav',

      // Background music
      AudioEvent.gameplayMusic: 'audio/music/gameplay_theme.mp3',
      AudioEvent.menuMusic: 'audio/music/menu_theme.mp3',
    });
  }

  /// Initialize sound pools for frequently used sounds
  Future<void> _initializeSoundPools() async {
    final frequentSounds = [
      AudioEvent.archerFire,
      AudioEvent.cannonFire,
      AudioEvent.magicFire,
      AudioEvent.sniperFire,
      AudioEvent.enemyHit,
      AudioEvent.buttonClick,
    ];

    for (final event in frequentSounds) {
      _soundPool[event] = [];
      for (int i = 0; i < _maxPoolSize; i++) {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        _soundPool[event]!.add(player);
      }
    }
  }

  /// Play a sound effect
  Future<void> playSfx(AudioEvent event, {double? volume}) async {
    if (!_isInitialized || _isMuted) return;

    try {
      final effectiveVolume = (volume ?? 1.0) * _sfxVolume * _masterVolume;

      // Use sound pool for frequent sounds
      if (_soundPool.containsKey(event)) {
        final pool = _soundPool[event]!;

        // Find an available player
        AudioPlayer? availablePlayer;
        for (final player in pool) {
          if (player.state != PlayerState.playing) {
            availablePlayer = player;
            break;
          }
        }

        // If no available player, use the first one (interrupt)
        availablePlayer ??= pool.first;

        await availablePlayer.setVolume(effectiveVolume);

        // For now, play a synthesized sound since we don't have audio files
        await _playSynthesizedSound(event, availablePlayer);
      } else {
        // Create a new player for less frequent sounds
        final player = AudioPlayer();
        await player.setVolume(effectiveVolume);
        await _playSynthesizedSound(event, player);

        // Clean up after playing
        player.onPlayerComplete.listen((_) {
          player.dispose();
        });
      }
    } catch (e) {
      debugPrint('Error playing sound effect $event: $e');
    }
  }

  /// Play synthesized sound (placeholder for actual audio files)
  Future<void> _playSynthesizedSound(
    AudioEvent event,
    AudioPlayer player,
  ) async {
    // Since we don't have actual audio files, we'll use system sounds for immediate feedback
    debugPrint('🔊 Playing sound: ${event.name}');

    try {
      // Use Flutter's built-in system sounds for immediate audio feedback
      final systemSound = _getSystemSound(event);
      if (systemSound != null) {
        SystemSound.play(systemSound);
      }
    } catch (e) {
      debugPrint('Error playing system sound: $e');
    }

    // Also simulate duration for the audio system
    await Future.delayed(
      Duration(milliseconds: 50),
    ); // Short delay for system sound
  }

  /// Get appropriate system sound for each event
  SystemSoundType? _getSystemSound(AudioEvent event) {
    switch (event) {
      case AudioEvent.archerFire:
      case AudioEvent.cannonFire:
      case AudioEvent.magicFire:
      case AudioEvent.sniperFire:
        return SystemSoundType.click; // Attack sounds

      case AudioEvent.enemyHit:
      case AudioEvent.arrowHit:
      case AudioEvent.explosionHit:
      case AudioEvent.magicHit:
        return SystemSoundType.click; // Hit sounds

      case AudioEvent.enemyDeath:
      case AudioEvent.bossSpawn:
        return SystemSoundType.alert; // Important events

      case AudioEvent.buttonClick:
      case AudioEvent.towerPlace:
        return SystemSoundType.click; // UI interactions

      case AudioEvent.towerUpgrade:
      case AudioEvent.waveStart:
      case AudioEvent.victory:
        return SystemSoundType.alert; // Success sounds

      case AudioEvent.gameOver:
        return SystemSoundType.alert; // Game over

      default:
        return SystemSoundType.click; // Default
    }
  }

  /// Play background music
  Future<void> playMusic(AudioEvent musicEvent, {bool loop = true}) async {
    if (!_isInitialized || _isMusicMuted || _musicPlayer == null) return;

    try {
      await _musicPlayer!.setVolume(_musicVolume * _masterVolume);
      await _musicPlayer!.setReleaseMode(
        loop ? ReleaseMode.loop : ReleaseMode.stop,
      );

      // For now, just log the music event
      debugPrint('🎵 Playing music: ${musicEvent.name}');

      // In a real implementation:
      // await _musicPlayer!.play(AssetSource(_audioCache[musicEvent]!));
    } catch (e) {
      debugPrint('Error playing music $musicEvent: $e');
    }
  }

  /// Stop background music
  Future<void> stopMusic() async {
    if (_musicPlayer != null) {
      await _musicPlayer!.stop();
    }
  }

  /// Pause background music
  Future<void> pauseMusic() async {
    if (_musicPlayer != null) {
      await _musicPlayer!.pause();
    }
  }

  /// Resume background music
  Future<void> resumeMusic() async {
    if (_musicPlayer != null) {
      await _musicPlayer!.resume();
    }
  }

  /// Set master volume (affects all audio)
  Future<void> setMasterVolume(double volume) async {
    _masterVolume = volume.clamp(0.0, 1.0);
    await _saveAudioSettings();
    await _updateAllVolumes();
  }

  /// Set SFX volume
  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    await _saveAudioSettings();
  }

  /// Set music volume
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _saveAudioSettings();
    if (_musicPlayer != null) {
      await _musicPlayer!.setVolume(_musicVolume * _masterVolume);
    }
  }

  /// Toggle mute for all audio
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await _saveAudioSettings();
    await _updateAllVolumes();
  }

  /// Toggle mute for music only
  Future<void> toggleMusicMute() async {
    _isMusicMuted = !_isMusicMuted;
    await _saveAudioSettings();

    if (_isMusicMuted) {
      await pauseMusic();
    } else {
      await resumeMusic();
    }
  }

  /// Update volumes for all active players
  Future<void> _updateAllVolumes() async {
    final effectiveVolume = _isMuted ? 0.0 : _masterVolume;

    // Update music volume
    if (_musicPlayer != null) {
      await _musicPlayer!.setVolume(
        _isMusicMuted ? 0.0 : _musicVolume * effectiveVolume,
      );
    }

    // Update sound pool volumes
    for (final pool in _soundPool.values) {
      for (final player in pool) {
        await player.setVolume(_sfxVolume * effectiveVolume);
      }
    }
  }

  /// Load audio settings from shared preferences
  Future<void> _loadAudioSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _masterVolume = prefs.getDouble('audio_master_volume') ?? 1.0;
      _sfxVolume = prefs.getDouble('audio_sfx_volume') ?? 1.0;
      _musicVolume = prefs.getDouble('audio_music_volume') ?? 0.7;
      _isMuted = prefs.getBool('audio_is_muted') ?? false;
      _isMusicMuted = prefs.getBool('audio_is_music_muted') ?? false;
    } catch (e) {
      debugPrint('Error loading audio settings: $e');
    }
  }

  /// Save audio settings to shared preferences
  Future<void> _saveAudioSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('audio_master_volume', _masterVolume);
      await prefs.setDouble('audio_sfx_volume', _sfxVolume);
      await prefs.setDouble('audio_music_volume', _musicVolume);
      await prefs.setBool('audio_is_muted', _isMuted);
      await prefs.setBool('audio_is_music_muted', _isMusicMuted);
    } catch (e) {
      debugPrint('Error saving audio settings: $e');
    }
  }

  /// Dispose of all audio resources
  Future<void> dispose() async {
    // Stop and dispose music player
    if (_musicPlayer != null) {
      await _musicPlayer!.stop();
      await _musicPlayer!.dispose();
      _musicPlayer = null;
    }

    // Dispose sound pool players
    for (final pool in _soundPool.values) {
      for (final player in pool) {
        await player.stop();
        await player.dispose();
      }
    }
    _soundPool.clear();

    // Dispose other sound players
    for (final player in _soundPlayers.values) {
      await player.stop();
      await player.dispose();
    }
    _soundPlayers.clear();

    _isInitialized = false;
    debugPrint('AudioManager disposed');
  }

  // Getters for current settings
  double get masterVolume => _masterVolume;
  double get sfxVolume => _sfxVolume;
  double get musicVolume => _musicVolume;
  bool get isMuted => _isMuted;
  bool get isMusicMuted => _isMusicMuted;
  bool get isInitialized => _isInitialized;
}
