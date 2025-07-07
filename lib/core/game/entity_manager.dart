import 'package:flutter/material.dart';
import '../../shared/models/entity.dart';
import '../../shared/models/vector2.dart';
import '../../features/game/domain/models/particle.dart';
import '../../features/game/domain/models/tower.dart';
import '../../features/game/domain/models/enemy.dart';
import '../../features/game/domain/models/projectile.dart';

/// Manages all game entities (towers, enemies, projectiles)
class EntityManager {
  final List<Entity> _entities = [];
  final List<Entity> _entitiesToAdd = [];
  final List<String> _entitiesToRemove = [];
  final ParticleSystem _particleSystem = ParticleSystem();

  // Performance optimization: track if entities have changed
  bool _hasChanged = false;

  // Performance optimization: cached entity lists
  List<Tower>? _cachedTowers;
  List<Enemy>? _cachedEnemies;
  List<Projectile>? _cachedProjectiles;
  int _lastCacheFrame = 0;

  // Performance optimization: spatial partitioning for collision detection
  static const int _gridSize = 100; // 100px grid cells
  final Map<String, List<Entity>> _spatialGrid = {};

  // Performance optimization: collision detection throttling
  int _collisionFrame = 0;
  static const int _collisionCheckInterval =
      3; // Check collisions every 3 frames

  /// Get all active entities
  List<Entity> get entities => _entities.where((e) => e.isActive).toList();

  /// Get entities of a specific type (with caching)
  List<T> getEntitiesOfType<T extends Entity>() {
    // Update cache if needed
    _updateCache();

    // Use cached lists for common types to avoid repeated filtering
    if (T == Tower && _cachedTowers != null) {
      return _cachedTowers!.cast<T>();
    }
    if (T == Enemy && _cachedEnemies != null) {
      return _cachedEnemies!.cast<T>();
    }
    if (T == Projectile && _cachedProjectiles != null) {
      return _cachedProjectiles!.cast<T>();
    }

    // Fallback to filtering
    return _entities.whereType<T>().where((e) => e.isActive).toList();
  }

  /// Add an entity to the manager
  void addEntity(Entity entity) {
    _entitiesToAdd.add(entity);
    _hasChanged = true;
    _invalidateCache();
  }

  /// Remove an entity by ID
  void removeEntity(String entityId) {
    _entitiesToRemove.add(entityId);
    _hasChanged = true;
    _invalidateCache();
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

    // Invalidate cache when entities change
    if (_entitiesToAdd.isNotEmpty || _entitiesToRemove.isNotEmpty) {
      _invalidateCache();
    }
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

    // Update particle system (with reduced frequency for performance)
    if (_collisionFrame % 2 == 0) {
      // Update particles every other frame
      _particleSystem.update(deltaTime);
    }

    // Mark as changed if any entities are active
    if (_entities.any((e) => e.isActive)) {
      _hasChanged = true;
    }

    _collisionFrame++;
  }

  /// Render all visible entities
  void render(Canvas canvas, Size canvasSize) {
    for (final entity in _entities) {
      if (entity.isActive && entity.isVisible) {
        entity.render(canvas, canvasSize);
      }
    }

    // Render particle effects on top (with reduced frequency)
    if (_collisionFrame % 2 == 0) {
      _particleSystem.render(canvas, canvasSize);
    }
  }

  /// Check collisions between entities (optimized with spatial partitioning)
  void checkCollisions() {
    // Only check collisions every few frames for performance
    if (_collisionFrame % _collisionCheckInterval != 0) return;

    // Clear spatial grid
    _spatialGrid.clear();

    // Populate spatial grid with active entities
    for (final entity in _entities) {
      if (!entity.isActive) continue;

      final gridX = (entity.center.x / _gridSize).floor();
      final gridY = (entity.center.y / _gridSize).floor();
      final gridKey = '$gridX,$gridY';

      _spatialGrid.putIfAbsent(gridKey, () => []).add(entity);
    }

    // Check collisions only within nearby grid cells
    for (final entity in _entities) {
      if (!entity.isActive) continue;

      final gridX = (entity.center.x / _gridSize).floor();
      final gridY = (entity.center.y / _gridSize).floor();

      // Check current cell and adjacent cells
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          final checkGridX = gridX + dx;
          final checkGridY = gridY + dy;
          final gridKey = '$checkGridX,$checkGridY';

          final nearbyEntities = _spatialGrid[gridKey];
          if (nearbyEntities == null) continue;

          for (final otherEntity in nearbyEntities) {
            if (otherEntity.id == entity.id || !otherEntity.isActive) continue;

            if (entity.intersects(otherEntity)) {
              entity.onCollision(otherEntity);
              otherEntity.onCollision(entity);
            }
          }
        }
      }
    }
  }

  /// Invalidate cached entity lists
  void _invalidateCache() {
    _cachedTowers = null;
    _cachedEnemies = null;
    _cachedProjectiles = null;
  }

  /// Update cached entity lists
  void _updateCache() {
    if (_lastCacheFrame == _collisionFrame) return;

    _cachedTowers = _entities
        .whereType<Tower>()
        .where((e) => e.isActive)
        .toList();
    _cachedEnemies = _entities
        .whereType<Enemy>()
        .where((e) => e.isActive)
        .toList();
    _cachedProjectiles = _entities
        .whereType<Projectile>()
        .where((e) => e.isActive)
        .toList();
    _lastCacheFrame = _collisionFrame;
  }

  /// Find entity by ID
  Entity? findEntityById(String id) {
    try {
      return _entities.firstWhere((entity) => entity.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get entities within a radius of a point (optimized)
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
    _spatialGrid.clear();
    _invalidateCache();
  }

  /// Get total entity count
  int get entityCount => _entities.length;

  /// Get active entity count
  int get activeEntityCount => _entities.where((e) => e.isActive).length;

  /// Check if entities have changed (for rendering optimization)
  bool get hasChanged => _hasChanged;

  /// Reset the change flag (called after rendering)
  void resetChangeFlag() {
    _hasChanged = false;
  }

  /// Dispose of the entity manager
  void dispose() {
    clear();
  }
}
