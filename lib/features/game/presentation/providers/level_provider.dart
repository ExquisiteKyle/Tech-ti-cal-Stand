import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/level.dart';
import '../../domain/models/level_manager.dart';

/// Provider for the level manager singleton
final levelManagerProvider = Provider<LevelManager>((ref) {
  return LevelManager.instance;
});

/// Provider for the current selected level
final currentLevelProvider = Provider<GameLevel?>((ref) {
  final levelManager = ref.watch(levelManagerProvider);
  return levelManager.currentLevel;
});

/// Provider for all available levels
final levelsProvider = Provider<List<GameLevel>>((ref) {
  final levelManager = ref.watch(levelManagerProvider);
  return levelManager.levels;
});

/// Provider for unlocked levels only
final unlockedLevelsProvider = Provider<List<GameLevel>>((ref) {
  final levelManager = ref.watch(levelManagerProvider);
  return levelManager.getUnlockedLevels();
});

/// Provider for completed levels only
final completedLevelsProvider = Provider<List<GameLevel>>((ref) {
  final levelManager = ref.watch(levelManagerProvider);
  return levelManager.getCompletedLevels();
});

/// Provider for overall progress percentage
final overallProgressProvider = Provider<double>((ref) {
  final levelManager = ref.watch(levelManagerProvider);
  return levelManager.getOverallProgress();
});

/// Provider for total score across all levels
final totalScoreProvider = Provider<int>((ref) {
  final levelManager = ref.watch(levelManagerProvider);
  return levelManager.getTotalScore();
});

/// Provider for total play time across all levels
final totalPlayTimeProvider = Provider<Duration>((ref) {
  final levelManager = ref.watch(levelManagerProvider);
  return levelManager.getTotalPlayTime();
});

/// Provider for current level's starting resources
final currentLevelResourcesProvider = Provider<({int gold, int lives})>((ref) {
  final levelManager = ref.watch(levelManagerProvider);
  return levelManager.getCurrentLevelResources();
});

/// Provider for current level's enemy multipliers
final currentLevelMultipliersProvider =
    Provider<({double speed, double health})>((ref) {
      final levelManager = ref.watch(levelManagerProvider);
      return levelManager.getCurrentLevelMultipliers();
    });

/// Provider for level statistics
final levelStatisticsProvider = Provider.family<Map<String, dynamic>, String>((
  ref,
  levelId,
) {
  final levelManager = ref.watch(levelManagerProvider);
  return levelManager.getLevelStatistics(levelId);
});

/// Provider for all game statistics
final allStatisticsProvider = Provider<Map<String, dynamic>>((ref) {
  final levelManager = ref.watch(levelManagerProvider);
  return levelManager.getAllStatistics();
});

/// Provider to check if level manager is initialized
final levelManagerInitializedProvider = Provider<bool>((ref) {
  final levelManager = ref.watch(levelManagerProvider);
  return levelManager.isInitialized;
});

/// Async provider to initialize level manager
final initializeLevelManagerProvider = FutureProvider<void>((ref) async {
  final levelManager = ref.watch(levelManagerProvider);
  if (!levelManager.isInitialized) {
    await levelManager.initialize();
  }
});

/// State notifier for level selection and management
class LevelNotifier extends StateNotifier<GameLevel?> {
  final LevelManager _levelManager;

  LevelNotifier(this._levelManager) : super(null);

  /// Select a level to play
  Future<bool> selectLevel(String levelId) async {
    final success = await _levelManager.selectLevel(levelId);
    if (success) {
      state = _levelManager.currentLevel;
    }
    return success;
  }

  /// Complete current level
  Future<void> completeLevel({
    required int score,
    required Duration completionTime,
    required bool isPerfect,
  }) async {
    if (state != null) {
      await _levelManager.completeLevel(
        state!.id,
        score: score,
        completionTime: completionTime,
        isPerfect: isPerfect,
      );
      // Update state to reflect changes
      state = _levelManager.currentLevel;
    }
  }

  /// Reset level selection
  void clearSelection() {
    state = null;
  }
}

/// Provider for level selection state notifier
final levelNotifierProvider = StateNotifierProvider<LevelNotifier, GameLevel?>((
  ref,
) {
  final levelManager = ref.watch(levelManagerProvider);
  return LevelNotifier(levelManager);
});
