import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/audio/audio_manager.dart';
import '../../../../core/game/game_engine.dart';
import '../providers/level_provider.dart';
import 'level_selection_screen.dart';
import 'achievements_screen.dart';

/// Main menu screen with beautiful UI and navigation options
class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeAudio();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
  }

  void _initializeAudio() {
    // Start menu music
    AudioManager().playMusic(AudioEvent.menuMusic);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Initialize level manager
    ref.watch(initializeLevelManagerProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.pastelLavender.withValues(alpha: 0.8),
              AppColors.pastelSky.withValues(alpha: 0.6),
              AppColors.backgroundSoft,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      _buildTitle(),
                      const SizedBox(height: 40),
                      _buildMenuButtons(),
                      const SizedBox(height: 40),
                      _buildFooter(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Techtical Defense',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textAccent,
                  shadows: [
                    Shadow(
                      color: AppColors.pastelLavender.withValues(alpha: 0.5),
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Strategic Tower Defense',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildProgressIndicator(),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Consumer(
      builder: (context, ref, child) {
        final levelManagerAsync = ref.watch(initializeLevelManagerProvider);

        return levelManagerAsync.when(
          data: (_) {
            final progress = ref.watch(overallProgressProvider);
            final completedLevels = ref.watch(completedLevelsProvider).length;
            final totalLevels = ref.watch(levelsProvider).length;

            if (progress > 0) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Text(
                      'Progress: $completedLevels/$totalLevels levels',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.2,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.secondary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildMenuButtons() {
    return Column(
      children: [
        _buildMenuButton(
          title: 'Quick Play',
          subtitle: 'Start first level',
          icon: Icons.play_arrow,
          onTap: _startQuickPlay,
          isPrimary: true,
        ),
        const SizedBox(height: 16),
        _buildMenuButton(
          title: 'Level Select',
          subtitle: 'Choose your challenge',
          icon: Icons.map,
          onTap: _openLevelSelection,
        ),
        const SizedBox(height: 16),
        _buildMenuButton(
          title: 'Achievements',
          subtitle: 'View your accomplishments',
          icon: Icons.emoji_events,
          onTap: _showAchievements,
        ),
        const SizedBox(height: 16),
        _buildMenuButton(
          title: 'Statistics',
          subtitle: 'View your progress',
          icon: Icons.analytics,
          onTap: _showStatistics,
        ),
        const SizedBox(height: 16),
        _buildMenuButton(
          title: 'Settings',
          subtitle: 'Audio and preferences',
          icon: Icons.settings,
          onTap: _showSettings,
        ),
      ],
    );
  }

  Widget _buildMenuButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: () {
        AudioManager().playSfx(AudioEvent.buttonClick);
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isPrimary
                ? [
                    AppColors.secondary,
                    AppColors.secondary.withValues(alpha: 0.8),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.9),
                    Colors.white.withValues(alpha: 0.7),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? AppColors.secondary.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isPrimary
                    ? AppColors.buttonPrimary.withValues(alpha: 0.9)
                    : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPrimary
                      ? AppColors.textAccent.withValues(alpha: 0.3)
                      : AppColors.cardBorder,
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isPrimary
                    ? AppColors.textAccent
                    : AppColors.textOnPastel,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isPrimary
                          ? AppColors.textAccent
                          : AppColors.textOnPastel,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isPrimary
                          ? AppColors.textAccent.withValues(alpha: 0.8)
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isPrimary ? AppColors.textAccent : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'v4.3.0 - Multiple Levels Update',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Built with Flutter & Riverpod',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  void _startQuickPlay() async {
    final levelManager = ref.read(levelManagerProvider);

    // Ensure level manager is initialized
    if (!levelManager.isInitialized) {
      await levelManager.initialize();
    }

    // Select the first available level
    final unlockedLevels = levelManager.getUnlockedLevels();
    if (unlockedLevels.isNotEmpty) {
      await levelManager.selectLevel(unlockedLevels.first.id);

      if (mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const GameEngine()));
      }
    }
  }

  void _openLevelSelection() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LevelSelectionScreen()),
    );
  }

  void _showStatistics() {
    showDialog(context: context, builder: (context) => _StatisticsDialog());
  }

  void _showAchievements() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AchievementsScreen()));
  }

  void _showSettings() {
    // TODO: Implement settings dialog
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings coming soon!')));
  }
}

/// Statistics dialog for main menu
class _StatisticsDialog extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelManagerAsync = ref.watch(initializeLevelManagerProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: levelManagerAsync.when(
          data: (_) {
            final stats = ref.watch(allStatisticsProvider);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Game Statistics',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textOnPastel,
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
                        _buildStatCard(
                          'Total Levels',
                          '${stats['totalLevels']}',
                        ),
                        _buildStatCard(
                          'Unlocked Levels',
                          '${stats['unlockedLevels']}',
                        ),
                        _buildStatCard(
                          'Completed Levels',
                          '${stats['completedLevels']}',
                        ),
                        _buildStatCard('Total Score', '${stats['totalScore']}'),
                        _buildStatCard(
                          'Total Play Time',
                          _formatDuration(
                            Duration(seconds: stats['totalPlayTime']),
                          ),
                        ),
                        _buildStatCard(
                          'Overall Progress',
                          '${(stats['overallProgress'] * 100).toStringAsFixed(1)}%',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              Center(child: Text('Error loading statistics: $error')),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.textAccent.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textOnPastel,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.buttonPrimary.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.textAccent.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
