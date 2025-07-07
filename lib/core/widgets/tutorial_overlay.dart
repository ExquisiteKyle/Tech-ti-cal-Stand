import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../audio/audio_manager.dart';

/// Tutorial step data
class TutorialStep {
  final String id;
  final String title;
  final String description;
  final String? targetElementId;
  final Offset? targetPosition;
  final TutorialStepType type;
  final List<String>? actions;

  const TutorialStep({
    required this.id,
    required this.title,
    required this.description,
    this.targetElementId,
    this.targetPosition,
    required this.type,
    this.actions,
  });
}

/// Tutorial step types
enum TutorialStepType { info, highlight, action, completion }

/// Tutorial overlay widget for guiding new players
class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback? onComplete;
  final bool isActive;

  const TutorialOverlay({
    super.key,
    required this.steps,
    this.onComplete,
    this.isActive = true,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentStepIndex = 0;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    if (widget.isActive) {
      _showTutorial();
    }
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );
  }

  void _showTutorial() {
    setState(() {
      _isVisible = true;
    });
    _fadeController.forward();
    _slideController.forward();
  }

  void _hideTutorial() {
    _fadeController.reverse();
    _slideController.reverse().then((_) {
      setState(() {
        _isVisible = false;
      });
    });
  }

  void _nextStep() {
    AudioManager().playSfx(AudioEvent.buttonClick);

    if (_currentStepIndex < widget.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
      _slideController.reset();
      _slideController.forward();
    } else {
      _completeTutorial();
    }
  }

  void _previousStep() {
    AudioManager().playSfx(AudioEvent.buttonClick);

    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
      _slideController.reset();
      _slideController.forward();
    }
  }

  void _completeTutorial() {
    _hideTutorial();
    widget.onComplete?.call();
  }

  void _skipTutorial() {
    AudioManager().playSfx(AudioEvent.buttonClick);
    _completeTutorial();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive || !_isVisible || widget.steps.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentStep = widget.steps[_currentStepIndex];

    return AnimatedBuilder(
      animation: Listenable.merge([_fadeController, _slideController]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Stack(
              children: [
                // Semi-transparent overlay
                Container(color: Colors.black.withValues(alpha: 0.7)),
                // Tutorial content
                _buildTutorialContent(currentStep),
                // Navigation buttons
                _buildNavigationButtons(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTutorialContent(TutorialStep step) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(40),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.pastelLavender.withValues(alpha: 0.98),
              AppColors.pastelSky.withValues(alpha: 0.98),
              AppColors.pastelMint.withValues(alpha: 0.95),
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
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.pastelRose.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStepIcon(step.type),
                    size: 24,
                    color: AppColors.textAccent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step.title,
                      style: const TextStyle(
                        color: Color(0xFF2D2A26),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${_currentStepIndex + 1}/${widget.steps.length}',
                    style: const TextStyle(
                      color: Color(0xFF2D2A26),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    step.description,
                    style: const TextStyle(
                      color: Color(0xFF2D2A26),
                      fontSize: 16,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (step.actions != null) ...[
                    const SizedBox(height: 16),
                    ...step.actions!.map(
                      (action) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.buttonSuccess,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                action,
                                style: const TextStyle(
                                  color: Color(0xFF2D2A26),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Skip button
          TextButton(
            onPressed: _skipTutorial,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Skip Tutorial', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 20),
          // Previous button
          if (_currentStepIndex > 0)
            ElevatedButton(
              onPressed: _previousStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pastelPeach.withValues(alpha: 0.8),
                foregroundColor: AppColors.textOnPastel,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Previous',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          if (_currentStepIndex > 0) const SizedBox(width: 12),
          // Next/Complete button
          ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonSuccess.withValues(alpha: 0.8),
              foregroundColor: AppColors.textOnPastel,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _currentStepIndex < widget.steps.length - 1 ? 'Next' : 'Complete',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStepIcon(TutorialStepType type) {
    switch (type) {
      case TutorialStepType.info:
        return Icons.info_outline;
      case TutorialStepType.highlight:
        return Icons.visibility;
      case TutorialStepType.action:
        return Icons.touch_app;
      case TutorialStepType.completion:
        return Icons.check_circle;
    }
  }
}

/// Tutorial manager for handling tutorial state and progression
class TutorialManager {
  static TutorialManager? _instance;
  static TutorialManager get instance => _instance ??= TutorialManager._();

  TutorialManager._();

  static const String _tutorialCompletedKey = 'tutorial_completed';
  static const String _tutorialStepKey = 'tutorial_step';

  bool _isTutorialCompleted = false;
  int _currentTutorialStep = 0;

  /// Initialize tutorial manager
  Future<void> initialize() async {
    // Load tutorial state from SharedPreferences
    // For now, we'll use default values
    _isTutorialCompleted = false;
    _currentTutorialStep = 0;
  }

  /// Check if tutorial is completed
  bool get isTutorialCompleted => _isTutorialCompleted;

  /// Get current tutorial step
  int get currentTutorialStep => _currentTutorialStep;

  /// Mark tutorial as completed
  Future<void> completeTutorial() async {
    _isTutorialCompleted = true;
    // Save to SharedPreferences
  }

  /// Reset tutorial progress
  Future<void> resetTutorial() async {
    _isTutorialCompleted = false;
    _currentTutorialStep = 0;
    // Save to SharedPreferences
  }

  /// Get tutorial steps for the main game
  List<TutorialStep> getMainGameTutorial() {
    return [
      const TutorialStep(
        id: 'welcome',
        title: 'Welcome to Techtical Defense!',
        description:
            'Let\'s learn the basics of tower defense. You\'ll place towers to defend against waves of enemies.',
        type: TutorialStepType.info,
      ),
      const TutorialStep(
        id: 'tower_shop',
        title: 'Tower Shop',
        description:
            'This is your tower shop. You can buy different types of towers with gold. Each tower has unique abilities.',
        type: TutorialStepType.highlight,
        targetElementId: 'tower_shop',
        actions: [
          'Archer Tower: Fast attacks, good against light enemies',
          'Cannon Tower: Splash damage, effective against groups',
          'Magic Tower: Slows enemies, magical damage',
          'Sniper Tower: High damage, long range',
        ],
      ),
      const TutorialStep(
        id: 'placement',
        title: 'Tower Placement',
        description:
            'Drag towers from the shop to place them on the battlefield. Towers can only be placed on valid tiles.',
        type: TutorialStepType.action,
        actions: [
          'Drag a tower from the shop',
          'Drop it on a valid tile (green highlight)',
          'Towers will automatically attack enemies in range',
        ],
      ),
      const TutorialStep(
        id: 'resources',
        title: 'Resources',
        description:
            'Manage your gold and lives carefully. You lose lives when enemies reach the end of the path.',
        type: TutorialStepType.info,
        actions: [
          'Gold: Earned by defeating enemies',
          'Lives: Lost when enemies reach the end',
          'Score: Increases with each enemy defeated',
        ],
      ),
      const TutorialStep(
        id: 'waves',
        title: 'Wave System',
        description:
            'Enemies come in waves. Each wave gets progressively harder. Prepare between waves!',
        type: TutorialStepType.info,
        actions: [
          'Waves get harder over time',
          'Use preparation time to build towers',
          'Boss enemies appear every 5 waves',
        ],
      ),
      const TutorialStep(
        id: 'upgrades',
        title: 'Tower Upgrades',
        description:
            'Click on placed towers to upgrade them. Upgrades improve damage, range, or add special effects.',
        type: TutorialStepType.action,
        actions: [
          'Click on any placed tower',
          'Choose an upgrade path',
          'Upgrades cost gold but are powerful',
        ],
      ),
      const TutorialStep(
        id: 'completion',
        title: 'You\'re Ready!',
        description:
            'You now know the basics of Techtical Defense. Good luck defending your territory!',
        type: TutorialStepType.completion,
      ),
    ];
  }

  /// Get tutorial steps for level selection
  List<TutorialStep> getLevelSelectionTutorial() {
    return [
      const TutorialStep(
        id: 'level_select',
        title: 'Level Selection',
        description:
            'Choose from different levels, each with unique challenges and enemy paths.',
        type: TutorialStepType.info,
      ),
      const TutorialStep(
        id: 'progression',
        title: 'Level Progression',
        description:
            'Complete levels to unlock new ones. Each level offers different difficulty and rewards.',
        type: TutorialStepType.info,
        actions: [
          'Complete levels to unlock new ones',
          'Higher levels have stronger enemies',
          'Master levels for perfect completion',
        ],
      ),
    ];
  }
}
