import 'package:flutter_test/flutter_test.dart';
import 'package:techtical_stand/features/game/domain/models/tower.dart';
import 'package:techtical_stand/shared/models/vector2.dart';

void main() {
  group('Tower Hit Detection Tests', () {
    test('Tower containsPoint works correctly', () {
      final tower = ArcherTower(position: Vector2(100, 100));

      // Test exact center
      expect(tower.containsPoint(Vector2(115, 115)), isTrue);

      // Test corners
      expect(tower.containsPoint(Vector2(100, 100)), isTrue); // Top-left
      expect(tower.containsPoint(Vector2(130, 100)), isTrue); // Top-right
      expect(tower.containsPoint(Vector2(100, 130)), isTrue); // Bottom-left
      expect(tower.containsPoint(Vector2(130, 130)), isTrue); // Bottom-right

      // Test outside bounds
      expect(tower.containsPoint(Vector2(99, 115)), isFalse); // Left
      expect(tower.containsPoint(Vector2(131, 115)), isFalse); // Right
      expect(tower.containsPoint(Vector2(115, 99)), isFalse); // Top
      expect(tower.containsPoint(Vector2(115, 131)), isFalse); // Bottom
    });

    test('Tower center calculation is correct', () {
      final tower = ArcherTower(position: Vector2(100, 100));

      // Tower size is 30x30, so center should be at (100 + 15, 100 + 15) = (115, 115)
      expect(tower.center.x, equals(115));
      expect(tower.center.y, equals(115));
    });

    test('Distance calculation works correctly', () {
      final tower = ArcherTower(position: Vector2(100, 100));
      final towerCenter = tower.center;

      // Test distance from center
      expect(towerCenter.distanceTo(Vector2(115, 115)), equals(0));
      expect(towerCenter.distanceTo(Vector2(130, 115)), equals(15));
      expect(towerCenter.distanceTo(Vector2(100, 115)), equals(15));
    });

    test('Expanded hit area calculation', () {
      final tower = ArcherTower(position: Vector2(100, 100));
      final towerCenter = tower.center;
      const double hitAreaExpansion = 35.0;
      final expandedRadius = (tower.size.x / 2) + hitAreaExpansion;

      // Should be 15 (half size) + 35 = 50
      expect(expandedRadius, equals(50));

      // Test points within expanded radius
      expect(
        towerCenter.distanceTo(Vector2(165, 115)),
        lessThanOrEqualTo(expandedRadius),
      ); // Right edge
      expect(
        towerCenter.distanceTo(Vector2(65, 115)),
        lessThanOrEqualTo(expandedRadius),
      ); // Left edge
      expect(
        towerCenter.distanceTo(Vector2(115, 165)),
        lessThanOrEqualTo(expandedRadius),
      ); // Bottom edge
      expect(
        towerCenter.distanceTo(Vector2(115, 65)),
        lessThanOrEqualTo(expandedRadius),
      ); // Top edge

      // Test points outside expanded radius
      expect(
        towerCenter.distanceTo(Vector2(166, 115)),
        greaterThan(expandedRadius),
      );
      expect(
        towerCenter.distanceTo(Vector2(64, 115)),
        greaterThan(expandedRadius),
      );
    });
  });
}
