import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../audio/audio_manager.dart';

/// Audio settings panel for controlling game audio
class AudioSettingsPanel extends StatefulWidget {
  final VoidCallback? onClose;

  const AudioSettingsPanel({super.key, this.onClose});

  @override
  State<AudioSettingsPanel> createState() => _AudioSettingsPanelState();

  /// Show the audio settings panel as a dialog
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => const AudioSettingsPanel(),
    );
  }
}

class _AudioSettingsPanelState extends State<AudioSettingsPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Audio settings state
  double _masterVolume = 1.0;
  double _sfxVolume = 1.0;
  double _musicVolume = 0.7;
  bool _isMuted = false;
  bool _isMusicMuted = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAudioSettings();
  }

  void _initializeAnimations() {
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

  void _loadAudioSettings() {
    final audioManager = AudioManager();
    setState(() {
      _masterVolume = audioManager.masterVolume;
      _sfxVolume = audioManager.sfxVolume;
      _musicVolume = audioManager.musicVolume;
      _isMuted = audioManager.isMuted;
      _isMusicMuted = audioManager.isMusicMuted;
    });
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
                  maxHeight: 500,
                ),
                padding: const EdgeInsets.all(20),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Icon(
                          Icons.volume_up,
                          size: 28,
                          color: Color(0xFF2D2A26),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Audio Settings',
                            style: TextStyle(
                              color: Color(0xFF2D2A26),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            AudioManager().playSfx(AudioEvent.buttonClick);
                            Navigator.of(context).pop();
                          },
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

                    const SizedBox(height: 24),

                    // Master Volume
                    _buildVolumeControl(
                      'Master Volume',
                      Icons.volume_up,
                      _masterVolume,
                      _isMuted,
                      (value) {
                        setState(() => _masterVolume = value);
                        AudioManager().setMasterVolume(value);
                      },
                      () {
                        AudioManager().toggleMute();
                        _loadAudioSettings();
                      },
                    ),

                    const SizedBox(height: 16),

                    // SFX Volume
                    _buildVolumeControl(
                      'Sound Effects',
                      Icons.whatshot,
                      _sfxVolume,
                      false, // SFX doesn't have separate mute
                      (value) {
                        setState(() => _sfxVolume = value);
                        AudioManager().setSfxVolume(value);
                        // Play test sound
                        AudioManager().playSfx(
                          AudioEvent.buttonClick,
                          volume: 0.5,
                        );
                      },
                      null,
                    ),

                    const SizedBox(height: 16),

                    // Music Volume
                    _buildVolumeControl(
                      'Background Music',
                      Icons.music_note,
                      _musicVolume,
                      _isMusicMuted,
                      (value) {
                        setState(() => _musicVolume = value);
                        AudioManager().setMusicVolume(value);
                      },
                      () {
                        AudioManager().toggleMusicMute();
                        _loadAudioSettings();
                      },
                    ),

                    const SizedBox(height: 24),

                    // Test Audio Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          AudioManager().playSfx(AudioEvent.archerFire);
                          AudioManager().playSfx(AudioEvent.enemyHit);
                          AudioManager().playSfx(AudioEvent.explosionHit);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonSuccess.withValues(
                            alpha: 0.8,
                          ),
                          foregroundColor: const Color(0xFF2D2A26),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Test Audio',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Close Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          AudioManager().playSfx(AudioEvent.buttonClick);
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.pastelRose.withValues(
                            alpha: 0.8,
                          ),
                          foregroundColor: const Color(0xFF2D2A26),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVolumeControl(
    String title,
    IconData icon,
    double value,
    bool isMuted,
    Function(double) onChanged,
    VoidCallback? onMuteToggle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.hudBorder.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF2D2A26)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF2D2A26),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onMuteToggle != null)
                GestureDetector(
                  onTap: () {
                    AudioManager().playSfx(AudioEvent.buttonClick);
                    onMuteToggle();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isMuted
                          ? Colors.red.withValues(alpha: 0.2)
                          : Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      isMuted ? Icons.volume_off : Icons.volume_up,
                      size: 16,
                      color: isMuted ? Colors.red : Colors.green,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.volume_down, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.buttonSuccess,
                    inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                    thumbColor: AppColors.buttonSuccess,
                    overlayColor: AppColors.buttonSuccess.withValues(
                      alpha: 0.2,
                    ),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16,
                    ),
                  ),
                  child: Slider(
                    value: value,
                    onChanged: isMuted ? null : onChanged,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.volume_up, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: Text(
                  '${(value * 100).round()}%',
                  style: const TextStyle(
                    color: Color(0xFF2D2A26),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
