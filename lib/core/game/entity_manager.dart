import 'package:flutter/material.dart';
import '../../shared/models/entity.dart';
import '../../shared/models/vector2.dart';

/// Manages all game entities (towers, enemies, projectiles)
class EntityManager {
  final List<Entity> _entities = [];
  final List<Entity> _entitiesToAdd = [];
  final List<String> _entitiesToRemove = [];

  /// Get all active entities
  List<Entity> get entities => _entities.where((e) => e.isActive).toList();

  /// Get entities of a specific type
  List<T> getEntitiesOfType<T extends Entity>() {
    return _entities.whereType<T>().where((e) => e.isActive).toList();
  }

  /// Add an entity to the manager
  void addEntity(Entity entity) {
    _entitiesToAdd.add(entity);
  }

  /// Remove an entity by ID
  void removeEntity(String entityId) {
    _entitiesToRemove.add(entityId);
  }

  /// Remove an entity directly
  void removeEntityDirect(Entity entity) {
    removeEntity(entity.id);
  }

  /// Update all entities
  void update(double deltaTime) {
    // Process additions
    _entities.addAll(_entitiesToAdd);
    _entitiesToAdd.clear();

    // Process removals
    for (final id in _entitiesToRemove) {
      _entities.removeWhere((entity) => entity.id == id);
    }
    _entitiesToRemove.clear();

    // Update active entities
    for (final entity in _entities) {
      if (entity.isActive) {
        entity.update(deltaTime);
      }
    }

    // Remove inactive entities
    final inactiveEntities = _entities
        .where((entity) => !entity.isActive)
        .toList();
    if (inactiveEntities.isNotEmpty) {
      print(
        'EntityManager removing ${inactiveEntities.length} inactive entities',
      );
      for (final entity in inactiveEntities) {
        print('Removing inactive entity: ${entity.runtimeType}');
      }
    }
    _entities.removeWhere((entity) => !entity.isActive);
  }

  /// Render all visible entities
  void render(Canvas canvas, Size canvasSize) {
    for (final entity in _entities) {
      if (entity.isActive && entity.isVisible) {
        entity.render(canvas, canvasSize);
      }
    }
  }

  /// Check collisions between entities
  void checkCollisions() {
    for (int i = 0; i < _entities.length; i++) {
      final entityA = _entities[i];
      if (!entityA.isActive) continue;

      for (int j = i + 1; j < _entities.length; j++) {
        final entityB = _entities[j];
        if (!entityB.isActive) continue;

        if (entityA.intersects(entityB)) {
          entityA.onCollision(entityB);
          entityB.onCollision(entityA);
        }
      }
    }
  }

  /// Find entity by ID
  Entity? findEntityById(String id) {
    try {
      return _entities.firstWhere((entity) => entity.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get entities within a radius of a point
  List<Entity> getEntitiesInRadius(Vector2 center, double radius) {
    return _entities.where((entity) {
      if (!entity.isActive) return false;
      return entity.center.distanceTo(center) <= radius;
    }).toList();
  }

  /// Clear all entities
  void clear() {
    for (final entity in _entities) {
      entity.onDestroy();
    }
    _entities.clear();
    _entitiesToAdd.clear();
    _entitiesToRemove.clear();
  }

  /// Get total entity count
  int get entityCount => _entities.length;

  /// Get active entity count
  int get activeEntityCount => _entities.where((e) => e.isActive).length;

  /// Dispose of the entity manager
  void dispose() {
    clear();
  }
}
