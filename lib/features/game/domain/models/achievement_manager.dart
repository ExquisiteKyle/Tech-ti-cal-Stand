import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'achievement.dart';
import '../../../../core/audio/audio_manager.dart';

/// Manager for handling achievements system
class AchievementManager {
  static AchievementManager? _instance;
  static AchievementManager get instance =>
      _instance ??= AchievementManager._();

  AchievementManager._();

  static const String _unlockedAchievementsKey = 'unlocked_achievements';
  static const String _achievementProgressKey = 'achievement_progress';

  List<Achievement> _achievements = [];
  Map<String, int> _achievementProgress = {};
  Set<String> _unlockedAchievements = {};

  /// Initialize achievement manager
  Future<void> initialize() async {
    _achievements = List.from(GameAchievements.defaultAchievements);
    await _loadAchievements();
  }

  /// Get all achievements
  List<Achievement> get achievements => _achievements;

  /// Get achievements by category
  List<Achievement> getAchievementsByCategory(AchievementCategory category) =>
      _achievements.where((a) => a.category == category).toList();

  /// Get unlocked achievements
  List<Achievement> get unlockedAchievements =>
      _achievements.where((a) => _unlockedAchievements.contains(a.id)).toList();

  /// Get locked achievements
  List<Achievement> get lockedAchievements => _achievements
      .where((a) => !_unlockedAchievements.contains(a.id))
      .toList();

  /// Get achievement progress
  int getAchievementProgress(String achievementId) =>
      _achievementProgress[achievementId] ?? 0;

  /// Check if achievement is unlocked
  bool isAchievementUnlocked(String achievementId) =>
      _unlockedAchievements.contains(achievementId);

  /// Update achievement progress
  Future<void> updateAchievementProgress(
    String achievementId,
    int progress,
  ) async {
    final achievement = _achievements.firstWhere(
      (a) => a.id == achievementId,
      orElse: () =>
          throw ArgumentError('Achievement not found: $achievementId'),
    );

    final currentProgress = _achievementProgress[achievementId] ?? 0;
    final newProgress = (currentProgress + progress).clamp(
      0,
      achievement.maxProgress,
    );

    _achievementProgress[achievementId] = newProgress;

    // Check if achievement should be unlocked
    if (newProgress >= achievement.maxProgress &&
        !_unlockedAchievements.contains(achievementId)) {
      await _unlockAchievement(achievementId);
    }

    await _saveAchievements();
  }

  /// Set achievement progress directly
  Future<void> setAchievementProgress(
    String achievementId,
    int progress,
  ) async {
    final achievement = _achievements.firstWhere(
      (a) => a.id == achievementId,
      orElse: () =>
          throw ArgumentError('Achievement not found: $achievementId'),
    );

    final clampedProgress = progress.clamp(0, achievement.maxProgress);
    _achievementProgress[achievementId] = clampedProgress;

    // Check if achievement should be unlocked
    if (clampedProgress >= achievement.maxProgress &&
        !_unlockedAchievements.contains(achievementId)) {
      await _unlockAchievement(achievementId);
    }

    await _saveAchievements();
  }

  /// Unlock achievement
  Future<void> _unlockAchievement(String achievementId) async {
    if (_unlockedAchievements.contains(achievementId)) return;

    _unlockedAchievements.add(achievementId);

    // Play achievement sound
    await AudioManager().playSfx(AudioEvent.victory);

    // Update achievement with unlock time
    final achievementIndex = _achievements.indexWhere(
      (a) => a.id == achievementId,
    );
    if (achievementIndex != -1) {
      _achievements[achievementIndex] = _achievements[achievementIndex]
          .copyWith(isUnlocked: true, unlockedAt: DateTime.now());
    }

    await _saveAchievements();
  }

  /// Get achievement statistics
  Map<String, dynamic> getAchievementStats() {
    final totalAchievements = _achievements.length;
    final unlockedCount = _unlockedAchievements.length;
    final completionRate = totalAchievements > 0
        ? (unlockedCount / totalAchievements) * 100
        : 0.0;

    final categoryStats = <AchievementCategory, Map<String, int>>{};
    for (final category in AchievementCategory.values) {
      final categoryAchievements = getAchievementsByCategory(category);
      final categoryUnlocked = categoryAchievements
          .where((a) => _unlockedAchievements.contains(a.id))
          .length;
      categoryStats[category] = {
        'total': categoryAchievements.length,
        'unlocked': categoryUnlocked,
      };
    }

    return {
      'totalAchievements': totalAchievements,
      'unlockedAchievements': unlockedCount,
      'completionRate': completionRate,
      'categoryStats': categoryStats,
    };
  }

  /// Get recent achievements (last 10)
  List<Achievement> getRecentAchievements() {
    final recent = _achievements
        .where(
          (a) => _unlockedAchievements.contains(a.id) && a.unlockedAt != null,
        )
        .toList();

    recent.sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));
    return recent.take(10).toList();
  }

  /// Check and update tower-related achievements
  Future<void> checkTowerAchievements({
    required String towerType,
    int towersPlaced = 0,
    int enemiesKilled = 0,
    int criticalHits = 0,
    int enemiesSlowed = 0,
    Set<String>? towerTypesUsed,
  }) async {
    // Tower Collector - Place all 4 tower types
    if (towerTypesUsed != null && towerTypesUsed.length >= 4) {
      await updateAchievementProgress('tower_collector', 1);
    }

    // Tower-specific achievements
    switch (towerType.toLowerCase()) {
      case 'archer':
        if (towersPlaced > 0) {
          await updateAchievementProgress('archer_expert', towersPlaced);
        }
        break;
      case 'cannon':
        if (enemiesKilled > 0) {
          await updateAchievementProgress('cannon_master', enemiesKilled);
        }
        break;
      case 'magic':
        if (enemiesSlowed > 0) {
          await updateAchievementProgress('magic_user', enemiesSlowed);
        }
        break;
      case 'sniper':
        if (criticalHits > 0) {
          await updateAchievementProgress('sniper_elite', criticalHits);
        }
        break;
    }
  }

  /// Check and update combat achievements
  Future<void> checkCombatAchievements({
    int enemiesKilled = 0,
    int bossesKilled = 0,
    int damageDealt = 0,
    int enemiesKilledInTimeframe = 0,
    Duration? timeframe,
  }) async {
    // Enemy Slayer
    if (enemiesKilled > 0) {
      await updateAchievementProgress('enemy_slayer', enemiesKilled);
    }

    // Boss Hunter
    if (bossesKilled > 0) {
      await updateAchievementProgress('boss_hunter', bossesKilled);
    }

    // Overkill - 1000 damage in single hit
    if (damageDealt >= 1000) {
      await updateAchievementProgress('overkill', 1);
    }

    // Chain Killer - 10 enemies in 5 seconds
    if (timeframe != null &&
        timeframe.inSeconds <= 5 &&
        enemiesKilledInTimeframe >= 10) {
      await updateAchievementProgress('chain_killer', 1);
    }
  }

  /// Check and update strategic achievements
  Future<void> checkStrategicAchievements({
    bool perfectWave = false,
    int goldRemaining = 0,
    Duration? levelTime,
    double? accuracy,
  }) async {
    // Perfect Defense
    if (perfectWave) {
      await updateAchievementProgress('perfect_defense', 1);
    }

    // Resource Manager - Complete wave with less than 50 gold
    if (goldRemaining < 50) {
      await updateAchievementProgress('resource_manager', 1);
    }

    // Speed Runner - Complete level in under 5 minutes
    if (levelTime != null && levelTime.inMinutes < 5) {
      await updateAchievementProgress('speed_runner', 1);
    }

    // Efficiency Expert - 90% accuracy
    if (accuracy != null && accuracy >= 0.9) {
      await updateAchievementProgress('efficiency_expert', 1);
    }
  }

  /// Check and update progression achievements
  Future<void> checkProgressionAchievements({
    int wavesCompleted = 0,
    int levelsCompleted = 0,
    int goldEarned = 0,
    bool isFirstVictory = false,
  }) async {
    // Wave Survivor
    if (wavesCompleted > 0) {
      await updateAchievementProgress('wave_survivor', wavesCompleted);
    }

    // Level Master
    if (levelsCompleted > 0) {
      await updateAchievementProgress('level_master', levelsCompleted);
    }

    // Gold Collector
    if (goldEarned > 0) {
      await updateAchievementProgress('gold_collector', goldEarned);
    }

    // First Victory
    if (isFirstVictory) {
      await updateAchievementProgress('first_victory', 1);
    }

    // Perfectionist - Master all 6 levels
    if (levelsCompleted >= 6) {
      await updateAchievementProgress('perfectionist', 1);
    }
  }

  /// Check time-based achievements
  Future<void> checkTimeAchievements() async {
    final now = DateTime.now();
    final hour = now.hour;

    // Early Bird - Play between 6-10 AM
    if (hour >= 6 && hour <= 10) {
      await updateAchievementProgress('early_bird', 1);
    }

    // Night Owl - Play between 10 PM - 2 AM
    if (hour >= 22 || hour <= 2) {
      await updateAchievementProgress('night_owl', 1);
    }

    // Dedication - Play for 7 consecutive days
    await _checkDedicationAchievement();
  }

  /// Check dedication achievement (7 consecutive days)
  Future<void> _checkDedicationAchievement() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final playDates = prefs.getStringList('play_dates') ?? [];

    if (!playDates.contains(today)) {
      playDates.add(today);
      await prefs.setStringList('play_dates', playDates);
    }

    // Check for 7 consecutive days
    if (playDates.length >= 7) {
      playDates.sort();
      final recentDates = playDates.take(7).toList();

      bool consecutive = true;
      for (int i = 1; i < recentDates.length; i++) {
        final prev = DateTime.parse(recentDates[i - 1]);
        final curr = DateTime.parse(recentDates[i]);
        if (curr.difference(prev).inDays != 1) {
          consecutive = false;
          break;
        }
      }

      if (consecutive) {
        await updateAchievementProgress('dedication', 1);
      }
    }
  }

  /// Reset all achievements (for testing)
  Future<void> resetAchievements() async {
    _achievementProgress.clear();
    _unlockedAchievements.clear();
    _achievements = List.from(GameAchievements.defaultAchievements);
    await _saveAchievements();
  }

  /// Load achievements from storage
  Future<void> _loadAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load progress
      final progressJson = prefs.getString(_achievementProgressKey);
      if (progressJson != null) {
        final progressData = jsonDecode(progressJson) as Map<String, dynamic>;
        _achievementProgress = progressData.map(
          (key, value) => MapEntry(key, value as int),
        );
      }

      // Load unlocked achievements
      final unlockedJson = prefs.getString(_unlockedAchievementsKey);
      if (unlockedJson != null) {
        final unlockedData = jsonDecode(unlockedJson) as List<dynamic>;
        _unlockedAchievements = unlockedData.cast<String>().toSet();
      }

      // Update achievement objects with current progress and unlock status
      for (int i = 0; i < _achievements.length; i++) {
        final achievement = _achievements[i];
        final progress = _achievementProgress[achievement.id] ?? 0;
        final isUnlocked = _unlockedAchievements.contains(achievement.id);

        _achievements[i] = achievement.copyWith(
          currentProgress: progress,
          isUnlocked: isUnlocked,
        );
      }
    } catch (e) {
      debugPrint('Error loading achievements: $e');
    }
  }

  /// Save achievements to storage
  Future<void> _saveAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save progress
      await prefs.setString(
        _achievementProgressKey,
        jsonEncode(_achievementProgress),
      );

      // Save unlocked achievements
      await prefs.setString(
        _unlockedAchievementsKey,
        jsonEncode(_unlockedAchievements.toList()),
      );
    } catch (e) {
      debugPrint('Error saving achievements: $e');
    }
  }
}
