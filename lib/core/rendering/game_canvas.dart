import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/entity_manager.dart';
import '../../features/game/domain/models/tower.dart';
import '../../features/game/domain/models/enemy.dart';
import '../../features/game/domain/models/projectile.dart';
import '../../features/game/domain/models/path.dart';
import '../../features/game/domain/models/wave.dart';
import '../../features/game/presentation/providers/tower_selection_provider.dart';
import '../../features/game/presentation/providers/game_state_provider.dart';
import '../../shared/models/vector2.dart';
import '../../shared/models/entity.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    // Use provided managers or create defaults
    _waveManager = widget.waveManager ?? WaveManager();

    if (widget.waveManager == null) {
      // Initialize with level 1 for now
      LevelWaves.generateWavesForLevel(_waveManager, 1);
    }

    // Use provided path or create default
    _currentPath =
        widget.currentPath ??
        GamePath(
          id: 'demo_path',
          name: 'Demo Path',
          waypoints: [
            Waypoint(position: Vector2(0, 200), id: 'start'),
            Waypoint(position: Vector2(150, 150), id: 'mid1'),
            Waypoint(position: Vector2(300, 250), id: 'mid2'),
            Waypoint(position: Vector2(450, 180), id: 'mid3'),
            Waypoint(position: Vector2(600, 200), id: 'end'),
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
        // Select tower for upgrade
        towerSelectionNotifier.selectExistingTower(clickedTower);
      } else {
        // Clear selection if clicking empty space
        towerSelectionNotifier.clearSelection();
        widget.onTap?.call();
      }
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final towerSelection = ref.read(towerSelectionProvider);

    if (towerSelection.isSelecting) {
      setState(() {
        _towerPreviewPosition = Vector2(
          details.localPosition.dx,
          details.localPosition.dy,
        );
      });
    }
  }

  void _placeTower(Vector2 position, TowerType towerType) {
    // Check if position is valid (not on path, not too close to other towers)
    if (!_isValidTowerPosition(position)) return;

    final gameStateNotifier = ref.read(gameStateProvider.notifier);
    final towerSelectionNotifier = ref.read(towerSelectionProvider.notifier);

    // Get tower cost and check affordability
    int cost = _getTowerCost(towerType);
    if (!gameStateNotifier.spendGold(cost)) return;

    Tower? tower;
    switch (towerType) {
      case TowerType.archer:
        tower = ArcherTower(position: position);
        break;
      case TowerType.cannon:
        tower = CannonTower(position: position);
        break;
      case TowerType.magic:
        tower = MagicTower(position: position);
        break;
      case TowerType.sniper:
        tower = SniperTower(position: position);
        break;
    }

    if (tower != null) {
      // Set up projectile creation callback
      tower.onProjectileCreated = (projectile) {
        widget.entityManager.addEntity(projectile);
      };

      widget.entityManager.addEntity(tower);

      // Clear selection
      towerSelectionNotifier.clearSelection();
      setState(() {
        _towerPreviewPosition = null;
      });
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

  bool _isValidTowerPosition(Vector2 position) {
    // Check if too close to path
    for (final waypoint in _currentPath.waypoints) {
      if (position.distanceTo(waypoint.position) < 40) {
        return false;
      }
    }

    // Check if too close to existing towers
    final towers = widget.entityManager.getEntitiesOfType<Tower>();
    for (final tower in towers) {
      if (position.distanceTo(tower.center) < 60) {
        return false;
      }
    }

    return true;
  }

  /// Find tower at given position (for tower selection)
  Tower? _getTowerAtPosition(Vector2 position) {
    final towers = widget.entityManager.getEntitiesOfType<Tower>();
    for (final tower in towers) {
      if (tower.containsPoint(position)) {
        return tower;
      }
    }
    return null;
  }

  void _updateGame() {
    // Game update logic is now handled by the GameEngine
    // This method is kept for future canvas-specific updates if needed
  }

  @override
  Widget build(BuildContext context) {
    final towerSelection = ref.watch(towerSelectionProvider);

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
            ),
            size: Size.infinite,
            child: Container(), // Transparent container to capture gestures
          ),
        );
      },
      onWillAccept: (data) {
        // Check if we can accept this tower type
        if (data == null) return false;

        final gameState = ref.read(gameStateProvider);
        final cost = _getTowerCost(data);
        return gameState.canAfford(cost);
      },
      onAccept: (towerType) {
        // This is called when a tower is dropped, but we need position
        // We'll handle the actual placement in onAcceptWithDetails
      },
      onAcceptWithDetails: (details) {
        final position = Vector2(details.offset.dx, details.offset.dy);

        _placeTower(position, details.data);
      },
      onMove: (details) {
        // Update preview position during drag
        if (details.data != null) {
          setState(() {
            _towerPreviewPosition = Vector2(
              details.offset.dx,
              details.offset.dy,
            );
          });
        }
      },
      onLeave: (data) {
        // Clear preview when drag leaves the canvas
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

  GameCanvasPainter({
    required this.entityManager,
    required this.path,
    this.selectedTowerType,
    this.towerPreviewPosition,
    this.isDragActive = false,
    this.selectedTower,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    _drawBackground(canvas, size);

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

    // Draw grid pattern
    final gridPaint = Paint()
      ..color = const Color(0xFFE6E6E6).withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const gridSize = 40.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
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

    final center = Offset(towerPreviewPosition!.x, towerPreviewPosition!.y);

    // Check if position is valid for placement
    bool isValidPosition = _isValidPreviewPosition(towerPreviewPosition!);

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
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
