import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/game_state.dart';

/// Provider for managing game state
final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>(
  (ref) => GameStateNotifier(),
);

/// Notifier for game state changes
class GameStateNotifier extends StateNotifier<GameState> {
  GameStateNotifier() : super(GameState.initial());

  /// Start a new game
  void startGame() {
    state = state.startGame();
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
    state = state.gameOver();
  }

  /// End the game with victory
  void victory() {
    state = state.victory();
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
    state = state.nextWave();
  }

  /// Set the game speed multiplier
  void setGameSpeed(double speed) {
    state = state.setGameSpeed(speed);
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
