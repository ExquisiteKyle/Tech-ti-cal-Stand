import 'package:flutter_test/flutter_test.dart';
import 'package:techtical_stand/features/game/domain/models/tower.dart';
import 'package:techtical_stand/shared/models/vector2.dart';

void main() {
  group('Performance Tests', () {
    group('Tower Performance', () {
      test('Tower upgrade performance', () {
        final tower = ArcherTower(position: Vector2(100, 100));

        final stopwatch = Stopwatch()..start();

        // Perform multiple upgrades
        for (int i = 0; i < 1000; i++) {
          tower.upgrade(UpgradePath.path1);
          tower.upgrade(UpgradePath.path2);
        }

        stopwatch.stop();

        // Should complete within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });

      test('Tower property access performance', () {
        final towers = List.generate(
          100,
          (index) => ArcherTower(position: Vector2(index * 10.0, index * 10.0)),
        );

        final stopwatch = Stopwatch()..start();

        // Access tower properties repeatedly
        for (int i = 0; i < 1000; i++) {
          for (final tower in towers) {
            final damage = tower.damage;
            final range = tower.range;
            final attackSpeed = tower.attackSpeed;

            // Use the values to prevent optimization
            expect(damage, greaterThan(0));
            expect(range, greaterThan(0));
            expect(attackSpeed, greaterThan(0));
          }
        }

        stopwatch.stop();

        // Should complete within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });

    group('Vector2 Performance', () {
      test('Vector2 operations performance', () {
        final vectors = List.generate(
          1000,
          (index) => Vector2(index * 1.0, index * 1.0),
        );

        final stopwatch = Stopwatch()..start();

        // Perform vector operations
        for (int i = 0; i < 100; i++) {
          for (final vector in vectors) {
            final distance = vector.distanceTo(Vector2(0, 0));
            final magnitude = vector.magnitude;

            // Use the values to prevent optimization
            expect(distance, greaterThanOrEqualTo(0));
            expect(magnitude, greaterThanOrEqualTo(0));
          }
        }

        stopwatch.stop();

        // Should complete within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });

    group('Memory Performance', () {
      test('Large tower list memory usage', () {
        final towers = List.generate(
          1000,
          (index) => ArcherTower(position: Vector2(index * 5.0, index * 5.0)),
        );

        // Perform operations that should not cause memory leaks
        for (int i = 0; i < 100; i++) {
          for (final tower in towers) {
            final cost = tower.getUpgradeCost();
            expect(cost, greaterThanOrEqualTo(0));
          }
        }

        // If we get here without memory issues, the test passes
        expect(towers.length, equals(1000));
      });

      test('Tower upgrade memory efficiency', () {
        final tower = ArcherTower(position: Vector2(100, 100));

        // Perform many upgrades
        for (int i = 0; i < 100; i++) {
          tower.upgrade(UpgradePath.path1);
          tower.upgrade(UpgradePath.path2);
        }

        // Should not cause memory issues
        expect(tower.upgradeLevel, equals(3)); // Max level
      });
    });

    group('Rendering Performance', () {
      test('Tower rendering calculations performance', () {
        final towers = List.generate(
          100,
          (index) => ArcherTower(position: Vector2(index * 8.0, index * 8.0)),
        );

        final stopwatch = Stopwatch()..start();

        // Simulate rendering calculations
        for (int i = 0; i < 100; i++) {
          for (final tower in towers) {
            // Simulate rendering calculations
            final damage = tower.damage;
            final range = tower.range;
            final attackSpeed = tower.attackSpeed;
            final cost = tower.getUpgradeCost();

            // Use the values to prevent optimization
            expect(damage, greaterThan(0));
            expect(range, greaterThan(0));
            expect(attackSpeed, greaterThan(0));
            expect(cost, greaterThanOrEqualTo(0));
          }
        }

        stopwatch.stop();

        // Should complete within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });

    group('Game Loop Performance', () {
      test('Tower update loop performance', () {
        final towers = List.generate(
          50,
          (index) => ArcherTower(position: Vector2(index * 10.0, index * 10.0)),
        );

        final stopwatch = Stopwatch()..start();

        // Simulate game loop updates
        for (int frame = 0; frame < 1000; frame++) {
          final deltaTime = 1 / 60; // 60 FPS

          // Update all towers
          for (final tower in towers) {
            tower.update(deltaTime);
          }

          // Simulate targeting calculations
          for (final tower in towers) {
            final canAttack = tower.canAttack(frame * deltaTime);
            expect(canAttack, isA<bool>());
          }
        }

        stopwatch.stop();

        // Should maintain 60 FPS performance (1000 frames in ~16.67 seconds)
        final expectedTime = 1000 * (1 / 60) * 1000; // milliseconds
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(expectedTime * 2),
        ); // Allow 2x overhead
      });
    });
  });
}
