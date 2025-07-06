import 'package:equatable/equatable.dart';
import 'tile_system.dart';

/// Enumeration of possible game states
enum GameStatus { menu, preparing, playing, paused, gameOver, victory, loading }

/// Represents the current state of the game
class GameState extends Equatable {
  final GameStatus status;
  final int gold;
  final int lives;
  final int wave;
  final int score;
  final double gameSpeed;
  final bool isPaused;
  final DateTime? gameStartTime;
  final Duration? gameDuration;
  final DateTime? preparationStartTime;
  final int preparationTimeSeconds;
  final TileSystem? tileSystem;

  const GameState({
    this.status = GameStatus.menu,
    this.gold = 300, // Increased from 100 to 300 for better early game
    this.lives = 20,
    this.wave = 1,
    this.score = 0,
    this.gameSpeed = 1.0,
    this.isPaused = false,
    this.gameStartTime,
    this.gameDuration,
    this.preparationStartTime,
    this.preparationTimeSeconds = 10,
    this.tileSystem,
  });

  /// Create initial game state
  factory GameState.initial() => GameState(
    status: GameStatus.menu,
    gold: 300, // Increased starting gold for better early game
    lives: 20,
    wave: 1,
    score: 0,
    gameSpeed: 1.0,
    isPaused: false,
    gameStartTime: DateTime.now(),
  );

  /// Start preparation phase (countdown before wave begins)
  GameState startPreparation() => copyWith(
    status: GameStatus.preparing,
    preparationStartTime: DateTime.now(),
  );

  /// Start the actual game after preparation
  GameState startPlaying() =>
      copyWith(status: GameStatus.playing, gameStartTime: DateTime.now());

  /// Pause the game
  GameState pauseGame() => copyWith(status: GameStatus.paused, isPaused: true);

  /// Resume the game
  GameState resumeGame() =>
      copyWith(status: GameStatus.playing, isPaused: false);

  /// End the game with game over
  GameState gameOver() => copyWith(
    status: GameStatus.gameOver,
    isPaused: true,
    gameDuration: gameStartTime != null
        ? DateTime.now().difference(gameStartTime!)
        : null,
  );

  /// End the game with victory
  GameState victory() => copyWith(
    status: GameStatus.victory,
    isPaused: true,
    gameDuration: gameStartTime != null
        ? DateTime.now().difference(gameStartTime!)
        : null,
  );

  /// Add gold to the current amount
  GameState addGold(int amount) => copyWith(gold: gold + amount);

  /// Spend gold (returns null if insufficient funds)
  GameState? spendGold(int amount) {
    if (gold >= amount) {
      return copyWith(gold: gold - amount);
    }
    return null;
  }

  /// Lose lives
  GameState loseLives(int amount) {
    final newLives = (lives - amount).clamp(0, lives);
    return copyWith(
      lives: newLives,
      status: newLives <= 0 ? GameStatus.gameOver : status,
    );
  }

  /// Add to score
  GameState addScore(int points) => copyWith(score: score + points);

  /// Progress to next wave
  GameState nextWave() => copyWith(wave: wave + 1);

  /// Set game speed
  GameState setGameSpeed(double speed) =>
      copyWith(gameSpeed: speed.clamp(0.5, 3.0));

  /// Copy with new values
  GameState copyWith({
    GameStatus? status,
    int? gold,
    int? lives,
    int? wave,
    int? score,
    double? gameSpeed,
    bool? isPaused,
    DateTime? gameStartTime,
    Duration? gameDuration,
    DateTime? preparationStartTime,
    int? preparationTimeSeconds,
    TileSystem? tileSystem,
  }) => GameState(
    status: status ?? this.status,
    gold: gold ?? this.gold,
    lives: lives ?? this.lives,
    wave: wave ?? this.wave,
    score: score ?? this.score,
    gameSpeed: gameSpeed ?? this.gameSpeed,
    isPaused: isPaused ?? this.isPaused,
    gameStartTime: gameStartTime ?? this.gameStartTime,
    gameDuration: gameDuration ?? this.gameDuration,
    preparationStartTime: preparationStartTime ?? this.preparationStartTime,
    preparationTimeSeconds:
        preparationTimeSeconds ?? this.preparationTimeSeconds,
    tileSystem: tileSystem ?? this.tileSystem,
  );

  // Convenience getters
  bool get isPlaying => status == GameStatus.playing;
  bool get isGameOver => status == GameStatus.gameOver;
  bool get isVictory => status == GameStatus.victory;
  bool get isInMenu => status == GameStatus.menu;
  bool get isPreparing => status == GameStatus.preparing;

  // Get remaining preparation time in seconds
  int get remainingPreparationTime {
    if (preparationStartTime == null || !isPreparing) return 0;
    final elapsed = DateTime.now().difference(preparationStartTime!).inSeconds;
    return (preparationTimeSeconds - elapsed).clamp(0, preparationTimeSeconds);
  }

  // Check if preparation time has ended
  bool get isPreparationTimeUp => isPreparing && remainingPreparationTime <= 0;

  // Convenience methods
  bool canAfford(int cost) => gold >= cost;
  bool get hasLivesRemaining => lives > 0;

  @override
  List<Object?> get props => [
    status,
    gold,
    lives,
    wave,
    score,
    gameSpeed,
    isPaused,
    gameStartTime,
    gameDuration,
    preparationStartTime,
    preparationTimeSeconds,
    tileSystem,
  ];

  @override
  String toString() =>
      'GameState('
      'status: $status, '
      'gold: $gold, '
      'lives: $lives, '
      'wave: $wave, '
      'score: $score, '
      'speed: $gameSpeed, '
      'paused: $isPaused'
      ')';
}
