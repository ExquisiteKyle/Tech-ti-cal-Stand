import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../shared/models/entity.dart';
import '../../../../shared/models/vector2.dart';

/// Enumeration of particle types
enum ParticleType {
  explosion,
  smoke,
  sparkle,
  trail,
  blood,
  magic,
  fire,
  ice,
  electric,
}

/// Individual particle entity
class Particle extends Entity {
  final ParticleType type;
  final Color color;
  final double maxLifetime;
  final Vector2 velocity;
  final double gravity;
  final double fadeRate;
  final double shrinkRate;

  double currentLifetime;
  double alpha;
  double currentSize;

  Particle({
    required this.type,
    required this.color,
    required this.maxLifetime,
    required this.velocity,
    required super.position,
    required super.size,
    this.gravity = 0.0,
    this.fadeRate = 1.0,
    this.shrinkRate = 0.0,
  }) : currentLifetime = 0.0,
       alpha = 1.0,
       currentSize = size.x;

  @override
  void update(double deltaTime) {
    currentLifetime += deltaTime;

    // Update position based on velocity and gravity
    position = Vector2(
      position.x + velocity.x * deltaTime,
      position.y + velocity.y * deltaTime + gravity * deltaTime * deltaTime / 2,
    );

    // Update velocity with gravity
    velocity.y += gravity * deltaTime;

    // Update alpha based on lifetime
    final lifeProgress = currentLifetime / maxLifetime;
    alpha = math.max(0.0, 1.0 - lifeProgress * fadeRate);

    // Update size based on shrink rate
    if (shrinkRate > 0) {
      currentSize = math.max(0.0, size.x - shrinkRate * currentLifetime);
    }

    // Remove particle when lifetime is exceeded or fully faded
    if (currentLifetime >= maxLifetime || alpha <= 0.0) {
      onDestroy();
    }
  }

  @override
  void render(Canvas canvas, Size canvasSize) {
    if (alpha <= 0.0) return;

    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    // Performance optimization: Simplified rendering for most particle types
    switch (type) {
      case ParticleType.explosion:
      case ParticleType.fire:
      case ParticleType.smoke:
      case ParticleType.trail:
      case ParticleType.blood:
        // Draw as simple circle (fastest rendering)
        canvas.drawCircle(Offset(position.x, position.y), currentSize, paint);
        break;

      case ParticleType.sparkle:
      case ParticleType.magic:
        // Only draw complex shapes for important effects
        if (currentSize > 4.0) {
          // Only draw stars for larger particles
          _drawStar(canvas, paint);
        } else {
          // Fallback to simple circle for small particles
          canvas.drawCircle(Offset(position.x, position.y), currentSize, paint);
        }
        break;

      case ParticleType.ice:
        // Simplified ice rendering
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 1.0; // Reduced stroke width
        canvas.drawCircle(Offset(position.x, position.y), currentSize, paint);
        break;

      case ParticleType.electric:
        // Only draw electric effects for large particles
        if (currentSize > 6.0) {
          _drawElectric(canvas, paint);
        } else {
          // Fallback to simple line
          paint.style = PaintingStyle.stroke;
          paint.strokeWidth = 1.0;
          canvas.drawLine(
            Offset(position.x, position.y),
            Offset(position.x + 4, position.y + 4),
            paint,
          );
        }
        break;
    }
  }

  void _drawStar(Canvas canvas, Paint paint) {
    final center = Offset(position.x, position.y);
    final path = Path();

    for (int i = 0; i < 5; i++) {
      final angle = i * 2 * math.pi / 5 - math.pi / 2;
      final x = center.dx + currentSize * math.cos(angle);
      final y = center.dy + currentSize * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawElectric(Canvas canvas, Paint paint) {
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.0;

    final random = math.Random();
    final path = Path();

    for (int i = 0; i < 5; i++) {
      final offset = random.nextDouble() * 10 - 5;
      final x = position.x + offset;
      final y = position.y + i * 2.0;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }
}

/// Particle emitter that creates multiple particles
class ParticleEmitter {
  final Vector2 position;
  final ParticleType type;
  final int particleCount;
  final double emissionRate;
  final double spreadAngle;
  final double minSpeed;
  final double maxSpeed;
  final double minLifetime;
  final double maxLifetime;
  final List<Color> colors;
  final double minSize;
  final double maxSize;
  final double gravity;

  double timeSinceLastEmission;
  bool isActive;

  ParticleEmitter({
    required this.position,
    required this.type,
    this.particleCount = 10,
    this.emissionRate = 0.1,
    this.spreadAngle = math.pi * 2,
    this.minSpeed = 50.0,
    this.maxSpeed = 150.0,
    this.minLifetime = 1.0,
    this.maxLifetime = 3.0,
    this.colors = const [Colors.white],
    this.minSize = 2.0,
    this.maxSize = 8.0,
    this.gravity = 0.0,
  }) : timeSinceLastEmission = 0.0,
       isActive = true;

  List<Particle> emit(double deltaTime) {
    if (!isActive) return [];

    timeSinceLastEmission += deltaTime;

    if (timeSinceLastEmission >= emissionRate) {
      timeSinceLastEmission = 0.0;
      return _createParticles();
    }

    return [];
  }

  // Performance optimization: reduced particle count for common effects
  List<Particle> _createParticles() {
    final particles = <Particle>[];
    final random = math.Random();

    // Performance optimization: reduce particle count for better performance
    final actualParticleCount = math.min(
      particleCount,
      8,
    ); // Cap at 8 particles max

    for (int i = 0; i < actualParticleCount; i++) {
      final angle = random.nextDouble() * spreadAngle - spreadAngle / 2;
      final speed = minSpeed + random.nextDouble() * (maxSpeed - minSpeed);
      final lifetime =
          minLifetime + random.nextDouble() * (maxLifetime - minLifetime);
      final size = minSize + random.nextDouble() * (maxSize - minSize);
      final color = colors[random.nextInt(colors.length)];

      final velocity = Vector2(
        math.cos(angle) * speed,
        math.sin(angle) * speed,
      );

      particles.add(
        Particle(
          type: type,
          color: color,
          maxLifetime: lifetime,
          velocity: velocity,
          position: Vector2(position.x, position.y),
          size: Vector2(size, size),
          gravity: gravity,
          fadeRate: 1.0,
          shrinkRate: type == ParticleType.explosion ? size * 0.5 : 0.0,
        ),
      );
    }

    return particles;
  }

  void stop() {
    isActive = false;
  }
}

/// Particle system manager
class ParticleSystem {
  final List<Particle> _particles = [];
  final List<ParticleEmitter> _emitters = [];

  // Performance optimization: limit total particles
  static const int _maxParticles = 200;
  static const int _maxEmitters = 20;

  void update(double deltaTime) {
    // Update existing particles
    _particles.removeWhere((particle) => !particle.isActive);
    for (final particle in _particles) {
      particle.update(deltaTime);
    }

    // Update emitters and create new particles (with limits)
    for (final emitter in _emitters) {
      if (_particles.length >= _maxParticles)
        break; // Stop creating particles if at limit

      final newParticles = emitter.emit(deltaTime);
      _particles.addAll(newParticles);
    }

    // Remove inactive emitters
    _emitters.removeWhere((emitter) => !emitter.isActive);

    // Performance optimization: limit particle count by removing oldest particles
    if (_particles.length > _maxParticles) {
      _particles.sort((a, b) => a.currentLifetime.compareTo(b.currentLifetime));
      _particles.removeRange(_maxParticles, _particles.length);
    }
  }

  void render(Canvas canvas, Size canvasSize) {
    for (final particle in _particles) {
      if (particle.isActive && particle.isVisible) {
        particle.render(canvas, canvasSize);
      }
    }
  }

  void addEmitter(ParticleEmitter emitter) {
    _emitters.add(emitter);
  }

  void addParticle(Particle particle) {
    _particles.add(particle);
  }

  void clear() {
    _particles.clear();
    _emitters.clear();
  }

  // Factory methods for common particle effects
  static ParticleEmitter createExplosion({
    required Vector2 position,
    int particleCount = 20,
    double size = 8.0,
  }) {
    return ParticleEmitter(
      position: position,
      type: ParticleType.explosion,
      particleCount: particleCount,
      emissionRate: 0.01,
      spreadAngle: math.pi * 2,
      minSpeed: 80.0,
      maxSpeed: 200.0,
      minLifetime: 0.5,
      maxLifetime: 1.5,
      colors: [Colors.orange, Colors.red, Colors.yellow, Colors.white],
      minSize: size * 0.5,
      maxSize: size,
      gravity: 50.0,
    );
  }

  static ParticleEmitter createMagicSparkles({
    required Vector2 position,
    int particleCount = 15,
  }) {
    return ParticleEmitter(
      position: position,
      type: ParticleType.sparkle,
      particleCount: particleCount,
      emissionRate: 0.05,
      spreadAngle: math.pi * 2,
      minSpeed: 30.0,
      maxSpeed: 100.0,
      minLifetime: 1.0,
      maxLifetime: 2.0,
      colors: [Colors.purple, Colors.pink, Colors.blue, Colors.white],
      minSize: 3.0,
      maxSize: 6.0,
      gravity: -20.0, // Float upward
    );
  }

  static ParticleEmitter createProjectileTrail({
    required Vector2 position,
    required ParticleType projectileType,
  }) {
    List<Color> colors;
    switch (projectileType) {
      case ParticleType.fire:
        colors = [Colors.red, Colors.orange, Colors.yellow];
        break;
      case ParticleType.magic:
        colors = [Colors.purple, Colors.pink, Colors.blue];
        break;
      case ParticleType.ice:
        colors = [Colors.lightBlue, Colors.white, Colors.cyan];
        break;
      default:
        colors = [Colors.grey, Colors.white];
    }

    return ParticleEmitter(
      position: position,
      type: ParticleType.trail,
      particleCount: 5,
      emissionRate: 0.02,
      spreadAngle: math.pi * 0.5,
      minSpeed: 10.0,
      maxSpeed: 30.0,
      minLifetime: 0.3,
      maxLifetime: 0.8,
      colors: colors,
      minSize: 2.0,
      maxSize: 4.0,
    );
  }

  static ParticleEmitter createBloodSplatter({
    required Vector2 position,
    int particleCount = 8,
  }) {
    return ParticleEmitter(
      position: position,
      type: ParticleType.blood,
      particleCount: particleCount,
      emissionRate: 0.01,
      spreadAngle: math.pi,
      minSpeed: 50.0,
      maxSpeed: 120.0,
      minLifetime: 0.5,
      maxLifetime: 1.0,
      colors: [Colors.red, Colors.red.shade800, Colors.red.shade900],
      minSize: 2.0,
      maxSize: 5.0,
      gravity: 100.0,
    );
  }

  static ParticleEmitter createCannonSmoke({required Vector2 position}) {
    return ParticleEmitter(
      position: position,
      type: ParticleType.smoke,
      particleCount: 10,
      emissionRate: 0.03,
      spreadAngle: math.pi * 0.5,
      minSpeed: 20.0,
      maxSpeed: 60.0,
      minLifetime: 1.0,
      maxLifetime: 2.5,
      colors: [Colors.grey, Colors.grey.shade600, Colors.grey.shade400],
      minSize: 8.0,
      maxSize: 15.0,
      gravity: -10.0, // Float upward
    );
  }

  int get particleCount => _particles.length;
  int get emitterCount => _emitters.length;
}
