import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/audio/audio_manager.dart';
import '../../domain/models/game_state.dart';
import 'achievement_provider.dart';

/// Provider for managing game state
final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>(
  (ref) => GameStateNotifier(ref),
);

/// Notifier for game state changes
class GameStateNotifier extends StateNotifier<GameState> {
  Timer? _preparationTimer;
  final Ref _ref;

  GameStateNotifier(this._ref) : super(GameState.initial());

  /// Start preparation phase (countdown before actual game)
  void startPreparation() {
    state = state.startPreparation();
    _startPreparationTimer();
  }

  /// Start the actual game immediately (skip preparation)
  void startGameDirectly() {
    state = state.startPlaying();
    _preparationTimer?.cancel();
  }

  void _startPreparationTimer() {
    _preparationTimer?.cancel();
    _preparationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        // Trigger state update to refresh countdown
        state = state.copyWith();

        // Check if preparation time is up
        if (state.isPreparationTimeUp) {
          timer.cancel();
          state = state.startPlaying();
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _preparationTimer?.cancel();
    super.dispose();
  }

  /// Pause the current game
  void pauseGame() {
    state = state.pauseGame();
  }

  /// Resume the paused game
  void resumeGame() {
    state = state.resumeGame();
  }

  /// End the game with game over
  void gameOver() {
    AudioManager().playSfx(AudioEvent.gameOver);
    state = state.gameOver();
  }

  /// End the game with victory
  void victory() {
    AudioManager().playSfx(AudioEvent.victory);
    state = state.victory();

    // Track victory achievements
    _trackVictoryAchievements();
  }

  /// Reset to initial state
  void resetGame() {
    state = GameState.initial();
  }

  /// Add gold to the player's resources
  void addGold(int amount) {
    state = state.addGold(amount);
  }

  /// Attempt to spend gold
  bool spendGold(int amount) {
    final newState = state.spendGold(amount);
    if (newState != null) {
      state = newState;
      return true;
    }
    return false;
  }

  /// Player loses lives
  void loseLives(int amount) {
    state = state.loseLives(amount);
  }

  /// Add points to the score
  void addScore(int points) {
    state = state.addScore(points);
  }

  /// Progress to the next wave
  void nextWave() {
    AudioManager().playSfx(AudioEvent.waveStart);
    state = state.nextWave();
  }

  /// Set the game speed multiplier
  void setGameSpeed(double speed) {
    state = state.setGameSpeed(speed);
  }

  /// Update game state with new values
  void updateGameState(GameState newState) {
    try {
      state = newState;
    } catch (e) {
      // If state update fails, log the error but don't crash
      // Debug: print('GameState update error: $e');
    }
  }

  /// Toggle game pause state
  void togglePause() {
    if (state.isPaused) {
      resumeGame();
    } else {
      pauseGame();
    }
  }

  /// Check if player can afford a purchase
  bool canAfford(int cost) => state.canAfford(cost);

  /// Get current game duration
  Duration? get gameDuration {
    if (state.gameStartTime != null) {
      return DateTime.now().difference(state.gameStartTime!);
    }
    return null;
  }

  /// Track victory achievements
  void _trackVictoryAchievements() {
    final achievementNotifier = _ref.read(achievementNotifierProvider.notifier);
    final duration = gameDuration;

    // Check progression achievements
    achievementNotifier.checkProgressionAchievements(
      wavesCompleted: 1,
      levelsCompleted: 1,
      goldEarned: state.gold,
      isFirstVictory: state.wave == 1,
    );

    // Check strategic achievements
    achievementNotifier.checkStrategicAchievements(
      perfectWave: state.lives == 20, // Full health
      goldRemaining: state.gold,
      levelTime: duration,
      accuracy: 1.0, // TODO: Track actual accuracy
    );

    // Check time-based achievements
    achievementNotifier.checkTimeAchievements();
  }
}

/// Provider for current game status
final gameStatusProvider = Provider<GameStatus>((ref) {
  return ref.watch(gameStateProvider).status;
});

/// Provider for player resources
final playerResourcesProvider = Provider<({int gold, int lives, int score})>((
  ref,
) {
  final gameState = ref.watch(gameStateProvider);
  return (gold: gameState.gold, lives: gameState.lives, score: gameState.score);
});

/// Provider for wave information
final waveProvider = Provider<int>((ref) {
  return ref.watch(gameStateProvider).wave;
});

/// Provider for game speed
final gameSpeedProvider = Provider<double>((ref) {
  return ref.watch(gameStateProvider).gameSpeed;
});

/// Provider for pause state
final isPausedProvider = Provider<bool>((ref) {
  return ref.watch(gameStateProvider).isPaused;
});

/// Provider for preparation phase information
final preparationProvider = Provider<({bool isPreparing, int remainingTime})>((
  ref,
) {
  final gameState = ref.watch(gameStateProvider);
  return (
    isPreparing: gameState.isPreparing,
    remainingTime: gameState.remainingPreparationTime,
  );
});
