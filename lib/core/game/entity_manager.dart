import 'package:flutter/material.dart';
import '../../shared/models/entity.dart';
import '../../shared/models/vector2.dart';
import '../../features/game/domain/models/particle.dart';

/// Manages all game entities (towers, enemies, projectiles)
class EntityManager {
  final List<Entity> _entities = [];
  final List<Entity> _entitiesToAdd = [];
  final List<String> _entitiesToRemove = [];
  final ParticleSystem _particleSystem = ParticleSystem();

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

  /// Process entity additions and removals without updating entity logic
  void processAdditionsAndRemovals() {
    // Process additions
    _entities.addAll(_entitiesToAdd);
    _entitiesToAdd.clear();

    // Process removals
    for (final id in _entitiesToRemove) {
      _entities.removeWhere((entity) => entity.id == id);
    }
    _entitiesToRemove.clear();

    // Remove inactive entities
    _entities.removeWhere((entity) => !entity.isActive);
  }

  /// Update all entities
  void update(double deltaTime) {
    // Process additions and removals first
    processAdditionsAndRemovals();

    // Update active entities
    for (final entity in _entities) {
      if (entity.isActive) {
        entity.update(deltaTime);
      }
    }

    // Update particle system
    _particleSystem.update(deltaTime);
  }

  /// Render all visible entities
  void render(Canvas canvas, Size canvasSize) {
    for (final entity in _entities) {
      if (entity.isActive && entity.isVisible) {
        entity.render(canvas, canvasSize);
      }
    }

    // Render particle effects on top
    _particleSystem.render(canvas, canvasSize);
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

  /// Add a particle emitter to the system
  void addParticleEmitter(ParticleEmitter emitter) {
    _particleSystem.addEmitter(emitter);
  }

  /// Add a single particle to the system
  void addParticle(Particle particle) {
    _particleSystem.addParticle(particle);
  }

  /// Get particle system for external access
  ParticleSystem get particleSystem => _particleSystem;

  /// Clear all entities
  void clear() {
    for (final entity in _entities) {
      entity.onDestroy();
    }
    _entities.clear();
    _entitiesToAdd.clear();
    _entitiesToRemove.clear();
    _particleSystem.clear();
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
