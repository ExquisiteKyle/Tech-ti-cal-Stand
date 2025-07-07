import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../shared/models/entity.dart';
import '../../../../shared/models/vector2.dart';
import '../../../../core/audio/audio_manager.dart';
import 'enemy.dart';
import 'particle.dart';

/// Enumeration of projectile types
enum ProjectileType { arrow, cannonball, magicBolt, sniperBullet }

/// Base class for all projectiles
abstract class Projectile extends Entity {
  final ProjectileType type;
  final double damage;
  final double speed;
  final Entity target;
  final Color color;
  final double maxLifetime;

  double lifetime;
  Vector2 direction;
  bool hasHitTarget;
  double lastTrailTime;

  /// Callback for when a particle emitter is created
  void Function(ParticleEmitter)? onParticleEmitterCreated;

  Projectile({
    required this.type,
    required this.damage,
    required this.speed,
    required this.target,
    required this.color,
    required this.maxLifetime,
    required super.position,
    required super.size,
  }) : lifetime = 0.0,
       direction = Vector2.zero(),
       hasHitTarget = false,
       lastTrailTime = 0.0 {
    // Calculate initial direction to target
    _calculateDirection();
    // Debug: print('Projectile created at $position targeting ${target.center}');
    // Debug: print('Projectile direction: $direction');
  }

  /// Calculate direction vector to target
  void _calculateDirection() {
    final targetPos = target.center;
    final myPos = center;

    direction = Vector2(targetPos.x - myPos.x, targetPos.y - myPos.y);
    final magnitude = direction.magnitude;

    if (magnitude > 0) {
      direction.normalize();
      // Set rotation to face target
      rotation = math.atan2(direction.y, direction.x);
    } else {
      // Debug: print('Warning: Projectile and target are at same position!');
    }
  }

  /// Check if projectile has reached its target
  bool _hasReachedTarget() {
    final distance = distanceTo(target);
    final hitRadius = 25.0; // Larger collision radius for moving targets
    return distance < hitRadius;
  }

  /// Apply damage to target and handle hit effects
  void _hitTarget() {
    if (!hasHitTarget && target.isActive) {
      // Debug: print('Projectile $type hitting target ${target.runtimeType}!');
      hasHitTarget = true;

      // Play impact sound
      final impactSound = getImpactSound();
      if (impactSound != null) {
        AudioManager().playSfx(impactSound);
      }

      // Create impact effect
      final impactEffect = createImpactEffect();
      if (impactEffect != null) {
        onParticleEmitterCreated?.call(impactEffect);
      }

      applyDamage();
      onHit();
      onDestroy();
    }
  }

  /// Get the impact sound for this projectile type (override in subclasses)
  AudioEvent? getImpactSound() => null;

  /// Create impact effect when projectile hits target (override in subclasses)
  ParticleEmitter? createImpactEffect() {
    // Default impact effect
    return ParticleEmitter(
      position: Vector2(center.x, center.y),
      type: ParticleType.sparkle,
      particleCount: 5,
      emissionRate: 0.01,
      spreadAngle: math.pi * 2,
      minSpeed: 40.0,
      maxSpeed: 100.0,
      minLifetime: 0.2,
      maxLifetime: 0.5,
      colors: [Colors.yellow, Colors.orange, Colors.white],
      minSize: 2.0,
      maxSize: 4.0,
      gravity: 20.0,
    );
  }

  /// Create projectile trail effect (override in subclasses)
  ParticleEmitter? createTrailEffect() {
    // Default trail effect
    return ParticleEmitter(
      position: Vector2(center.x, center.y),
      type: ParticleType.trail,
      particleCount: 2,
      emissionRate: 0.02,
      spreadAngle: math.pi * 0.2,
      minSpeed: 10.0,
      maxSpeed: 30.0,
      minLifetime: 0.3,
      maxLifetime: 0.6,
      colors: [color.withAlpha(150), color.withAlpha(100)],
      minSize: 1.0,
      maxSize: 3.0,
      gravity: 0.0,
    );
  }

  /// Apply damage to the target (override for different damage types)
  void applyDamage() {
    if (target is Enemy) {
      final enemy = target as Enemy;
      // Debug: print('Projectile dealing $damage damage to ${enemy.name}');
      // Debug: print('Enemy health before: ${enemy.currentHealth}');
      enemy.takeDamage(damage);
      // Debug: print('Enemy health after: ${enemy.currentHealth}');
    }
  }

  /// Called when projectile hits target (override for special effects)
  void onHit() {}

  @override
  void update(double deltaTime) {
    if (!isActive) return;

    // Update lifetime
    lifetime += deltaTime;

    // Check if projectile should be destroyed due to lifetime
    if (lifetime >= maxLifetime) {
      // Debug: print('Projectile expired after $lifetime seconds');
      onDestroy();
      return;
    }

    // Check if target is still valid
    if (!target.isActive) {
      // Debug: print('Projectile target is no longer active');
      onDestroy();
      return;
    }

    // Recalculate direction more frequently to track moving targets
    if (isHoming || lifetime < 1.0) {
      // Recalculate direction for first 1 second to track moving enemies
      _calculateDirection();
    }

    // Move projectile
    final moveDistance = speed * deltaTime;
    position = Vector2(
      position.x + direction.x * moveDistance,
      position.y + direction.y * moveDistance,
    );

    // Debug: Log projectile movement occasionally
    if (DateTime.now().millisecondsSinceEpoch % 3000 < 100) {
      print(
        'Projectile $type: speed=$speed, deltaTime=$deltaTime, moveDistance=${moveDistance.toStringAsFixed(2)}',
      );
    }

    // Create trail effect periodically
    lastTrailTime += deltaTime;
    if (lastTrailTime >= 0.05) {
      // Create trail every 0.05 seconds
      final trailEffect = createTrailEffect();
      if (trailEffect != null) {
        onParticleEmitterCreated?.call(trailEffect);
      }
      lastTrailTime = 0.0;
    }

    // final distanceToTarget = distanceTo(target);

    // Debug projectile tracking (commented out for production)
    // if (lifetime % 0.5 < deltaTime) {
    //   print('Projectile at $position, target at ${target.center}, distance: $distanceToTarget, active: ${target.isActive}');
    // }

    // Check if hit target
    if (_hasReachedTarget()) {
      // Debug: print('Projectile reached target!');
      _hitTarget();
    }
  }

  /// Whether this projectile homes in on targets
  bool get isHoming =>
      true; // Make all projectiles track targets for better hit rate

  @override
  void onDestroy() {
    // Debug: print('Projectile $type destroyed at $position');
    super.onDestroy();
  }

  @override
  void render(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw projectile based on type
    switch (type) {
      case ProjectileType.arrow:
        _drawArrow(canvas, paint);
        break;
      case ProjectileType.cannonball:
        _drawCannonball(canvas, paint);
        break;
      case ProjectileType.magicBolt:
        _drawMagicBolt(canvas, paint);
        break;
      case ProjectileType.sniperBullet:
        _drawSniperBullet(canvas, paint);
        break;
    }
  }

  /// Draw arrow projectile
  void _drawArrow(Canvas canvas, Paint paint) {
    final arrowLength = size.x;
    final arrowWidth = size.y;

    // Calculate arrow points
    final tip = Vector2(
      center.x + math.cos(rotation) * arrowLength / 2,
      center.y + math.sin(rotation) * arrowLength / 2,
    );

    final back = Vector2(
      center.x - math.cos(rotation) * arrowLength / 2,
      center.y - math.sin(rotation) * arrowLength / 2,
    );

    final feather1 = Vector2(
      back.x - math.cos(rotation + math.pi / 4) * arrowWidth / 2,
      back.y - math.sin(rotation + math.pi / 4) * arrowWidth / 2,
    );

    final feather2 = Vector2(
      back.x - math.cos(rotation - math.pi / 4) * arrowWidth / 2,
      back.y - math.sin(rotation - math.pi / 4) * arrowWidth / 2,
    );

    // Draw arrow
    final path = Path();
    path.moveTo(tip.x, tip.y);
    path.lineTo(feather1.x, feather1.y);
    path.lineTo(back.x, back.y);
    path.lineTo(feather2.x, feather2.y);
    path.close();

    canvas.drawPath(path, paint);
  }

  /// Draw cannonball projectile
  void _drawCannonball(Canvas canvas, Paint paint) {
    canvas.drawCircle(Offset(center.x, center.y), size.x / 2, paint);

    // Add shadow effect
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(50)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(center.x + 2, center.y + 2),
      size.x / 2,
      shadowPaint,
    );
  }

  /// Draw magic bolt projectile
  void _drawMagicBolt(Canvas canvas, Paint paint) {
    // Draw glowing effect
    final glowPaint = Paint()
      ..color = color.withAlpha(100)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(center.x, center.y), size.x / 2 + 3, glowPaint);

    // Draw main bolt
    canvas.drawCircle(Offset(center.x, center.y), size.x / 2, paint);
  }

  /// Draw sniper bullet projectile
  void _drawSniperBullet(Canvas canvas, Paint paint) {
    // Draw bullet trail
    final trailPaint = Paint()
      ..color = color.withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final trailStart = Vector2(
      center.x - math.cos(rotation) * 20,
      center.y - math.sin(rotation) * 20,
    );

    canvas.drawLine(
      Offset(trailStart.x, trailStart.y),
      Offset(center.x, center.y),
      trailPaint,
    );

    // Draw bullet
    canvas.drawCircle(Offset(center.x, center.y), size.x / 2, paint);
  }
}

/// Arrow projectile from Archer Tower
class Arrow extends Projectile {
  Arrow({required super.target, required super.damage, required super.position})
    : super(
        type: ProjectileType.arrow,
        speed: 300,
        color: const Color(0xFF8B4513), // Saddle Brown
        maxLifetime: 3.0,
        size: Vector2(12, 4),
      ) {
    // Debug: print('Arrow created with $damage damage targeting ${target.runtimeType}');
  }

  @override
  void applyDamage() {
    // Debug: print('Arrow applyDamage called with $damage damage');
    if (target is Enemy) {
      final enemy = target as Enemy;
      // Debug: print('Arrow hitting ${enemy.name} with $damage damage');
      // Debug: print('Enemy health before Arrow hit: ${enemy.currentHealth}');
      enemy.takeDamage(damage);
      // Debug: print('Enemy health after Arrow hit: ${enemy.currentHealth}');
    }
  }

  @override
  ParticleEmitter? createImpactEffect() {
    // Arrow creates small blood splatter on impact
    return ParticleEmitter(
      position: Vector2(center.x, center.y),
      type: ParticleType.blood,
      particleCount: 4,
      emissionRate: 0.01,
      spreadAngle: math.pi,
      minSpeed: 30.0,
      maxSpeed: 80.0,
      minLifetime: 0.3,
      maxLifetime: 0.6,
      colors: [Colors.red, Colors.red.shade800],
      minSize: 1.5,
      maxSize: 3.0,
      gravity: 40.0,
    );
  }

  @override
  ParticleEmitter? createTrailEffect() {
    // Arrow creates minimal trail
    return ParticleEmitter(
      position: Vector2(center.x, center.y),
      type: ParticleType.trail,
      particleCount: 1,
      emissionRate: 0.03,
      spreadAngle: math.pi * 0.1,
      minSpeed: 15.0,
      maxSpeed: 25.0,
      minLifetime: 0.2,
      maxLifetime: 0.4,
      colors: [color.withAlpha(120), Colors.brown.withAlpha(80)],
      minSize: 1.0,
      maxSize: 2.0,
      gravity: 0.0,
    );
  }

  @override
  AudioEvent? getImpactSound() => AudioEvent.arrowHit;
}

/// Cannonball projectile from Cannon Tower
class Cannonball extends Projectile {
  final double splashRadius;

  Cannonball({
    required super.target,
    required super.damage,
    required super.position,
    this.splashRadius = 50.0,
  }) : super(
         type: ProjectileType.cannonball,
         speed: 200,
         color: const Color(0xFF696969), // Dim Gray
         maxLifetime: 4.0,
         size: Vector2(8, 8),
       );

  @override
  void onHit() {
    // This will require access to the entity manager
    super.onHit();
  }

  @override
  ParticleEmitter? createImpactEffect() {
    // Cannonball creates explosion on impact
    return ParticleEmitter(
      position: Vector2(center.x, center.y),
      type: ParticleType.explosion,
      particleCount: 12,
      emissionRate: 0.01,
      spreadAngle: math.pi * 2,
      minSpeed: 60.0,
      maxSpeed: 150.0,
      minLifetime: 0.4,
      maxLifetime: 0.8,
      colors: [Colors.orange, Colors.red, Colors.yellow, Colors.grey],
      minSize: 3.0,
      maxSize: 8.0,
      gravity: 50.0,
    );
  }

  @override
  ParticleEmitter? createTrailEffect() {
    // Cannonball creates smoke trail
    return ParticleEmitter(
      position: Vector2(center.x, center.y),
      type: ParticleType.smoke,
      particleCount: 2,
      emissionRate: 0.02,
      spreadAngle: math.pi * 0.3,
      minSpeed: 20.0,
      maxSpeed: 40.0,
      minLifetime: 0.5,
      maxLifetime: 1.0,
      colors: [Colors.grey, Colors.grey.shade600],
      minSize: 2.0,
      maxSize: 5.0,
      gravity: -10.0, // Float upward
    );
  }

  @override
  AudioEvent? getImpactSound() => AudioEvent.explosionHit;
}

/// Magic bolt projectile from Magic Tower
class MagicBolt extends Projectile {
  final double slowStrength;
  final double slowDuration;

  MagicBolt({
    required super.target,
    required super.damage,
    required super.position,
    this.slowStrength = 0.5,
    this.slowDuration = 2.0,
  }) : super(
         type: ProjectileType.magicBolt,
         speed: 250,
         color: const Color(0xFF9370DB), // Medium Purple
         maxLifetime: 3.5,
         size: Vector2(10, 10),
       );

  @override
  bool get isHoming => true;

  @override
  void applyDamage() {
    super.applyDamage();

    // Apply slow effect
    if (target is Enemy) {
      (target as Enemy).applySlow(slowStrength, slowDuration);
    }
  }

  @override
  ParticleEmitter? createImpactEffect() {
    // Magic bolt creates magical sparkles on impact
    return ParticleEmitter(
      position: Vector2(center.x, center.y),
      type: ParticleType.magic,
      particleCount: 8,
      emissionRate: 0.01,
      spreadAngle: math.pi * 2,
      minSpeed: 50.0,
      maxSpeed: 120.0,
      minLifetime: 0.3,
      maxLifetime: 0.7,
      colors: [Colors.purple, Colors.pink, Colors.blue, Colors.white],
      minSize: 2.0,
      maxSize: 5.0,
      gravity: -20.0, // Float upward
    );
  }

  @override
  ParticleEmitter? createTrailEffect() {
    // Magic bolt creates magical trail
    return ParticleEmitter(
      position: Vector2(center.x, center.y),
      type: ParticleType.sparkle,
      particleCount: 3,
      emissionRate: 0.02,
      spreadAngle: math.pi * 0.4,
      minSpeed: 20.0,
      maxSpeed: 50.0,
      minLifetime: 0.4,
      maxLifetime: 0.8,
      colors: [Colors.purple.withAlpha(150), Colors.pink.withAlpha(120)],
      minSize: 1.5,
      maxSize: 3.5,
      gravity: -15.0, // Float upward
    );
  }

  @override
  AudioEvent? getImpactSound() => AudioEvent.magicHit;
}

/// Sniper bullet projectile from Sniper Tower
class SniperBullet extends Projectile {
  final bool isCritical;
  final double armorPenetration;

  SniperBullet({
    required super.target,
    required super.damage,
    required super.position,
    this.isCritical = false,
    this.armorPenetration = 0.0,
  }) : super(
         type: ProjectileType.sniperBullet,
         speed: 800,
         color: const Color(0xFFFFD700), // Gold
         maxLifetime: 2.0,
         size: Vector2(6, 6),
       );

  @override
  void applyDamage() {
    if (target is Enemy) {
      final enemy = target as Enemy;

      // Calculate final damage with armor penetration
      final effectiveArmor = enemy.armor * (1 - armorPenetration);
      final finalDamage = damage * (1 - effectiveArmor / 100);

      // Apply critical hit multiplier
      final criticalDamage = isCritical ? finalDamage * 2.0 : finalDamage;

      enemy.currentHealth -= criticalDamage;

      if (enemy.currentHealth <= 0) {
        enemy.onDestroy();
      }
    }
  }

  @override
  ParticleEmitter? createImpactEffect() {
    // Sniper bullet creates precise impact with sparks
    return ParticleEmitter(
      position: Vector2(center.x, center.y),
      type: ParticleType.sparkle,
      particleCount: isCritical ? 10 : 6,
      emissionRate: 0.01,
      spreadAngle: math.pi,
      minSpeed: 80.0,
      maxSpeed: 180.0,
      minLifetime: 0.2,
      maxLifetime: 0.5,
      colors: isCritical
          ? [Colors.yellow, Colors.orange, Colors.red, Colors.white]
          : [Colors.yellow, Colors.white, Colors.lightGreen],
      minSize: isCritical ? 3.0 : 2.0,
      maxSize: isCritical ? 6.0 : 4.0,
      gravity: 30.0,
    );
  }

  @override
  ParticleEmitter? createTrailEffect() {
    // Sniper bullet creates fast, precise trail
    return ParticleEmitter(
      position: Vector2(center.x, center.y),
      type: ParticleType.trail,
      particleCount: 1,
      emissionRate: 0.01,
      spreadAngle: math.pi * 0.05, // Very focused
      minSpeed: 10.0,
      maxSpeed: 20.0,
      minLifetime: 0.1,
      maxLifetime: 0.2,
      colors: [Colors.yellow.withAlpha(180), Colors.white.withAlpha(120)],
      minSize: 1.0,
      maxSize: 2.0,
      gravity: 0.0,
    );
  }

  @override
  AudioEvent? getImpactSound() => AudioEvent.arrowHit; // Similar to arrow for now
}
