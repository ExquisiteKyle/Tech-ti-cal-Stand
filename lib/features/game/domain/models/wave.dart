import 'dart:math' as math;
import '../../../../shared/models/vector2.dart';
import 'enemy.dart';
import 'path.dart';

/// Represents a single enemy spawn in a wave
class EnemySpawn {
  final EnemyType enemyType;
  final double spawnTime;
  final Map<String, dynamic> metadata;

  EnemySpawn({
    required this.enemyType,
    required this.spawnTime,
    this.metadata = const {},
  });
}

/// Represents a wave of enemies
class EnemyWave {
  final int waveNumber;
  final List<EnemySpawn> enemySpawns;
  final double totalDuration;
  final int goldBonus;
  final Map<String, dynamic> metadata;

  EnemyWave({
    required this.waveNumber,
    required this.enemySpawns,
    this.goldBonus = 50,
    this.metadata = const {},
  }) : totalDuration = _calculateTotalDuration(enemySpawns);

  /// Calculate the total duration of the wave
  static double _calculateTotalDuration(List<EnemySpawn> spawns) {
    if (spawns.isEmpty) return 0.0;
    return spawns.map((s) => s.spawnTime).reduce(math.max);
  }

  /// Get the number of enemies in this wave
  int get enemyCount => enemySpawns.length;

  /// Get enemies to spawn at a specific time
  List<EnemySpawn> getEnemiesAtTime(double time) {
    const tolerance = 0.1; // 100ms tolerance
    return enemySpawns.where((spawn) {
      return (spawn.spawnTime - time).abs() <= tolerance;
    }).toList();
  }

  /// Get the enemy type distribution
  Map<EnemyType, int> get enemyDistribution {
    final distribution = <EnemyType, int>{};
    for (final spawn in enemySpawns) {
      distribution[spawn.enemyType] = (distribution[spawn.enemyType] ?? 0) + 1;
    }
    return distribution;
  }

  /// Check if this is a boss wave
  bool get isBossWave =>
      enemySpawns.any((spawn) => spawn.enemyType == EnemyType.boss);

  /// Get the difficulty rating of this wave
  double get difficultyRating {
    double rating = 0.0;
    for (final spawn in enemySpawns) {
      switch (spawn.enemyType) {
        case EnemyType.goblin:
          rating += 1.0;
          break;
        case EnemyType.orc:
          rating += 2.5;
          break;
        case EnemyType.troll:
          rating += 4.0;
          break;
        case EnemyType.boss:
          rating += 10.0;
          break;
      }
    }
    return rating;
  }
}

/// Manages wave generation and progression
class WaveManager {
  final math.Random _random = math.Random();
  final List<EnemyWave> _waves = [];

  int _currentWaveIndex = 0;
  double _currentWaveTime = 0.0;
  bool _isWaveActive = false;
  bool _isWaveComplete = false;

  /// Generate waves for the current level
  void generateWaves(int levelNumber, int totalWaves) {
    _waves.clear();
    _currentWaveIndex = 0;
    _currentWaveTime = 0.0;
    _isWaveActive = false;
    _isWaveComplete = false;

    for (int i = 1; i <= totalWaves; i++) {
      final wave = _generateWave(i, levelNumber);
      _waves.add(wave);
    }
  }

  /// Generate a single wave based on wave number and level
  EnemyWave _generateWave(int waveNumber, int levelNumber) {
    final spawns = <EnemySpawn>[];

    // More balanced enemy count progression
    int baseEnemies;
    if (waveNumber <= 3) {
      // Early waves: 1, 2, 3 enemies
      baseEnemies = waveNumber;
    } else if (waveNumber <= 10) {
      // Mid waves: 3-6 enemies
      baseEnemies = 3 + ((waveNumber - 3) ~/ 2);
    } else {
      // Late waves: 6+ enemies
      baseEnemies = 6 + ((waveNumber - 10) ~/ 3);
    }

    print('Generating wave ${waveNumber} with ${baseEnemies} enemies');

    // Enemy type probabilities change with wave progression
    final goblinChance = math.max(0.1, 0.8 - (waveNumber * 0.05)).toDouble();
    final orcChance = math.min(0.6, 0.2 + (waveNumber * 0.03)).toDouble();
    final trollChance = math
        .min(0.3, math.max(0, (waveNumber - 5) * 0.02))
        .toDouble();

    // Generate enemy spawns
    for (int i = 0; i < baseEnemies; i++) {
      final enemyType = _selectEnemyType(goblinChance, orcChance, trollChance);
      final spawnTime = i.toDouble() * 0.8; // 800ms between spawns

      spawns.add(EnemySpawn(enemyType: enemyType, spawnTime: spawnTime));
    }

    // Add boss every 5 waves
    if (waveNumber % 5 == 0) {
      spawns.add(
        EnemySpawn(
          enemyType: EnemyType.boss,
          spawnTime:
              baseEnemies.toDouble() * 0.8 +
              2.0, // Spawn boss 2 seconds after last enemy
        ),
      );
    }

    // Calculate gold bonus based on wave difficulty
    final goldBonus = 75 + (waveNumber * 15); // Increased bonus

    return EnemyWave(
      waveNumber: waveNumber,
      enemySpawns: spawns,
      goldBonus: goldBonus,
      metadata: {'level': levelNumber, 'isBossWave': waveNumber % 5 == 0},
    );
  }

  /// Select enemy type based on probabilities
  EnemyType _selectEnemyType(
    double goblinChance,
    double orcChance,
    double trollChance,
  ) {
    final random = _random.nextDouble();

    if (random < goblinChance) {
      return EnemyType.goblin;
    } else if (random < goblinChance + orcChance) {
      return EnemyType.orc;
    } else if (random < goblinChance + orcChance + trollChance) {
      return EnemyType.troll;
    } else {
      return EnemyType.goblin; // Fallback
    }
  }

  /// Start the current wave
  void startWave() {
    if (_currentWaveIndex < _waves.length) {
      _isWaveActive = true;
      _isWaveComplete = false;
      _currentWaveTime = 0.0;
      final wave = _waves[_currentWaveIndex];
      print('Starting wave ${wave.waveNumber} with ${wave.enemyCount} enemies');
    }
  }

  /// Update wave timing and spawn enemies
  List<Enemy> updateWave(double deltaTime, GamePath path) {
    if (!_isWaveActive || _currentWaveIndex >= _waves.length) {
      return [];
    }

    _currentWaveTime += deltaTime;
    final currentWave = _waves[_currentWaveIndex];

    // Check if wave is complete
    if (_currentWaveTime >= currentWave.totalDuration + 5.0) {
      // 5 second buffer
      _isWaveComplete = true;
      _isWaveActive = false;
    }

    // Get enemies to spawn at current time
    final spawnsAtTime = currentWave.getEnemiesAtTime(_currentWaveTime);
    final enemiesToSpawn = <Enemy>[];

    for (final spawn in spawnsAtTime) {
      final enemy = _createEnemy(spawn.enemyType, path);
      if (enemy != null) {
        enemiesToSpawn.add(enemy);
      }
    }

    return enemiesToSpawn;
  }

  /// Create an enemy of the specified type
  Enemy? _createEnemy(EnemyType type, GamePath path) {
    final startPosition = path.waypoints.isNotEmpty
        ? path.waypoints.first.position
        : Vector2.zero();

    switch (type) {
      case EnemyType.goblin:
        return Goblin(
          waypoints: path.positions,
          position: Vector2(startPosition.x, startPosition.y),
        );
      case EnemyType.orc:
        return Orc(
          waypoints: path.positions,
          position: Vector2(startPosition.x, startPosition.y),
        );
      case EnemyType.troll:
        return Troll(
          waypoints: path.positions,
          position: Vector2(startPosition.x, startPosition.y),
        );
      case EnemyType.boss:
        return Boss(
          waypoints: path.positions,
          position: Vector2(startPosition.x, startPosition.y),
        );
    }
  }

  /// Move to the next wave
  void nextWave() {
    if (_isWaveComplete) {
      _currentWaveIndex++;
      _currentWaveTime = 0.0;
      _isWaveActive = false;
      _isWaveComplete = false;
    }
  }

  /// Check if all waves are complete
  bool get isAllWavesComplete => _currentWaveIndex >= _waves.length;

  /// Get the current wave
  EnemyWave? get currentWave {
    if (_currentWaveIndex < _waves.length) {
      return _waves[_currentWaveIndex];
    }
    return null;
  }

  /// Get the current wave number (1-based)
  int get currentWaveNumber => _currentWaveIndex + 1;

  /// Get the total number of waves
  int get totalWaves => _waves.length;

  /// Check if a wave is currently active
  bool get isWaveActive => _isWaveActive;

  /// Check if the current wave is complete
  bool get isWaveComplete => _isWaveComplete;

  /// Get the current wave progress (0.0 to 1.0)
  double get currentWaveProgress {
    if (currentWave == null) return 0.0;
    return (_currentWaveTime / currentWave!.totalDuration).clamp(0.0, 1.0);
  }

  /// Get wave statistics
  Map<String, dynamic> getWaveStats() {
    if (currentWave == null) return {};

    final wave = currentWave!;
    return {
      'waveNumber': wave.waveNumber,
      'totalEnemies': wave.enemyCount,
      'enemyDistribution': wave.enemyDistribution,
      'difficultyRating': wave.difficultyRating,
      'goldBonus': wave.goldBonus,
      'isBossWave': wave.isBossWave,
      'progress': currentWaveProgress,
      'timeRemaining': math.max(0, wave.totalDuration - _currentWaveTime),
    };
  }

  /// Get preview of next wave
  Map<String, dynamic>? getNextWavePreview() {
    if (_currentWaveIndex + 1 >= _waves.length) return null;

    final nextWave = _waves[_currentWaveIndex + 1];
    return {
      'waveNumber': nextWave.waveNumber,
      'totalEnemies': nextWave.enemyCount,
      'enemyDistribution': nextWave.enemyDistribution,
      'difficultyRating': nextWave.difficultyRating,
      'goldBonus': nextWave.goldBonus,
      'isBossWave': nextWave.isBossWave,
    };
  }

  /// Reset the wave manager
  void reset() {
    _waves.clear();
    _currentWaveIndex = 0;
    _currentWaveTime = 0.0;
    _isWaveActive = false;
    _isWaveComplete = false;
  }
}

/// Predefined wave configurations for different levels
class LevelWaves {
  /// Generate waves for Level 1 (Forest Path)
  static void generateLevel1Waves(WaveManager waveManager) {
    waveManager.generateWaves(1, 20);
  }

  /// Generate waves for Level 2 (Mountain Pass)
  static void generateLevel2Waves(WaveManager waveManager) {
    waveManager.generateWaves(2, 25);
  }

  /// Generate waves for Level 3 (Castle Courtyard)
  static void generateLevel3Waves(WaveManager waveManager) {
    waveManager.generateWaves(3, 30);
  }

  /// Generate waves for a specific level
  static void generateWavesForLevel(WaveManager waveManager, int level) {
    switch (level) {
      case 1:
        generateLevel1Waves(waveManager);
        break;
      case 2:
        generateLevel2Waves(waveManager);
        break;
      case 3:
        generateLevel3Waves(waveManager);
        break;
      default:
        // Default to level 1 configuration
        generateLevel1Waves(waveManager);
    }
  }
}
