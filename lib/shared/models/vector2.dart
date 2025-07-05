import 'dart:math' as math;

/// 2D Vector class for game positioning and calculations
class Vector2 {
  double x;
  double y;

  Vector2(this.x, this.y);

  Vector2.zero() : x = 0, y = 0;

  Vector2.fromAngle(double angle, double magnitude)
    : x = math.cos(angle) * magnitude,
      y = math.sin(angle) * magnitude;

  // Vector operations
  Vector2 operator +(Vector2 other) => Vector2(x + other.x, y + other.y);
  Vector2 operator -(Vector2 other) => Vector2(x - other.x, y - other.y);
  Vector2 operator *(double scalar) => Vector2(x * scalar, y * scalar);
  Vector2 operator /(double scalar) => Vector2(x / scalar, y / scalar);

  // Utility methods
  double get magnitude => math.sqrt(x * x + y * y);
  double get angle => math.atan2(y, x);

  Vector2 get normalized {
    final mag = magnitude;
    return mag == 0 ? Vector2.zero() : Vector2(x / mag, y / mag);
  }

  double distanceTo(Vector2 other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  double dot(Vector2 other) => x * other.x + y * other.y;

  Vector2 copy() => Vector2(x, y);

  @override
  String toString() => 'Vector2($x, $y)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vector2 && other.x == x && other.y == y;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}
