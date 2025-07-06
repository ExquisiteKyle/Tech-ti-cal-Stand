import 'package:flutter/material.dart';

/// Comprehensive MMORPG-style player UI matching the reference design
class MMORPGPlayerUI extends StatefulWidget {
  final String playerName;
  final int playerLevel;
  final int currentHealth;
  final int maxHealth;
  final int gold;
  final int score;
  final int enemiesInField;
  final String? portraitAsset;

  const MMORPGPlayerUI({
    super.key,
    required this.playerName,
    required this.playerLevel,
    required this.currentHealth,
    required this.maxHealth,
    required this.gold,
    required this.score,
    required this.enemiesInField,
    this.portraitAsset,
  });

  @override
  State<MMORPGPlayerUI> createState() => _MMORPGPlayerUIState();
}

class _MMORPGPlayerUIState extends State<MMORPGPlayerUI>
    with TickerProviderStateMixin {
  late AnimationController _healthAnimationController;
  late AnimationController _glowAnimationController;

  late Animation<double> _healthAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _healthAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _glowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _healthAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _healthAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations
    _healthAnimationController.forward();
    _glowAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _healthAnimationController.dispose();
    _glowAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25), // Matches portrait circle
          bottomLeft: Radius.circular(25),
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A).withValues(alpha: 0.4),
            const Color(0xFF2D2A26).withValues(alpha: 0.3),
            const Color(0xFF1A1A1A).withValues(alpha: 0.2),
            const Color(0xFF8B4513).withValues(alpha: 0.1),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
        border: Border.all(
          color: const Color(0xFF8B4513).withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CustomPaint(
        painter: PatternPainter(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Character Portrait
            _buildCharacterPortrait(),

            const SizedBox(width: 6),

            // Player Info and Bars - Use Expanded to fill available space
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Player Name
                  _buildPlayerName(),

                  const SizedBox(height: 1),

                  // Health Bar
                  _buildHealthBar(),

                  const SizedBox(height: 2),

                  // Resource Display
                  _buildResourceDisplay(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterPortrait() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF8B4513).withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.2,
              colors: [Color(0xFF4A4A4A), Color(0xFF2D2A26), Color(0xFF1A1A1A)],
            ),
          ),
          child: widget.portraitAsset != null
              ? Image.asset(widget.portraitAsset!, fit: BoxFit.cover)
              : const Icon(Icons.shield, size: 24, color: Color(0xFFFFD700)),
        ),
      ),
    );
  }

  Widget _buildPlayerName() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: const Color(0xFF8B4513).withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.playerName,
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black,
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 3),
          Text(
            'Lv.${widget.playerLevel}',
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthBar() {
    final healthPercentage = widget.maxHealth > 0
        ? (widget.currentHealth / widget.maxHealth).clamp(0.0, 1.0)
        : 0.0;

    return AnimatedBuilder(
      animation: _healthAnimation,
      builder: (context, child) {
        final animatedPercentage = healthPercentage * _healthAnimation.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Health label
            const Text(
              'Health',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Health bar container
            Container(
              width: double.infinity,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF8B4513).withValues(alpha: 0.6),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                  // Critical health pulsing effect
                  if (healthPercentage < 0.3)
                    BoxShadow(
                      color: const Color(
                        0xFFFF4500,
                      ).withValues(alpha: 0.6 * _glowAnimation.value),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Stack(
                children: [
                  // Clipped health bar graphics
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        // Background
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF2D1B0E), Color(0xFF1A0F08)],
                            ),
                          ),
                        ),

                        // Health fill
                        FractionallySizedBox(
                          widthFactor: animatedPercentage,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: _getHealthColors(healthPercentage),
                              ),
                            ),
                          ),
                        ),

                        // Inner highlight
                        FractionallySizedBox(
                          widthFactor: animatedPercentage,
                          heightFactor: 0.4,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.3),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Health text (outside ClipRRect so it's not clipped)
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        '${widget.currentHealth}/${widget.maxHealth}',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResourceDisplay() {
    return Row(
      children: [
        // Gold
        Expanded(
          child: _buildResourceItem(
            icon: Icons.monetization_on,
            label: 'Gold',
            value: widget.gold.toString(),
            color: const Color(0xFFFFD700),
          ),
        ),

        const SizedBox(width: 2),

        // Score
        Expanded(
          child: _buildResourceItem(
            icon: Icons.star,
            label: 'Score',
            value: widget.score.toString(),
            color: const Color(0xFFDDA0DD),
          ),
        ),

        const SizedBox(width: 2),

        // Enemy Counter
        Expanded(
          child: _buildResourceItem(
            icon: Icons.bug_report,
            label: 'Enemies',
            value: widget.enemiesInField.toString(),
            color: const Color(0xFFFF6B6B),
          ),
        ),
      ],
    );
  }

  Widget _buildResourceItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 8, color: color),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getHealthColors(double percentage) {
    if (percentage > 0.6) {
      return [const Color(0xFF32CD32), const Color(0xFF228B22)];
    } else if (percentage > 0.3) {
      return [const Color(0xFFFFD700), const Color(0xFFFF8C00)];
    } else {
      return [const Color(0xFFFF4500), const Color(0xFFDC143C)];
    }
  }
}

// Custom painter for subtle dot pattern
class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B4513).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Create a subtle dot pattern
    const dotSize = 1.0;
    const spacing = 12.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Add some randomness to make it more organic
        final offsetX = x + (y % 2 == 0 ? 0 : spacing / 2);
        canvas.drawCircle(Offset(offsetX, y), dotSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
