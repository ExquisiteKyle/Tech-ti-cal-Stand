import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../audio/audio_manager.dart';
import '../../features/game/domain/models/tower.dart';
import '../../features/game/presentation/providers/game_state_provider.dart';

/// Tower upgrade dialog that shows as a popup when a tower is selected
class TowerUpgradeDialog extends ConsumerStatefulWidget {
  final Tower tower;

  const TowerUpgradeDialog({super.key, required this.tower});

  @override
  ConsumerState<TowerUpgradeDialog> createState() => _TowerUpgradeDialogState();

  /// Show the tower upgrade dialog
  static Future<void> show(BuildContext context, Tower tower) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => TowerUpgradeDialog(tower: tower),
    );
  }
}

class _TowerUpgradeDialogState extends ConsumerState<TowerUpgradeDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final upgradeCost = widget.tower.getUpgradeCost();
    final canAfford = gameState.canAfford(upgradeCost);
    final canUpgrade = widget.tower.upgradeLevel < 3;
    final upgradeDescriptions = widget.tower.getUpgradeDescriptions();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                  maxHeight: 600,
                ),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.pastelLavender.withValues(alpha: 0.98),
                      AppColors.pastelSky.withValues(alpha: 0.98),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.hudBorder.withValues(alpha: 0.8),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with tower info and close button
                    Row(
                      children: [
                        // Tower icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: widget.tower.towerColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _getTowerIcon(widget.tower.type),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Tower name and level
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.tower.name,
                                style: const TextStyle(
                                  color: Color(0xFF2D2A26),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Level ${widget.tower.upgradeLevel}',
                                    style: const TextStyle(
                                      color: Color(0xFF4A4A4A),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Level stars
                                  ...List.generate(
                                    3,
                                    (index) => Padding(
                                      padding: const EdgeInsets.only(right: 2),
                                      child: Icon(
                                        index < widget.tower.upgradeLevel
                                            ? Icons.star
                                            : Icons.star_border,
                                        size: 16,
                                        color: index < widget.tower.upgradeLevel
                                            ? Colors.amber
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Close button
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Tower description
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.pastelMint.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.pastelMint.withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.tower.description,
                        style: const TextStyle(
                          color: Color(0xFF2D2A26),
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Current stats
                    Text(
                      'Current Stats',
                      style: const TextStyle(
                        color: Color(0xFF2D2A26),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.pastelMint.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.pastelMint.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildStatRow(
                            'Damage',
                            widget.tower.damage.toInt().toString(),
                            Icons.flash_on,
                            Colors.orange,
                          ),
                          const SizedBox(height: 8),
                          _buildStatRow(
                            'Range',
                            widget.tower.range.toInt().toString(),
                            Icons.radio_button_unchecked,
                            Colors.blue,
                          ),
                          const SizedBox(height: 8),
                          _buildStatRow(
                            'Attack Speed',
                            '${widget.tower.attackSpeed.toStringAsFixed(1)}/s',
                            Icons.speed,
                            Colors.green,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Upgrade section
                    if (canUpgrade) ...[
                      Text(
                        'Upgrade Options',
                        style: const TextStyle(
                          color: Color(0xFF2D2A26),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Upgrade paths
                      if (widget.tower.upgradeLevel == 0 ||
                          widget.tower.selectedUpgradePath == null) ...[
                        // Show both paths for level 0 towers
                        _buildUpgradeOption(
                          context,
                          'Path 1: Specialization',
                          upgradeDescriptions.isNotEmpty
                              ? upgradeDescriptions[0]
                              : 'Upgrade Path 1',
                          upgradeCost,
                          canAfford,
                          UpgradePath.path1,
                          Colors.blue,
                        ),

                        const SizedBox(height: 8),

                        _buildUpgradeOption(
                          context,
                          'Path 2: Enhancement',
                          upgradeDescriptions.length > 1
                              ? upgradeDescriptions[1]
                              : 'Upgrade Path 2',
                          upgradeCost,
                          canAfford,
                          UpgradePath.path2,
                          Colors.purple,
                        ),
                      ] else ...[
                        // Show only selected path for upgraded towers
                        _buildUpgradeOption(
                          context,
                          widget.tower.selectedUpgradePath == UpgradePath.path1
                              ? 'Path 1: Specialization'
                              : 'Path 2: Enhancement',
                          widget.tower.selectedUpgradePath == UpgradePath.path1
                              ? (upgradeDescriptions.isNotEmpty
                                    ? upgradeDescriptions[0]
                                    : 'Upgrade Path 1')
                              : (upgradeDescriptions.length > 1
                                    ? upgradeDescriptions[1]
                                    : 'Upgrade Path 2'),
                          upgradeCost,
                          canAfford,
                          widget.tower.selectedUpgradePath!,
                          widget.tower.selectedUpgradePath == UpgradePath.path1
                              ? Colors.blue
                              : Colors.purple,
                        ),
                      ],
                    ] else ...[
                      // Max level reached
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.goldYellow.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.goldYellow.withValues(alpha: 0.6),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'MAXIMUM LEVEL REACHED',
                              style: TextStyle(
                                color: Color(0xFF2D2A26),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) => Row(
    children: [
      Icon(icon, size: 18, color: iconColor),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF4A4A4A),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      const Spacer(),
      Text(
        value,
        style: const TextStyle(
          color: Color(0xFF2D2A26),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );

  Widget _buildUpgradeOption(
    BuildContext context,
    String pathName,
    String description,
    int cost,
    bool canAfford,
    UpgradePath path,
    Color pathColor,
  ) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeInOut,
    decoration: BoxDecoration(
      color: canAfford
          ? AppColors.buttonSuccess.withValues(alpha: 0.2)
          : AppColors.buttonWarning.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: canAfford
            ? AppColors.buttonSuccess.withValues(alpha: 0.4)
            : AppColors.buttonWarning.withValues(alpha: 0.4),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: pathColor.withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: canAfford ? () => _upgradeTowerWithAnimation(path) : null,
        splashColor: pathColor.withValues(alpha: 0.3),
        highlightColor: pathColor.withValues(alpha: 0.1),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 300),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.8 + (0.2 * value),
                        child: Icon(
                          Icons.arrow_upward,
                          size: 18,
                          color: pathColor,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  Text(
                    pathName,
                    style: const TextStyle(
                      color: Color(0xFF2D2A26),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 400),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: Icon(
                              Icons.monetization_on,
                              size: 16,
                              color: canAfford ? Colors.green : Colors.red,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: canAfford ? Colors.green : Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        child: Text(cost.toString()),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: const TextStyle(
                  color: Color(0xFF4A4A4A),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                child: Text(description),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  void _upgradeTowerWithAnimation(UpgradePath path) {
    final gameStateNotifier = ref.read(gameStateProvider.notifier);
    final upgradeCost = widget.tower.getUpgradeCost();

    // Check if player can afford the upgrade
    if (gameStateNotifier.spendGold(upgradeCost)) {
      // Play upgrade sound
      AudioManager().playSfx(AudioEvent.towerUpgrade);

      // Perform the upgrade
      widget.tower.upgrade(path);

      // Add a small scale animation for feedback
      _animationController.reverse().then((_) {
        if (mounted) {
          // Re-open the animation for feedback, but do NOT close the dialog
          _animationController.forward();
        }
      });
    }
  }

  Widget _getTowerIcon(TowerType type) {
    switch (type) {
      case TowerType.archer:
        return const Icon(Icons.sports_score, color: Colors.white, size: 24);
      case TowerType.cannon:
        return const Icon(Icons.circle, color: Colors.white, size: 24);
      case TowerType.magic:
        return const Icon(Icons.auto_fix_high, color: Colors.white, size: 24);
      case TowerType.sniper:
        return const Icon(Icons.my_location, color: Colors.white, size: 24);
    }
  }
}
