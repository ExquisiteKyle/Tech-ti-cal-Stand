import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Game Over dialog that shows when player health reaches 0
class GameOverDialog extends StatefulWidget {
  final int finalScore;
  final int finalWave;
  final int goldEarned;
  final Duration? gameDuration;
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  const GameOverDialog({
    super.key,
    required this.finalScore,
    required this.finalWave,
    required this.goldEarned,
    this.gameDuration,
    required this.onRestart,
    required this.onQuit,
  });

  @override
  State<GameOverDialog> createState() => _GameOverDialogState();
}

class _GameOverDialogState extends State<GameOverDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animationController,
    builder: (context, child) => Container(
      color: Colors.black.withValues(alpha: 0.7 * _fadeAnimation.value),
      child: Center(
        child: Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 320,
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.pastelLavender.withValues(alpha: 0.95),
                  AppColors.pastelSky.withValues(alpha: 0.95),
                  AppColors.pastelMint.withValues(alpha: 0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.hudBorder.withValues(alpha: 0.8),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.pastelRose.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(17),
                      topRight: Radius.circular(17),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.heart_broken,
                        size: 48,
                        color: Color(0xFFFF6B6B),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'GAME OVER',
                        style: TextStyle(
                          color: Color(
                            0xFF2D2A26,
                          ), // Dark brown for high contrast
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: Colors.white,
                              offset: Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Your defenses have fallen!',
                        style: TextStyle(
                          color: Color(
                            0xFF4A4A4A,
                          ), // Darker gray for better contrast
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Final Statistics',
                        style: TextStyle(
                          color: Color(
                            0xFF2D2A26,
                          ), // Dark brown for high contrast
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.white,
                              offset: Offset(0.5, 0.5),
                              blurRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Score
                      _buildStatRow(
                        icon: Icons.star,
                        label: 'Final Score',
                        value: widget.finalScore.toString(),
                        color: const Color(0xFF9B59B6), // Vibrant purple
                      ),

                      const SizedBox(height: 12),

                      // Wave
                      _buildStatRow(
                        icon: Icons.waves,
                        label: 'Waves Survived',
                        value: '${widget.finalWave - 1}',
                        color: const Color(0xFF3498DB), // Vibrant blue
                      ),

                      const SizedBox(height: 12),

                      // Gold
                      _buildStatRow(
                        icon: Icons.monetization_on,
                        label: 'Gold Earned',
                        value: widget.goldEarned.toString(),
                        color: const Color(0xFFE67E22), // Vibrant orange
                      ),

                      if (widget.gameDuration != null) ...[
                        const SizedBox(height: 12),
                        _buildStatRow(
                          icon: Icons.timer,
                          label: 'Time Survived',
                          value: _formatDuration(widget.gameDuration!),
                          color: const Color(0xFF27AE60), // Vibrant green
                        ),
                      ],
                    ],
                  ),
                ),

                // Buttons Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      // Restart Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: widget.onRestart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF98E4D6,
                            ), // Pastel mint green
                            foregroundColor: const Color(
                              0xFF2D2A26,
                            ), // Dark brown text
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(
                              color: Color(0xFF2D2A26),
                              width: 2,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Try Again',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Quit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: widget.onQuit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFFE6B3FF,
                            ), // Pastel lavender
                            foregroundColor: const Color(
                              0xFF2D2A26,
                            ), // Dark brown text
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(
                              color: Color(0xFF2D2A26),
                              width: 2,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.exit_to_app, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Main Menu',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF2D2A26), // Dark brown for high contrast
              fontSize: 16,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.white,
                  offset: Offset(0.5, 0.5),
                  blurRadius: 1,
                ),
              ],
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
