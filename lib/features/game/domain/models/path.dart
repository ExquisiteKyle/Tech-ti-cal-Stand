import 'dart:math' as math;
import '../../../../shared/models/vector2.dart';
import 'tile_system.dart';

/// Represents a single waypoint in a path
class Waypoint {
  final Vector2 position;
  final String id;
  final double waitTime;
  final Map<String, dynamic> metadata;

  Waypoint({
    required this.position,
    required this.id,
    this.waitTime = 0.0,
    this.metadata = const {},
  });
}

/// Represents a path that enemies can follow
class GamePath {
  final String id;
  final String name;
  final List<Waypoint> waypoints;
  final double totalLength;
  final bool isLoop;
  final Map<String, dynamic> metadata;

  GamePath({
    required this.id,
    required this.name,
    required this.waypoints,
    this.isLoop = false,
    this.metadata = const {},
  }) : totalLength = _calculateTotalLength(waypoints);

  /// Calculate the total length of the path
  static double _calculateTotalLength(List<Waypoint> waypoints) {
    if (waypoints.length < 2) return 0.0;

    double totalLength = 0.0;
    for (int i = 1; i < waypoints.length; i++) {
      totalLength += waypoints[i - 1].position.distanceTo(
        waypoints[i].position,
      );
    }
    return totalLength;
  }

  /// Get the waypoint positions as a list of Vector2
  List<Vector2> get positions => waypoints.map((w) => w.position).toList();

  /// Get waypoint at index, with loop support
  Waypoint? getWaypoint(int index) {
    if (waypoints.isEmpty) return null;

    if (isLoop) {
      return waypoints[index % waypoints.length];
    } else {
      return index >= 0 && index < waypoints.length ? waypoints[index] : null;
    }
  }

  /// Get the next waypoint after the given index
  Waypoint? getNextWaypoint(int currentIndex) {
    if (isLoop) {
      return getWaypoint(currentIndex + 1);
    } else {
      return currentIndex + 1 < waypoints.length
          ? waypoints[currentIndex + 1]
          : null;
    }
  }

  /// Get progress along the path (0.0 to 1.0)
  double getProgress(int currentWaypointIndex, double distanceToNext) {
    if (waypoints.isEmpty || totalLength == 0) return 0.0;

    double distanceTraveled = 0.0;

    // Add distances of completed segments
    for (int i = 1; i <= currentWaypointIndex && i < waypoints.length; i++) {
      distanceTraveled += waypoints[i - 1].position.distanceTo(
        waypoints[i].position,
      );
    }

    // Add distance in current segment
    if (currentWaypointIndex < waypoints.length - 1) {
      final currentSegmentLength = waypoints[currentWaypointIndex].position
          .distanceTo(waypoints[currentWaypointIndex + 1].position);
      distanceTraveled += currentSegmentLength - distanceToNext;
    }

    return (distanceTraveled / totalLength).clamp(0.0, 1.0);
  }
}

/// Manages multiple paths and path-related operations
class PathManager {
  final Map<String, GamePath> _paths = {};

  /// Add a path to the manager
  void addPath(GamePath path) {
    _paths[path.id] = path;
  }

  /// Get a path by ID
  GamePath? getPath(String id) => _paths[id];

  /// Get all paths
  List<GamePath> get allPaths => _paths.values.toList();

  /// Remove a path
  void removePath(String id) {
    _paths.remove(id);
  }

  /// Clear all paths
  void clearPaths() {
    _paths.clear();
  }

  /// Create a simple straight path
  GamePath createStraightPath({
    required String id,
    required String name,
    required Vector2 start,
    required Vector2 end,
    int intermediatePoints = 0,
  }) {
    final waypoints = <Waypoint>[];

    // Add start waypoint
    waypoints.add(Waypoint(position: start, id: '${id}_start'));

    // Add intermediate waypoints
    for (int i = 1; i <= intermediatePoints; i++) {
      final progress = i / (intermediatePoints + 1);
      final position = Vector2(
        start.x + (end.x - start.x) * progress,
        start.y + (end.y - start.y) * progress,
      );
      waypoints.add(Waypoint(position: position, id: '${id}_mid_$i'));
    }

    // Add end waypoint
    waypoints.add(Waypoint(position: end, id: '${id}_end'));

    final path = GamePath(id: id, name: name, waypoints: waypoints);

    addPath(path);
    return path;
  }

  /// Create a curved path using bezier curves
  GamePath createCurvedPath({
    required String id,
    required String name,
    required Vector2 start,
    required Vector2 end,
    required List<Vector2> controlPoints,
    int resolution = 20,
  }) {
    final waypoints = <Waypoint>[];

    // Generate points along the curve
    for (int i = 0; i <= resolution; i++) {
      final t = i / resolution;
      final position = _calculateBezierPoint(start, end, controlPoints, t);
      waypoints.add(Waypoint(position: position, id: '${id}_curve_$i'));
    }

    final path = GamePath(id: id, name: name, waypoints: waypoints);

    addPath(path);
    return path;
  }

  /// Calculate a point on a bezier curve
  Vector2 _calculateBezierPoint(
    Vector2 start,
    Vector2 end,
    List<Vector2> controlPoints,
    double t,
  ) {
    if (controlPoints.isEmpty) {
      // Linear interpolation
      return Vector2(
        start.x + (end.x - start.x) * t,
        start.y + (end.y - start.y) * t,
      );
    }

    // For now, implement simple quadratic bezier (1 control point)
    if (controlPoints.length == 1) {
      final cp = controlPoints[0];
      final x =
          math.pow(1 - t, 2) * start.x +
          2 * (1 - t) * t * cp.x +
          math.pow(t, 2) * end.x;
      final y =
          math.pow(1 - t, 2) * start.y +
          2 * (1 - t) * t * cp.y +
          math.pow(t, 2) * end.y;
      return Vector2(x.toDouble(), y.toDouble());
    }

    // For multiple control points, use linear interpolation for now
    return Vector2(
      start.x + (end.x - start.x) * t,
      start.y + (end.y - start.y) * t,
    );
  }

  /// Create a zigzag path
  GamePath createZigzagPath({
    required String id,
    required String name,
    required Vector2 start,
    required Vector2 end,
    required int segments,
    required double amplitude,
  }) {
    final waypoints = <Waypoint>[];

    // Calculate direction and perpendicular
    final direction = Vector2(end.x - start.x, end.y - start.y);
    direction.normalize();
    final perpendicular = Vector2(-direction.y, direction.x);

    final segmentLength = start.distanceTo(end) / segments;

    for (int i = 0; i <= segments; i++) {
      final basePosition = Vector2(
        start.x + direction.x * segmentLength * i,
        start.y + direction.y * segmentLength * i,
      );

      // Add zigzag offset
      final offset = (i % 2 == 0 ? amplitude : -amplitude);
      final position = Vector2(
        basePosition.x + perpendicular.x * offset,
        basePosition.y + perpendicular.y * offset,
      );

      waypoints.add(Waypoint(position: position, id: '${id}_zigzag_$i'));
    }

    final path = GamePath(id: id, name: name, waypoints: waypoints);

    addPath(path);
    return path;
  }
}

/// Predefined paths for different levels
class LevelPaths {
  static final PathManager _pathManager = PathManager();

  /// Get the path manager instance
  static PathManager get instance => _pathManager;

  /// Helper function to snap coordinates to tile centers
  static Vector2 _snapToTileCenter(
    double x,
    double y,
    double screenWidth,
    double screenHeight,
  ) {
    final tileSize = TileSystem.tileSize;

    // Use the same grid calculation as TileSystem
    final cols = 14; // Force exactly 14 tiles horizontally (same as TileSystem)
    final rows = (screenHeight / tileSize).floor();

    // Calculate offset to center the grid within the screen (same as TileSystem)
    final gridWidth = cols * tileSize;
    final gridHeight = rows * tileSize;
    final offsetX = (screenWidth - gridWidth) / 2;
    final offsetY = (screenHeight - gridHeight) / 2;

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

  /// Initialize paths for Level 1 (Forest Path)
  static void initializeLevel1Paths(double screenWidth, double screenHeight) {
    _pathManager.clearPaths();

    // Calculate safe boundaries (same as game engine)
    final topHudHeight = screenHeight < 600
        ? 60.0
        : (screenHeight < 800 ? 85.0 : 120.0);
    final bottomUIHeight = screenHeight < 600
        ? 120.0
        : (screenHeight < 800 ? 150.0 : 200.0);

    final horizontalPadding = 20.0;
    final verticalPadding = 20.0;

    final leftBoundary = horizontalPadding;
    final rightBoundary = screenWidth - horizontalPadding;
    final topBoundary = topHudHeight + verticalPadding;
    final bottomBoundary = screenHeight - bottomUIHeight - verticalPadding;

    final playableWidth = rightBoundary - leftBoundary;
    final playableHeight = bottomBoundary - topBoundary;

    // Forest path - winding S-curve pattern with multiple turns
    final waypoints = [
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary,
          topBoundary + playableHeight * 0.5,
          screenWidth,
          screenHeight,
        ),
        id: 'forest_start',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.15,
          topBoundary + playableHeight * 0.5,
          screenWidth,
          screenHeight,
        ),
        id: 'forest_1',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.15,
          topBoundary + playableHeight * 0.2,
          screenWidth,
          screenHeight,
        ),
        id: 'forest_2',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.4,
          topBoundary + playableHeight * 0.2,
          screenWidth,
          screenHeight,
        ),
        id: 'forest_3',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.4,
          topBoundary + playableHeight * 0.7,
          screenWidth,
          screenHeight,
        ),
        id: 'forest_4',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.65,
          topBoundary + playableHeight * 0.7,
          screenWidth,
          screenHeight,
        ),
        id: 'forest_5',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.65,
          topBoundary + playableHeight * 0.3,
          screenWidth,
          screenHeight,
        ),
        id: 'forest_6',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.85,
          topBoundary + playableHeight * 0.3,
          screenWidth,
          screenHeight,
        ),
        id: 'forest_7',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.85,
          topBoundary + playableHeight * 0.6,
          screenWidth,
          screenHeight,
        ),
        id: 'forest_8',
      ),
      Waypoint(
        position: _snapToTileCenter(
          rightBoundary,
          topBoundary + playableHeight * 0.6,
          screenWidth,
          screenHeight,
        ),
        id: 'forest_end',
      ),
    ];

    _pathManager.addPath(
      GamePath(
        id: 'forest_main',
        name: 'Forest Main Path',
        waypoints: waypoints,
      ),
    );
  }

  /// Initialize paths for Level 2 (Mountain Pass)
  static void initializeLevel2Paths(double screenWidth, double screenHeight) {
    _pathManager.clearPaths();

    // Calculate safe boundaries (same as game engine)
    final topHudHeight = screenHeight < 600
        ? 60.0
        : (screenHeight < 800 ? 85.0 : 120.0);
    final bottomUIHeight = screenHeight < 600
        ? 120.0
        : (screenHeight < 800 ? 150.0 : 200.0);

    final horizontalPadding = 20.0;
    final verticalPadding = 20.0;

    final leftBoundary = horizontalPadding;
    final rightBoundary = screenWidth - horizontalPadding;
    final topBoundary = topHudHeight + verticalPadding;
    final bottomBoundary = screenHeight - bottomUIHeight - verticalPadding;

    final playableWidth = rightBoundary - leftBoundary;
    final playableHeight = bottomBoundary - topBoundary;

    // Mountain path - complex switchback pattern like mountain roads
    final waypoints = [
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary,
          topBoundary + playableHeight * 0.8,
          screenWidth,
          screenHeight,
        ),
        id: 'mountain_start',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.3,
          topBoundary + playableHeight * 0.8,
          screenWidth,
          screenHeight,
        ),
        id: 'mountain_1',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.3,
          topBoundary + playableHeight * 0.6,
          screenWidth,
          screenHeight,
        ),
        id: 'mountain_2',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.1,
          topBoundary + playableHeight * 0.6,
          screenWidth,
          screenHeight,
        ),
        id: 'mountain_3',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.1,
          topBoundary + playableHeight * 0.4,
          screenWidth,
          screenHeight,
        ),
        id: 'mountain_4',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.5,
          topBoundary + playableHeight * 0.4,
          screenWidth,
          screenHeight,
        ),
        id: 'mountain_5',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.5,
          topBoundary + playableHeight * 0.2,
          screenWidth,
          screenHeight,
        ),
        id: 'mountain_6',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.2,
          topBoundary + playableHeight * 0.2,
          screenWidth,
          screenHeight,
        ),
        id: 'mountain_7',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.2,
          topBoundary + playableHeight * 0.1,
          screenWidth,
          screenHeight,
        ),
        id: 'mountain_8',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.7,
          topBoundary + playableHeight * 0.1,
          screenWidth,
          screenHeight,
        ),
        id: 'mountain_9',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.7,
          topBoundary + playableHeight * 0.5,
          screenWidth,
          screenHeight,
        ),
        id: 'mountain_10',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.9,
          topBoundary + playableHeight * 0.5,
          screenWidth,
          screenHeight,
        ),
        id: 'mountain_11',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.9,
          topBoundary + playableHeight * 0.3,
          screenWidth,
          screenHeight,
        ),
        id: 'mountain_12',
      ),
      Waypoint(
        position: _snapToTileCenter(
          rightBoundary,
          topBoundary + playableHeight * 0.3,
          screenWidth,
          screenHeight,
        ),
        id: 'mountain_end',
      ),
    ];

    _pathManager.addPath(
      GamePath(
        id: 'mountain_main',
        name: 'Mountain Main Path',
        waypoints: waypoints,
      ),
    );
  }

  /// Initialize paths for Level 3 (Castle Courtyard)
  static void initializeLevel3Paths(double screenWidth, double screenHeight) {
    _pathManager.clearPaths();

    // Calculate safe boundaries (same as game engine)
    final topHudHeight = screenHeight < 600
        ? 60.0
        : (screenHeight < 800 ? 85.0 : 120.0);
    final bottomUIHeight = screenHeight < 600
        ? 120.0
        : (screenHeight < 800 ? 150.0 : 200.0);

    final horizontalPadding = 20.0;
    final verticalPadding = 20.0;

    final leftBoundary = horizontalPadding;
    final rightBoundary = screenWidth - horizontalPadding;
    final topBoundary = topHudHeight + verticalPadding;
    final bottomBoundary = screenHeight - bottomUIHeight - verticalPadding;

    final playableWidth = rightBoundary - leftBoundary;
    final playableHeight = bottomBoundary - topBoundary;

    // Castle path - intricate fortress maze with multiple chambers
    final waypoints = [
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary,
          topBoundary + playableHeight * 0.6,
          screenWidth,
          screenHeight,
        ),
        id: 'castle_start',
      ),
      // Enter first chamber
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.15,
          topBoundary + playableHeight * 0.6,
          screenWidth,
          screenHeight,
        ),
        id: 'castle_1',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.15,
          topBoundary + playableHeight * 0.2,
          screenWidth,
          screenHeight,
        ),
        id: 'castle_2',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.35,
          topBoundary + playableHeight * 0.2,
          screenWidth,
          screenHeight,
        ),
        id: 'castle_3',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.35,
          topBoundary + playableHeight * 0.4,
          screenWidth,
          screenHeight,
        ),
        id: 'castle_4',
      ),
      // Move to second chamber
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.25,
          topBoundary + playableHeight * 0.4,
          screenWidth,
          screenHeight,
        ),
        id: 'castle_5',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.25,
          topBoundary + playableHeight * 0.8,
          screenWidth,
          screenHeight,
        ),
        id: 'castle_6',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.55,
          topBoundary + playableHeight * 0.8,
          screenWidth,
          screenHeight,
        ),
        id: 'castle_7',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.55,
          topBoundary + playableHeight * 0.5,
          screenWidth,
          screenHeight,
        ),
        id: 'castle_8',
      ),
      // Navigate through narrow corridor
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.45,
          topBoundary + playableHeight * 0.5,
          screenWidth,
          screenHeight,
        ),
        id: 'castle_9',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.45,
          topBoundary + playableHeight * 0.1,
          screenWidth,
          screenHeight,
        ),
        id: 'castle_10',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.75,
          topBoundary + playableHeight * 0.1,
          screenWidth,
          screenHeight,
        ),
        id: 'castle_11',
      ),
      // Final chamber approach
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.75,
          topBoundary + playableHeight * 0.6,
          screenWidth,
          screenHeight,
        ),
        id: 'castle_12',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.65,
          topBoundary + playableHeight * 0.6,
          screenWidth,
          screenHeight,
        ),
        id: 'castle_13',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.65,
          topBoundary + playableHeight * 0.9,
          screenWidth,
          screenHeight,
        ),
        id: 'castle_14',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.85,
          topBoundary + playableHeight * 0.9,
          screenWidth,
          screenHeight,
        ),
        id: 'castle_15',
      ),
      Waypoint(
        position: _snapToTileCenter(
          leftBoundary + playableWidth * 0.85,
          topBoundary + playableHeight * 0.4,
          screenWidth,
          screenHeight,
        ),
        id: 'castle_16',
      ),
      Waypoint(
        position: _snapToTileCenter(
          rightBoundary,
          topBoundary + playableHeight * 0.4,
          screenWidth,
          screenHeight,
        ),
        id: 'castle_end',
      ),
    ];

    _pathManager.addPath(
      GamePath(
        id: 'castle_main',
        name: 'Castle Main Path',
        waypoints: waypoints,
      ),
    );
  }

  /// Get the main path for a level
  static GamePath? getMainPath(int level) {
    switch (level) {
      case 1:
        return _pathManager.getPath('forest_main');
      case 2:
        return _pathManager.getPath('mountain_main');
      case 3:
        return _pathManager.getPath('castle_main');
      default:
        return null;
    }
  }
}
