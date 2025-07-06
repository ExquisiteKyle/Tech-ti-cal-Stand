import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:techtical_stand/features/game/domain/models/game_state.dart';
import 'package:techtical_stand/features/game/presentation/providers/game_state_provider.dart';

void main() {
  group('GameState Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('GameState initializes with correct default values', () {
      final gameState = GameState();

      expect(gameState.gold, equals(300));
      expect(gameState.lives, equals(20));
      expect(gameState.score, equals(0));
      expect(gameState.wave, equals(1));
      expect(gameState.isGameOver, isFalse);
      expect(gameState.isPaused, isFalse);
      expect(gameState.status, equals(GameStatus.menu));
    });

    test('GameState can be updated with new values', () {
      final gameState = GameState();
      final updatedState = gameState.copyWith(
        gold: 500,
        lives: 15,
        score: 1000,
        wave: 5,
      );

      expect(updatedState.gold, equals(500));
      expect(updatedState.lives, equals(15));
      expect(updatedState.score, equals(1000));
      expect(updatedState.wave, equals(5));
    });

    test('GameState provider initializes correctly', () {
      final gameState = container.read(gameStateProvider);

      expect(gameState.gold, equals(300));
      expect(gameState.lives, equals(20));
      expect(gameState.score, equals(0));
    });

    test('GameState provider can update state', () {
      final notifier = container.read(gameStateProvider.notifier);

      notifier.addGold(500);
      notifier.loseLives(5);
      notifier.addScore(1000);

      final updatedState = container.read(gameStateProvider);

      expect(updatedState.gold, equals(800)); // 300 + 500
      expect(updatedState.lives, equals(15)); // 20 - 5
      expect(updatedState.score, equals(1000));
    });

    test('GameState handles game over correctly', () {
      final notifier = container.read(gameStateProvider.notifier);

      notifier.gameOver();

      final gameState = container.read(gameStateProvider);
      expect(gameState.isGameOver, isTrue);
    });

    test('GameState handles pause correctly', () {
      final notifier = container.read(gameStateProvider.notifier);

      notifier.pauseGame();

      final gameState = container.read(gameStateProvider);
      expect(gameState.isPaused, isTrue);
    });

    test('GameState can be reset', () {
      final notifier = container.read(gameStateProvider.notifier);

      // Modify state
      notifier.addGold(500);
      notifier.loseLives(5);
      notifier.addScore(1000);

      // Reset
      notifier.resetGame();

      final resetState = container.read(gameStateProvider);
      expect(resetState.gold, equals(300));
      expect(resetState.lives, equals(20));
      expect(resetState.score, equals(0));
      expect(resetState.wave, equals(1));
      expect(resetState.isGameOver, isFalse);
      expect(resetState.isPaused, isFalse);
    });
  });
}
