import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:techtical_stand/features/game/presentation/screens/level_selection_screen.dart';
import 'package:techtical_stand/features/game/presentation/screens/achievements_screen.dart';
import 'package:techtical_stand/features/game/presentation/providers/level_provider.dart';
import 'package:techtical_stand/features/game/presentation/providers/achievement_provider.dart';
import 'package:techtical_stand/features/game/domain/models/level.dart';
import 'package:techtical_stand/features/game/domain/models/achievement.dart';
import 'package:techtical_stand/features/game/domain/models/achievement_manager.dart';

void main() {
  group('Provider Override Examples', () {
    // Example 1: Override regular providers with synchronous data
    testWidgets('Level Selection with overridden provider', (
      WidgetTester tester,
    ) async {
      // Create mock level data
      final mockLevels = [
        GameLevel(
          id: 'level_1',
          name: 'Test Level 1',
          description: 'A test level',
          theme: LevelTheme.forest,
          difficulty: LevelDifficulty.easy,
          levelNumber: 1,
          primaryColor: const Color(0xFF2E7D32),
          secondaryColor: const Color(0xFF4CAF50),
          pathColor: const Color(0xFF8BC34A),
        ),
      ];

      // Override the levelsProvider to return mock data immediately
      final overrides = [
        levelsProvider.overrideWithValue(mockLevels),
        // Also override the initialization provider to avoid async loading
        initializeLevelManagerProvider.overrideWith((ref) async {
          // Return immediately without doing any async work
          return;
        }),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: const MaterialApp(home: LevelSelectionScreen()),
        ),
      );

      // Now the screen should load immediately without waiting for async operations
      await tester.pump();

      // Verify the mock level is displayed
      expect(find.text('Test Level 1'), findsOneWidget);
    });

    // Example 2: Override FutureProvider with synchronous data
    testWidgets('Achievements with overridden provider', (
      WidgetTester tester,
    ) async {
      // Create mock achievement data
      final mockAchievements = [
        Achievement(
          id: 'test_achievement',
          name: 'Test Achievement',
          description: 'A test achievement',
          type: AchievementType.progression,
          category: AchievementCategory.levels,
          icon: Icons.emoji_events,
          color: Colors.blue,
          isUnlocked: true,
          currentProgress: 100,
          maxProgress: 100,
        ),
      ];

      // Override the achievements provider
      final overrides = [
        achievementsProvider.overrideWith((ref) async {
          // Return mock data immediately
          return mockAchievements;
        }),
        // Override the achievement manager to avoid initialization
        achievementManagerProvider.overrideWithValue(
          AchievementManager.instance, // Use the singleton but avoid async init
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: const MaterialApp(home: AchievementsScreen()),
        ),
      );

      await tester.pump();

      // Verify the mock achievement is displayed
      expect(find.text('Test Achievement'), findsOneWidget);
    });

    // Example 3: Override multiple providers for complex scenarios
    testWidgets('Complex screen with multiple overrides', (
      WidgetTester tester,
    ) async {
      // Create multiple mock providers
      final mockLevels = [
        GameLevel(
          id: 'level_1',
          name: 'Mock Level',
          description: 'Mock level for testing',
          theme: LevelTheme.forest,
          difficulty: LevelDifficulty.easy,
          levelNumber: 1,
          primaryColor: const Color(0xFF2E7D32),
          secondaryColor: const Color(0xFF4CAF50),
          pathColor: const Color(0xFF8BC34A),
        ),
      ];

      final mockAchievements = [
        Achievement(
          id: 'mock_achievement',
          name: 'Mock Achievement',
          description: 'Mock achievement for testing',
          type: AchievementType.progression,
          category: AchievementCategory.levels,
          icon: Icons.emoji_events,
          color: Colors.blue,
          isUnlocked: true,
          currentProgress: 100,
          maxProgress: 100,
        ),
      ];

      // Override multiple providers at once
      final overrides = [
        levelsProvider.overrideWithValue(mockLevels),
        achievementsProvider.overrideWith((ref) async => mockAchievements),
        initializeLevelManagerProvider.overrideWith((ref) async => null),
        achievementManagerProvider.overrideWithValue(
          AchievementManager.instance,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: const MaterialApp(home: LevelSelectionScreen()),
        ),
      );

      await tester.pump();

      // Now all async dependencies are resolved immediately
      expect(find.text('Mock Level'), findsOneWidget);
    });

    // Example 4: Override with computed values
    testWidgets('Override with computed provider', (WidgetTester tester) async {
      // Override with a provider that computes values
      final overrides = [
        levelsProvider.overrideWith((ref) {
          // Return computed levels based on some condition
          return [
            GameLevel(
              id: 'computed_level',
              name: 'Computed Level',
              description: 'A computed level',
              theme: LevelTheme.forest,
              difficulty: LevelDifficulty.easy,
              levelNumber: 1,
              primaryColor: const Color(0xFF2E7D32),
              secondaryColor: const Color(0xFF4CAF50),
              pathColor: const Color(0xFF8BC34A),
            ),
          ];
        }),
        initializeLevelManagerProvider.overrideWith((ref) async => null),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: const MaterialApp(home: LevelSelectionScreen()),
        ),
      );

      await tester.pump();

      expect(find.text('Computed Level'), findsOneWidget);
    });
  });
}
