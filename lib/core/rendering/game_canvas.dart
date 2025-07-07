import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/entity_manager.dart';
import '../audio/audio_manager.dart';
import '../../features/game/domain/models/tower.dart';
import '../../features/game/domain/models/path.dart';
import '../../features/game/domain/models/wave.dart';
import '../../features/game/domain/models/tile_system.dart';
import '../../features/game/presentation/providers/tower_selection_provider.dart';
import '../../features/game/presentation/providers/game_state_provider.dart';
import '../../shared/models/vector2.dart';

/// Interactive game canvas widget
class GameCanvas extends ConsumerStatefulWidget {
  final EntityManager entityManager;
  final double gameSpeed;
  final bool isPaused;
  final VoidCallback? onTap;
  final WaveManager? waveManager;
  final GamePath? currentPath;

  const GameCanvas({
    super.key,
    required this.entityManager,
    required this.gameSpeed,
    required this.isPaused,
    this.onTap,
    this.waveManager,
    this.currentPath,
  });

  @override
  ConsumerState<GameCanvas> createState() => _GameCanvasState();
}

class _GameCanvasState extends ConsumerState<GameCanvas> {
  late WaveManager _waveManager;
  late GamePath _currentPath;
  Vector2? _towerPreviewPosition;
  DateTime? _lastTowerClickTime;
  static const Duration _clickThrottleDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  @override
  void didUpdateWidget(GameCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update path if it changed
    if (widget.currentPath != oldWidget.currentPath) {
      _currentPath = widget.currentPath ?? _createDefaultPath();
      // Debug: print('GameCanvas: Path updated with ${_currentPath.waypoints.length} waypoints');
      // Debug: print('GameCanvas: First waypoint: ${_currentPath.waypoints.first.position}');
      // Debug: print('GameCanvas: Last waypoint: ${_currentPath.waypoints.last.position}');
    }
  }

  void _initializeGame() {
    // Use provided managers or create defaults
    _waveManager = widget.waveManager ?? WaveManager();

    if (widget.waveManager == null) {
      // Initialize with level 1 for now
      LevelWaves.generateWavesForLevel(_waveManager, 1);
    }

    // Use provided path or create default
    _currentPath = widget.currentPath ?? _createDefaultPath();

    // Debug: print('GameCanvas: Initialized with ${_currentPath.waypoints.length} waypoints');
    // Debug: print('GameCanvas: First waypoint: ${_currentPath.waypoints.first.position}');
    // Debug: print('GameCanvas: Last waypoint: ${_currentPath.waypoints.last.position}');
  }

  GamePath _createDefaultPath() {
    // Get current screen size from context
    final screenSize = MediaQuery.of(context).size;

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
      id: 'demo_path',
      name: 'Demo Path',
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

  void _handleTapUp(TapUpDetails details) {
    final position = Vector2(
      details.localPosition.dx,
      details.localPosition.dy,
    );

    final towerSelection = ref.read(towerSelectionProvider);
    final towerSelectionNotifier = ref.read(towerSelectionProvider.notifier);

    if (towerSelection.isPlacingTower) {
      // Place new tower
      _placeTower(position, towerSelection.selectedTowerType!);
    } else {
      // Check if clicking on existing tower
      final clickedTower = _getTowerAtPosition(position);
      if (clickedTower != null) {
        // Throttle tower clicks to prevent accidental double-clicks
        final now = DateTime.now();
        if (_lastTowerClickTime == null ||
            now.difference(_lastTowerClickTime!) > _clickThrottleDuration) {
          _lastTowerClickTime = now;

          // Visual feedback handled by tower selection state

          // Select tower for upgrade
          towerSelectionNotifier.selectExistingTower(clickedTower);

          // Brief pause to make interaction feel more responsive
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted) {
              setState(() {
                // This small setState helps ensure the UI updates immediately
              });
            }
          });

          // Add haptic feedback for better user experience
          // HapticFeedback.lightImpact(); // Uncomment if you want haptic feedback
        }
      } else {
        // Only clear selection and call onTap if we're not in tower selection mode
        if (towerSelection.selectedTowerType == null) {
          towerSelectionNotifier.clearSelection();
          widget.onTap?.call();
        }
        // If a tower is selected but not in placing mode, keep the selection
      }
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final towerSelection = ref.read(towerSelectionProvider);

    if (towerSelection.isSelecting) {
      final position = Vector2(
        details.localPosition.dx,
        details.localPosition.dy,
      );

      setState(() {
        _towerPreviewPosition = position;
      });

      // Highlight tile under cursor
      try {
        final gameState = ref.read(gameStateProvider);
        final tileSystem = gameState.tileSystem;
        if (tileSystem != null) {
          final tile = tileSystem.getTileAtWorldPosition(position);
          if (tile != null) {
            tileSystem.highlightTile(tile.gridX, tile.gridY);
          }
        }
      } catch (e) {
        // Ignore tile highlighting errors to prevent crashes
        // Debug: print('Tile highlighting error: $e');
      }
    }
  }

  void _placeTower(Vector2 position, TowerType towerType) {
    // Debug: _placeTower called: position=$position, towerType=$towerType

    final gameState = ref.read(gameStateProvider);
    final tileSystem = gameState.tileSystem;

    if (tileSystem == null) {
      // Debug: Tower placement failed: No tile system available
      return;
    }

    // Get the tile at this position
    final tile = tileSystem.getTileAtWorldPosition(position);
    // Debug: _placeTower: tile found=${tile != null}, tile position=${tile?.worldPosition}

    if (tile == null) {
      // Debug: Tower placement failed: No tile found at position $position
      return;
    }

    final canPlace = tileSystem.canPlaceTower(tile.gridX, tile.gridY);
    // Debug: _placeTower: canPlaceTower=$canPlace, tile state=${tile.state}

    if (!canPlace) {
      // Debug: Tower placement failed: Cannot place tower on tile (${tile.gridX}, ${tile.gridY})
      return;
    }

    final gameStateNotifier = ref.read(gameStateProvider.notifier);
    final towerSelectionNotifier = ref.read(towerSelectionProvider.notifier);

    // Get tower cost and check affordability
    int cost = _getTowerCost(towerType);
    if (!gameStateNotifier.spendGold(cost)) {
      // Debug: Tower placement failed: Insufficient gold
      return;
    }

    // Debug: Tower placement successful at tile: (${tile.gridX}, ${tile.gridY})

    // Use tile center position for precise placement
    // Adjust position so tower center aligns with tile center
    Tower? tower;
    switch (towerType) {
      case TowerType.archer:
        tower = ArcherTower(position: tile.worldPosition);
        break;
      case TowerType.cannon:
        tower = CannonTower(position: tile.worldPosition);
        break;
      case TowerType.magic:
        tower = MagicTower(position: tile.worldPosition);
        break;
      case TowerType.sniper:
        tower = SniperTower(position: tile.worldPosition);
        break;
    }

    // Adjust tower position so its center aligns with tile center
    final adjustedPosition = Vector2(
      tile.worldPosition.x - tower.size.x / 2,
      tile.worldPosition.y - tower.size.y / 2,
    );
    tower.position = adjustedPosition;

    // Debug: Tower created: ${tower.name} at position ${tower.position}

    // Set up projectile creation callback
    tower.onProjectileCreated = (projectile) {
      widget.entityManager.addEntity(projectile);
    };

    // Set up particle emitter creation callback
    tower.onParticleEmitterCreated = (emitter) {
      widget.entityManager.addParticleEmitter(emitter);
    };

    widget.entityManager.addEntity(tower);
    // Debug: Tower added to entity manager. Total entities: ${widget.entityManager.entities.length}

    // Play tower placement sound
    AudioManager().playSfx(AudioEvent.towerPlace);

    // Update tile system to mark tile as occupied
    try {
      tileSystem.placeTower(tile.gridX, tile.gridY, tower.id);
      // Debug: Tile system updated: tile (${tile.gridX}, ${tile.gridY}) marked as occupied
    } catch (e) {
      // Debug: Tile system update error: $e
    }

    // Clear selection
    towerSelectionNotifier.clearSelection();
    setState(() {
      _towerPreviewPosition = null;
    });
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

  /// Find tower at given position (for tower selection)
  /// Uses enlarged hit area for easier clicking during active gameplay
  Tower? _getTowerAtPosition(Vector2 position) {
    final towers = widget.entityManager.getEntitiesOfType<Tower>();

    // Use a larger hit area for easier tower selection
    const double hitAreaExpansion = 20.0; // Extra pixels around tower

    // First pass: Check exact tower bounds for precise selection
    for (final tower in towers) {
      if (tower.containsPoint(position)) {
        return tower;
      }
    }

    // Second pass: Check expanded bounds for easier selection
    for (final tower in towers) {
      // Create expanded hit area
      final expandedBounds = Rect.fromLTWH(
        tower.position.x - hitAreaExpansion,
        tower.position.y - hitAreaExpansion,
        tower.size.x + (hitAreaExpansion * 2),
        tower.size.y + (hitAreaExpansion * 2),
      );

      if (expandedBounds.contains(Offset(position.x, position.y))) {
        return tower;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final towerSelection = ref.watch(towerSelectionProvider);
    final gameState = ref.watch(gameStateProvider);

    return DragTarget<TowerType>(
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTapUp: _handleTapUp,
          onPanUpdate: _handlePanUpdate,
          child: CustomPaint(
            painter: GameCanvasPainter(
              entityManager: widget.entityManager,
              path: _currentPath,
              selectedTowerType: towerSelection.selectedTowerType,
              towerPreviewPosition: _towerPreviewPosition,
              isDragActive: candidateData.isNotEmpty,
              selectedTower: towerSelection.selectedTower,
              tileSystem: gameState.tileSystem,
            ),
            size: Size.infinite,
            child: Container(), // Transparent container to capture gestures
          ),
        );
      },
      onWillAcceptWithDetails: (data) {
        // Check if we can accept this tower type
        final gameState = ref.read(gameStateProvider);
        final cost = _getTowerCost(data.data);
        final canAfford = gameState.canAfford(cost);

        // Also check if position is valid for tile placement
        final position = Vector2(data.offset.dx, data.offset.dy);
        bool validPosition = true;

        try {
          final tileSystem = gameState.tileSystem;
          if (tileSystem != null) {
            final tile = tileSystem.getTileAtWorldPosition(position);
            if (tile != null) {
              final canPlace = tileSystem.canPlaceTower(tile.gridX, tile.gridY);
              // Debug: Tile at (${tile.gridX}, ${tile.gridY}): state=${tile.state}, canPlace=$canPlace
              validPosition = canPlace;
            } else {
              // Debug: No tile found at position $position
              validPosition = false;
            }
          }
        } catch (e) {
          // If tile system access fails, fall back to allowing placement
          validPosition = true;
          // Debug: Tile validation error: $e
        }

        // Debug: onWillAcceptWithDetails: tower=${data.data}, cost=$cost, gold=${gameState.gold}, canAfford=$canAfford, validPosition=$validPosition
        return canAfford && validPosition;
      },
      onAcceptWithDetails: (details) {
        final position = Vector2(details.offset.dx, details.offset.dy);
        // Debug: onAcceptWithDetails called: position=$position, tower=${details.data}

        // Snap to tile center for precise placement
        try {
          final gameState = ref.read(gameStateProvider);
          final tileSystem = gameState.tileSystem;
          // Debug: Tile system available: ${tileSystem != null}

          if (tileSystem != null) {
            final tile = tileSystem.getTileAtWorldPosition(position);
            // Debug: Found tile: ${tile != null}, position: ${tile?.worldPosition}
            if (tile != null) {
              // Debug: Placing tower at tile center: ${tile.worldPosition}
              _placeTower(tile.worldPosition, details.data);
            } else {
              // Debug: No tile found, placing at original position
              _placeTower(position, details.data);
            }
          } else {
            // Debug: No tile system, placing at original position
            _placeTower(position, details.data);
          }
        } catch (e) {
          // Debug: Tile placement error: $e
          _placeTower(position, details.data);
        }
      },
      onMove: (details) {
        // Update preview position during drag
        final position = Vector2(details.offset.dx, details.offset.dy);
        setState(() {
          _towerPreviewPosition = position;
        });

        // Highlight tile under cursor
        try {
          final gameState = ref.read(gameStateProvider);
          final tileSystem = gameState.tileSystem;
          if (tileSystem != null) {
            final tile = tileSystem.getTileAtWorldPosition(position);
            if (tile != null) {
              tileSystem.highlightTile(tile.gridX, tile.gridY);
            }
          }
        } catch (e) {
          // Ignore tile highlighting errors to prevent crashes
          // Debug: print('Tile highlighting error in onMove: $e');
        }
      },
      onLeave: (data) {
        // Clear preview and highlights when drag leaves the canvas
        try {
          final gameState = ref.read(gameStateProvider);
          final tileSystem = gameState.tileSystem;
          if (tileSystem != null) {
            tileSystem.clearHighlights();
          }
        } catch (e) {
          // Ignore tile clearing errors to prevent crashes
          // Debug: print('Tile clearing error: $e');
        }

        setState(() {
          _towerPreviewPosition = null;
        });
      },
    );
  }

  /// Select a tower type for placement
  void selectTower(TowerType towerType) {
    final towerSelectionNotifier = ref.read(towerSelectionProvider.notifier);
    towerSelectionNotifier.selectTower(towerType);
  }

  /// Clear tower selection
  void clearSelection() {
    final towerSelectionNotifier = ref.read(towerSelectionProvider.notifier);
    towerSelectionNotifier.clearSelection();
    setState(() {
      _towerPreviewPosition = null;
    });
  }

  /// Start the next wave
  void startWave() {
    _waveManager.startWave();
  }

  /// Get wave statistics
  Map<String, dynamic> getWaveStats() => _waveManager.getWaveStats();
}

/// Custom painter for the game canvas
class GameCanvasPainter extends CustomPainter {
  final EntityManager entityManager;
  final GamePath path;
  final TowerType? selectedTowerType;
  final Vector2? towerPreviewPosition;
  final bool isDragActive;
  final Tower? selectedTower;
  final TileSystem? tileSystem;

  GameCanvasPainter({
    required this.entityManager,
    required this.path,
    this.selectedTowerType,
    this.towerPreviewPosition,
    this.isDragActive = false,
    this.selectedTower,
    this.tileSystem,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    _drawBackground(canvas, size);

    // Draw tile system
    if (tileSystem != null) {
      _drawTileSystem(canvas, size);
    }

    // Draw path
    _drawPath(canvas, size);

    // Draw entities with special handling for tower selection
    _renderEntitiesWithSelection(canvas, size);

    // Draw tower preview
    if (selectedTowerType != null && towerPreviewPosition != null) {
      _drawTowerPreview(canvas, size);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0xFFF5F3F0) // Soft background
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawTileSystem(Canvas canvas, Size size) {
    if (tileSystem == null) return;

    try {
      final emptyTilePaint = Paint()
        ..color = const Color(0xFFE8F5E8)
            .withAlpha(100) // Soft pastel green for empty tiles
        ..style = PaintingStyle.fill;

      final occupiedTilePaint = Paint()
        ..color = const Color(0xFFF5E8E8)
            .withAlpha(120) // Soft pastel pink for occupied tiles
        ..style = PaintingStyle.fill;

      final blockedTilePaint = Paint()
        ..color = const Color(0xFFE8E8F5)
            .withAlpha(80) // Soft pastel purple for blocked tiles
        ..style = PaintingStyle.fill;

      final highlightedTilePaint = Paint()
        ..color = const Color(0xFFFFF5E8)
            .withAlpha(150) // Soft pastel peach for highlighted tiles
        ..style = PaintingStyle.fill;

      final invalidTilePaint = Paint()
        ..color = Colors
            .black // Black for invalid edge tiles
        ..style = PaintingStyle.fill;

      final preparationBlockedPaint = Paint()
        ..color = Colors
            .black // Solid black for preparation blocked tiles
        ..style = PaintingStyle.fill;

      final tileBorderPaint = Paint()
        ..color = const Color(0xFFCCCCCC).withAlpha(150)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      // Draw tiles
      for (final row in tileSystem!.tiles) {
        for (final tile in row) {
          final rect = Rect.fromCenter(
            center: Offset(tile.worldPosition.x, tile.worldPosition.y),
            width: TileSystem.tileSize,
            height: TileSystem.tileSize,
          );

          // Choose paint based on tile state
          Paint fillPaint;
          switch (tile.state) {
            case TileState.empty:
              fillPaint = emptyTilePaint;
              break;
            case TileState.occupied:
              fillPaint = occupiedTilePaint;
              break;
            case TileState.blocked:
              fillPaint = blockedTilePaint;
              break;
            case TileState.highlighted:
              fillPaint = highlightedTilePaint;
              break;
            case TileState.invalid:
              fillPaint = invalidTilePaint;
              break;
            case TileState.preparationBlocked:
              fillPaint = preparationBlockedPaint;
              break;
          }

          // Draw tile
          canvas.drawRect(rect, fillPaint);

          // Only draw borders for non-preparation-blocked tiles
          if (tile.state != TileState.preparationBlocked) {
            canvas.drawRect(rect, tileBorderPaint);
          } else {
            // Draw red X on blacked out tiles to show they're invalid
            final redPaint = Paint()
              ..color = Colors.red
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2;

            final center = Offset(tile.worldPosition.x, tile.worldPosition.y);
            final size = TileSystem.tileSize * 0.4;

            // Draw X
            canvas.drawLine(
              Offset(center.dx - size / 2, center.dy - size / 2),
              Offset(center.dx + size / 2, center.dy + size / 2),
              redPaint,
            );
            canvas.drawLine(
              Offset(center.dx + size / 2, center.dy - size / 2),
              Offset(center.dx - size / 2, center.dy + size / 2),
              redPaint,
            );
          }
        }
      }
    } catch (e) {
      // If tile system drawing fails, skip rendering tiles
      // Debug: print('Tile system drawing error: $e');
    }
  }

  void _drawPath(Canvas canvas, Size size) {
    if (path.waypoints.length < 2) return;

    // Draw path line
    final pathPaint = Paint()
      ..color = const Color(0xFFD4C5E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    final pathLinePaint = Paint()
      ..color = const Color(0xFFF0E6FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    final pathPoints = path.waypoints
        .map((w) => Offset(w.position.x, w.position.y))
        .toList();

    // Draw path segments
    for (int i = 0; i < pathPoints.length - 1; i++) {
      canvas.drawLine(pathPoints[i], pathPoints[i + 1], pathPaint);
      canvas.drawLine(pathPoints[i], pathPoints[i + 1], pathLinePaint);
    }

    // Draw waypoints
    final waypointPaint = Paint()
      ..color = const Color(0xFFD4C5E8)
      ..style = PaintingStyle.fill;

    for (final waypoint in path.waypoints) {
      canvas.drawCircle(
        Offset(waypoint.position.x, waypoint.position.y),
        8,
        waypointPaint,
      );
    }

    // Draw start and end markers
    if (path.waypoints.isNotEmpty) {
      final startPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill;

      final endPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;

      final start = path.waypoints.first.position;
      final end = path.waypoints.last.position;

      canvas.drawCircle(Offset(start.x, start.y), 12, startPaint);
      canvas.drawCircle(Offset(end.x, end.y), 12, endPaint);
    }
  }

  void _drawTowerPreview(Canvas canvas, Size size) {
    if (selectedTowerType == null || towerPreviewPosition == null) return;

    Color towerColor;
    double towerSize;
    double range;

    switch (selectedTowerType!) {
      case TowerType.archer:
        towerColor = const Color(0xFFD2B48C);
        towerSize = 30;
        range = 150; // Updated to match new archer range
        break;
      case TowerType.cannon:
        towerColor = const Color(0xFFC0C0C0);
        towerSize = 35;
        range = 130; // Updated to match new cannon range
        break;
      case TowerType.magic:
        towerColor = const Color(0xFFDDA0DD);
        towerSize = 32;
        range = 170; // Updated to match new magic range
        break;
      case TowerType.sniper:
        towerColor = const Color(0xFF98FB98);
        towerSize = 28;
        range = 250; // Updated to match new sniper range
        break;
    }

    // Snap preview to tile center if tile system is available
    Vector2 previewPos = towerPreviewPosition!;
    if (tileSystem != null) {
      final tile = tileSystem!.getTileAtWorldPosition(towerPreviewPosition!);
      if (tile != null) {
        previewPos = tile.worldPosition;
      }
    }

    final center = Offset(previewPos.x, previewPos.y);

    // Check if position is valid for placement
    bool isValidPosition = _isValidPreviewPosition(previewPos);

    // Choose colors based on validity and drag state
    Color previewColor = isValidPosition ? towerColor : Colors.red;
    Color borderColor = isValidPosition ? towerColor : Colors.red;
    Color rangeColor = isValidPosition ? towerColor : Colors.red;

    // Different opacity for drag vs select
    int alphaLevel = isDragActive ? 200 : 150;

    final previewPaint = Paint()
      ..color = previewColor.withAlpha(alphaLevel)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDragActive ? 3 : 2;

    // Draw preview tower
    canvas.drawCircle(center, towerSize / 2, previewPaint);
    canvas.drawCircle(center, towerSize / 2, borderPaint);

    // Draw range indicator
    final rangePaint = Paint()
      ..color = rangeColor.withAlpha(isDragActive ? 80 : 50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDragActive ? 3 : 2;

    canvas.drawCircle(center, range, rangePaint);

    // Draw validity indicator when dragging
    if (isDragActive) {
      final validityPaint = Paint()
        ..color = isValidPosition ? Colors.green : Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;

      // Draw a square indicator around the tower
      final validityRect = Rect.fromCenter(
        center: center,
        width: towerSize + 10,
        height: towerSize + 10,
      );

      canvas.drawRect(validityRect, validityPaint);
    }
  }

  bool _isValidPreviewPosition(Vector2 position) {
    // Use tile system validation if available
    if (tileSystem != null) {
      final tile = tileSystem!.getTileAtWorldPosition(position);
      if (tile == null) return false;
      return tileSystem!.canPlaceTower(tile.gridX, tile.gridY);
    }

    // Fallback to old validation logic
    // Check if too close to path
    for (final waypoint in path.waypoints) {
      if (position.distanceTo(waypoint.position) < 40) {
        return false;
      }
    }

    // Check if too close to existing towers
    final towers = entityManager.getEntitiesOfType<Tower>();
    for (final tower in towers) {
      if (position.distanceTo(tower.center) < 60) {
        return false;
      }
    }

    return true;
  }

  /// Render entities with special tower selection handling
  void _renderEntitiesWithSelection(Canvas canvas, Size size) {
    final entities = entityManager.entities;

    for (final entity in entities) {
      if (!entity.isActive || !entity.isVisible) continue;

      if (entity is Tower) {
        // Use selection-aware rendering for towers
        final isSelected = selectedTower?.id == entity.id;
        entity.renderWithSelection(canvas, size, isSelected);
      } else {
        // Use normal rendering for other entities
        entity.render(canvas, size);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    // Only repaint if entities have actually changed
    // This reduces unnecessary repaints and improves performance
    final shouldRepaint = entityManager.hasChanged;
    if (shouldRepaint) {
      // Reset the change flag after determining we need to repaint
      entityManager.resetChangeFlag();
    }
    return shouldRepaint;
  }
}
