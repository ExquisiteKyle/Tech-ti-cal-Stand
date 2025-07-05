import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../shared/models/entity.dart';
import '../../../../shared/models/vector2.dart';

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
       hasReachedEnd = false;

  /// Get the color associated with this enemy type
  Color get enemyColor;

  /// Get health percentage (0.0 to 1.0)
  double get healthPercentage => currentHealth / maxHealth;

  /// Check if enemy is alive
  bool get isAlive => currentHealth > 0;

  /// Check if enemy has reached the end
  bool get reachedEnd => hasReachedEnd;

  /// Take damage from tower attacks
  void takeDamage(double damage) {
    final finalDamage = damage * (1 - armor / 100);
    print(
      '${name} taking ${finalDamage} damage (${damage} before armor reduction)',
    );
    currentHealth -= finalDamage;
    print('${name} health: ${currentHealth}/${maxHealth}');

    if (currentHealth <= 0) {
      currentHealth = 0;
      print('${name} has been eliminated! Calling onDestroy()');
      onDestroy();
      print('${name} isActive after onDestroy: ${isActive}');
    }
  }

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

    // Move towards next waypoint
    if (currentWaypointIndex < waypoints.length) {
      _moveTowardsWaypoint(deltaTime);
    } else {
      // Reached the end
      hasReachedEnd = true;
      onDestroy();
    }
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

  /// Move towards the next waypoint
  void _moveTowardsWaypoint(double deltaTime) {
    if (currentWaypointIndex >= waypoints.length) return;

    final target = waypoints[currentWaypointIndex];
    final direction = Vector2(target.x - position.x, target.y - position.y);
    final distance = direction.magnitude;

    if (distance < 5.0) {
      // Reached current waypoint, move to next
      currentWaypointIndex++;
      print('${name} reached waypoint ${currentWaypointIndex}, moving to next');
      return;
    }

    // Normalize direction and move
    direction.normalize();
    final moveDistance = currentSpeed * deltaTime;

    final oldPosition = Vector2(position.x, position.y);
    position = Vector2(
      position.x + direction.x * moveDistance,
      position.y + direction.y * moveDistance,
    );

    // Update rotation to face movement direction
    rotation = math.atan2(direction.y, direction.x);

    // Debug enemy movement occasionally
    if (DateTime.now().millisecondsSinceEpoch % 1000 < 50) {
      // Log roughly every second
      print(
        '${name} moving from ${oldPosition} to ${position}, speed: ${currentSpeed}',
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
        baseSpeed: 80,
        armor: 0,
        goldReward: 15, // Increased from 10 to 15
        name: 'Goblin',
        description: 'Fast movement, low health',
        size: Vector2(20, 20),
      );

  @override
  Color get enemyColor => const Color(0xFF8FBC8F); // Dark Sea Green
}

/// Orc - Balanced stats enemy
class Orc extends Enemy {
  Orc({required super.waypoints, required super.position})
    : super(
        type: EnemyType.orc,
        maxHealth: 150,
        baseSpeed: 60,
        armor: 10,
        goldReward: 35, // Increased from 25 to 35
        name: 'Orc',
        description: 'Balanced stats, medium difficulty',
        size: Vector2(25, 25),
      );

  @override
  Color get enemyColor => const Color(0xFF8B4513); // Saddle Brown
}

/// Troll - High health, slow enemy
class Troll extends Enemy {
  Troll({required super.waypoints, required super.position})
    : super(
        type: EnemyType.troll,
        maxHealth: 250, // Reduced from 300 to 250 for better balance
        baseSpeed: 35, // Reduced from 40 to 35 for slower movement
        armor: 20, // Reduced from 25 to 20 for less armor
        goldReward: 75, // Increased from 50 to 75
        name: 'Troll',
        description: 'High health, slow movement',
        size: Vector2(30, 30),
      );

  @override
  Color get enemyColor => const Color(0xFF696969); // Dim Gray
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
        baseSpeed: 25, // Reduced from 30 to 25 for slower movement
        armor: 40, // Reduced from 50 to 40 for less armor
        goldReward: 200,
        name: 'Boss',
        description: 'Massive health, special abilities',
        size: Vector2(40, 40),
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
}
