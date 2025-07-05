import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_loop.dart';
import 'entity_manager.dart';
import '../rendering/game_canvas.dart';
import '../widgets/mmorpg_player_ui.dart';
import '../../features/game/presentation/providers/game_state_provider.dart';
import '../../features/game/presentation/providers/tower_selection_provider.dart';
import '../../features/game/domain/models/game_state.dart';
import '../../features/game/domain/models/tower.dart';
import '../../features/game/domain/models/enemy.dart';
import '../../features/game/domain/models/path.dart';
import '../../features/game/domain/models/wave.dart';
import '../../shared/models/vector2.dart';
import '../../shared/models/entity.dart';

/// Main game engine that coordinates all game systems
class GameEngine extends ConsumerStatefulWidget {
  const GameEngine({super.key});

  @override
  ConsumerState<GameEngine> createState() => _GameEngineState();
}

class _GameEngineState extends ConsumerState<GameEngine> {
  late GameLoop _gameLoop;
  late EntityManager _entityManager;
  late WaveManager _waveManager;
  late GamePath _currentPath;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeEngine();
  }

  void _initializeEngine() {
    _entityManager = EntityManager();
    _gameLoop = GameLoop();
    _waveManager = WaveManager();

    // Initialize game path
    _currentPath = GamePath(
      id: 'level_1_path',
      name: 'Level 1 Path',
      waypoints: [
        Waypoint(position: Vector2(50, 300), id: 'start'),
        Waypoint(position: Vector2(200, 250), id: 'mid1'),
        Waypoint(position: Vector2(350, 350), id: 'mid2'),
        Waypoint(position: Vector2(500, 200), id: 'mid3'),
        Waypoint(position: Vector2(650, 300), id: 'end'),
      ],
    );

    // Generate waves for level 1
    LevelWaves.generateWavesForLevel(_waveManager, 1);

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
    final gameStateNotifier = ref.read(gameStateProvider.notifier);

    // Don't update if game is paused or not playing
    if (gameState.isPaused || !gameState.isPlaying) return;

    final deltaTime = 1.0 / 60.0; // 60 FPS target

    // Update wave and spawn enemies
    final newEnemies = _waveManager.updateWave(deltaTime, _currentPath);
    if (newEnemies.isNotEmpty) {
      print(
        'Wave ${_waveManager.currentWaveNumber}: Spawning ${newEnemies.length} enemies',
      );
    }
    for (final enemy in newEnemies) {
      _entityManager.addEntity(enemy);
    }

    // Update tower targeting and attacks
    final towers = _entityManager.getEntitiesOfType<Tower>();
    final enemies = _entityManager.getEntitiesOfType<Enemy>();

    if (towers.isNotEmpty && enemies.isNotEmpty) {
      print('Game Engine: ${towers.length} towers, ${enemies.length} enemies');
    }

    for (final tower in towers) {
      // Ensure tower has projectile callback set (safety check)
      if (tower.onProjectileCreated == null) {
        print('Setting missing projectile callback for ${tower.name}');
        tower.onProjectileCreated = (projectile) {
          _entityManager.addEntity(projectile);
        };
      }

      final target = tower.findTarget(enemies.cast<Entity>());
      if (target != null) {
        print(
          'Tower ${tower.name} found target at distance ${tower.distanceTo(target)}',
        );
        tower.attack(target, DateTime.now().millisecondsSinceEpoch / 1000.0);
      }
    }

    // Update all entities
    _entityManager.update(deltaTime);

    // Check collisions
    _entityManager.checkCollisions();

    // Check for enemies that reached the end
    final reachedEnemies = enemies.where((e) => e.hasReachedEnd).toList();
    for (final enemy in reachedEnemies) {
      gameStateNotifier.loseLives(1);
      _entityManager.removeEntityDirect(enemy);
    }

    // Check for dead enemies and award gold
    final deadEnemies = enemies
        .where((e) => !e.isAlive && !e.hasReachedEnd)
        .toList();

    if (deadEnemies.isNotEmpty) {
      print('Found ${deadEnemies.length} dead enemies to reward');
    }

    for (final enemy in deadEnemies) {
      print('Awarding ${enemy.goldReward} gold for killing ${enemy.name}');
      gameStateNotifier.addGold(enemy.goldReward);
      gameStateNotifier.addScore(enemy.goldReward * 10);

      // Ensure dead enemy is removed from entity manager
      if (enemy.isActive) {
        print('Dead enemy ${enemy.name} is still active, removing manually');
        _entityManager.removeEntityDirect(enemy);
      }
    }

    // Check wave completion
    if (_waveManager.isWaveComplete && enemies.isEmpty) {
      // Award wave bonus
      final waveStats = _waveManager.getWaveStats();
      if (waveStats['goldBonus'] != null) {
        gameStateNotifier.addGold(waveStats['goldBonus'] as int);
      }

      // Progress to next wave
      _waveManager.nextWave();
      gameStateNotifier.nextWave();

      // Check if all waves completed
      if (_waveManager.isAllWavesComplete) {
        gameStateNotifier.victory();
      }
    }

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
      // Start the first wave automatically
      print(
        'Starting game! Current wave manager wave: ${_waveManager.currentWaveNumber}',
      );
      print('Game state wave: ${gameState.wave}');

      // Give initial prep gold for first wave
      final prepGold = 25 + (_waveManager.currentWaveNumber * 5);
      gameStateNotifier.addGold(prepGold);
      print('Giving ${prepGold} prep gold for first wave');

      _waveManager.startWave();
    }
    // Removed pause toggle from screen tap - pause only works through button
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
            waveManager: _waveManager,
            currentPath: _currentPath,
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
                : gameState.status == GameStatus.gameOver
                ? Center(child: _buildGameOverControls(gameState))
                : gameState.status == GameStatus.victory
                ? Center(child: _buildVictoryControls(gameState))
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
        enemiesInField: _entityManager.getEntitiesOfType<Enemy>().length,
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

  Widget _buildGameOverControls(GameState gameState) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE6E6).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF9999), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Game Over',
            style: TextStyle(
              color: Color(0xFF8B0000),
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Final Score: ${gameState.score}',
            style: const TextStyle(
              color: Color(0xFF4A4A4A),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Wave Reached: ${gameState.wave}',
            style: const TextStyle(
              color: Color(0xFF4A4A4A),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _restartGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB3B3),
              foregroundColor: const Color(0xFF8B0000),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Restart Game',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVictoryControls(GameState gameState) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFE6FFE6).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF99FF99), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Victory!',
            style: TextStyle(
              color: Color(0xFF006400),
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Final Score: ${gameState.score}',
            style: const TextStyle(
              color: Color(0xFF4A4A4A),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All ${gameState.wave} waves completed!',
            style: const TextStyle(
              color: Color(0xFF4A4A4A),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _restartGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB3FFB3),
              foregroundColor: const Color(0xFF006400),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Play Again',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _restartGame() {
    final gameStateNotifier = ref.read(gameStateProvider.notifier);
    final towerSelectionNotifier = ref.read(towerSelectionProvider.notifier);

    // Reset game state
    gameStateNotifier.resetGame();

    // Clear tower selection
    towerSelectionNotifier.clearSelection();

    // Clear all entities
    _entityManager.clear();

    // Reset wave manager
    _waveManager.reset();

    // Regenerate waves for level 1
    LevelWaves.generateWavesForLevel(_waveManager, 1);

    // Reset UI state
    setState(() {
      // Any local state resets
    });
  }

  Widget _buildGameControls(GameState gameState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tower Shop
        _buildTowerShop(gameState),
        const SizedBox(height: 16),

        // Game Controls
        _buildGameActionControls(gameState),
      ],
    );
  }

  Widget _buildTowerShop(GameState gameState) {
    final towerSelection = ref.watch(towerSelectionProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E6FF).withAlpha(240),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4C5E8), width: 2),
      ),
      child: Column(
        children: [
          const Text(
            'Tower Shop',
            style: TextStyle(
              color: Color(0xFF4A4A4A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (towerSelection.isSelecting)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Drag & Drop or Tap to Place',
                style: TextStyle(
                  color: Color(0xFF8B8B8B),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTowerButton(
                TowerType.archer,
                'Archer',
                '50G',
                const Color(0xFFD2B48C),
                gameState.canAfford(50),
              ),
              _buildTowerButton(
                TowerType.cannon,
                'Cannon',
                '100G',
                const Color(0xFFC0C0C0),
                gameState.canAfford(100),
              ),
              _buildTowerButton(
                TowerType.magic,
                'Magic',
                '150G',
                const Color(0xFFDDA0DD),
                gameState.canAfford(150),
              ),
              _buildTowerButton(
                TowerType.sniper,
                'Sniper',
                '200G',
                const Color(0xFF98FB98),
                gameState.canAfford(200),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTowerButton(
    TowerType towerType,
    String name,
    String cost,
    Color color,
    bool canAfford,
  ) {
    return Draggable<TowerType>(
      data: towerType,
      feedback: _buildDragFeedback(towerType, name, color, canAfford),
      childWhenDragging: _buildTowerButtonContent(
        name,
        cost,
        color.withAlpha(100),
        false, // Make it appear dimmed when dragging
      ),
      onDragStarted: () {
        if (canAfford) {
          final towerSelectionNotifier = ref.read(
            towerSelectionProvider.notifier,
          );
          towerSelectionNotifier.selectTower(towerType);
        }
      },
      onDragEnd: (details) {
        final towerSelectionNotifier = ref.read(
          towerSelectionProvider.notifier,
        );
        towerSelectionNotifier.clearSelection();
      },
      child: GestureDetector(
        onTap: canAfford ? () => _selectTower(towerType) : null,
        child: _buildTowerButtonContent(name, cost, color, canAfford),
      ),
    );
  }

  Widget _buildTowerButtonContent(
    String name,
    String cost,
    Color color,
    bool canAfford,
  ) {
    return Container(
      width: 70,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: canAfford ? color.withAlpha(200) : Colors.grey.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: canAfford ? color : Colors.grey, width: 2),
      ),
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: canAfford ? color : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              color: canAfford ? const Color(0xFF4A4A4A) : Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            cost,
            style: TextStyle(
              color: canAfford ? const Color(0xFF4A4A4A) : Colors.grey,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDragFeedback(
    TowerType towerType,
    String name,
    Color color,
    bool canAfford,
  ) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: canAfford ? color.withAlpha(220) : Colors.grey.withAlpha(150),
          shape: BoxShape.circle,
          border: Border.all(color: canAfford ? color : Colors.grey, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: canAfford ? color : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: TextStyle(
                  color: canAfford ? const Color(0xFF4A4A4A) : Colors.grey,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectTower(TowerType towerType) {
    final gameStateNotifier = ref.read(gameStateProvider.notifier);
    final gameState = ref.read(gameStateProvider);
    final towerSelectionNotifier = ref.read(towerSelectionProvider.notifier);

    // Get tower cost
    int cost = _getTowerCost(towerType);

    // Check if player can afford the tower
    if (gameState.canAfford(cost)) {
      towerSelectionNotifier.selectTower(towerType);
    }
  }

  int _getTowerCost(TowerType towerType) {
    switch (towerType) {
      case TowerType.archer:
        return 50;
      case TowerType.cannon:
        return 100;
      case TowerType.magic:
        return 150;
      case TowerType.sniper:
        return 200;
    }
  }

  Widget _buildGameActionControls(GameState gameState) {
    final waveStats = _waveManager.getWaveStats();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E6FF).withAlpha(200),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4C5E8), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Wave info
          Column(
            children: [
              Text(
                'Wave ${_waveManager.currentWaveNumber}/${_waveManager.totalWaves}',
                style: const TextStyle(
                  color: Color(0xFF4A4A4A),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (waveStats.isNotEmpty && waveStats['progress'] != null)
                Text(
                  '${(waveStats['progress'] * 100).toInt()}%',
                  style: const TextStyle(
                    color: Color(0xFF8B8B8B),
                    fontSize: 12,
                  ),
                ),
            ],
          ),

          // Start wave button
          if (!_waveManager.isWaveActive && !_waveManager.isAllWavesComplete)
            ElevatedButton(
              onPressed: () {
                // Give player prep gold before starting wave
                final gameStateNotifier = ref.read(gameStateProvider.notifier);
                final prepGold = 25 + (_waveManager.currentWaveNumber * 5);
                gameStateNotifier.addGold(prepGold);
                print(
                  'Giving ${prepGold} prep gold for wave ${_waveManager.currentWaveNumber}',
                );

                _waveManager.startWave();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB3FFB3),
                foregroundColor: const Color(0xFF4A4A4A),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
              ),
              child: const Text('Start Wave'),
            ),

          // Pause/Resume button
          ElevatedButton(
            onPressed: () {
              final gameStateNotifier = ref.read(gameStateProvider.notifier);
              gameStateNotifier.togglePause();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: gameState.isPaused
                  ? const Color(0xFFB3FFB3)
                  : const Color(0xFFFFE6B3),
              foregroundColor: const Color(0xFF4A4A4A),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: Text(gameState.isPaused ? 'Resume' : 'Pause'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegacyGameControls(GameState gameState) {
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
