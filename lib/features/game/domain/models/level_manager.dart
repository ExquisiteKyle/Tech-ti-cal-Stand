import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'level.dart';
import 'path.dart';
import 'wave.dart';
import '../../../../core/audio/audio_manager.dart';

/// Manages level progression, state, and data persistence
class LevelManager extends ChangeNotifier {
  static LevelManager? _instance;
  static LevelManager get instance => _instance ??= LevelManager._();

  LevelManager._();

  // Current game state
  GameLevel? _currentLevel;
  List<GameLevel> _levels = [];
  Map<String, Map<String, dynamic>> _levelProgress = {};
  bool _isInitialized = false;

  // Getters
  GameLevel? get currentLevel => _currentLevel;
  List<GameLevel> get levels => List.unmodifiable(_levels);
  bool get isInitialized => _isInitialized;

  /// Initialize the level manager with default levels
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Load default levels
    _levels = GameLevels.getAllLevels();

    // Load saved progress
    await _loadProgress();

    // Update level states based on progress
    _updateLevelStates();

    _isInitialized = true;
    notifyListeners();
  }

  /// Load level progress from persistent storage
  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString('level_progress');
      if (progressJson != null) {
        final progressMap = json.decode(progressJson) as Map<String, dynamic>;
        _levelProgress = progressMap.map(
          (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
        );
      }
    } catch (e) {
      // If loading fails, start with empty progress
      _levelProgress = {};
    }
  }

  /// Save level progress to persistent storage
  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = json.encode(_levelProgress);
      await prefs.setString('level_progress', progressJson);
    } catch (e) {
      // Silently fail if saving fails
      debugPrint('Failed to save level progress: $e');
    }
  }

  /// Update level states based on saved progress
  void _updateLevelStates() {
    final updatedLevels = <GameLevel>[];

    for (final level in _levels) {
      final progress = _levelProgress[level.id];
      if (progress != null) {
        final status = LevelStatus.values.firstWhere(
          (s) => s.name == progress['status'],
          orElse: () => LevelStatus.locked,
        );

        final updatedLevel = level.copyWith(
          status: status,
          isUnlocked: progress['isUnlocked'] ?? false,
          highScore: progress['highScore'],
          timesCompleted: progress['timesCompleted'] ?? 0,
          bestCompletionTime: progress['bestCompletionTime'] != null
              ? DateTime.parse(progress['bestCompletionTime'])
              : null,
          statistics: Map<String, dynamic>.from(progress['statistics'] ?? {}),
        );
        updatedLevels.add(updatedLevel);
      } else {
        // First level is unlocked by default
        if (level.levelNumber == 1) {
          updatedLevels.add(
            level.copyWith(isUnlocked: true, status: LevelStatus.unlocked),
          );
        } else {
          updatedLevels.add(level);
        }
      }
    }

    _levels = updatedLevels;
    _checkAndUnlockLevels();
  }

  /// Check if levels should be unlocked based on completed requirements
  void _checkAndUnlockLevels() {
    bool hasChanges = false;

    for (int i = 0; i < _levels.length; i++) {
      final level = _levels[i];
      if (level.isUnlocked) continue;

      // Check if all required levels are completed
      bool canUnlock = true;
      for (final requiredId in level.requiredLevels) {
        final requiredLevel = _levels.firstWhere(
          (l) => l.id == requiredId,
          orElse: () => level, // If not found, treat as not completed
        );
        if (requiredLevel.status != LevelStatus.completed &&
            requiredLevel.status != LevelStatus.mastered) {
          canUnlock = false;
          break;
        }
      }

      if (canUnlock) {
        _levels[i] = level.copyWith(
          isUnlocked: true,
          status: LevelStatus.unlocked,
        );
        hasChanges = true;
      }
    }

    if (hasChanges) {
      _saveProgress();
      notifyListeners();
    }
  }

  /// Select a level to play
  Future<bool> selectLevel(String levelId) async {
    final level = _levels.firstWhere(
      (l) => l.id == levelId,
      orElse: () => _levels.first,
    );

    if (!level.canPlay) {
      return false;
    }

    _currentLevel = level;
    notifyListeners();
    return true;
  }

  /// Complete a level with score and time
  Future<void> completeLevel(
    String levelId, {
    required int score,
    required Duration completionTime,
    required bool isPerfect,
  }) async {
    final levelIndex = _levels.indexWhere((l) => l.id == levelId);
    if (levelIndex == -1) return;

    final level = _levels[levelIndex];

    // Determine new status
    LevelStatus newStatus;
    if (isPerfect && score > (level.highScore ?? 0)) {
      newStatus = LevelStatus.mastered;
    } else {
      newStatus = LevelStatus.completed;
    }

    // Update high score if better
    final newHighScore = score > (level.highScore ?? 0)
        ? score
        : level.highScore;

    // Update best time if better
    DateTime? newBestTime;
    if (level.bestCompletionTime == null) {
      newBestTime = DateTime.now();
    } else {
      // Compare completion times properly
      final currentBestDuration =
          level.statistics['bestCompletionDuration'] as int?;
      if (currentBestDuration == null ||
          completionTime.inSeconds < currentBestDuration) {
        newBestTime = DateTime.now();
      } else {
        newBestTime = level.bestCompletionTime;
      }
    }

    // Update statistics
    final stats = Map<String, dynamic>.from(level.statistics);
    stats['totalPlayTime'] =
        (stats['totalPlayTime'] ?? 0) + completionTime.inSeconds;
    stats['averageScore'] =
        ((stats['averageScore'] ?? 0) * level.timesCompleted + score) /
        (level.timesCompleted + 1);

    // Update best completion duration if this is better
    final currentBestDuration = stats['bestCompletionDuration'] as int?;
    if (currentBestDuration == null ||
        completionTime.inSeconds < currentBestDuration) {
      stats['bestCompletionDuration'] = completionTime.inSeconds;
    }

    // Update level
    _levels[levelIndex] = level.copyWith(
      status: newStatus,
      highScore: newHighScore,
      timesCompleted: level.timesCompleted + 1,
      bestCompletionTime: newBestTime,
      statistics: stats,
    );

    // Update progress data
    _levelProgress[levelId] = {
      'status': newStatus.name,
      'isUnlocked': true,
      'highScore': newHighScore,
      'timesCompleted': level.timesCompleted + 1,
      'bestCompletionTime': newBestTime?.toIso8601String(),
      'statistics': stats,
    };

    // Save progress
    await _saveProgress();

    // Check if new levels should be unlocked
    _checkAndUnlockLevels();

    // Play completion sound
    if (isPerfect) {
      AudioManager().playSfx(AudioEvent.victory);
    } else {
      AudioManager().playSfx(AudioEvent.waveStart);
    }

    notifyListeners();
  }

  /// Get level by ID
  GameLevel? getLevelById(String id) {
    try {
      return _levels.firstWhere((l) => l.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get unlocked levels
  List<GameLevel> getUnlockedLevels() =>
      _levels.where((l) => l.isUnlocked).toList();

  /// Get completed levels
  List<GameLevel> getCompletedLevels() => _levels
      .where(
        (l) =>
            l.status == LevelStatus.completed ||
            l.status == LevelStatus.mastered,
      )
      .toList();

  /// Get levels by difficulty
  List<GameLevel> getLevelsByDifficulty(LevelDifficulty difficulty) =>
      _levels.where((l) => l.difficulty == difficulty).toList();

  /// Get overall progress percentage
  double getOverallProgress() {
    if (_levels.isEmpty) return 0.0;
    final completedCount = getCompletedLevels().length;
    return completedCount / _levels.length;
  }

  /// Get total score across all levels
  int getTotalScore() {
    return _levels.fold(0, (sum, level) => sum + (level.highScore ?? 0));
  }

  /// Get total play time across all levels
  Duration getTotalPlayTime() {
    int totalSeconds = 0;
    for (final level in _levels) {
      final stats = level.statistics;
      totalSeconds += (stats['totalPlayTime'] ?? 0) as int;
    }
    return Duration(seconds: totalSeconds);
  }

  /// Reset all progress (for testing or new game)
  Future<void> resetProgress() async {
    _levelProgress.clear();
    await _saveProgress();
    _updateLevelStates();
    _currentLevel = null;
    notifyListeners();
  }

  /// Initialize level path for current level
  GamePath? initializeLevelPath(double screenWidth, double screenHeight) {
    if (_currentLevel == null) return null;
    return _currentLevel!.getPath(screenWidth, screenHeight);
  }

  /// Generate waves for current level
  void generateLevelWaves(WaveManager waveManager) {
    if (_currentLevel == null) return;
    _currentLevel!.generateWaves(waveManager);
  }

  /// Get current level's starting resources
  ({int gold, int lives}) getCurrentLevelResources() {
    if (_currentLevel == null) return (gold: 300, lives: 20);
    return (
      gold: _currentLevel!.startingGold,
      lives: _currentLevel!.startingLives,
    );
  }

  /// Get current level's enemy multipliers
  ({double speed, double health}) getCurrentLevelMultipliers() {
    if (_currentLevel == null) return (speed: 1.0, health: 1.0);
    return (
      speed: _currentLevel!.enemySpeedMultiplier,
      health: _currentLevel!.enemyHealthMultiplier,
    );
  }

  /// Check if a level is the first level
  bool isFirstLevel(String levelId) {
    final level = getLevelById(levelId);
    return level?.levelNumber == 1;
  }

  /// Get next level after current
  GameLevel? getNextLevel() {
    if (_currentLevel == null) return null;

    final currentIndex = _levels.indexWhere((l) => l.id == _currentLevel!.id);
    if (currentIndex == -1 || currentIndex >= _levels.length - 1) return null;

    return _levels[currentIndex + 1];
  }

  /// Get previous level before current
  GameLevel? getPreviousLevel() {
    if (_currentLevel == null) return null;

    final currentIndex = _levels.indexWhere((l) => l.id == _currentLevel!.id);
    if (currentIndex <= 0) return null;

    return _levels[currentIndex - 1];
  }

  /// Get level statistics for analytics
  Map<String, dynamic> getLevelStatistics(String levelId) {
    final level = getLevelById(levelId);
    if (level == null) return {};

    return {
      'levelId': levelId,
      'levelName': level.name,
      'theme': level.theme.name,
      'difficulty': level.difficulty.name,
      'status': level.status.name,
      'highScore': level.highScore ?? 0,
      'timesCompleted': level.timesCompleted,
      'bestCompletionTime': level.bestCompletionTime?.toIso8601String(),
      'statistics': level.statistics,
    };
  }

  /// Get all statistics for analytics
  Map<String, dynamic> getAllStatistics() {
    return {
      'totalLevels': _levels.length,
      'unlockedLevels': getUnlockedLevels().length,
      'completedLevels': getCompletedLevels().length,
      'overallProgress': getOverallProgress(),
      'totalScore': getTotalScore(),
      'totalPlayTime': getTotalPlayTime().inSeconds,
      'levels': _levels.map((l) => getLevelStatistics(l.id)).toList(),
    };
  }
}
