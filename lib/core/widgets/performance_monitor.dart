import 'package:flutter/material.dart';
import '../game/game_loop.dart';
import '../theme/app_colors.dart';

/// Performance monitoring widget that displays FPS and frame time
class PerformanceMonitor extends StatelessWidget {
  final GameLoop gameLoop;

  const PerformanceMonitor({super.key, required this.gameLoop});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: Stream.periodic(
        const Duration(milliseconds: 500),
        (_) => gameLoop.currentFPS,
      ),
      builder: (context, snapshot) {
        final fps = snapshot.data ?? 0.0;
        final frameTime = gameLoop.frameTime * 1000; // Convert to milliseconds

        // Color based on performance
        Color fpsColor;
        if (fps >= 55) {
          fpsColor = Colors.green;
        } else if (fps >= 45) {
          fpsColor = Colors.orange;
        } else {
          fpsColor = Colors.red;
        }

        return Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.hudBackground.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.hudBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.speed, size: 16, color: fpsColor),
                const SizedBox(width: 4),
                Text(
                  '${fps.toStringAsFixed(1)} FPS',
                  style: TextStyle(
                    color: fpsColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${frameTime.toStringAsFixed(1)}ms',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
