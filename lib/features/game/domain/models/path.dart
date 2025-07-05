import 'dart:math' as math;
import '../../../../shared/models/vector2.dart';

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
      final progress = i / segments;
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

  /// Initialize paths for Level 1 (Forest Path)
  static void initializeLevel1Paths(double screenWidth, double screenHeight) {
    _pathManager.clearPaths();

    // Main forest path - simple curved path from left to right
    _pathManager.createCurvedPath(
      id: 'forest_main',
      name: 'Forest Main Path',
      start: Vector2(0, screenHeight * 0.5),
      end: Vector2(screenWidth, screenHeight * 0.5),
      controlPoints: [
        Vector2(screenWidth * 0.25, screenHeight * 0.3),
        Vector2(screenWidth * 0.75, screenHeight * 0.7),
      ],
      resolution: 30,
    );
  }

  /// Initialize paths for Level 2 (Mountain Pass)
  static void initializeLevel2Paths(double screenWidth, double screenHeight) {
    _pathManager.clearPaths();

    // Mountain path - zigzag pattern
    _pathManager.createZigzagPath(
      id: 'mountain_main',
      name: 'Mountain Main Path',
      start: Vector2(0, screenHeight * 0.2),
      end: Vector2(screenWidth, screenHeight * 0.8),
      segments: 6,
      amplitude: 40,
    );
  }

  /// Initialize paths for Level 3 (Castle Courtyard)
  static void initializeLevel3Paths(double screenWidth, double screenHeight) {
    _pathManager.clearPaths();

    // Castle path - complex maze-like pattern
    final waypoints = [
      Waypoint(position: Vector2(0, screenHeight * 0.5), id: 'castle_start'),
      Waypoint(
        position: Vector2(screenWidth * 0.2, screenHeight * 0.5),
        id: 'castle_1',
      ),
      Waypoint(
        position: Vector2(screenWidth * 0.2, screenHeight * 0.2),
        id: 'castle_2',
      ),
      Waypoint(
        position: Vector2(screenWidth * 0.5, screenHeight * 0.2),
        id: 'castle_3',
      ),
      Waypoint(
        position: Vector2(screenWidth * 0.5, screenHeight * 0.8),
        id: 'castle_4',
      ),
      Waypoint(
        position: Vector2(screenWidth * 0.8, screenHeight * 0.8),
        id: 'castle_5',
      ),
      Waypoint(
        position: Vector2(screenWidth * 0.8, screenHeight * 0.3),
        id: 'castle_6',
      ),
      Waypoint(
        position: Vector2(screenWidth, screenHeight * 0.3),
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
