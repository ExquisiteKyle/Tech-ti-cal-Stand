import 'package:flutter/material.dart';
import '../../../../shared/models/entity.dart';
import '../../../../shared/models/vector2.dart';
import 'enemy.dart';
import 'projectile.dart';
import 'particle.dart';

/// Enumeration of tower types
enum TowerType { archer, cannon, magic, sniper }

/// Enumeration of upgrade paths
enum UpgradePath { path1, path2 }

/// Base class for all towers
abstract class Tower extends Entity {
  final TowerType type;
  final int baseCost;
  final double baseDamage;
  final double baseRange;
  final double baseAttackSpeed;
  final String name;
  final String description;

  int upgradeLevel;
  UpgradePath? selectedUpgradePath;
  double lastAttackTime;
  Entity? currentTarget;

  Tower({
    required this.type,
    required this.baseCost,
    required this.baseDamage,
    required this.baseRange,
    required this.baseAttackSpeed,
    required this.name,
    required this.description,
    required super.position,
    required super.size,
    this.upgradeLevel = 0,
    this.selectedUpgradePath,
    this.lastAttackTime = 0.0,
  });

  /// Get current damage based on level and upgrades
  double get damage => baseDamage * (1 + upgradeLevel * 0.2);

  /// Get current range based on level and upgrades
  double get range => baseRange * (1 + upgradeLevel * 0.1);

  /// Get current attack speed based on level and upgrades
  double get attackSpeed => baseAttackSpeed * (1 + upgradeLevel * 0.15);

  /// Get the color associated with this tower type
  Color get towerColor;

  /// Get the cost to upgrade this tower
  int getUpgradeCost() => (baseCost * 0.75 * (upgradeLevel + 1)).round();

  /// Check if this tower can attack (cooldown elapsed)
  bool canAttack(double currentTime) =>
      currentTime - lastAttackTime >= 1.0 / attackSpeed;

  /// Find the best target within range
  Entity? findTarget(List<Entity> enemies) {
    final enemiesInRange = enemies.where((enemy) {
      final distance = distanceTo(enemy);
      return enemy.isActive && distance <= range;
    }).toList();

    if (enemiesInRange.isEmpty) {
      // Debug why no enemies in range occasionally
      if (enemies.isNotEmpty &&
          DateTime.now().millisecondsSinceEpoch % 2000 < 50) {
        // final closest = enemies.reduce((a, b) => distanceTo(a) < distanceTo(b) ? a : b);
        // Debug: print('${name} no enemies in range. Closest enemy at distance ${distanceTo(closest)}, range: ${range}');
      }
      return null;
    }

    return selectTarget(enemiesInRange);
  }

  /// Select the best target from available enemies (override in subclasses)
  Entity selectTarget(List<Entity> enemies);

  /// Perform an attack on the current target
  void attack(Entity target, double currentTime) {
    if (canAttack(currentTime)) {
      // Debug: print('${name} attacking target at ${target.center}');
      final projectile = createProjectile(target);
      if (projectile != null) {
        // Debug: print('Created projectile: ${projectile.type} with damage ${projectile.damage}');
        // The projectile will be added to the entity manager
        // This callback will be set by the tower manager
        onProjectileCreated?.call(projectile);
        // Debug: print('Projectile added to entity manager');
      }
      lastAttackTime = currentTime;
    }
  }

  /// Create a projectile for this tower type (override in subclasses)
  Projectile? createProjectile(Entity target);

  /// Callback for when a projectile is created
  void Function(Projectile)? onProjectileCreated;

  /// Callback for when a particle emitter is created
  void Function(ParticleEmitter)? onParticleEmitterCreated;

  /// Upgrade this tower to the next level
  bool upgrade(UpgradePath path) {
    if (upgradeLevel < 3) {
      upgradeLevel++;
      selectedUpgradePath = path;
      return true;
    }
    return false;
  }

  /// Get upgrade descriptions for both paths
  List<String> getUpgradeDescriptions();

  @override
  void update(double deltaTime) {
    // Tower update logic will be handled by the tower manager
  }

  @override
  void render(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = towerColor
      ..style = PaintingStyle.fill;

    // Draw tower base (slightly larger for upgraded towers)
    final towerRadius = size.x / 2 + (upgradeLevel * 2);
    canvas.drawCircle(Offset(center.x, center.y), towerRadius, paint);

    // Draw tower border
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(Offset(center.x, center.y), towerRadius, borderPaint);

    // Draw range indicator if selected
    if (currentTarget != null) {
      final rangePaint = Paint()
        ..color = towerColor.withAlpha(50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawCircle(Offset(center.x, center.y), range, rangePaint);
    }

    // Draw upgrade path indicator ring first (behind tower)
    if (upgradeLevel > 0 && selectedUpgradePath != null) {
      final pathPaint = Paint()
        ..color = selectedUpgradePath == UpgradePath.path1
            ? Colors.blue.withValues(alpha: 0.6)
            : Colors.purple.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      // Draw a small indicator ring around the tower
      canvas.drawCircle(Offset(center.x, center.y), towerRadius + 2, pathPaint);
    }

    // Draw upgrade badge on top of tower (always last)
    _drawUpgradeBadge(canvas);
  }

  /// Draw upgrade level number badge on top of tower
  void _drawUpgradeBadge(Canvas canvas) {
    if (upgradeLevel <= 0) return;

    final towerRadius = size.x / 2 + (upgradeLevel * 2);

    // Draw upgrade level number in a circle
    final levelBgPaint = Paint()
      ..color = selectedUpgradePath == UpgradePath.path1
          ? Colors.blue.withValues(alpha: 0.95)
          : (selectedUpgradePath == UpgradePath.path2
                ? Colors.purple.withValues(alpha: 0.95)
                : Colors.green.withValues(alpha: 0.95))
      ..style = PaintingStyle.fill;

    final levelBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw level number circle at bottom-right of tower
    final levelCircleRadius = 10.0;
    final levelCircleX = center.x + towerRadius - 4;
    final levelCircleY = center.y + towerRadius - 4;

    // Background circle with subtle glow
    final glowPaint = Paint()
      ..color = levelBgPaint.color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    // Draw glow effect
    canvas.drawCircle(
      Offset(levelCircleX, levelCircleY),
      levelCircleRadius + 3,
      glowPaint,
    );

    // Draw main background circle
    canvas.drawCircle(
      Offset(levelCircleX, levelCircleY),
      levelCircleRadius,
      levelBgPaint,
    );
    canvas.drawCircle(
      Offset(levelCircleX, levelCircleY),
      levelCircleRadius,
      levelBorderPaint,
    );

    // Draw level number
    final textPainter = TextPainter(
      text: TextSpan(
        text: upgradeLevel.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final textX = levelCircleX - textPainter.width / 2;
    final textY = levelCircleY - textPainter.height / 2;
    textPainter.paint(canvas, Offset(textX, textY));
  }

  /// Render tower with selection indicator
  void renderWithSelection(Canvas canvas, Size canvasSize, bool isSelected) {
    // Draw selection indicator first (so it's behind the tower)
    if (isSelected) {
      final towerRadius = size.x / 2 + (upgradeLevel * 2);
      final selectionPaint = Paint()
        ..color = Colors.lightBlue.withAlpha(150)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;

      canvas.drawCircle(
        Offset(center.x, center.y),
        towerRadius + 8,
        selectionPaint,
      );

      // Draw range indicator when selected
      final rangePaint = Paint()
        ..color = Colors.lightBlue.withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(Offset(center.x, center.y), range, rangePaint);
    }

    // Render normal tower
    render(canvas, canvasSize);

    // Draw upgrade badge on top of tower
    _drawUpgradeBadge(canvas);
  }
}

/// Archer Tower - Fast attacks, good against light enemies
class ArcherTower extends Tower {
  ArcherTower({required super.position})
    : super(
        type: TowerType.archer,
        baseCost: 50,
        baseDamage: 80, // Massive increase from 35 to 80 for 1-shot kills
        baseRange: 150, // Increased from 120 to 150 for better coverage
        baseAttackSpeed: 2.0, // Increased from 1.2 to 2.0 for faster attacks
        name: 'Archer Tower',
        description: 'Fast attacks, good against light enemies',
        size: Vector2(30, 30),
      );

  @override
  Color get towerColor => const Color(0xFFD2B48C); // Tan/Brown

  @override
  Entity selectTarget(List<Entity> enemies) {
    // Target first enemy in range
    return enemies.first;
  }

  @override
  Projectile? createProjectile(Entity target) {
    // Debug: print('ArcherTower creating arrow at ${center} for target at ${target.center}');
    // Debug: print('ArcherTower damage: ${damage}, baseDamage: ${baseDamage}');
    final arrow = Arrow(
      target: target,
      damage: damage,
      position: Vector2(center.x, center.y),
    );
    // Debug: print('Arrow created with damage: ${arrow.damage}');
    return arrow;
  }

  @override
  List<String> getUpgradeDescriptions() => [
    'Path 1: Multi-shot (${upgradeLevel + 1} arrows)',
    'Path 2: Poison arrows (damage over time)',
  ];
}

/// Cannon Tower - High damage, splash damage
class CannonTower extends Tower {
  CannonTower({required super.position})
    : super(
        type: TowerType.cannon,
        baseCost: 100,
        baseDamage: 150, // Massive increase from 60 to 150 for heavy hits
        baseRange: 130, // Increased from 100 to 130 for better coverage
        baseAttackSpeed: 1.2, // Increased from 0.8 to 1.2 for faster firing
        name: 'Cannon Tower',
        description: 'High damage with splash effect',
        size: Vector2(35, 35),
      );

  @override
  Color get towerColor => const Color(0xFFC0C0C0); // Silver

  @override
  Entity selectTarget(List<Entity> enemies) {
    // Target closest enemy
    return enemies.reduce((a, b) => distanceTo(a) < distanceTo(b) ? a : b);
  }

  @override
  Projectile? createProjectile(Entity target) {
    // Debug: print('CannonTower creating cannonball at ${center} for target at ${target.center}');
    return Cannonball(
      target: target,
      damage: damage,
      position: Vector2(center.x, center.y),
      splashRadius: 50.0 + (upgradeLevel * 10),
    );
  }

  @override
  List<String> getUpgradeDescriptions() => [
    'Path 1: Explosive rounds (${25 + upgradeLevel * 25}% splash)',
    'Path 2: Area damage (increased splash radius)',
  ];
}

/// Magic Tower - Slows enemies, magical damage
class MagicTower extends Tower {
  MagicTower({required super.position})
    : super(
        type: TowerType.magic,
        baseCost: 150,
        baseDamage: 100, // Increased from 45 to 100 for magical power
        baseRange: 170, // Increased from 140 to 170 for magical reach
        baseAttackSpeed: 1.5, // Increased from 1.0 to 1.5 for faster casting
        name: 'Magic Tower',
        description: 'Slows enemies with magical damage',
        size: Vector2(32, 32),
      );

  @override
  Color get towerColor => const Color(0xFFDDA0DD); // Plum

  @override
  Entity selectTarget(List<Entity> enemies) {
    // Target strongest enemy in range
    return enemies.reduce((a, b) {
      if (a is Enemy && b is Enemy) {
        return a.maxHealth > b.maxHealth ? a : b;
      }
      return a;
    });
  }

  @override
  Projectile? createProjectile(Entity target) {
    final slowStrength = 0.5 + (upgradeLevel * 0.1);
    final slowDuration = 2.0 + (upgradeLevel * 0.5);

    return MagicBolt(
      target: target,
      damage: damage,
      position: Vector2(center.x, center.y),
      slowStrength: slowStrength,
      slowDuration: slowDuration,
    );
  }

  @override
  List<String> getUpgradeDescriptions() => [
    'Path 1: Chain lightning (hits ${upgradeLevel + 2} enemies)',
    'Path 2: Freeze effect (${20 + upgradeLevel * 20}% slow)',
  ];
}

/// Sniper Tower - Very high damage, long range
class SniperTower extends Tower {
  SniperTower({required super.position})
    : super(
        type: TowerType.sniper,
        baseCost: 200,
        baseDamage:
            250, // Massive increase from 120 to 250 for devastating shots
        baseRange: 250, // Increased from 200 to 250 for sniper range
        baseAttackSpeed: 0.8, // Increased from 0.5 to 0.8 for faster sniping
        name: 'Sniper Tower',
        description: 'High damage, long range attacks',
        size: Vector2(28, 28),
      );

  @override
  Color get towerColor => const Color(0xFF98FB98); // Light Green

  @override
  Entity selectTarget(List<Entity> enemies) {
    // Target furthest enemy in range
    return enemies.reduce((a, b) => distanceTo(a) > distanceTo(b) ? a : b);
  }

  @override
  Projectile? createProjectile(Entity target) {
    bool isCritical = false;
    double armorPenetration = 0.0;

    // Apply upgrade effects
    if (selectedUpgradePath == UpgradePath.path1) {
      final critChance = 0.15 + (upgradeLevel * 0.15);
      isCritical =
          DateTime.now().millisecondsSinceEpoch % 100 < critChance * 100;
    } else if (selectedUpgradePath == UpgradePath.path2) {
      armorPenetration = 0.25 + (upgradeLevel * 0.25);
    }

    return SniperBullet(
      target: target,
      damage: damage,
      position: Vector2(center.x, center.y),
      isCritical: isCritical,
      armorPenetration: armorPenetration,
    );
  }

  @override
  List<String> getUpgradeDescriptions() => [
    'Path 1: Critical hits (${15 + upgradeLevel * 15}% chance)',
    'Path 2: Armor piercing (ignores ${25 + upgradeLevel * 25}% armor)',
  ];
}
