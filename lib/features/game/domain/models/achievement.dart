import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Types of achievements available
enum AchievementType {
  towerMastery,
  strategic,
  progression,
  special,
  combat,
  efficiency,
}

/// Achievement categories for organization
enum AchievementCategory { towers, strategy, levels, combat, time, special }

/// Achievement rarity levels
enum AchievementRarity { common, uncommon, rare, epic, legendary }

/// Individual achievement definition
class Achievement extends Equatable {
  final String id;
  final String name;
  final String description;
  final AchievementType type;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final IconData icon;
  final Color color;
  final int maxProgress;
  final int currentProgress;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int rewardGold;
  final Map<String, dynamic> metadata;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    this.rarity = AchievementRarity.common,
    required this.icon,
    required this.color,
    this.maxProgress = 1,
    this.currentProgress = 0,
    this.isUnlocked = false,
    this.unlockedAt,
    this.rewardGold = 0,
    this.metadata = const {},
  });

  /// Create a copy with updated values
  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    AchievementType? type,
    AchievementCategory? category,
    AchievementRarity? rarity,
    IconData? icon,
    Color? color,
    int? maxProgress,
    int? currentProgress,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? rewardGold,
    Map<String, dynamic>? metadata,
  }) => Achievement(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    type: type ?? this.type,
    category: category ?? this.category,
    rarity: rarity ?? this.rarity,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    maxProgress: maxProgress ?? this.maxProgress,
    currentProgress: currentProgress ?? this.currentProgress,
    isUnlocked: isUnlocked ?? this.isUnlocked,
    unlockedAt: unlockedAt ?? this.unlockedAt,
    rewardGold: rewardGold ?? this.rewardGold,
    metadata: metadata ?? this.metadata,
  );

  /// Get progress percentage (0.0 to 1.0)
  double get progressPercentage =>
      maxProgress > 0 ? currentProgress / maxProgress : 0.0;

  /// Check if achievement is completed
  bool get isCompleted => currentProgress >= maxProgress;

  /// Get rarity display name
  String get rarityDisplayName {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.uncommon:
        return 'Uncommon';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }

  /// Get rarity color
  Color get rarityColor {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.uncommon:
        return Colors.green;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.orange;
    }
  }

  /// Get category display name
  String get categoryDisplayName {
    switch (category) {
      case AchievementCategory.towers:
        return 'Tower Mastery';
      case AchievementCategory.strategy:
        return 'Strategic';
      case AchievementCategory.levels:
        return 'Progression';
      case AchievementCategory.combat:
        return 'Combat';
      case AchievementCategory.time:
        return 'Efficiency';
      case AchievementCategory.special:
        return 'Special';
    }
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    type,
    category,
    rarity,
    icon,
    color,
    maxProgress,
    currentProgress,
    isUnlocked,
    unlockedAt,
    rewardGold,
    metadata,
  ];
}

/// Predefined achievements
class GameAchievements {
  static const List<Achievement> defaultAchievements = [
    // Tower Mastery Achievements
    Achievement(
      id: 'archer_expert',
      name: 'Archer Expert',
      description: 'Complete 10 waves using only archer towers',
      type: AchievementType.towerMastery,
      category: AchievementCategory.towers,
      rarity: AchievementRarity.uncommon,
      icon: Icons.sports_esports,
      color: Color(0xFF4CAF50),
      maxProgress: 10,
      rewardGold: 500,
    ),

    Achievement(
      id: 'cannon_master',
      name: 'Cannon Master',
      description: 'Defeat 100 enemies with cannon towers',
      type: AchievementType.towerMastery,
      category: AchievementCategory.towers,
      rarity: AchievementRarity.uncommon,
      icon: Icons.blur_on,
      color: Color(0xFFFF9800),
      maxProgress: 100,
      rewardGold: 500,
    ),

    Achievement(
      id: 'magic_user',
      name: 'Magic User',
      description: 'Slow 50 enemies with magic towers',
      type: AchievementType.towerMastery,
      category: AchievementCategory.towers,
      rarity: AchievementRarity.uncommon,
      icon: Icons.auto_fix_high,
      color: Color(0xFF9C27B0),
      maxProgress: 50,
      rewardGold: 500,
    ),

    Achievement(
      id: 'sniper_elite',
      name: 'Sniper Elite',
      description: 'Get 50 critical hits with sniper towers',
      type: AchievementType.towerMastery,
      category: AchievementCategory.towers,
      rarity: AchievementRarity.rare,
      icon: Icons.gps_fixed,
      color: Color(0xFF2196F3),
      maxProgress: 50,
      rewardGold: 750,
    ),

    Achievement(
      id: 'tower_collector',
      name: 'Tower Collector',
      description: 'Place all 4 tower types in a single level',
      type: AchievementType.towerMastery,
      category: AchievementCategory.towers,
      rarity: AchievementRarity.common,
      icon: Icons.collections,
      color: Color(0xFF607D8B),
      maxProgress: 1,
      rewardGold: 250,
    ),

    // Strategic Achievements
    Achievement(
      id: 'perfect_defense',
      name: 'Perfect Defense',
      description: 'Complete a wave without losing lives',
      type: AchievementType.strategic,
      category: AchievementCategory.strategy,
      rarity: AchievementRarity.common,
      icon: Icons.shield,
      color: Color(0xFF4CAF50),
      maxProgress: 1,
      rewardGold: 300,
    ),

    Achievement(
      id: 'resource_manager',
      name: 'Resource Manager',
      description: 'Complete 5 waves with less than 50 gold',
      type: AchievementType.strategic,
      category: AchievementCategory.strategy,
      rarity: AchievementRarity.rare,
      icon: Icons.account_balance_wallet,
      color: Color(0xFFFFEB3B),
      maxProgress: 5,
      rewardGold: 1000,
    ),

    Achievement(
      id: 'speed_runner',
      name: 'Speed Runner',
      description: 'Complete a level in under 5 minutes',
      type: AchievementType.strategic,
      category: AchievementCategory.time,
      rarity: AchievementRarity.rare,
      icon: Icons.timer,
      color: Color(0xFFFF5722),
      maxProgress: 1,
      rewardGold: 750,
    ),

    Achievement(
      id: 'efficiency_expert',
      name: 'Efficiency Expert',
      description: 'Complete a level with 90% accuracy',
      type: AchievementType.strategic,
      category: AchievementCategory.strategy,
      rarity: AchievementRarity.epic,
      icon: Icons.trending_up,
      color: Color(0xFF3F51B5),
      maxProgress: 1,
      rewardGold: 1500,
    ),

    // Progression Achievements
    Achievement(
      id: 'wave_survivor',
      name: 'Wave Survivor',
      description: 'Complete 20 waves',
      type: AchievementType.progression,
      category: AchievementCategory.levels,
      rarity: AchievementRarity.common,
      icon: Icons.waves,
      color: Color(0xFF00BCD4),
      maxProgress: 20,
      rewardGold: 400,
    ),

    Achievement(
      id: 'level_master',
      name: 'Level Master',
      description: 'Complete all 6 levels',
      type: AchievementType.progression,
      category: AchievementCategory.levels,
      rarity: AchievementRarity.epic,
      icon: Icons.emoji_events,
      color: Color(0xFFFFD700),
      maxProgress: 6,
      rewardGold: 2000,
    ),

    Achievement(
      id: 'gold_collector',
      name: 'Gold Collector',
      description: 'Accumulate 10,000 gold',
      type: AchievementType.progression,
      category: AchievementCategory.levels,
      rarity: AchievementRarity.uncommon,
      icon: Icons.monetization_on,
      color: Color(0xFFFFD700),
      maxProgress: 10000,
      rewardGold: 500,
    ),

    Achievement(
      id: 'enemy_slayer',
      name: 'Enemy Slayer',
      description: 'Defeat 1,000 enemies',
      type: AchievementType.progression,
      category: AchievementCategory.combat,
      rarity: AchievementRarity.uncommon,
      icon: Icons.local_fire_department,
      color: Color(0xFFE91E63),
      maxProgress: 1000,
      rewardGold: 600,
    ),

    // Combat Achievements
    Achievement(
      id: 'chain_killer',
      name: 'Chain Killer',
      description: 'Defeat 10 enemies in 5 seconds',
      type: AchievementType.combat,
      category: AchievementCategory.combat,
      rarity: AchievementRarity.rare,
      icon: Icons.flash_on,
      color: Color(0xFFFFEB3B),
      maxProgress: 1,
      rewardGold: 800,
    ),

    Achievement(
      id: 'boss_hunter',
      name: 'Boss Hunter',
      description: 'Defeat 10 boss enemies',
      type: AchievementType.combat,
      category: AchievementCategory.combat,
      rarity: AchievementRarity.rare,
      icon: Icons.dangerous,
      color: Color(0xFF9C27B0),
      maxProgress: 10,
      rewardGold: 1000,
    ),

    Achievement(
      id: 'overkill',
      name: 'Overkill',
      description: 'Deal 1000 damage in a single hit',
      type: AchievementType.combat,
      category: AchievementCategory.combat,
      rarity: AchievementRarity.epic,
      icon: Icons.whatshot,
      color: Color(0xFFFF5722),
      maxProgress: 1,
      rewardGold: 1200,
    ),

    // Special Achievements
    Achievement(
      id: 'first_victory',
      name: 'First Victory',
      description: 'Complete your first level',
      type: AchievementType.special,
      category: AchievementCategory.special,
      rarity: AchievementRarity.common,
      icon: Icons.star,
      color: Color(0xFFFFD700),
      maxProgress: 1,
      rewardGold: 200,
    ),

    Achievement(
      id: 'perfectionist',
      name: 'Perfectionist',
      description: 'Master all 6 levels',
      type: AchievementType.special,
      category: AchievementCategory.special,
      rarity: AchievementRarity.legendary,
      icon: Icons.diamond,
      color: Color(0xFF9C27B0),
      maxProgress: 6,
      rewardGold: 5000,
    ),

    Achievement(
      id: 'dedication',
      name: 'Dedication',
      description: 'Play for 10 hours total',
      type: AchievementType.special,
      category: AchievementCategory.time,
      rarity: AchievementRarity.rare,
      icon: Icons.schedule,
      color: Color(0xFF795548),
      maxProgress: 36000, // 10 hours in seconds
      rewardGold: 1500,
    ),

    Achievement(
      id: 'early_bird',
      name: 'Early Bird',
      description: 'Complete a level before 6 AM',
      type: AchievementType.special,
      category: AchievementCategory.special,
      rarity: AchievementRarity.uncommon,
      icon: Icons.wb_sunny,
      color: Color(0xFFFFEB3B),
      maxProgress: 1,
      rewardGold: 300,
    ),

    Achievement(
      id: 'night_owl',
      name: 'Night Owl',
      description: 'Complete a level after 10 PM',
      type: AchievementType.special,
      category: AchievementCategory.special,
      rarity: AchievementRarity.uncommon,
      icon: Icons.nightlight,
      color: Color(0xFF3F51B5),
      maxProgress: 1,
      rewardGold: 300,
    ),
  ];

  /// Get achievement by ID
  static Achievement? getAchievementById(String id) {
    try {
      return defaultAchievements.firstWhere(
        (achievement) => achievement.id == id,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get achievements by category
  static List<Achievement> getAchievementsByCategory(
    AchievementCategory category,
  ) => defaultAchievements
      .where((achievement) => achievement.category == category)
      .toList();

  /// Get achievements by rarity
  static List<Achievement> getAchievementsByRarity(AchievementRarity rarity) =>
      defaultAchievements
          .where((achievement) => achievement.rarity == rarity)
          .toList();

  /// Get achievements by type
  static List<Achievement> getAchievementsByType(AchievementType type) =>
      defaultAchievements
          .where((achievement) => achievement.type == type)
          .toList();

  /// Get all achievements
  static List<Achievement> getAllAchievements() =>
      List.from(defaultAchievements);
}
