import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/achievement.dart';
import '../providers/achievement_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/audio/audio_manager.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AchievementCategory.values.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievementStats = ref.watch(achievementStatsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildStatsOverview(achievementStats),
              _buildTabBar(),
              Expanded(child: _buildTabBarView()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        IconButton(
          onPressed: () {
            AudioManager().playSfx(AudioEvent.buttonClick);
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 8),
        const Text(
          'Achievements',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => _showAchievementStats(),
          icon: const Icon(Icons.info_outline, color: AppColors.textPrimary),
        ),
      ],
    ),
  );

  Widget _buildStatsOverview(AsyncValue<Map<String, dynamic>> statsAsync) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: statsAsync.when(
        data: (stats) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Total',
              '${stats['totalAchievements']}',
              Icons.emoji_events,
              AppColors.textAccent,
            ),
            _buildStatItem(
              'Unlocked',
              '${stats['unlockedAchievements']}',
              Icons.lock_open,
              AppColors.healthGreen,
            ),
            _buildStatItem(
              'Progress',
              '${stats['completionRate'].toStringAsFixed(1)}%',
              Icons.trending_up,
              AppColors.waveBlue,
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Text('Error: $error'),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textOnPastel,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: AppColors.backgroundCard,
      borderRadius: BorderRadius.circular(12),
    ),
    child: TabBar(
      controller: _tabController,
      isScrollable: true,
      indicatorColor: AppColors.buttonPrimary,
      labelColor: AppColors.textPrimary,
      unselectedLabelColor: AppColors.textSecondary,
      tabs: AchievementCategory.values.map((category) {
        return Tab(text: _getCategoryDisplayName(category));
      }).toList(),
    ),
  );

  Widget _buildTabBarView() => TabBarView(
    controller: _tabController,
    children: AchievementCategory.values.map((category) {
      return _buildCategoryView(category);
    }).toList(),
  );

  Widget _buildCategoryView(AchievementCategory category) {
    final achievementsAsync = ref.watch(
      achievementsByCategoryProvider(category),
    );

    return achievementsAsync.when(
      data: (achievements) {
        if (achievements.isEmpty) {
          return const Center(
            child: Text(
              'No achievements in this category',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            return _buildAchievementCard(achievements[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          'Error loading achievements: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achievement.isUnlocked
              ? achievement.rarityColor.withValues(alpha: 0.5)
              : AppColors.gridLine,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: achievement.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    achievement.icon,
                    color: achievement.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            achievement.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: achievement.isUnlocked
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildRarityBadge(achievement.rarity),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: achievement.isUnlocked
                              ? AppColors.textSecondary
                              : AppColors.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (achievement.isUnlocked)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.healthGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: AppColors.healthGreen,
                      size: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildProgressBar(achievement),
            if (achievement.rewardGold > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: AppColors.goldYellow,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Reward: ${achievement.rewardGold} Gold',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.goldYellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            if (achievement.isUnlocked && achievement.unlockedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Unlocked: ${_formatDate(achievement.unlockedAt!)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRarityBadge(AchievementRarity rarity) {
    Color badgeColor;
    switch (rarity) {
      case AchievementRarity.common:
        badgeColor = Colors.grey;
        break;
      case AchievementRarity.uncommon:
        badgeColor = Colors.green;
        break;
      case AchievementRarity.rare:
        badgeColor = Colors.blue;
        break;
      case AchievementRarity.epic:
        badgeColor = Colors.purple;
        break;
      case AchievementRarity.legendary:
        badgeColor = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        rarity.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildProgressBar(Achievement achievement) {
    final progress = achievement.progressPercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            Text(
              '${achievement.currentProgress}/${achievement.maxProgress}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.gridLine,
          valueColor: AlwaysStoppedAnimation<Color>(
            achievement.isUnlocked ? AppColors.healthGreen : achievement.color,
          ),
          minHeight: 6,
        ),
      ],
    );
  }

  String _getCategoryDisplayName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.towers:
        return 'Towers';
      case AchievementCategory.strategy:
        return 'Strategy';
      case AchievementCategory.levels:
        return 'Levels';
      case AchievementCategory.combat:
        return 'Combat';
      case AchievementCategory.time:
        return 'Time';
      case AchievementCategory.special:
        return 'Special';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAchievementStats() {
    AudioManager().playSfx(AudioEvent.buttonClick);

    showDialog(
      context: context,
      builder: (context) => const _AchievementStatsDialog(),
    );
  }
}

class _AchievementStatsDialog extends ConsumerWidget {
  const _AchievementStatsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(achievementStatsProvider);
    final recentAsync = ref.watch(recentAchievementsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Achievement Stats',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    statsAsync.when(
                      data: (stats) => _buildDetailedStats(stats),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Text('Error: $error'),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Recent Achievements',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    recentAsync.when(
                      data: (recent) => _buildRecentAchievements(recent),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Text('Error: $error'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStats(Map<String, dynamic> stats) {
    final categoryStats =
        stats['categoryStats'] as Map<AchievementCategory, Map<String, int>>;

    return Column(
      children: [
        for (final category in AchievementCategory.values)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getCategoryDisplayName(category),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${categoryStats[category]!['unlocked']}/${categoryStats[category]!['total']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRecentAchievements(List<Achievement> recent) {
    if (recent.isEmpty) {
      return const Text(
        'No recent achievements',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    return Column(
      children: recent.take(5).map((achievement) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(achievement.icon, color: achievement.color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  achievement.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getCategoryDisplayName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.towers:
        return 'Towers';
      case AchievementCategory.strategy:
        return 'Strategy';
      case AchievementCategory.levels:
        return 'Levels';
      case AchievementCategory.combat:
        return 'Combat';
      case AchievementCategory.time:
        return 'Time';
      case AchievementCategory.special:
        return 'Special';
    }
  }
}
