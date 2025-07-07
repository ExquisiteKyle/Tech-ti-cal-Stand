import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_loop.dart';
import 'entity_manager.dart';
import '../rendering/game_canvas.dart';
import '../theme/app_colors.dart';
import '../widgets/mmorpg_player_ui.dart';
import '../widgets/game_over_dialog.dart';
import '../widgets/tower_upgrade_dialog.dart';
import '../widgets/audio_settings_panel.dart';
import '../widgets/performance_monitor.dart';
import '../audio/audio_manager.dart';
import '../../features/game/presentation/providers/game_state_provider.dart';
import '../../features/game/presentation/providers/tower_selection_provider.dart';

import '../../features/game/domain/models/game_state.dart';
import '../../features/game/domain/models/tower.dart';
import '../../features/game/domain/models/enemy.dart';
import '../../features/game/domain/models/path.dart';
import '../../features/game/domain/models/wave.dart';
import '../../features/game/domain/models/tile_system.dart';
import '../../features/game/domain/models/level.dart';
import '../../features/game/domain/models/level_manager.dart';
import '../../features/game/domain/models/projectile.dart';
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
  late TileSystem _tileSystem;
  Size? _lastScreenSize; // Track screen size changes
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
    _tileSystem = TileSystem(gridWidth: 20, gridHeight: 15); // Initial size

    // Initialize with level-aware path creation
    _currentPath = _createLevelPath();

    // Generate waves based on current level
    _generateLevelWaves();

    // Set up game loop callbacks
    _gameLoop.onUpdate = _updateGame;
    _gameLoop.onRender = _renderGame;

    _isInitialized = true;

    // Start background music
    AudioManager().playMusic(AudioEvent.gameplayMusic);

    // Start the game loop
    _gameLoop.start();
  }

  /// Create path based on current level selection
  GamePath _createLevelPath() {
    final levelManager = LevelManager.instance;
    final screenSize = _lastScreenSize ?? const Size(800, 600);

    // If level manager has a current level, use its path
    if (levelManager.isInitialized && levelManager.currentLevel != null) {
      final levelPath = levelManager.initializeLevelPath(
        screenSize.width,
        screenSize.height,
      );
      if (levelPath != null) {
        return levelPath;
      }
    }

    // Fallback to default path creation
    return _createPath();
  }

  /// Generate waves based on current level
  void _generateLevelWaves() {
    final levelManager = LevelManager.instance;

    // If level manager has a current level, use its wave generation
    if (levelManager.isInitialized && levelManager.currentLevel != null) {
      levelManager.generateLevelWaves(_waveManager);
    } else {
      // Fallback to level 1 waves
      LevelWaves.generateWavesForLevel(_waveManager, 1);
    }
  }

  /// Apply level-specific multipliers to enemy
  void _applyLevelMultipliers(Enemy enemy) {
    final levelManager = LevelManager.instance;

    if (levelManager.isInitialized && levelManager.currentLevel != null) {
      final multipliers = levelManager.getCurrentLevelMultipliers();

      // Apply health multiplier
      if (multipliers.health != 1.0) {
        enemy.currentHealth = (enemy.maxHealth * multipliers.health);
      }

      // Apply speed multiplier
      if (multipliers.speed != 1.0) {
        enemy.currentSpeed = (enemy.baseSpeed * multipliers.speed);
      }
    }
  }

  // Helper methods for tower option styling to avoid dead code warnings
  double _getHoverScale(bool isHovered, bool canAfford) {
    if (isHovered && canAfford) return 1.05;
    return 1.0;
  }

  Color _getBackgroundColor(Color color, bool canAfford, bool isHovered) {
    if (!canAfford) return color.withValues(alpha: 0.4);
    if (isHovered) return color.withValues(alpha: 0.9);
    return color.withValues(alpha: 0.8);
  }

  Color _getBorderColor(bool canAfford, bool isHovered) {
    if (!canAfford) return AppColors.textSecondary;
    if (isHovered) return AppColors.textAccent;
    return AppColors.hudBorder;
  }

  double _getBorderWidth(bool isHovered, bool canAfford) {
    if (isHovered && canAfford) return 2;
    return 1;
  }

  List<BoxShadow>? _getBoxShadow(bool canAfford, bool isHovered, Color color) {
    if (canAfford && isHovered) {
      return [
        BoxShadow(
          color: color.withValues(alpha: 0.5),
          blurRadius: 8,
          spreadRadius: 2,
        ),
      ];
    }
    return null;
  }

  double _getIconScale(bool isHovered, bool canAfford) {
    if (isHovered && canAfford) return 1.1;
    return 1.0;
  }

  Color _getIconColor(bool canAfford, bool isHovered) {
    if (!canAfford) return AppColors.textSecondary;
    if (isHovered) return AppColors.textAccent;
    return AppColors.textOnPastel;
  }

  Color _getTextColor(bool canAfford, bool isHovered) {
    if (!canAfford) return AppColors.textSecondary;
    if (isHovered) return AppColors.textAccent;
    return AppColors.textOnPastel;
  }

  Color _getDescriptionColor(bool canAfford, bool isHovered) {
    if (!canAfford) return AppColors.textSecondary;
    if (isHovered) return AppColors.textOnPastel;
    return AppColors.textSecondary;
  }

  Color _getCostColor(bool canAfford, bool isHovered) {
    if (!canAfford) return AppColors.textSecondary;
    if (isHovered) return AppColors.textAccent;
    return AppColors.textOnPastel;
  }

  /// Create path using actual screen dimensions with horizontal/vertical segments only
  GamePath _createPath() {
    // Get current screen size, fallback to default if not available
    final screenSize = _lastScreenSize ?? const Size(800, 600);

    // Calculate safe boundaries (accounting for UI elements)
    final topHudHeight = screenSize.height < 600
        ? 60.0
        : (screenSize.height < 800 ? 85.0 : 120.0);
    final bottomUIHeight = screenSize.height < 600
        ? 120.0
        : (screenSize.height < 800 ? 150.0 : 200.0);

    // Define playable area boundaries with padding
    final horizontalPadding = 20.0; // 20px padding from left/right edges
    final verticalPadding = 20.0; // 20px padding from top/bottom edges

    final leftBoundary = horizontalPadding;
    final rightBoundary = screenSize.width - horizontalPadding;
    final topBoundary = topHudHeight + verticalPadding;
    final bottomBoundary = screenSize.height - bottomUIHeight - verticalPadding;

    // Calculate path points as percentages of playable area
    final playableWidth = rightBoundary - leftBoundary;
    final playableHeight = bottomBoundary - topBoundary;

    // Helper function to snap coordinates to tile centers using tile system coordinates
    Vector2 snapToTileCenter(double x, double y) {
      final tileSize = TileSystem.tileSize;

      // Use the same grid calculation as TileSystem
      final cols =
          14; // Force exactly 14 tiles horizontally (same as TileSystem)
      final rows = (screenSize.height / tileSize).floor();

      // Calculate offset to center the grid within the screen (same as TileSystem)
      final gridWidth = cols * tileSize;
      final gridHeight = rows * tileSize;
      final offsetX = (screenSize.width - gridWidth) / 2;
      final offsetY = (screenSize.height - gridHeight) / 2;

      // Convert world position to grid coordinates
      int tileX = ((x - offsetX) / tileSize).round();
      int tileY = ((y - offsetY) / tileSize).round();

      // Ensure we don't use edge tiles (keep at least 1 tile margin)
      tileX = tileX.clamp(1, cols - 2);
      tileY = tileY.clamp(1, rows - 2);

      // Return tile center position using the same calculation as TileSystem
      return Vector2(
        offsetX + tileX * tileSize + tileSize / 2,
        offsetY + tileY * tileSize + tileSize / 2,
      );
    }

    return GamePath(
      id: 'level_1_path',
      name: 'Level 1 Path',
      waypoints: [
        // Start from left edge at center height - snap to tile center
        Waypoint(
          position: snapToTileCenter(
            leftBoundary,
            topBoundary + playableHeight * 0.5,
          ),
          id: 'start',
        ),
        // Move right horizontally (20% of playable width) - snap to tile center
        Waypoint(
          position: snapToTileCenter(
            leftBoundary + playableWidth * 0.2,
            topBoundary + playableHeight * 0.5,
          ),
          id: 'h1',
        ),
        // Move up vertically (to 25% from top) - snap to tile center
        Waypoint(
          position: snapToTileCenter(
            leftBoundary + playableWidth * 0.2,
            topBoundary + playableHeight * 0.25,
          ),
          id: 'v1',
        ),
        // Move right horizontally (to 50% width) - snap to tile center
        Waypoint(
          position: snapToTileCenter(
            leftBoundary + playableWidth * 0.5,
            topBoundary + playableHeight * 0.25,
          ),
          id: 'h2',
        ),
        // Move down vertically (to 75% from top) - snap to tile center
        Waypoint(
          position: snapToTileCenter(
            leftBoundary + playableWidth * 0.5,
            topBoundary + playableHeight * 0.75,
          ),
          id: 'v2',
        ),
        // Move right horizontally (to 75% width) - snap to tile center
        Waypoint(
          position: snapToTileCenter(
            leftBoundary + playableWidth * 0.75,
            topBoundary + playableHeight * 0.75,
          ),
          id: 'h3',
        ),
        // Move up vertically (to 40% from top) - snap to tile center
        Waypoint(
          position: snapToTileCenter(
            leftBoundary + playableWidth * 0.75,
            topBoundary + playableHeight * 0.4,
          ),
          id: 'v3',
        ),
        // Move right horizontally to end - snap to tile center
        Waypoint(
          position: snapToTileCenter(
            rightBoundary,
            topBoundary + playableHeight * 0.4,
          ),
          id: 'end',
        ),
      ],
    );
  }

  void _updateGame() {
    if (!mounted) return;

    final gameState = ref.read(gameStateProvider);
    final gameStateNotifier = ref.read(gameStateProvider.notifier);

    // Use actual frame time from game loop for smooth 60 FPS
    final deltaTime = _gameLoop.frameTime;

    // Always update entity manager for additions/removals (towers placed during prep)
    // but only update entity logic when game is playing
    if (gameState.isPlaying) {
      _entityManager.update(deltaTime);
    } else {
      // During preparation, only process entity additions/removals, not updates
      _entityManager.processAdditionsAndRemovals();
    }

    // Don't update game logic if game is paused or not playing
    if (gameState.isPaused || !gameState.isPlaying) return;

    // Update wave and spawn enemies (optimized)
    final newEnemies = _waveManager.updateWave(deltaTime, _currentPath);
    if (newEnemies.isNotEmpty) {
      // Debug: print('Wave ${_waveManager.currentWaveNumber}: Spawning ${newEnemies.length} enemies');
    }
    for (final enemy in newEnemies) {
      // Apply level-specific enemy multipliers
      _applyLevelMultipliers(enemy);

      // Set up particle emitter callback for enemy death effects
      enemy.onParticleEmitterCreated = (emitter) {
        _entityManager.addParticleEmitter(emitter);
      };
      _entityManager.addEntity(enemy);
    }

    // Update tower targeting and attacks (optimized with reduced frequency)
    final enemies = _entityManager.getEntitiesOfType<Enemy>();

    if (_gameLoop.frameCount % 2 == 0) {
      // Only update targeting every other frame
      final towers = _entityManager.getEntitiesOfType<Tower>();

      if (towers.isNotEmpty && enemies.isNotEmpty) {
        // Optimized tower targeting - process in batches
        final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;

        for (final tower in towers) {
          // Ensure tower has projectile callback set (safety check)
          tower.onProjectileCreated ??= (projectile) {
            // Set up particle emitter callback for projectile effects
            projectile.onParticleEmitterCreated = (emitter) {
              _entityManager.addParticleEmitter(emitter);
            };
            _entityManager.addEntity(projectile);
          };

          // Ensure tower has particle emitter callback set (safety check)
          tower.onParticleEmitterCreated ??= (emitter) {
            _entityManager.addParticleEmitter(emitter);
          };

          final target = tower.findTarget(enemies.cast<Entity>());
          if (target != null && tower.canAttack(currentTime)) {
            // Debug: print('Tower ${tower.name} found target at distance ${tower.distanceTo(target)}');
            tower.attack(target, currentTime);
          }
        }
      }
    }

    // Update all entities
    _entityManager.update(deltaTime);

    // Check collisions (optimized)
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
      // Debug: print('Found ${deadEnemies.length} dead enemies to reward');
    }

    for (final enemy in deadEnemies) {
      // Debug: print('Awarding ${enemy.goldReward} gold for killing ${enemy.name}');
      gameStateNotifier.addGold(enemy.goldReward);
      gameStateNotifier.addScore(enemy.goldReward * 10);

      // Ensure dead enemy is removed from entity manager
      if (enemy.isActive) {
        // Debug: print('Dead enemy ${enemy.name} is still active, removing manually');
        _entityManager.removeEntityDirect(enemy);
      }
    }

    // Check wave completion - wave is complete when all enemies spawned AND all enemies defeated
    // Also ensure at least one enemy was spawned to avoid immediate completion
    if (_waveManager.allEnemiesSpawned &&
        enemies.isEmpty &&
        !_waveManager.isWaveComplete &&
        _waveManager.hasSpawnedAtLeastOneEnemy) {
      // Mark wave as complete
      _waveManager.markWaveComplete();

      // Award wave bonus
      final waveStats = _waveManager.getWaveStats();
      if (waveStats['goldBonus'] != null) {
        gameStateNotifier.addGold(waveStats['goldBonus'] as int);
      }

      // Check if all waves completed
      if (_waveManager.isAllWavesComplete) {
        gameStateNotifier.victory();

        // Handle level completion
        _handleLevelCompletion(gameState);
      } else {
        // Start preparation for next wave
        _waveManager.nextWave();
        gameStateNotifier.nextWave();
        gameStateNotifier.startPreparation();

        // Give preparation gold for next wave
        final prepGold = 25 + (_waveManager.currentWaveNumber * 5);
        gameStateNotifier.addGold(prepGold);
      }
    }

    // Update UI less frequently to maintain 60 FPS
    // Only update UI every 3 frames (20 FPS UI updates) to reduce overhead
    if (mounted && _gameLoop.frameCount % 3 == 0) {
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
      // Start preparation phase with countdown
      gameStateNotifier.startPreparation();
      // Debug: print('Starting preparation phase with ${gameState.preparationTimeSeconds}s countdown');

      // Give initial prep gold for first wave
      final prepGold = 25 + (_waveManager.currentWaveNumber * 5);
      gameStateNotifier.addGold(prepGold);
      // Debug: print('Giving $prepGold prep gold for preparation');
    }
    // Removed pause toggle from screen tap - pause only works through button
  }

  /// Restart the game from the beginning
  void _restartGame() {
    final gameStateNotifier = ref.read(gameStateProvider.notifier);

    // Reset game state
    gameStateNotifier.resetGame();

    // Clear all entities
    _entityManager.clear();

    // Reset wave manager
    _waveManager.reset();
    LevelWaves.generateWavesForLevel(_waveManager, 1);

    // Clear tower selection
    ref.read(towerSelectionProvider.notifier).clearSelection();

    // Restart game loop if needed
    if (!_gameLoop.isRunning) {
      _gameLoop.start();
    }
  }

  /// Quit to main menu
  void _quitToMenu() {
    final gameStateNotifier = ref.read(gameStateProvider.notifier);

    // Reset to initial state (menu)
    gameStateNotifier.resetGame();

    // Clear all entities
    _entityManager.clear();

    // Reset wave manager
    _waveManager.reset();
    LevelWaves.generateWavesForLevel(_waveManager, 1);

    // Clear tower selection
    ref.read(towerSelectionProvider.notifier).clearSelection();

    // Stop the game loop
    _gameLoop.stop();

    // Navigate back to main menu screen
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  /// Handle level completion and progression
  void _handleLevelCompletion(GameState gameState) async {
    final levelManager = LevelManager.instance;

    if (!levelManager.isInitialized || levelManager.currentLevel == null) {
      return;
    }

    final currentLevel = levelManager.currentLevel!;
    final completionTime = gameState.gameDuration ?? Duration.zero;
    final score = gameState.score;

    // Determine if this was a perfect completion
    // Perfect = no lives lost and high score
    final isPerfect =
        gameState.lives >= currentLevel.startingLives &&
        score > (currentLevel.highScore ?? 0);

    // Complete the level in the level manager
    await levelManager.completeLevel(
      currentLevel.id,
      score: score,
      completionTime: completionTime,
      isPerfect: isPerfect,
    );

    // Show completion dialog with next level option
    if (mounted) {
      _showLevelCompletionDialog(
        currentLevel,
        score,
        completionTime,
        isPerfect,
      );
    }
  }

  /// Show level completion dialog
  void _showLevelCompletionDialog(
    GameLevel completedLevel,
    int score,
    Duration completionTime,
    bool isPerfect,
  ) {
    final levelManager = LevelManager.instance;
    final nextLevel = levelManager.getNextLevel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isPerfect ? '🌟 Level Mastered!' : '✅ Level Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${completedLevel.name} completed!'),
            const SizedBox(height: 8),
            Text('Score: $score'),
            Text('Time: ${_formatDuration(completionTime)}'),
            if (isPerfect)
              const Text(
                'Perfect completion! 🎉',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (nextLevel != null && nextLevel.isUnlocked) ...[
              const SizedBox(height: 16),
              Text('Next: ${nextLevel.name}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _quitToMenu();
            },
            child: const Text('Main Menu'),
          ),
          if (nextLevel != null && nextLevel.isUnlocked)
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await levelManager.selectLevel(nextLevel.id);
                _restartGame();
              },
              child: const Text('Next Level'),
            ),
        ],
      ),
    );
  }

  /// Format duration for display
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Update path and tile system when screen size changes significantly
  void _updatePathIfNeeded(Size screenSize) {
    if (_lastScreenSize == null ||
        (screenSize.width - _lastScreenSize!.width).abs() > 50 ||
        (screenSize.height - _lastScreenSize!.height).abs() > 50) {
      _lastScreenSize = screenSize;
      _currentPath = _createLevelPath();

      // Calculate UI heights for tile system
      final topHudHeight = screenSize.height < 600
          ? 60.0
          : (screenSize.height < 800 ? 85.0 : 120.0);
      final bottomUIHeight = screenSize.height < 600
          ? 120.0
          : (screenSize.height < 800 ? 150.0 : 200.0);

      // Initialize tile system with screen size, path, and UI areas
      _tileSystem.initializeGrid(
        screenSize,
        _currentPath.waypoints.map((w) => w.position).toList(),
        topUIHeight: topHudHeight,
        bottomUIHeight: bottomUIHeight,
      );
      // Debug: Tile system initialized with ${_tileSystem.tiles.length} rows

      // Update game state with tile system using a post-frame callback to avoid concurrent modifications
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final gameStateNotifier = ref.read(gameStateProvider.notifier);
          final currentState = ref.read(gameStateProvider);
          gameStateNotifier.updateGameState(
            currentState.copyWith(tileSystem: _tileSystem),
          );
          // Debug: Game state updated with tile system
        }
      });

      // Debug: Path and tile system updated for screen size: ${screenSize.width} x ${screenSize.height}
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
    final screenSize = MediaQuery.of(context).size;

    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final gameState = ref.watch(gameStateProvider);
    _updatePathIfNeeded(screenSize);

    // Listen for tower selection changes and show upgrade dialog
    ref.listen(towerSelectionProvider, (previous, current) {
      if (current.hasTowerSelected) {
        // Show upgrade dialog when any tower is selected (including re-selection)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            TowerUpgradeDialog.show(context, current.selectedTower!);
          }
        });
      }
    });

    // Start wave when transitioning from preparing to playing
    if (gameState.isPlaying && !_waveManager.isWaveActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Debug: print('Game started! Starting first wave...');
        _waveManager.startWave();
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Game Canvas - Full screen
            GameCanvas(
              entityManager: _entityManager,
              gameSpeed: gameState.gameSpeed,
              isPaused: gameState.isPaused,
              onTap: _handleTap,
              waveManager: _waveManager,
              currentPath: _currentPath,
              key: ValueKey(
                '${_currentPath.id}_${_entityManager.entities.length}',
              ),
            ),

            // Game UI Overlay
            _buildGameUI(gameState, screenSize),

            // Preparation Phase Overlay
            _buildPreparationOverlay(gameState, screenSize),

            // Performance Monitor (debug)
            PerformanceMonitor(gameLoop: _gameLoop),

            // Game Over Dialog
            if (gameState.isGameOver)
              GameOverDialog(
                finalScore: gameState.score,
                finalWave: gameState.wave,
                goldEarned: gameState.gold,
                gameDuration: gameState.gameDuration,
                onRestart: _restartGame,
                onQuit: _quitToMenu,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameUI(GameState gameState, Size screenSize) {
    // Simple responsive approach based on screen height
    final isSmallScreen = screenSize.height < 600;
    final isMediumScreen = screenSize.height < 800;

    // Use fixed heights that work well on different screen sizes
    final topHudHeight = isSmallScreen ? 60.0 : (isMediumScreen ? 85.0 : 120.0);
    final bottomHeight = isSmallScreen
        ? 120.0
        : (isMediumScreen ? 150.0 : 200.0);

    return Stack(
      children: [
        // Top HUD - Simple responsive height
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: topHudHeight,
            color: Colors.black.withValues(alpha: 0.8),
            child: isSmallScreen
                ? Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Lv.${gameState.wave} | ${gameState.lives}❤️ | ${gameState.gold}G',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        // Control buttons for small screens
                        if (gameState.isPlaying) ...[
                          _buildControlButtons(gameState),
                          const SizedBox(width: 8),
                        ],
                        // Wave stats on the right
                        _buildTopWaveStats(),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final availableWidth = constraints.maxWidth;
                        final isVeryNarrow = availableWidth < 600;
                        final isNarrow = availableWidth < 800;

                        // Calculate responsive widths
                        final playerUIWidth = isVeryNarrow
                            ? (availableWidth * 0.4).clamp(200.0, 240.0)
                            : (isNarrow ? 240.0 : 280.0);

                        return Row(
                          children: [
                            // Player panel with responsive width
                            SizedBox(
                              width: playerUIWidth,
                              child: MMORPGPlayerUI(
                                playerName: 'Player',
                                playerLevel: gameState.wave,
                                currentHealth: gameState.lives,
                                maxHealth: _getMaxHealthForCurrentLevel(),
                                gold: gameState.gold,
                                score: gameState.score,
                                enemiesInField: _entityManager
                                    .getEntitiesOfType<Enemy>()
                                    .length,
                              ),
                            ),
                            const Spacer(),
                            // Control buttons in the middle-right
                            if (gameState.isPlaying) ...[
                              _buildControlButtons(
                                gameState,
                                isCompact: isVeryNarrow,
                              ),
                              SizedBox(width: isVeryNarrow ? 6 : 12),
                            ],
                            // Wave stats on the right
                            _buildTopWaveStats(isCompact: isVeryNarrow),
                          ],
                        );
                      },
                    ),
                  ),
          ),
        ),

        // Preparation message overlay - positioned at the top center
        if (gameState.isPreparing) ...[
          // Notification banner at top center
          Positioned(
            top: topHudHeight + 16, // Just below the top HUD
            left: 16,
            right: 16,
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.8),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Preparing Wave ${gameState.wave}... ${gameState.remainingPreparationTime}s',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],

        // Bottom UI Panel - Responsive design
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: bottomHeight,
            color: Colors.black.withValues(alpha: 0.8),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 4.0 : 8.0),
              child: SizedBox(
                height:
                    bottomHeight -
                    (isSmallScreen ? 8.0 : 16.0), // Account for padding
                child: Stack(
                  children: [
                    // Main UI Column - Tower shop and upgrade panel
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top row: Tower Selection - Use Flexible to allow shrinking
                        Flexible(
                          flex: 3,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isVerySmall = constraints.maxHeight < 80;

                              if (isVerySmall) {
                                // Ultra-minimal single row layout
                                return _buildUltraCompactRow(gameState);
                              }

                              return Row(
                                children: [
                                  // Tower Selection (takes full width)
                                  Expanded(child: _buildTowerSelection()),
                                ],
                              );
                            },
                          ),
                        ),

                        // Minimal gap between tower shop and controls
                        const SizedBox(height: 2),

                        // Tower upgrade panel is now a popup dialog
                        // No inline panel needed
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Tower upgrade panel is now handled by popup dialog
  // This method is no longer needed but kept for compatibility

  Widget _buildTowerSelection() {
    final gameState = ref.watch(gameStateProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isVerySmall = constraints.maxHeight < 80;
        final isSmall = constraints.maxHeight < 120;

        return Container(
          padding: EdgeInsets.all(isVerySmall ? 4 : (isSmall ? 6 : 8)),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tower Shop Header - Only show if not very small
              if (!isVerySmall) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 8 : 12,
                    vertical: isSmall ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.pastelLavender.withValues(alpha: 0.8),
                        AppColors.pastelSky.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.hudBorder.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.store,
                        size: isSmall ? 14 : 16,
                        color: AppColors.textOnPastel,
                      ),
                      SizedBox(width: isSmall ? 4 : 6),
                      Text(
                        'Tower Shop',
                        style: TextStyle(
                          color: AppColors.textOnPastel,
                          fontSize: isSmall ? 12 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isSmall ? 4 : 6),
              ],

              // Tower options - Full width with even spacing
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildTowerOption(
                      icon: Icons.sports_esports,
                      title: isVerySmall ? 'A' : 'Archer',
                      cost: 50,
                      color: const Color(0xFFE6F3FF),
                      description: isVerySmall ? '' : 'Fast',
                      canAfford: gameState.gold >= 50,
                      isSmall: isVerySmall || isSmall,
                      towerType: TowerType.archer,
                    ),
                  ),
                  Expanded(
                    child: _buildTowerOption(
                      icon: Icons.whatshot,
                      title: isVerySmall ? 'C' : 'Cannon',
                      cost: 100,
                      color: const Color(0xFFFFE6E6),
                      description: isVerySmall ? '' : 'Power',
                      canAfford: gameState.gold >= 100,
                      isSmall: isVerySmall || isSmall,
                      towerType: TowerType.cannon,
                    ),
                  ),
                  Expanded(
                    child: _buildTowerOption(
                      icon: Icons.auto_awesome,
                      title: isVerySmall ? 'M' : 'Magic',
                      cost: 150,
                      color: const Color(0xFFF0E6FF),
                      description: isVerySmall ? '' : 'Area',
                      canAfford: gameState.gold >= 150,
                      isSmall: isVerySmall || isSmall,
                      towerType: TowerType.magic,
                    ),
                  ),
                  Expanded(
                    child: _buildTowerOption(
                      icon: Icons.gps_fixed,
                      title: isVerySmall ? 'S' : 'Sniper',
                      cost: 200,
                      color: const Color(0xFFE6FFE6),
                      description: isVerySmall ? '' : 'Range',
                      canAfford: gameState.gold >= 200,
                      isSmall: isVerySmall || isSmall,
                      towerType: TowerType.sniper,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTowerOption({
    required IconData icon,
    required String title,
    required int cost,
    required Color color,
    required String description,
    required bool canAfford,
    required bool isSmall,
    required TowerType towerType,
  }) {
    final towerWidget = StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            transform: Matrix4.identity()
              ..scale(_getHoverScale(isHovered, canAfford)),
            padding: EdgeInsets.all(isSmall ? 4 : 8),
            decoration: BoxDecoration(
              color: _getBackgroundColor(color, canAfford, isHovered),
              borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
              border: Border.all(
                color: _getBorderColor(canAfford, isHovered),
                width: _getBorderWidth(isHovered, canAfford),
              ),
              boxShadow: _getBoxShadow(canAfford, isHovered, color),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 200),
                  tween: Tween(
                    begin: 1.0,
                    end: _getIconScale(isHovered, canAfford),
                  ),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Icon(
                        icon,
                        size: isSmall ? 24 : 32,
                        color: _getIconColor(canAfford, isHovered),
                      ),
                    );
                  },
                ),
                if (title.isNotEmpty) ...[
                  SizedBox(height: isSmall ? 2 : 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: _getTextColor(canAfford, isHovered),
                      fontSize: isSmall ? 10 : 12,
                      fontWeight: FontWeight.bold,
                    ),
                    child: Text(title),
                  ),
                ],
                if (description.isNotEmpty) ...[
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: _getDescriptionColor(canAfford, isHovered),
                      fontSize: isSmall ? 8 : 10,
                    ),
                    child: Text(description),
                  ),
                ],
                // Show cost
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: _getCostColor(canAfford, isHovered),
                    fontSize: isSmall ? 8 : 10,
                    fontWeight: FontWeight.bold,
                  ),
                  child: Text('$cost G'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!canAfford) {
      return towerWidget; // Return non-draggable widget if can't afford
    }

    return Draggable<TowerType>(
      data: towerType,
      feedback: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 200),
          tween: Tween(begin: 1.0, end: 1.2),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Icon(icon, size: 32, color: AppColors.textLight),
              ),
            );
          },
        ),
      ),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      childWhenDragging: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(0.9),
        child: Opacity(opacity: 0.3, child: towerWidget),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: towerWidget,
      ),
    );
  }

  Widget _buildUltraCompactRow(GameState gameState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMinimalTowerIcon(
              Icons.sports_esports,
              50,
              gameState.gold >= 50,
              TowerType.archer,
            ),
            _buildMinimalTowerIcon(
              Icons.whatshot,
              100,
              gameState.gold >= 100,
              TowerType.cannon,
            ),
            _buildMinimalTowerIcon(
              Icons.auto_awesome,
              150,
              gameState.gold >= 150,
              TowerType.magic,
            ),
            _buildMinimalTowerIcon(
              Icons.gps_fixed,
              200,
              gameState.gold >= 200,
              TowerType.sniper,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopWaveStats({bool isCompact = false}) {
    final waveStats = _waveManager.getWaveStats();
    final progress = waveStats.isNotEmpty && waveStats['progress'] != null
        ? (waveStats['progress'] as double)
        : 0.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Wave ${_waveManager.currentWaveNumber}',
            style: TextStyle(
              color: Colors.white,
              fontSize: isCompact ? 12 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isCompact ? 2 : 4),
          Container(
            width: isCompact ? 60 : 80,
            height: isCompact ? 3 : 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalTowerIcon(
    IconData icon,
    int cost,
    bool canAfford,
    TowerType towerType,
  ) {
    final towerWidget = Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: canAfford
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        icon,
        size: 16,
        color: canAfford ? AppColors.textOnPastel : AppColors.textSecondary,
      ),
    );

    if (!canAfford) {
      return towerWidget;
    }

    return Draggable<TowerType>(
      data: towerType,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: Colors.black),
        ),
      ),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      childWhenDragging: Opacity(opacity: 0.5, child: towerWidget),
      child: towerWidget,
    );
  }

  Widget _buildControlButtons(GameState gameState, {bool isCompact = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pause/Resume button
        GestureDetector(
          onTap: () {
            if (gameState.isPaused) {
              AudioManager().resumeMusic();
              ref.read(gameStateProvider.notifier).resumeGame();
            } else {
              AudioManager().pauseMusic();
              ref.read(gameStateProvider.notifier).pauseGame();
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 8 : 12,
              vertical: isCompact ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  gameState.isPaused ? Icons.play_arrow : Icons.pause,
                  color: Colors.white,
                  size: isCompact ? 14 : 16,
                ),
                SizedBox(width: isCompact ? 2 : 4),
                if (!isCompact)
                  Text(
                    gameState.isPaused ? 'Resume' : 'Pause',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(width: isCompact ? 4 : 8),
        // Audio settings button
        GestureDetector(
          onTap: () {
            AudioManager().playSfx(AudioEvent.buttonClick);
            AudioSettingsPanel.show(context);
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 8 : 12,
              vertical: isCompact ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.volume_up,
              color: Colors.white,
              size: isCompact ? 14 : 16,
            ),
          ),
        ),
        SizedBox(width: isCompact ? 4 : 8),
        // Speed toggle button
        GestureDetector(
          onTap: () {
            final currentSpeed = gameState.gameSpeed;
            double newSpeed;
            if (currentSpeed == 0.5) {
              newSpeed = 1.0;
            } else if (currentSpeed == 1.0) {
              newSpeed = 2.0;
            } else {
              newSpeed = 0.5;
            }
            ref.read(gameStateProvider.notifier).setGameSpeed(newSpeed);
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 8 : 12,
              vertical: isCompact ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.speed,
                  color: Colors.white,
                  size: isCompact ? 14 : 16,
                ),
                SizedBox(width: isCompact ? 2 : 4),
                Text(
                  '${gameState.gameSpeed}x',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isCompact ? 10 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreparationOverlay(GameState gameState, Size screenSize) {
    if (gameState.isInMenu) {
      return _buildMenuOverlay(screenSize);
    }

    if (gameState.isPreparing) {
      return _buildPreparationCountdown(gameState, screenSize);
    }

    return Container();
  }

  Widget _buildMenuOverlay(Size screenSize) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Techtical Defense',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tap to Start',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 40),
              const Text(
                'Drag towers from the shop to place them\nDefend against waves of enemies!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreparationCountdown(GameState gameState, Size screenSize) {
    // No overlay during preparation - the countdown is already shown in the bottom UI
    return Container();
  }

  /// Get the maximum health for the current level
  int _getMaxHealthForCurrentLevel() {
    try {
      final levelManager = LevelManager.instance;
      if (levelManager.isInitialized && levelManager.currentLevel != null) {
        return levelManager.currentLevel!.startingLives;
      }
    } catch (e) {
      // Fallback to default if level manager not available
    }
    return 20; // Default fallback
  }
}
