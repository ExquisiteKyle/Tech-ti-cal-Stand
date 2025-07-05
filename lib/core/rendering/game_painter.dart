import 'package:flutter/material.dart';
import '../game/entity_manager.dart';

/// Custom painter for rendering the game canvas
class GamePainter extends CustomPainter {
  final EntityManager entityManager;
  final Size gameSize;
  final double gameSpeed;
  final bool isPaused;

  GamePainter({
    required this.entityManager,
    required this.gameSize,
    this.gameSpeed = 1.0,
    this.isPaused = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Clear the canvas with background color
    _drawBackground(canvas, size);

    // Draw grid if in debug mode
    _drawGrid(canvas, size);

    // Render all game entities
    entityManager.render(canvas, size);

    // Draw pause overlay if paused
    if (isPaused) {
      _drawPauseOverlay(canvas, size);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    // Draw gradient background
    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFAF9F6), Color(0xFFF0E6FF), Color(0xFFE6F3FF)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE6E6E6)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const gridSize = 40.0;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawPauseOverlay(Canvas canvas, Size size) {
    // Semi-transparent pastel overlay
    final overlayPaint = Paint()
      ..color = const Color(0x80F5F3F0)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);

    // Pause text with pastel styling
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'PAUSED',
        style: TextStyle(
          color: Color(0xFF4A4A4A),
          fontSize: 48,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    return entityManager != oldDelegate.entityManager ||
        gameSpeed != oldDelegate.gameSpeed ||
        isPaused != oldDelegate.isPaused;
  }
}

/// Widget that wraps the game canvas
class GameCanvas extends StatelessWidget {
  final EntityManager entityManager;
  final double gameSpeed;
  final bool isPaused;
  final VoidCallback? onTap;

  const GameCanvas({
    super.key,
    required this.entityManager,
    this.gameSpeed = 1.0,
    this.isPaused = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: CustomPaint(
        painter: GamePainter(
          entityManager: entityManager,
          gameSize: Size(
            MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height,
          ),
          gameSpeed: gameSpeed,
          isPaused: isPaused,
        ),
      ),
    ),
  );
}
