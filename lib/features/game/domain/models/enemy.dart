import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../shared/models/entity.dart';
import '../../../../shared/models/vector2.dart';
import 'particle.dart';

/// Enumeration of enemy types
enum EnemyType { goblin, orc, troll, boss }

/// Status effect types
enum StatusEffectType { slow, poison, freeze, burn }

/// Status effect class
class StatusEffect {
  final StatusEffectType type;
  final double strength;
  final double duration;
  final double timeRemaining;

  StatusEffect({
    required this.type,
    required this.strength,
    required this.duration,
    required this.timeRemaining,
  });

  StatusEffect copyWith({
    StatusEffectType? type,
    double? strength,
    double? duration,
    double? timeRemaining,
  }) => StatusEffect(
    type: type ?? this.type,
    strength: strength ?? this.strength,
    duration: duration ?? this.duration,
    timeRemaining: timeRemaining ?? this.timeRemaining,
  );
}

/// Base class for all enemies
abstract class Enemy extends Entity {
  final EnemyType type;
  final double maxHealth;
  final double baseSpeed;
  final double armor;
  final int goldReward;
  final String name;
  final String description;

  double currentHealth;
  double currentSpeed;
  List<StatusEffect> statusEffects;
  List<Vector2> waypoints;
  int currentWaypointIndex;
  double distanceToNextWaypoint;
  bool hasReachedEnd;

  // Path-following system
  double pathProgress; // Distance traveled along the entire path
  double totalPathLength;

  /// Callback for when a particle emitter is created
  void Function(ParticleEmitter)? onParticleEmitterCreated;

  Enemy({
    required this.type,
    required this.maxHealth,
    required this.baseSpeed,
    required this.armor,
    required this.goldReward,
    required this.name,
    required this.description,
    required this.waypoints,
    required super.position,
    required super.size,
  }) : currentHealth = maxHealth,
       currentSpeed = baseSpeed,
       statusEffects = [],
       currentWaypointIndex = 0,
       distanceToNextWaypoint = 0,
       hasReachedEnd = false,
       pathProgress = 0.0,
       totalPathLength = _calculatePathLength(waypoints);

  /// Get the color associated with this enemy type
  Color get enemyColor;

  /// Get health percentage (0.0 to 1.0)
  double get healthPercentage => currentHealth / maxHealth;

  /// Calculate total path length from waypoints
  static double _calculatePathLength(List<Vector2> waypoints) {
    if (waypoints.length < 2) return 0.0;

    double totalLength = 0.0;
    for (int i = 1; i < waypoints.length; i++) {
      totalLength += waypoints[i - 1].distanceTo(waypoints[i]);
    }
    return totalLength;
  }

  /// Check if enemy is alive
  bool get isAlive => currentHealth > 0;

  /// Check if enemy has reached the end
  bool get reachedEnd => hasReachedEnd;

  /// Take damage from tower attacks
  void takeDamage(double damage) {
    final finalDamage = damage * (1 - armor / 100);
    // Debug damage calculation
    // print('$name taking $finalDamage damage ($damage before armor reduction)');
    currentHealth -= finalDamage;
    // print('$name health: $currentHealth/$maxHealth');

    if (currentHealth <= 0) {
      currentHealth = 0;
      // Debug: print('$name has been eliminated! Creating death effects');

      // Create death particle effects
      final deathEffects = createDeathEffects();
      for (final effect in deathEffects) {
        onParticleEmitterCreated?.call(effect);
      }

      // Debug: print('$name has been eliminated! Calling onDestroy()');
      onDestroy();
      // Debug: print('$name isActive after onDestroy: $isActive');
    }
  }

  /// Create death particle effects (override in subclasses)
  List<ParticleEmitter> createDeathEffects();

  /// Apply status effect to enemy
  void applyStatusEffect(StatusEffect effect) {
    // Remove existing effect of same type
    statusEffects.removeWhere((e) => e.type == effect.type);

    // Add new effect
    statusEffects.add(effect);

    // Apply immediate effect
    switch (effect.type) {
      case StatusEffectType.slow:
        currentSpeed = baseSpeed * (1 - effect.strength);
        break;
      case StatusEffectType.freeze:
        currentSpeed = 0;
        break;
      case StatusEffectType.poison:
      case StatusEffectType.burn:
        // Damage over time effects handled in update
        break;
    }
  }

  /// Apply slow effect (convenience method)
  void applySlow(double slowAmount, double duration) {
    applyStatusEffect(
      StatusEffect(
        type: StatusEffectType.slow,
        strength: slowAmount,
        duration: duration,
        timeRemaining: duration,
      ),
    );
  }

  /// Apply poison effect
  void applyPoison(double damagePerSecond, double duration) {
    applyStatusEffect(
      StatusEffect(
        type: StatusEffectType.poison,
        strength: damagePerSecond,
        duration: duration,
        timeRemaining: duration,
      ),
    );
  }

  /// Update enemy movement and status effects
  @override
  void update(double deltaTime) {
    if (!isAlive) return;

    // Update status effects
    _updateStatusEffects(deltaTime);

    // Move along the path
    _moveTowardsWaypoint(deltaTime);
  }

  /// Update status effects and their timers
  void _updateStatusEffects(double deltaTime) {
    final effectsToRemove = <StatusEffect>[];

    for (final effect in statusEffects) {
      final updatedEffect = effect.copyWith(
        timeRemaining: effect.timeRemaining - deltaTime,
      );

      if (updatedEffect.timeRemaining <= 0) {
        effectsToRemove.add(effect);
      } else {
        // Apply damage over time effects
        if (effect.type == StatusEffectType.poison ||
            effect.type == StatusEffectType.burn) {
          takeDamage(effect.strength * deltaTime);
        }
      }
    }

    // Remove expired effects
    for (final effect in effectsToRemove) {
      statusEffects.remove(effect);
    }

    // Recalculate current speed based on remaining effects
    currentSpeed = baseSpeed;
    for (final effect in statusEffects) {
      if (effect.type == StatusEffectType.slow) {
        currentSpeed = baseSpeed * (1 - effect.strength);
      } else if (effect.type == StatusEffectType.freeze) {
        currentSpeed = 0;
      }
    }
  }

  /// Move along the path using distance-based progression
  void _moveTowardsWaypoint(double deltaTime) {
    if (waypoints.length < 2 || totalPathLength <= 0) return;

    // Calculate how far to move this frame
    final moveDistance = currentSpeed * deltaTime;

    // Clamp movement to prevent teleporting (max 5 pixels per frame)
    final clampedMoveDistance = math.min(moveDistance, 5.0);

    // Advance progress along the path
    pathProgress += clampedMoveDistance;

    // Check if reached the end
    if (pathProgress >= totalPathLength) {
      hasReachedEnd = true;
      // Don't call onDestroy() here - let the game engine handle it
      // This ensures the game engine can detect the enemy and reduce player health
      return;
    }

    // Calculate current position based on path progress
    final newPosition = _getPositionAtProgress(pathProgress);
    // final oldPosition = Vector2(position.x, position.y);

    if (newPosition != null) {
      // Calculate direction for rotation
      final direction = Vector2(
        newPosition.x - position.x,
        newPosition.y - position.y,
      );

      if (direction.magnitude > 0.1) {
        rotation = math.atan2(direction.y, direction.x);
      }

      // Set the new position (guaranteed to be on the path)
      position = newPosition;

      // Apply position correction to ensure perfect centering
      _applyPositionCorrection();

      // Debug enemy movement occasionally
      // if (DateTime.now().millisecondsSinceEpoch % 2000 < 100) {
      //   print('$name moving from $oldPosition to $position, progress: ${pathProgress.toStringAsFixed(1)}/${totalPathLength.toStringAsFixed(1)}, speed: ${currentSpeed.toStringAsFixed(1)}');
      // }
    }
  }

  /// Get position at specific progress along the path
  Vector2? _getPositionAtProgress(double progress) {
    if (waypoints.length < 2 || progress < 0) return null;

    if (progress >= totalPathLength) {
      // Center the enemy at the last waypoint
      final lastWaypoint = waypoints.last;
      return Vector2(lastWaypoint.x - size.x / 2, lastWaypoint.y - size.y / 2);
    }

    // Find which segment we're in
    double accumulatedDistance = 0.0;

    for (int i = 0; i < waypoints.length - 1; i++) {
      final segmentStart = waypoints[i];
      final segmentEnd = waypoints[i + 1];
      final segmentLength = segmentStart.distanceTo(segmentEnd);

      if (progress <= accumulatedDistance + segmentLength) {
        // We're in this segment
        final segmentProgress = progress - accumulatedDistance;
        final t = segmentProgress / segmentLength;

        // Linear interpolation between waypoints
        final centerPos = Vector2(
          segmentStart.x + (segmentEnd.x - segmentStart.x) * t,
          segmentStart.y + (segmentEnd.y - segmentStart.y) * t,
        );

        // Adjust position so enemy center is at waypoint (not top-left corner)
        return Vector2(centerPos.x - size.x / 2, centerPos.y - size.y / 2);
      }

      accumulatedDistance += segmentLength;
    }

    // Fallback to last waypoint (centered)
    final lastWaypoint = waypoints.last;
    return Vector2(lastWaypoint.x - size.x / 2, lastWaypoint.y - size.y / 2);
  }

  /// Apply position correction to ensure perfect centering on path
  void _applyPositionCorrection() {
    // Get the exact position that should be at current progress
    final exactPosition = _getPositionAtProgress(pathProgress);
    if (exactPosition == null) return;

    // Calculate the drift distance
    final drift = position.distanceTo(exactPosition);

    // If drift is more than 0.5 pixels, correct it
    if (drift > 0.5) {
      // Smoothly correct the position instead of snapping
      final correctionFactor =
          0.1; // Adjust this value to control correction strength
      position = Vector2(
        position.x + (exactPosition.x - position.x) * correctionFactor,
        position.y + (exactPosition.y - position.y) * correctionFactor,
      );
    }
  }

  /// Render enemy on canvas
  @override
  void render(Canvas canvas, Size canvasSize) {
    // Draw enemy body
    final paint = Paint()
      ..color = enemyColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(center.x, center.y), size.x / 2, paint);

    // Draw enemy border
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(Offset(center.x, center.y), size.x / 2, borderPaint);

    // Draw health bar
    _drawHealthBar(canvas);

    // Draw status effect indicators
    _drawStatusEffects(canvas);
  }

  /// Draw health bar above enemy
  void _drawHealthBar(Canvas canvas) {
    const barWidth = 30.0;
    const barHeight = 4.0;
    final barX = center.x - barWidth / 2;
    final barY = center.y - size.y / 2 - 10;

    // Background
    final bgPaint = Paint()
      ..color = Colors.red.withAlpha(100)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(barX, barY, barWidth, barHeight), bgPaint);

    // Health
    final healthPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth * healthPercentage, barHeight),
      healthPaint,
    );

    // Border
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth, barHeight),
      borderPaint,
    );
  }

  /// Draw status effect indicators
  void _drawStatusEffects(Canvas canvas) {
    if (statusEffects.isEmpty) return;

    const iconSize = 8.0;
    const spacing = 10.0;
    final startX = center.x - (statusEffects.length * spacing) / 2;
    final iconY = center.y + size.y / 2 + 5;

    for (int i = 0; i < statusEffects.length; i++) {
      final effect = statusEffects[i];
      final iconX = startX + i * spacing;

      Color iconColor;
      switch (effect.type) {
        case StatusEffectType.slow:
          iconColor = Colors.blue;
          break;
        case StatusEffectType.poison:
          iconColor = Colors.green;
          break;
        case StatusEffectType.freeze:
          iconColor = Colors.cyan;
          break;
        case StatusEffectType.burn:
          iconColor = Colors.orange;
          break;
      }

      final iconPaint = Paint()
        ..color = iconColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(iconX, iconY), iconSize / 2, iconPaint);
    }
  }
}

/// Goblin - Fast, low health enemy
class Goblin extends Enemy {
  Goblin({required super.waypoints, required super.position})
    : super(
        type: EnemyType.goblin,
        maxHealth: 50,
        baseSpeed: 40, // Reduced from 80 to 40 to prevent teleporting
        armor: 0,
        goldReward: 15, // Increased from 10 to 15
        name: 'Goblin',
        description: 'Fast movement, low health',
        size: Vector2(12, 12), // Reduced from 20x20 to 12x12
      );

  @override
  Color get enemyColor => const Color(0xFF8FBC8F); // Dark Sea Green

  @override
  List<ParticleEmitter> createDeathEffects() {
    // Goblin creates small blood splatter and green sparkles
    return [
      ParticleSystem.createBloodSplatter(
        position: Vector2(center.x, center.y),
        particleCount: 5,
      ),
      ParticleEmitter(
        position: Vector2(center.x, center.y),
        type: ParticleType.sparkle,
        particleCount: 8,
        emissionRate: 0.01,
        spreadAngle: math.pi * 2,
        minSpeed: 40.0,
        maxSpeed: 100.0,
        minLifetime: 0.5,
        maxLifetime: 1.2,
        colors: [Colors.green, Colors.lightGreen, Colors.white],
        minSize: 2.0,
        maxSize: 4.0,
        gravity: 30.0,
      ),
    ];
  }
}

/// Orc - Balanced stats enemy
class Orc extends Enemy {
  Orc({required super.waypoints, required super.position})
    : super(
        type: EnemyType.orc,
        maxHealth: 150,
        baseSpeed: 30, // Reduced from 60 to 30 to prevent teleporting
        armor: 10,
        goldReward: 35, // Increased from 25 to 35
        name: 'Orc',
        description: 'Balanced stats, medium difficulty',
        size: Vector2(14, 14), // Reduced from 25x25 to 14x14
      );

  @override
  Color get enemyColor => const Color(0xFF8B4513); // Saddle Brown

  @override
  List<ParticleEmitter> createDeathEffects() {
    // Orc creates medium blood splatter and brown smoke
    return [
      ParticleSystem.createBloodSplatter(
        position: Vector2(center.x, center.y),
        particleCount: 8,
      ),
      ParticleEmitter(
        position: Vector2(center.x, center.y),
        type: ParticleType.smoke,
        particleCount: 6,
        emissionRate: 0.01,
        spreadAngle: math.pi,
        minSpeed: 20.0,
        maxSpeed: 60.0,
        minLifetime: 0.8,
        maxLifetime: 1.5,
        colors: [Colors.brown, Colors.grey, Colors.black],
        minSize: 4.0,
        maxSize: 8.0,
        gravity: -15.0, // Float upward
      ),
    ];
  }
}

/// Troll - High health, slow enemy
class Troll extends Enemy {
  Troll({required super.waypoints, required super.position})
    : super(
        type: EnemyType.troll,
        maxHealth: 250, // Reduced from 300 to 250 for better balance
        baseSpeed: 20, // Reduced from 35 to 20 to prevent teleporting
        armor: 20, // Reduced from 25 to 20 for less armor
        goldReward: 75, // Increased from 50 to 75
        name: 'Troll',
        description: 'High health, slow movement',
        size: Vector2(15, 15), // Reduced from 30x30 to 15x15
      );

  @override
  Color get enemyColor => const Color(0xFF696969); // Dim Gray

  @override
  List<ParticleEmitter> createDeathEffects() {
    // Troll creates large explosion with rocks and debris
    return [
      ParticleSystem.createExplosion(
        position: Vector2(center.x, center.y),
        particleCount: 15,
        size: 10.0,
      ),
      ParticleEmitter(
        position: Vector2(center.x, center.y),
        type: ParticleType.trail,
        particleCount: 12,
        emissionRate: 0.01,
        spreadAngle: math.pi * 2,
        minSpeed: 60.0,
        maxSpeed: 150.0,
        minLifetime: 1.0,
        maxLifetime: 2.0,
        colors: [Colors.grey, Colors.brown, Colors.black],
        minSize: 3.0,
        maxSize: 7.0,
        gravity: 80.0, // Heavy debris falls
      ),
    ];
  }
}

/// Boss - Massive health, special abilities
class Boss extends Enemy {
  double specialAbilityCooldown;
  double timeSinceLastSpecial;

  Boss({required super.waypoints, required super.position})
    : specialAbilityCooldown = 5.0,
      timeSinceLastSpecial = 0.0,
      super(
        type: EnemyType.boss,
        maxHealth: 600, // Reduced from 1000 to 600 for balance
        baseSpeed: 15, // Reduced from 25 to 15 to prevent teleporting
        armor: 40, // Reduced from 50 to 40 for less armor
        goldReward: 200,
        name: 'Boss',
        description: 'Massive health, special abilities',
        size: Vector2(16, 16), // Reduced from 40x40 to 16x16
      );

  @override
  Color get enemyColor => const Color(0xFF800080); // Purple

  @override
  void update(double deltaTime) {
    super.update(deltaTime);

    // Update special ability cooldown
    timeSinceLastSpecial += deltaTime;

    // Use special ability if available
    if (timeSinceLastSpecial >= specialAbilityCooldown) {
      _useSpecialAbility();
      timeSinceLastSpecial = 0.0;
    }
  }

  /// Boss special ability - heal over time
  void _useSpecialAbility() {
    // Heal 5% of max health
    final healAmount = maxHealth * 0.05;
    currentHealth = math.min(currentHealth + healAmount, maxHealth);
  }

  @override
  void render(Canvas canvas, Size canvasSize) {
    super.render(canvas, canvasSize);

    // Draw boss crown indicator
    final crownPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;

    final crownSize = 8.0;
    final crownX = center.x;
    final crownY = center.y - size.y / 2 - 15;

    // Draw simple crown shape
    canvas.drawCircle(Offset(crownX, crownY), crownSize / 2, crownPaint);

    // Draw crown points
    for (int i = 0; i < 3; i++) {
      final pointX = crownX - 6 + i * 6;
      final pointY = crownY - 4;
      canvas.drawCircle(Offset(pointX, pointY), 2, crownPaint);
    }
  }

  @override
  List<ParticleEmitter> createDeathEffects() {
    // Boss creates massive purple explosion with magical effects
    return [
      ParticleSystem.createExplosion(
        position: Vector2(center.x, center.y),
        particleCount: 25,
        size: 15.0,
      ),
      ParticleSystem.createMagicSparkles(
        position: Vector2(center.x, center.y),
        particleCount: 20,
      ),
      ParticleEmitter(
        position: Vector2(center.x, center.y),
        type: ParticleType.magic,
        particleCount: 15,
        emissionRate: 0.01,
        spreadAngle: math.pi * 2,
        minSpeed: 80.0,
        maxSpeed: 200.0,
        minLifetime: 1.5,
        maxLifetime: 3.0,
        colors: [Colors.purple, Colors.pink, Colors.blue, Colors.white],
        minSize: 5.0,
        maxSize: 12.0,
        gravity: -40.0, // Magical energy rises
      ),
    ];
  }
}
