import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'path.dart';
import 'wave.dart';

/// Enumeration of level themes
enum LevelTheme { forest, mountain, castle, desert, ice, volcano }

/// Enumeration of difficulty levels
enum LevelDifficulty { easy, medium, hard, expert }

/// Level completion status
enum LevelStatus {
  locked,
  unlocked,
  completed,
  mastered, // Completed with perfect score
}

/// Level metadata and configuration
class GameLevel extends Equatable {
  final String id;
  final String name;
  final String description;
  final LevelTheme theme;
  final LevelDifficulty difficulty;
  final int levelNumber;
  final bool isUnlocked;
  final LevelStatus status;

  // Gameplay settings
  final int startingGold;
  final int startingLives;
  final int totalWaves;
  final double enemySpeedMultiplier;
  final double enemyHealthMultiplier;
  final int goldRewardMultiplier;

  // Visual settings
  final Color primaryColor;
  final Color secondaryColor;
  final Color pathColor;
  final String backgroundAsset;
  final Map<String, dynamic> visualEffects;

  // Requirements
  final List<String> requiredLevels; // Level IDs that must be completed first
  final int minimumScore; // Minimum score required to unlock next level

  // Metadata
  final DateTime? bestCompletionTime;
  final int? highScore;
  final int timesCompleted;
  final Map<String, dynamic> statistics;

  const GameLevel({
    required this.id,
    required this.name,
    required this.description,
    required this.theme,
    required this.difficulty,
    required this.levelNumber,
    this.isUnlocked = false,
    this.status = LevelStatus.locked,
    this.startingGold = 300,
    this.startingLives = 20,
    this.totalWaves = 20,
    this.enemySpeedMultiplier = 1.0,
    this.enemyHealthMultiplier = 1.0,
    this.goldRewardMultiplier = 1,
    required this.primaryColor,
    required this.secondaryColor,
    required this.pathColor,
    this.backgroundAsset = '',
    this.visualEffects = const {},
    this.requiredLevels = const [],
    this.minimumScore = 0,
    this.bestCompletionTime,
    this.highScore,
    this.timesCompleted = 0,
    this.statistics = const {},
  });

  /// Create a copy with updated values
  GameLevel copyWith({
    String? id,
    String? name,
    String? description,
    LevelTheme? theme,
    LevelDifficulty? difficulty,
    int? levelNumber,
    bool? isUnlocked,
    LevelStatus? status,
    int? startingGold,
    int? startingLives,
    int? totalWaves,
    double? enemySpeedMultiplier,
    double? enemyHealthMultiplier,
    int? goldRewardMultiplier,
    Color? primaryColor,
    Color? secondaryColor,
    Color? pathColor,
    String? backgroundAsset,
    Map<String, dynamic>? visualEffects,
    List<String>? requiredLevels,
    int? minimumScore,
    DateTime? bestCompletionTime,
    int? highScore,
    int? timesCompleted,
    Map<String, dynamic>? statistics,
  }) => GameLevel(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    theme: theme ?? this.theme,
    difficulty: difficulty ?? this.difficulty,
    levelNumber: levelNumber ?? this.levelNumber,
    isUnlocked: isUnlocked ?? this.isUnlocked,
    status: status ?? this.status,
    startingGold: startingGold ?? this.startingGold,
    startingLives: startingLives ?? this.startingLives,
    totalWaves: totalWaves ?? this.totalWaves,
    enemySpeedMultiplier: enemySpeedMultiplier ?? this.enemySpeedMultiplier,
    enemyHealthMultiplier: enemyHealthMultiplier ?? this.enemyHealthMultiplier,
    goldRewardMultiplier: goldRewardMultiplier ?? this.goldRewardMultiplier,
    primaryColor: primaryColor ?? this.primaryColor,
    secondaryColor: secondaryColor ?? this.secondaryColor,
    pathColor: pathColor ?? this.pathColor,
    backgroundAsset: backgroundAsset ?? this.backgroundAsset,
    visualEffects: visualEffects ?? this.visualEffects,
    requiredLevels: requiredLevels ?? this.requiredLevels,
    minimumScore: minimumScore ?? this.minimumScore,
    bestCompletionTime: bestCompletionTime ?? this.bestCompletionTime,
    highScore: highScore ?? this.highScore,
    timesCompleted: timesCompleted ?? this.timesCompleted,
    statistics: statistics ?? this.statistics,
  );

  /// Get difficulty rating (1-5 stars)
  int get difficultyRating {
    switch (difficulty) {
      case LevelDifficulty.easy:
        return 1;
      case LevelDifficulty.medium:
        return 2;
      case LevelDifficulty.hard:
        return 3;
      case LevelDifficulty.expert:
        return 4;
    }
  }

  /// Get theme display name
  String get themeDisplayName {
    switch (theme) {
      case LevelTheme.forest:
        return 'Forest Path';
      case LevelTheme.mountain:
        return 'Mountain Pass';
      case LevelTheme.castle:
        return 'Castle Courtyard';
      case LevelTheme.desert:
        return 'Desert Oasis';
      case LevelTheme.ice:
        return 'Frozen Tundra';
      case LevelTheme.volcano:
        return 'Volcanic Crater';
    }
  }

  /// Get difficulty display name
  String get difficultyDisplayName {
    switch (difficulty) {
      case LevelDifficulty.easy:
        return 'Easy';
      case LevelDifficulty.medium:
        return 'Medium';
      case LevelDifficulty.hard:
        return 'Hard';
      case LevelDifficulty.expert:
        return 'Expert';
    }
  }

  /// Check if level can be played
  bool get canPlay => isUnlocked && status != LevelStatus.locked;

  /// Get progress percentage (0.0 to 1.0)
  double get progressPercentage {
    switch (status) {
      case LevelStatus.locked:
        return 0.0;
      case LevelStatus.unlocked:
        return 0.0;
      case LevelStatus.completed:
        return 1.0;
      case LevelStatus.mastered:
        return 1.0;
    }
  }

  /// Get level path using existing LevelPaths system
  GamePath? getPath(double screenWidth, double screenHeight) {
    // Initialize paths for this level
    switch (theme) {
      case LevelTheme.forest:
        LevelPaths.initializeLevel1Paths(screenWidth, screenHeight);
        return LevelPaths.getMainPath(1);
      case LevelTheme.mountain:
        LevelPaths.initializeLevel2Paths(screenWidth, screenHeight);
        return LevelPaths.getMainPath(2);
      case LevelTheme.castle:
        LevelPaths.initializeLevel3Paths(screenWidth, screenHeight);
        return LevelPaths.getMainPath(3);
      case LevelTheme.desert:
      case LevelTheme.ice:
      case LevelTheme.volcano:
        // For now, use forest path as fallback
        LevelPaths.initializeLevel1Paths(screenWidth, screenHeight);
        return LevelPaths.getMainPath(1);
    }
  }

  /// Generate waves for this level
  void generateWaves(WaveManager waveManager) {
    // Use existing wave generation with level-specific parameters
    switch (theme) {
      case LevelTheme.forest:
        LevelWaves.generateLevel1Waves(waveManager);
        break;
      case LevelTheme.mountain:
        LevelWaves.generateLevel2Waves(waveManager);
        break;
      case LevelTheme.castle:
        LevelWaves.generateLevel3Waves(waveManager);
        break;
      case LevelTheme.desert:
      case LevelTheme.ice:
      case LevelTheme.volcano:
        // For now, use level 1 waves as fallback
        LevelWaves.generateLevel1Waves(waveManager);
        break;
    }
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    theme,
    difficulty,
    levelNumber,
    isUnlocked,
    status,
    startingGold,
    startingLives,
    totalWaves,
    enemySpeedMultiplier,
    enemyHealthMultiplier,
    goldRewardMultiplier,
    primaryColor,
    secondaryColor,
    pathColor,
    backgroundAsset,
    visualEffects,
    requiredLevels,
    minimumScore,
    bestCompletionTime,
    highScore,
    timesCompleted,
    statistics,
  ];
}

/// Predefined levels configuration
class GameLevels {
  static const List<GameLevel> defaultLevels = [
    // Level 1: Forest Path - Tutorial/Easy
    GameLevel(
      id: 'forest_path',
      name: 'Forest Path',
      description:
          'A peaceful forest trail perfect for learning the basics of tower defense.',
      theme: LevelTheme.forest,
      difficulty: LevelDifficulty.easy,
      levelNumber: 1,
      isUnlocked: true,
      status: LevelStatus.unlocked,
      startingGold: 400, // Extra gold for tutorial
      startingLives: 25, // Extra lives for tutorial
      totalWaves: 15, // Fewer waves for tutorial
      enemySpeedMultiplier: 0.8, // Slower enemies for tutorial
      enemyHealthMultiplier: 0.9, // Slightly weaker enemies
      goldRewardMultiplier: 1,
      primaryColor: Color(0xFF2E7D32), // Forest green
      secondaryColor: Color(0xFF4CAF50), // Light green
      pathColor: Color(0xFF8BC34A), // Lime green
      backgroundAsset: 'forest_bg.png',
      visualEffects: {
        'particles': ['leaves', 'fireflies'],
        'ambient': 'forest_sounds',
      },
      requiredLevels: [],
      minimumScore: 0,
    ),

    // Level 2: Mountain Pass - Medium
    GameLevel(
      id: 'mountain_pass',
      name: 'Mountain Pass',
      description:
          'Navigate treacherous mountain paths with challenging terrain.',
      theme: LevelTheme.mountain,
      difficulty: LevelDifficulty.medium,
      levelNumber: 2,
      startingGold: 300,
      startingLives: 20,
      totalWaves: 20,
      enemySpeedMultiplier: 1.0,
      enemyHealthMultiplier: 1.2,
      goldRewardMultiplier: 1,
      primaryColor: Color(0xFF5D4037), // Brown
      secondaryColor: Color(0xFF8D6E63), // Light brown
      pathColor: Color(0xFFBCAAA4), // Tan
      backgroundAsset: 'mountain_bg.png',
      visualEffects: {
        'particles': ['snow', 'rocks'],
        'ambient': 'mountain_wind',
      },
      requiredLevels: ['forest_path'],
      minimumScore: 10000,
    ),

    // Level 3: Castle Courtyard - Hard
    GameLevel(
      id: 'castle_courtyard',
      name: 'Castle Courtyard',
      description:
          'Defend the ancient castle with its complex maze-like layout.',
      theme: LevelTheme.castle,
      difficulty: LevelDifficulty.hard,
      levelNumber: 3,
      startingGold: 250,
      startingLives: 15,
      totalWaves: 25,
      enemySpeedMultiplier: 1.1,
      enemyHealthMultiplier: 1.5,
      goldRewardMultiplier: 2,
      primaryColor: Color(0xFF424242), // Dark grey
      secondaryColor: Color(0xFF757575), // Grey
      pathColor: Color(0xFF9E9E9E), // Light grey
      backgroundAsset: 'castle_bg.png',
      visualEffects: {
        'particles': ['dust', 'sparks'],
        'ambient': 'castle_echo',
      },
      requiredLevels: ['mountain_pass'],
      minimumScore: 25000,
    ),

    // Level 4: Desert Oasis - Expert
    GameLevel(
      id: 'desert_oasis',
      name: 'Desert Oasis',
      description:
          'Survive the scorching desert heat in this challenging oasis defense.',
      theme: LevelTheme.desert,
      difficulty: LevelDifficulty.expert,
      levelNumber: 4,
      startingGold: 200,
      startingLives: 10,
      totalWaves: 30,
      enemySpeedMultiplier: 1.3,
      enemyHealthMultiplier: 2.0,
      goldRewardMultiplier: 3,
      primaryColor: Color(0xFFFF8F00), // Orange
      secondaryColor: Color(0xFFFFB74D), // Light orange
      pathColor: Color(0xFFFFE082), // Yellow
      backgroundAsset: 'desert_bg.png',
      visualEffects: {
        'particles': ['sand', 'heat_waves'],
        'ambient': 'desert_wind',
      },
      requiredLevels: ['castle_courtyard'],
      minimumScore: 50000,
    ),

    // Level 5: Frozen Tundra - Expert
    GameLevel(
      id: 'frozen_tundra',
      name: 'Frozen Tundra',
      description:
          'Battle through the frozen wasteland where enemies move unpredictably.',
      theme: LevelTheme.ice,
      difficulty: LevelDifficulty.expert,
      levelNumber: 5,
      startingGold: 200,
      startingLives: 10,
      totalWaves: 30,
      enemySpeedMultiplier: 0.9, // Slower but more health
      enemyHealthMultiplier: 2.5,
      goldRewardMultiplier: 3,
      primaryColor: Color(0xFF0277BD), // Blue
      secondaryColor: Color(0xFF4FC3F7), // Light blue
      pathColor: Color(0xFF81D4FA), // Very light blue
      backgroundAsset: 'ice_bg.png',
      visualEffects: {
        'particles': ['snowflakes', 'ice_crystals'],
        'ambient': 'arctic_wind',
      },
      requiredLevels: ['desert_oasis'],
      minimumScore: 75000,
    ),

    // Level 6: Volcanic Crater - Expert
    GameLevel(
      id: 'volcanic_crater',
      name: 'Volcanic Crater',
      description: 'The ultimate challenge in the heart of an active volcano.',
      theme: LevelTheme.volcano,
      difficulty: LevelDifficulty.expert,
      levelNumber: 6,
      startingGold: 150,
      startingLives: 5,
      totalWaves: 35,
      enemySpeedMultiplier: 1.5,
      enemyHealthMultiplier: 3.0,
      goldRewardMultiplier: 5,
      primaryColor: Color(0xFFD32F2F), // Red
      secondaryColor: Color(0xFFFF5722), // Deep orange
      pathColor: Color(0xFFFF9800), // Orange
      backgroundAsset: 'volcano_bg.png',
      visualEffects: {
        'particles': ['lava', 'embers', 'smoke'],
        'ambient': 'volcano_rumble',
      },
      requiredLevels: ['frozen_tundra'],
      minimumScore: 100000,
    ),
  ];

  /// Get a level by ID
  static GameLevel? getLevelById(String id) {
    try {
      return defaultLevels.firstWhere((level) => level.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get a level by number
  static GameLevel? getLevelByNumber(int levelNumber) {
    try {
      return defaultLevels.firstWhere(
        (level) => level.levelNumber == levelNumber,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get all levels
  static List<GameLevel> getAllLevels() => List.from(defaultLevels);

  /// Get unlocked levels
  static List<GameLevel> getUnlockedLevels() =>
      defaultLevels.where((level) => level.isUnlocked).toList();

  /// Get levels by difficulty
  static List<GameLevel> getLevelsByDifficulty(LevelDifficulty difficulty) =>
      defaultLevels.where((level) => level.difficulty == difficulty).toList();

  /// Get levels by theme
  static List<GameLevel> getLevelsByTheme(LevelTheme theme) =>
      defaultLevels.where((level) => level.theme == theme).toList();
}
