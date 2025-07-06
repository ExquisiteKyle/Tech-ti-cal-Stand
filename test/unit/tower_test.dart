import 'package:flutter_test/flutter_test.dart';
import 'package:techtical_stand/features/game/domain/models/tower.dart';
import 'package:techtical_stand/shared/models/vector2.dart';

void main() {
  group('Tower Tests', () {
    late Vector2 towerPosition;

    setUp(() {
      towerPosition = Vector2(100, 100);
    });

    group('Tower Base Properties', () {
      test('Tower has correct base properties', () {
        final tower = ArcherTower(position: towerPosition);

        expect(tower.type, equals(TowerType.archer));
        expect(tower.baseCost, greaterThan(0));
        expect(tower.baseDamage, greaterThan(0));
        expect(tower.baseRange, greaterThan(0));
        expect(tower.baseAttackSpeed, greaterThan(0));
        expect(tower.name, isNotEmpty);
        expect(tower.description, isNotEmpty);
      });

      test('Tower damage increases with level', () {
        final tower = ArcherTower(position: towerPosition);
        final baseDamage = tower.damage;

        tower.upgrade(UpgradePath.path1);
        final upgradedDamage = tower.damage;

        expect(upgradedDamage, greaterThan(baseDamage));
      });

      test('Tower range increases with level', () {
        final tower = ArcherTower(position: towerPosition);
        final baseRange = tower.range;

        tower.upgrade(UpgradePath.path1);
        final upgradedRange = tower.range;

        expect(upgradedRange, greaterThan(baseRange));
      });

      test('Tower attack speed increases with level', () {
        final tower = ArcherTower(position: towerPosition);
        final baseAttackSpeed = tower.attackSpeed;

        tower.upgrade(UpgradePath.path1);
        final upgradedAttackSpeed = tower.attackSpeed;

        expect(upgradedAttackSpeed, greaterThan(baseAttackSpeed));
      });
    });

    group('Tower Upgrade System', () {
      test('Tower can upgrade up to level 3', () {
        final tower = ArcherTower(position: towerPosition);

        expect(tower.upgradeLevel, equals(0));

        expect(tower.upgrade(UpgradePath.path1), isTrue);
        expect(tower.upgradeLevel, equals(1));

        expect(tower.upgrade(UpgradePath.path2), isTrue);
        expect(tower.upgradeLevel, equals(2));

        expect(tower.upgrade(UpgradePath.path1), isTrue);
        expect(tower.upgradeLevel, equals(3));

        // Cannot upgrade beyond level 3
        expect(tower.upgrade(UpgradePath.path1), isFalse);
        expect(tower.upgradeLevel, equals(3));
      });

      test('Tower upgrade cost increases with level', () {
        final tower = ArcherTower(position: towerPosition);
        final cost1 = tower.getUpgradeCost();

        tower.upgrade(UpgradePath.path1);
        final cost2 = tower.getUpgradeCost();

        expect(cost2, greaterThan(cost1));
      });

      test('Tower tracks selected upgrade path', () {
        final tower = ArcherTower(position: towerPosition);

        tower.upgrade(UpgradePath.path1);
        expect(tower.selectedUpgradePath, equals(UpgradePath.path1));

        tower.upgrade(UpgradePath.path2);
        expect(tower.selectedUpgradePath, equals(UpgradePath.path2));
      });
    });

    group('Tower Attack System', () {
      test('Tower can attack when cooldown is ready', () {
        final tower = ArcherTower(position: towerPosition);
        final currentTime = 1.0;

        expect(tower.canAttack(currentTime), isTrue);
      });

      test('Tower cannot attack during cooldown', () {
        final tower = ArcherTower(position: towerPosition);
        final currentTime = 1.0;

        // First attack - just update lastAttackTime
        tower.lastAttackTime = currentTime;

        // Immediately try to attack again
        expect(tower.canAttack(currentTime), isFalse);
      });

      test('Tower attack cooldown respects attack speed', () {
        final tower = ArcherTower(position: towerPosition);
        final currentTime = 1.0;

        // First attack - just update lastAttackTime
        tower.lastAttackTime = currentTime;

        // Wait for cooldown to expire
        final cooldownTime = 1.0 / tower.attackSpeed;
        final nextAttackTime = currentTime + cooldownTime;

        expect(tower.canAttack(nextAttackTime), isTrue);
      });
    });

    group('Tower Types', () {
      test('Archer tower has correct properties', () {
        final tower = ArcherTower(position: towerPosition);

        expect(tower.type, equals(TowerType.archer));
        expect(tower.baseCost, equals(50));
        expect(tower.baseDamage, equals(80));
        expect(tower.baseRange, equals(150));
        expect(tower.baseAttackSpeed, equals(2.0));
      });

      test('Cannon tower has correct properties', () {
        final tower = CannonTower(position: towerPosition);

        expect(tower.type, equals(TowerType.cannon));
        expect(tower.baseCost, equals(100));
        expect(tower.baseDamage, equals(150));
        expect(tower.baseRange, equals(130));
        expect(tower.baseAttackSpeed, equals(1.2));
      });

      test('Magic tower has correct properties', () {
        final tower = MagicTower(position: towerPosition);

        expect(tower.type, equals(TowerType.magic));
        expect(tower.baseCost, equals(150));
        expect(tower.baseDamage, equals(100));
        expect(tower.baseRange, equals(170));
        expect(tower.baseAttackSpeed, equals(1.5));
      });

      test('Sniper tower has correct properties', () {
        final tower = SniperTower(position: towerPosition);

        expect(tower.type, equals(TowerType.sniper));
        expect(tower.baseCost, equals(200));
        expect(tower.baseDamage, equals(250));
        expect(tower.baseRange, equals(250));
        expect(tower.baseAttackSpeed, equals(0.8));
      });
    });
  });
}
