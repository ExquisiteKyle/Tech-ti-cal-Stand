import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:techtical_stand/features/game/domain/models/level.dart';

void main() {
  group('Level Tests', () {
    group('GameLevel Tests', () {
      test('GameLevel initializes with correct default values', () {
        final level = GameLevel(
          id: 'test_level',
          name: 'Test Level',
          description: 'A test level',
          theme: LevelTheme.forest,
          difficulty: LevelDifficulty.easy,
          levelNumber: 1,
          primaryColor: const Color(0xFF2E7D32),
          secondaryColor: const Color(0xFF4CAF50),
          pathColor: const Color(0xFF8BC34A),
        );

        expect(level.id, equals('test_level'));
        expect(level.name, equals('Test Level'));
        expect(level.description, equals('A test level'));
        expect(level.theme, equals(LevelTheme.forest));
        expect(level.difficulty, equals(LevelDifficulty.easy));
        expect(level.levelNumber, equals(1));
        expect(level.isUnlocked, isFalse);
        expect(level.status, equals(LevelStatus.locked));
        expect(level.startingGold, equals(300));
        expect(level.startingLives, equals(20));
        expect(level.totalWaves, equals(20));
      });

      test('GameLevel can be unlocked', () {
        final level = GameLevel(
          id: 'test_level',
          name: 'Test Level',
          description: 'A test level',
          theme: LevelTheme.forest,
          difficulty: LevelDifficulty.easy,
          levelNumber: 1,
          primaryColor: const Color(0xFF2E7D32),
          secondaryColor: const Color(0xFF4CAF50),
          pathColor: const Color(0xFF8BC34A),
        );

        final unlockedLevel = level.copyWith(
          isUnlocked: true,
          status: LevelStatus.unlocked,
        );

        expect(unlockedLevel.isUnlocked, isTrue);
        expect(unlockedLevel.status, equals(LevelStatus.unlocked));
        expect(unlockedLevel.canPlay, isTrue);
      });

      test('GameLevel can be completed', () {
        final level = GameLevel(
          id: 'test_level',
          name: 'Test Level',
          description: 'A test level',
          theme: LevelTheme.forest,
          difficulty: LevelDifficulty.easy,
          levelNumber: 1,
          primaryColor: const Color(0xFF2E7D32),
          secondaryColor: const Color(0xFF4CAF50),
          pathColor: const Color(0xFF8BC34A),
        );

        final completedLevel = level.copyWith(
          status: LevelStatus.completed,
          highScore: 10000,
          timesCompleted: 1,
        );

        expect(completedLevel.status, equals(LevelStatus.completed));
        expect(completedLevel.highScore, equals(10000));
        expect(completedLevel.timesCompleted, equals(1));
        expect(completedLevel.progressPercentage, equals(1.0));
      });

      test('GameLevel difficulty rating is correct', () {
        final easyLevel = GameLevel(
          id: 'easy',
          name: 'Easy Level',
          description: 'Easy level',
          theme: LevelTheme.forest,
          difficulty: LevelDifficulty.easy,
          levelNumber: 1,
          primaryColor: const Color(0xFF2E7D32),
          secondaryColor: const Color(0xFF4CAF50),
          pathColor: const Color(0xFF8BC34A),
        );

        final hardLevel = GameLevel(
          id: 'hard',
          name: 'Hard Level',
          description: 'Hard level',
          theme: LevelTheme.castle,
          difficulty: LevelDifficulty.hard,
          levelNumber: 3,
          primaryColor: const Color(0xFF424242),
          secondaryColor: const Color(0xFF757575),
          pathColor: const Color(0xFF9E9E9E),
        );

        expect(easyLevel.difficultyRating, equals(1));
        expect(hardLevel.difficultyRating, equals(3));
      });

      test('GameLevel theme display names are correct', () {
        final forestLevel = GameLevel(
          id: 'forest',
          name: 'Forest Level',
          description: 'Forest level',
          theme: LevelTheme.forest,
          difficulty: LevelDifficulty.easy,
          levelNumber: 1,
          primaryColor: const Color(0xFF2E7D32),
          secondaryColor: const Color(0xFF4CAF50),
          pathColor: const Color(0xFF8BC34A),
        );

        final castleLevel = GameLevel(
          id: 'castle',
          name: 'Castle Level',
          description: 'Castle level',
          theme: LevelTheme.castle,
          difficulty: LevelDifficulty.hard,
          levelNumber: 3,
          primaryColor: const Color(0xFF424242),
          secondaryColor: const Color(0xFF757575),
          pathColor: const Color(0xFF9E9E9E),
        );

        expect(forestLevel.themeDisplayName, equals('Forest Path'));
        expect(castleLevel.themeDisplayName, equals('Castle Courtyard'));
      });
    });

    group('GameLevels Tests', () {
      test('GameLevels provides default levels', () {
        final levels = GameLevels.getAllLevels();

        expect(levels, isNotEmpty);
        expect(levels.length, equals(6)); // 6 default levels

        // Check first level is unlocked
        expect(levels.first.isUnlocked, isTrue);
        expect(levels.first.status, equals(LevelStatus.unlocked));
      });

      test('GameLevels can find level by ID', () {
        final forestLevel = GameLevels.getLevelById('forest_path');
        final mountainLevel = GameLevels.getLevelById('mountain_pass');

        expect(forestLevel, isNotNull);
        expect(forestLevel!.name, equals('Forest Path'));
        expect(forestLevel.theme, equals(LevelTheme.forest));

        expect(mountainLevel, isNotNull);
        expect(mountainLevel!.name, equals('Mountain Pass'));
        expect(mountainLevel.theme, equals(LevelTheme.mountain));
      });

      test('GameLevels can find level by number', () {
        final level1 = GameLevels.getLevelByNumber(1);
        final level3 = GameLevels.getLevelByNumber(3);

        expect(level1, isNotNull);
        expect(level1!.name, equals('Forest Path'));
        expect(level1.levelNumber, equals(1));

        expect(level3, isNotNull);
        expect(level3!.name, equals('Castle Courtyard'));
        expect(level3.levelNumber, equals(3));
      });

      test('GameLevels can filter by difficulty', () {
        final easyLevels = GameLevels.getLevelsByDifficulty(
          LevelDifficulty.easy,
        );
        final expertLevels = GameLevels.getLevelsByDifficulty(
          LevelDifficulty.expert,
        );

        expect(easyLevels, isNotEmpty);
        expect(
          easyLevels.every((level) => level.difficulty == LevelDifficulty.easy),
          isTrue,
        );

        expect(expertLevels, isNotEmpty);
        expect(
          expertLevels.every(
            (level) => level.difficulty == LevelDifficulty.expert,
          ),
          isTrue,
        );
      });

      test('GameLevels can filter by theme', () {
        final forestLevels = GameLevels.getLevelsByTheme(LevelTheme.forest);
        final castleLevels = GameLevels.getLevelsByTheme(LevelTheme.castle);

        expect(forestLevels, isNotEmpty);
        expect(
          forestLevels.every((level) => level.theme == LevelTheme.forest),
          isTrue,
        );

        expect(castleLevels, isNotEmpty);
        expect(
          castleLevels.every((level) => level.theme == LevelTheme.castle),
          isTrue,
        );
      });
    });

    group('Level Progression Tests', () {
      test('Level requirements are enforced', () {
        final levels = GameLevels.getAllLevels();

        // First level should have no requirements
        expect(levels.first.requiredLevels, isEmpty);

        // Later levels should have requirements
        final mountainLevel = levels.firstWhere((l) => l.id == 'mountain_pass');
        expect(mountainLevel.requiredLevels, contains('forest_path'));

        final castleLevel = levels.firstWhere(
          (l) => l.id == 'castle_courtyard',
        );
        expect(castleLevel.requiredLevels, contains('mountain_pass'));
      });

      test('Level difficulty increases progressively', () {
        final levels = GameLevels.getAllLevels();

        for (int i = 1; i < levels.length; i++) {
          final currentLevel = levels[i - 1];
          final nextLevel = levels[i];

          // Each level should be at least as difficult as the previous
          expect(
            nextLevel.difficultyRating,
            greaterThanOrEqualTo(currentLevel.difficultyRating),
          );
        }
      });

      test('Level resources scale appropriately', () {
        final levels = GameLevels.getAllLevels();

        // Later levels should have more challenging resource requirements
        final earlyLevel = levels.first;
        final lateLevel = levels.last;

        expect(
          lateLevel.startingGold,
          lessThanOrEqualTo(earlyLevel.startingGold),
        );
        expect(
          lateLevel.startingLives,
          lessThanOrEqualTo(earlyLevel.startingLives),
        );
        expect(
          lateLevel.totalWaves,
          greaterThanOrEqualTo(earlyLevel.totalWaves),
        );
      });
    });
  });
}
