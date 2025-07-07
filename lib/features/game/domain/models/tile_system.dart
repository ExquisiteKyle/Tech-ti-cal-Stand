import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../shared/models/vector2.dart';

/// Represents the state of a single tile in the grid
enum TileState {
  empty, // Available for tower placement
  occupied, // Has a tower
  blocked, // Path tile or invalid for placement
  highlighted, // Currently being hovered/previewed
  invalid, // Edge tiles that are outside viewport boundaries
  preparationBlocked, // Blocked during preparation phase
}

/// Represents a single tile in the placement grid
class GameTile extends Equatable {
  final int gridX;
  final int gridY;
  final Vector2 worldPosition;
  final TileState state;
  final String? towerId; // ID of tower occupying this tile, if any

  const GameTile({
    required this.gridX,
    required this.gridY,
    required this.worldPosition,
    required this.state,
    this.towerId,
  });

  GameTile copyWith({
    int? gridX,
    int? gridY,
    Vector2? worldPosition,
    TileState? state,
    String? towerId,
  }) => GameTile(
    gridX: gridX ?? this.gridX,
    gridY: gridY ?? this.gridY,
    worldPosition: worldPosition ?? this.worldPosition,
    state: state ?? this.state,
    towerId: towerId ?? this.towerId,
  );

  @override
  List<Object?> get props => [gridX, gridY, worldPosition, state, towerId];
}

/// Manages the tile-based grid system for tower placement
class TileSystem {
  static const double tileSize = 40.0;

  final int gridWidth;
  final int gridHeight;
  final List<List<GameTile>> _grid;

  // Store the grid offset for world position calculations
  double _offsetX = 0.0;
  double _offsetY = 0.0;

  // Store preparation blocking area
  double? _preparationBlockTop;
  double? _preparationBlockBottom;

  TileSystem({required this.gridWidth, required this.gridHeight}) : _grid = [];

  /// Initialize the grid based on screen size and path
  void initializeGrid(
    Size screenSize,
    List<Vector2> pathPoints, {
    double topUIHeight = 0.0,
    double bottomUIHeight = 0.0,
  }) {
    _grid.clear();

    // Force exactly 14 tiles horizontally and calculate rows based on screen height
    final cols = 14;
    final rows = (screenSize.height / tileSize).floor();

    // Calculate offset to center the grid within the screen
    final gridWidth = cols * tileSize;
    final gridHeight = rows * tileSize;
    final offsetX = (screenSize.width - gridWidth) / 2;
    final offsetY = (screenSize.height - gridHeight) / 2;

    // Store offsets for world position calculations
    _offsetX = offsetX;
    _offsetY = offsetY;

    // Create the grid
    for (int y = 0; y < rows; y++) {
      final row = <GameTile>[];
      for (int x = 0; x < cols; x++) {
        final worldPos = Vector2(
          offsetX + x * tileSize + tileSize / 2,
          offsetY + y * tileSize + tileSize / 2,
        );

        // Determine initial tile state
        TileState state = TileState.empty;

        // Check if tile is at the edge of the viewport or in UI areas (invalid for gameplay)
        final isEdge = _isEdgeTile(x, y, cols, rows, screenSize);
        final isInUI = _isInUIArea(
          worldPos,
          screenSize,
          topUIHeight,
          bottomUIHeight,
        );

        if (isEdge || isInUI) {
          state = TileState.invalid;
        } else if (_isOnPath(worldPos, pathPoints)) {
          state = TileState.blocked;
        } else if (_isTopBufferRow(y, topUIHeight, screenSize)) {
          // Mark the top row of available tiles as invalid for visual separation
          state = TileState.invalid;
        }

        row.add(
          GameTile(gridX: x, gridY: y, worldPosition: worldPos, state: state),
        );
      }
      _grid.add(row);
    }
  }

  /// Check if a tile is at the edge of the viewport and should be marked invalid
  bool _isEdgeTile(int x, int y, int cols, int rows, Size screenSize) {
    // Only mark the outermost edge tiles as invalid for safety margin
    // This is less restrictive than marking the entire border
    return x == 0 ||
        x == cols - 1; // Only mark left and right edges, not top/bottom
  }

  /// Check if a tile position is within UI areas and should be marked invalid
  bool _isInUIArea(
    Vector2 tilePosition,
    Size screenSize,
    double topUIHeight,
    double bottomUIHeight,
  ) {
    // Check if tile is in top UI area - be more conservative
    if (tilePosition.y <= topUIHeight + 10) {
      // Added 10px buffer
      return true;
    }

    // Check if tile is in bottom UI area - be more conservative to allow more playable space
    // Only mark tiles as invalid if they're clearly in the UI area
    if (tilePosition.y >= screenSize.height - bottomUIHeight + 20) {
      // Reduced from 40 to 20
      return true;
    }

    return false;
  }

  /// Check if this is the top buffer row that should be marked invalid
  bool _isTopBufferRow(int gridY, double topUIHeight, Size screenSize) {
    // Find the row that's one row above the first playable row
    final firstPlayableY = topUIHeight + tileSize;
    final bufferRowY = _offsetY + (gridY * tileSize) + (tileSize / 2);

    // Mark only the row that's exactly one row above the first playable row as invalid
    // This is more precise than the previous logic
    return bufferRowY >= (firstPlayableY - tileSize - 5) &&
        bufferRowY < (firstPlayableY - tileSize + 5);
  }

  /// Check if a world position is on the path
  bool _isOnPath(Vector2 position, List<Vector2> pathPoints) {
    const pathWidth =
        25.0; // Increased from 15.0 to 25.0 for more reasonable path width

    for (int i = 0; i < pathPoints.length - 1; i++) {
      final start = pathPoints[i];
      final end = pathPoints[i + 1];

      final distance = _distanceToLineSegment(position, start, end);
      if (distance <= pathWidth) {
        return true;
      }
    }

    return false;
  }

  /// Calculate distance from point to line segment
  double _distanceToLineSegment(
    Vector2 point,
    Vector2 lineStart,
    Vector2 lineEnd,
  ) {
    final lineLength = lineStart.distanceTo(lineEnd);
    if (lineLength == 0) return point.distanceTo(lineStart);

    final t =
        ((point.x - lineStart.x) * (lineEnd.x - lineStart.x) +
            (point.y - lineStart.y) * (lineEnd.y - lineStart.y)) /
        (lineLength * lineLength);

    final clampedT = t.clamp(0.0, 1.0);
    final projection = Vector2(
      lineStart.x + clampedT * (lineEnd.x - lineStart.x),
      lineStart.y + clampedT * (lineEnd.y - lineStart.y),
    );

    return point.distanceTo(projection);
  }

  /// Get tile at grid coordinates
  GameTile? getTileAt(int gridX, int gridY) {
    if (gridY >= 0 &&
        gridY < _grid.length &&
        gridX >= 0 &&
        gridX < _grid[gridY].length) {
      return _grid[gridY][gridX];
    }
    return null;
  }

  /// Get tile at world position
  GameTile? getTileAtWorldPosition(Vector2 worldPos) {
    // Account for grid offset when converting world position to grid coordinates
    final gridX = ((worldPos.x - _offsetX) / tileSize).floor();
    final gridY = ((worldPos.y - _offsetY) / tileSize).floor();
    return getTileAt(gridX, gridY);
  }

  /// Update tile state
  void updateTile(int gridX, int gridY, TileState newState, {String? towerId}) {
    if (gridY >= 0 &&
        gridY < _grid.length &&
        gridX >= 0 &&
        gridX < _grid[gridY].length) {
      _grid[gridY][gridX] = _grid[gridY][gridX].copyWith(
        state: newState,
        towerId: towerId,
      );
    }
  }

  /// Get all tiles
  List<List<GameTile>> get tiles => _grid;

  /// Get all empty tiles
  List<GameTile> get emptyTiles {
    final empty = <GameTile>[];
    for (final row in _grid) {
      for (final tile in row) {
        if (tile.state == TileState.empty) {
          empty.add(tile);
        }
      }
    }
    return empty;
  }

  /// Check if a tile can have a tower placed on it
  bool canPlaceTower(int gridX, int gridY) {
    final tile = getTileAt(gridX, gridY);
    return tile != null &&
        (tile.state == TileState.empty ||
            tile.state == TileState.highlighted) &&
        tile.state != TileState.invalid &&
        tile.state != TileState.preparationBlocked;
  }

  /// Place a tower on a tile
  bool placeTower(int gridX, int gridY, String towerId) {
    if (canPlaceTower(gridX, gridY)) {
      // Clear any existing highlights first
      clearHighlights();
      updateTile(gridX, gridY, TileState.occupied, towerId: towerId);
      return true;
    }
    return false;
  }

  /// Remove a tower from a tile
  bool removeTower(int gridX, int gridY) {
    final tile = getTileAt(gridX, gridY);
    if (tile != null && tile.state == TileState.occupied) {
      updateTile(gridX, gridY, TileState.empty);
      return true;
    }
    return false;
  }

  /// Clear all highlights
  void clearHighlights() {
    for (int y = 0; y < _grid.length; y++) {
      for (int x = 0; x < _grid[y].length; x++) {
        final tile = _grid[y][x];
        if (tile.state == TileState.highlighted) {
          updateTile(x, y, TileState.empty);
        }
      }
    }
  }

  /// Highlight a tile for preview
  void highlightTile(int gridX, int gridY) {
    clearHighlights();
    final tile = getTileAt(gridX, gridY);
    if (tile != null && tile.state == TileState.empty) {
      updateTile(gridX, gridY, TileState.highlighted);
    }
  }

  /// Block tiles in the preparation notification area
  void blockPreparationArea(double screenHeight, double bottomUIHeight) {
    // Calculate the area where the preparation notification appears
    // The notification is positioned at bottom: bottomHeight + 8
    // With height of 60px (including padding)
    final notificationTop = screenHeight - bottomUIHeight - 60;
    final notificationBottom = screenHeight - bottomUIHeight + 8;

    _preparationBlockTop = notificationTop;
    _preparationBlockBottom = notificationBottom;

    // Block tiles in this area
    for (int y = 0; y < _grid.length; y++) {
      for (int x = 0; x < _grid[y].length; x++) {
        final tile = _grid[y][x];
        final tileY = tile.worldPosition.y;

        // Check if tile is in the preparation notification area
        if (tileY >= notificationTop && tileY <= notificationBottom) {
          // Only block empty tiles, don't affect already occupied or blocked tiles
          if (tile.state == TileState.empty ||
              tile.state == TileState.highlighted) {
            updateTile(x, y, TileState.preparationBlocked);
          }
        }
      }
    }
  }

  /// Unblock tiles in the preparation notification area
  void unblockPreparationArea() {
    if (_preparationBlockTop == null || _preparationBlockBottom == null) return;

    // Restore tiles that were blocked during preparation
    for (int y = 0; y < _grid.length; y++) {
      for (int x = 0; x < _grid[y].length; x++) {
        final tile = _grid[y][x];

        // Only restore tiles that were blocked during preparation
        if (tile.state == TileState.preparationBlocked) {
          updateTile(x, y, TileState.empty);
        }
      }
    }

    _preparationBlockTop = null;
    _preparationBlockBottom = null;
  }

  /// Check if preparation area is currently blocked
  bool get isPreparationAreaBlocked => _preparationBlockTop != null;
}
