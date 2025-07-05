import 'package:flutter/material.dart';

/// MMORPG-style health bar widget with fantasy game aesthetics
class MMORPGHealthBar extends StatefulWidget {
  final int currentHealth;
  final int maxHealth;
  final double width;
  final double height;
  final String? label;
  final bool showNumbers;
  final bool showGlow;

  const MMORPGHealthBar({
    super.key,
    required this.currentHealth,
    required this.maxHealth,
    this.width = 200,
    this.height = 24,
    this.label,
    this.showNumbers = true,
    this.showGlow = true,
  });

  @override
  State<MMORPGHealthBar> createState() => _MMORPGHealthBarState();
}

class _MMORPGHealthBarState extends State<MMORPGHealthBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _healthAnimation;
  late Animation<double> _glowAnimation;

  double _previousHealthPercentage = 1.0;
  double _targetHealthPercentage = 1.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _healthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _updateHealthPercentage();
  }

  @override
  void didUpdateWidget(MMORPGHealthBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentHealth != widget.currentHealth ||
        oldWidget.maxHealth != widget.maxHealth) {
      _updateHealthPercentage();
    }
  }

  void _updateHealthPercentage() {
    _previousHealthPercentage = _targetHealthPercentage;
    _targetHealthPercentage = widget.maxHealth > 0
        ? (widget.currentHealth / widget.maxHealth).clamp(0.0, 1.0)
        : 0.0;

    _animationController.reset();

    // Different animation behavior based on health
    if (_targetHealthPercentage < 0.3) {
      // Critical health - fast pulsing
      _animationController.duration = const Duration(milliseconds: 600);
      _animationController.repeat(reverse: true);
    } else if (_targetHealthPercentage > 0.95) {
      // Full health - slow shine effect
      _animationController.duration = const Duration(milliseconds: 2000);
      _animationController.repeat(reverse: true);
    } else {
      // Normal health - single animation
      _animationController.duration = const Duration(milliseconds: 800);
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final currentPercentage =
            _previousHealthPercentage +
            (_targetHealthPercentage - _previousHealthPercentage) *
                _healthAnimation.value;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            if (widget.label != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  widget.label!,
                  style: const TextStyle(
                    color: Color(0xFF4A4A4A),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Color(0x40000000),
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

            // Health bar container
            Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.height / 2),
                border: Border.all(color: const Color(0xFF8B4513), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                  if (widget.showGlow && currentPercentage > 0.7)
                    BoxShadow(
                      color: const Color(
                        0xFF32CD32,
                      ).withValues(alpha: 0.6 * _glowAnimation.value),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  // Critical health pulsing red glow
                  if (widget.showGlow && currentPercentage < 0.3)
                    BoxShadow(
                      color: const Color(
                        0xFFFF4500,
                      ).withValues(alpha: 0.8 * _glowAnimation.value),
                      blurRadius: 12,
                      spreadRadius: 3,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.height / 2),
                child: Stack(
                  children: [
                    // Background
                    Container(
                      width: widget.width,
                      height: widget.height,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF2D1B0E), Color(0xFF1A0F08)],
                        ),
                      ),
                    ),

                    // Health fill
                    Container(
                      width: widget.width * currentPercentage,
                      height: widget.height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: _getHealthColors(currentPercentage),
                        ),
                      ),
                    ),

                    // Inner glow effect
                    if (widget.showGlow && currentPercentage > 0)
                      Container(
                        width: widget.width * currentPercentage,
                        height: widget.height * 0.4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(
                                alpha: 0.3 * _glowAnimation.value,
                              ),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),

                    // Segmented lines (like classic MMO health bars)
                    ...List.generate(4, (index) {
                      final position = (index + 1) * (widget.width / 5);
                      return Positioned(
                        left: position,
                        child: Container(
                          width: 1,
                          height: widget.height,
                          color: const Color(0xFF8B4513).withValues(alpha: 0.6),
                        ),
                      );
                    }),

                    // Animated shine effect for full health
                    if (currentPercentage > 0.95 && widget.showGlow)
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Positioned(
                            left:
                                -widget.width +
                                (widget.width * 2 * _glowAnimation.value),
                            child: Container(
                              width: widget.width * 0.3,
                              height: widget.height,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withValues(alpha: 0.4),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    // Health text overlay
                    if (widget.showNumbers)
                      Positioned.fill(
                        child: Center(
                          child: Text(
                            '${widget.currentHealth}/${widget.maxHealth}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: widget.height * 0.5,
                              fontWeight: FontWeight.bold,
                              shadows: const [
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
            ),
          ],
        );
      },
    );
  }

  List<Color> _getHealthColors(double percentage) {
    if (percentage > 0.6) {
      // Healthy - Green gradient
      return [const Color(0xFF32CD32), const Color(0xFF228B22)];
    } else if (percentage > 0.3) {
      // Caution - Yellow/Orange gradient
      return [const Color(0xFFFFD700), const Color(0xFFFF8C00)];
    } else {
      // Critical - Red gradient
      return [const Color(0xFFFF4500), const Color(0xFFDC143C)];
    }
  }
}

/// Enhanced MMORPG health bar with additional features
class EnhancedMMORPGHealthBar extends StatelessWidget {
  final int currentHealth;
  final int maxHealth;
  final String playerName;
  final int playerLevel;
  final double width;

  const EnhancedMMORPGHealthBar({
    super.key,
    required this.currentHealth,
    required this.maxHealth,
    required this.playerName,
    this.playerLevel = 1,
    this.width = 250,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF2D1B0E).withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF8B4513), width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Player info
        Row(
          children: [
            Icon(Icons.person, color: const Color(0xFFFFD700), size: 16),
            const SizedBox(width: 4),
            Text(
              playerName,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              'Lv.$playerLevel',
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Health bar
        MMORPGHealthBar(
          currentHealth: currentHealth,
          maxHealth: maxHealth,
          width: width - 24,
          height: 20,
          showNumbers: true,
          showGlow: true,
        ),
      ],
    ),
  );
}
