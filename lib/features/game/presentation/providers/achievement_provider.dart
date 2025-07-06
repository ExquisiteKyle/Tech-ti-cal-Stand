import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/achievement.dart';
import '../../domain/models/achievement_manager.dart';

/// Provider for the AchievementManager singleton
final achievementManagerProvider = Provider<AchievementManager>(
  (ref) => AchievementManager.instance,
);

/// Provider for all achievements
final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final manager = ref.watch(achievementManagerProvider);
  await manager.initialize();
  return manager.achievements;
});

/// Provider for achievements by category
final achievementsByCategoryProvider =
    Provider.family<AsyncValue<List<Achievement>>, AchievementCategory>((
      ref,
      category,
    ) {
      final achievementsAsync = ref.watch(achievementsProvider);
      return achievementsAsync.when(
        data: (achievements) => AsyncValue.data(
          achievements.where((a) => a.category == category).toList(),
        ),
        loading: () => const AsyncValue.loading(),
        error: (error, stack) => AsyncValue.error(error, stack),
      );
    });

/// Provider for unlocked achievements
final unlockedAchievementsProvider = FutureProvider<List<Achievement>>((
  ref,
) async {
  final manager = ref.watch(achievementManagerProvider);
  await manager.initialize();
  return manager.unlockedAchievements;
});

/// Provider for locked achievements
final lockedAchievementsProvider = FutureProvider<List<Achievement>>((
  ref,
) async {
  final manager = ref.watch(achievementManagerProvider);
  await manager.initialize();
  return manager.lockedAchievements;
});

/// Provider for recent achievements
final recentAchievementsProvider = FutureProvider<List<Achievement>>((
  ref,
) async {
  final manager = ref.watch(achievementManagerProvider);
  await manager.initialize();
  return manager.getRecentAchievements();
});

/// Provider for achievement statistics
final achievementStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final manager = ref.watch(achievementManagerProvider);
  await manager.initialize();
  return manager.getAchievementStats();
});

/// Provider for specific achievement progress
final achievementProgressProvider = Provider.family<AsyncValue<int>, String>((
  ref,
  achievementId,
) {
  final achievementsAsync = ref.watch(achievementsProvider);
  return achievementsAsync.when(
    data: (achievements) {
      final achievement = achievements.firstWhere(
        (a) => a.id == achievementId,
        orElse: () =>
            throw ArgumentError('Achievement not found: $achievementId'),
      );
      return AsyncValue.data(achievement.currentProgress);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Provider for checking if an achievement is unlocked
final isAchievementUnlockedProvider = Provider.family<AsyncValue<bool>, String>(
  (ref, achievementId) {
    final achievementsAsync = ref.watch(achievementsProvider);
    return achievementsAsync.when(
      data: (achievements) {
        final achievement = achievements.firstWhere(
          (a) => a.id == achievementId,
          orElse: () =>
              throw ArgumentError('Achievement not found: $achievementId'),
        );
        return AsyncValue.data(achievement.isUnlocked);
      },
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

/// Notifier for achievement operations
class AchievementNotifier extends StateNotifier<AsyncValue<void>> {
  AchievementNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  /// Update achievement progress
  Future<void> updateAchievementProgress(
    String achievementId,
    int progress,
  ) async {
    state = const AsyncValue.loading();
    try {
      final manager = ref.read(achievementManagerProvider);
      await manager.updateAchievementProgress(achievementId, progress);

      // Invalidate providers to refresh UI
      ref.invalidate(achievementsProvider);
      ref.invalidate(unlockedAchievementsProvider);
      ref.invalidate(lockedAchievementsProvider);
      ref.invalidate(recentAchievementsProvider);
      ref.invalidate(achievementStatsProvider);

      state = const AsyncValue.data(null);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  /// Set achievement progress directly
  Future<void> setAchievementProgress(
    String achievementId,
    int progress,
  ) async {
    state = const AsyncValue.loading();
    try {
      final manager = ref.read(achievementManagerProvider);
      await manager.setAchievementProgress(achievementId, progress);

      // Invalidate providers to refresh UI
      ref.invalidate(achievementsProvider);
      ref.invalidate(unlockedAchievementsProvider);
      ref.invalidate(lockedAchievementsProvider);
      ref.invalidate(recentAchievementsProvider);
      ref.invalidate(achievementStatsProvider);

      state = const AsyncValue.data(null);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  /// Check tower achievements
  Future<void> checkTowerAchievements({
    required String towerType,
    int towersPlaced = 0,
    int enemiesKilled = 0,
    int criticalHits = 0,
    int enemiesSlowed = 0,
    Set<String>? towerTypesUsed,
  }) async {
    try {
      final manager = ref.read(achievementManagerProvider);
      await manager.checkTowerAchievements(
        towerType: towerType,
        towersPlaced: towersPlaced,
        enemiesKilled: enemiesKilled,
        criticalHits: criticalHits,
        enemiesSlowed: enemiesSlowed,
        towerTypesUsed: towerTypesUsed,
      );

      // Refresh providers
      ref.invalidate(achievementsProvider);
      ref.invalidate(unlockedAchievementsProvider);
      ref.invalidate(recentAchievementsProvider);
      ref.invalidate(achievementStatsProvider);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  /// Check combat achievements
  Future<void> checkCombatAchievements({
    int enemiesKilled = 0,
    int bossesKilled = 0,
    int damageDealt = 0,
    int enemiesKilledInTimeframe = 0,
    Duration? timeframe,
  }) async {
    try {
      final manager = ref.read(achievementManagerProvider);
      await manager.checkCombatAchievements(
        enemiesKilled: enemiesKilled,
        bossesKilled: bossesKilled,
        damageDealt: damageDealt,
        enemiesKilledInTimeframe: enemiesKilledInTimeframe,
        timeframe: timeframe,
      );

      // Refresh providers
      ref.invalidate(achievementsProvider);
      ref.invalidate(unlockedAchievementsProvider);
      ref.invalidate(recentAchievementsProvider);
      ref.invalidate(achievementStatsProvider);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  /// Check strategic achievements
  Future<void> checkStrategicAchievements({
    bool perfectWave = false,
    int goldRemaining = 0,
    Duration? levelTime,
    double? accuracy,
  }) async {
    try {
      final manager = ref.read(achievementManagerProvider);
      await manager.checkStrategicAchievements(
        perfectWave: perfectWave,
        goldRemaining: goldRemaining,
        levelTime: levelTime,
        accuracy: accuracy,
      );

      // Refresh providers
      ref.invalidate(achievementsProvider);
      ref.invalidate(unlockedAchievementsProvider);
      ref.invalidate(recentAchievementsProvider);
      ref.invalidate(achievementStatsProvider);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  /// Check progression achievements
  Future<void> checkProgressionAchievements({
    int wavesCompleted = 0,
    int levelsCompleted = 0,
    int goldEarned = 0,
    bool isFirstVictory = false,
  }) async {
    try {
      final manager = ref.read(achievementManagerProvider);
      await manager.checkProgressionAchievements(
        wavesCompleted: wavesCompleted,
        levelsCompleted: levelsCompleted,
        goldEarned: goldEarned,
        isFirstVictory: isFirstVictory,
      );

      // Refresh providers
      ref.invalidate(achievementsProvider);
      ref.invalidate(unlockedAchievementsProvider);
      ref.invalidate(recentAchievementsProvider);
      ref.invalidate(achievementStatsProvider);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  /// Check time-based achievements
  Future<void> checkTimeAchievements() async {
    try {
      final manager = ref.read(achievementManagerProvider);
      await manager.checkTimeAchievements();

      // Refresh providers
      ref.invalidate(achievementsProvider);
      ref.invalidate(unlockedAchievementsProvider);
      ref.invalidate(recentAchievementsProvider);
      ref.invalidate(achievementStatsProvider);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  /// Reset all achievements
  Future<void> resetAchievements() async {
    state = const AsyncValue.loading();
    try {
      final manager = ref.read(achievementManagerProvider);
      await manager.resetAchievements();

      // Invalidate all providers
      ref.invalidate(achievementsProvider);
      ref.invalidate(unlockedAchievementsProvider);
      ref.invalidate(lockedAchievementsProvider);
      ref.invalidate(recentAchievementsProvider);
      ref.invalidate(achievementStatsProvider);

      state = const AsyncValue.data(null);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }
}

/// Provider for achievement operations
final achievementNotifierProvider =
    StateNotifierProvider<AchievementNotifier, AsyncValue<void>>((ref) {
      return AchievementNotifier(ref);
    });
