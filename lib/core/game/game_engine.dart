import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_loop.dart';
import 'entity_manager.dart';
import '../rendering/game_painter.dart';
import '../widgets/mmorpg_player_ui.dart';
import '../../features/game/presentation/providers/game_state_provider.dart';
import '../../features/game/domain/models/game_state.dart';

/// Main game engine that coordinates all game systems
class GameEngine extends ConsumerStatefulWidget {
  const GameEngine({super.key});

  @override
  ConsumerState<GameEngine> createState() => _GameEngineState();
}

class _GameEngineState extends ConsumerState<GameEngine> {
  late GameLoop _gameLoop;
  late EntityManager _entityManager;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeEngine();
  }

  void _initializeEngine() {
    _entityManager = EntityManager();
    _gameLoop = GameLoop();

    // Set up game loop callbacks
    _gameLoop.onUpdate = _updateGame;
    _gameLoop.onRender = _renderGame;

    _isInitialized = true;

    // Start the game loop
    _gameLoop.start();
  }

  void _updateGame() {
    if (!mounted) return;

    final gameState = ref.read(gameStateProvider);

    // Don't update if game is paused or not playing
    if (gameState.isPaused || !gameState.isPlaying) return;

    // Update all entities
    _entityManager.update(1.0 / 60.0); // 60 FPS target

    // Check collisions
    _entityManager.checkCollisions();

    // Update UI
    if (mounted) {
      setState(() {});
    }
  }

  void _renderGame() {
    // Rendering is handled by the CustomPainter
    // This callback is for any additional render logic
  }

  void _handleTap() {
    final gameStateNotifier = ref.read(gameStateProvider.notifier);
    final gameState = ref.read(gameStateProvider);

    if (gameState.status == GameStatus.menu) {
      gameStateNotifier.startGame();
    } else if (gameState.isPlaying) {
      gameStateNotifier.togglePause();
    }
  }

  @override
  void dispose() {
    _gameLoop.dispose();
    _entityManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final gameState = ref.watch(gameStateProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Game Canvas
          GameCanvas(
            entityManager: _entityManager,
            gameSpeed: gameState.gameSpeed,
            isPaused: gameState.isPaused,
            onTap: _handleTap,
          ),

          // Game UI Overlay
          _buildGameUI(gameState),
        ],
      ),
    );
  }

  Widget _buildGameUI(GameState gameState) {
    return SafeArea(
      child: Stack(
        children: [
          // Top HUD - positioned in top-left corner
          _buildTopHUD(gameState),

          // Bottom controls - centered at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: gameState.status == GameStatus.menu
                ? Center(child: _buildMenuControls())
                : gameState.isPlaying || gameState.isPaused
                ? _buildGameControls(gameState)
                : Container(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHUD(GameState gameState) {
    if (gameState.status == GameStatus.menu) {
      return Container();
    }

    return Positioned(
      top: 16,
      left: 16,
      child: MMORPGPlayerUI(
        playerName: "Base Defense",
        playerLevel: gameState.wave,
        currentHealth: gameState.lives,
        maxHealth: 20,
        currentMana: gameState.score ~/ 10, // Convert score to mana-like value
        maxMana: 100,
        gold: gameState.gold,
        score: gameState.score,
      ),
    );
  }

  Widget _buildMenuControls() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E6FF).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4C5E8), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Techtical Stand',
            style: TextStyle(
              color: Color(0xFF4A4A4A),
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tap to Start',
            style: TextStyle(
              color: Color(0xFF8B8B8B),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameControls(GameState gameState) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pause/Resume button
          ElevatedButton.icon(
            onPressed: () {
              ref.read(gameStateProvider.notifier).togglePause();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: gameState.isPaused
                  ? const Color(0xFFB3FFB3) // buttonSuccess
                  : const Color(0xFFFFE6B3), // buttonWarning
              foregroundColor: const Color(0xFF4A4A4A),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(gameState.isPaused ? Icons.play_arrow : Icons.pause),
            label: Text(gameState.isPaused ? 'Resume' : 'Pause'),
          ),

          const SizedBox(width: 16),

          // Speed control
          ElevatedButton.icon(
            onPressed: () {
              final currentSpeed = gameState.gameSpeed;
              final newSpeed = currentSpeed >= 3.0 ? 1.0 : currentSpeed + 0.5;
              ref.read(gameStateProvider.notifier).setGameSpeed(newSpeed);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB3E6FF), // buttonSecondary
              foregroundColor: const Color(0xFF4A4A4A),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.speed),
            label: Text('${gameState.gameSpeed}x'),
          ),
        ],
      ),
    );
  }
}
