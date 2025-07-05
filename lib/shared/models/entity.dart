import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'vector2.dart';

/// Base class for all game entities (towers, enemies, projectiles)
abstract class Entity {
  final String id;
  Vector2 position;
  Vector2 size;
  double rotation;
  bool isActive;
  bool isVisible;
  final DateTime createdAt;

  Entity({
    String? id,
    required this.position,
    required this.size,
    this.rotation = 0.0,
    this.isActive = true,
    this.isVisible = true,
  }) : id = id ?? const Uuid().v4(),
       createdAt = DateTime.now();

  /// Update the entity's logic (called every frame)
  void update(double deltaTime);

  /// Render the entity on the canvas
  void render(Canvas canvas, Size canvasSize);

  /// Handle collision with another entity
  void onCollision(Entity other) {}

  /// Called when the entity is destroyed
  void onDestroy() {
    isActive = false;
    isVisible = false;
  }

  /// Check if this entity intersects with another entity
  bool intersects(Entity other) {
    return position.x < other.position.x + other.size.x &&
        position.x + size.x > other.position.x &&
        position.y < other.position.y + other.size.y &&
        position.y + size.y > other.position.y;
  }

  /// Get the distance to another entity
  double distanceTo(Entity other) => position.distanceTo(other.position);

  /// Get the center point of the entity
  Vector2 get center =>
      Vector2(position.x + size.x / 2, position.y + size.y / 2);

  /// Get the bounding rectangle
  Rect get bounds => Rect.fromLTWH(position.x, position.y, size.x, size.y);

  /// Check if a point is inside this entity
  bool containsPoint(Vector2 point) {
    return point.x >= position.x &&
        point.x <= position.x + size.x &&
        point.y >= position.y &&
        point.y <= position.y + size.y;
  }

  @override
  String toString() => 'Entity(id: $id, pos: $position, size: $size)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Entity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
