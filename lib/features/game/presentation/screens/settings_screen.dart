import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/audio/audio_manager.dart';
import '../../../../core/widgets/audio_settings_panel.dart';
import '../providers/settings_provider.dart';

/// Comprehensive settings screen with all game preferences
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildSettingsContent()),
                _buildBottomActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              AudioManager().playSfx(AudioEvent.buttonClick);
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back, color: AppColors.textOnPastel),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textAccent,
                  ),
                ),
                Text(
                  'Customize your gaming experience',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildAudioSection(),
          const SizedBox(height: 24),
          _buildGraphicsSection(),
          const SizedBox(height: 24),
          _buildAccessibilitySection(),
          const SizedBox(height: 24),
          _buildGameSection(),
        ],
      ),
    );
  }

  Widget _buildAudioSection() {
    return _buildSettingsCard(
      title: 'Audio',
      icon: Icons.volume_up,
      color: AppColors.pastelLavender,
      children: [
        _buildSettingTile(
          title: 'Audio Settings',
          subtitle: 'Master volume, SFX, and music controls',
          trailing: IconButton(
            onPressed: () {
              AudioManager().playSfx(AudioEvent.buttonClick);
              AudioSettingsPanel.show(context);
            },
            icon: const Icon(Icons.settings, color: AppColors.textAccent),
          ),
        ),
      ],
    );
  }

  Widget _buildGraphicsSection() {
    final settings = ref.watch(settingsProvider);

    return _buildSettingsCard(
      title: 'Graphics',
      icon: Icons.visibility,
      color: AppColors.pastelSky,
      children: [
        _buildSwitchTile(
          title: 'Show FPS Counter',
          subtitle: 'Display frame rate during gameplay',
          value: settings.showFPS,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).setShowFPS(value);
            AudioManager().playSfx(AudioEvent.buttonClick);
          },
        ),
        _buildSwitchTile(
          title: 'Damage Numbers',
          subtitle: 'Show damage dealt to enemies',
          value: settings.showDamageNumbers,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).setShowDamageNumbers(value);
            AudioManager().playSfx(AudioEvent.buttonClick);
          },
        ),
        _buildSwitchTile(
          title: 'Particle Effects',
          subtitle: 'Show visual effects and animations',
          value: settings.showParticleEffects,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).setShowParticleEffects(value);
            AudioManager().playSfx(AudioEvent.buttonClick);
          },
        ),
      ],
    );
  }

  Widget _buildAccessibilitySection() {
    final settings = ref.watch(settingsProvider);

    return _buildSettingsCard(
      title: 'Accessibility',
      icon: Icons.accessibility,
      color: AppColors.pastelMint,
      children: [
        _buildDropdownTile(
          title: 'Color Blind Support',
          subtitle: 'Choose color scheme for better visibility',
          value: settings.colorBlindType,
          items: const [
            {'value': 'normal', 'label': 'Normal Vision'},
            {'value': 'deuteranopia', 'label': 'Deuteranopia (Red-Green)'},
            {'value': 'protanopia', 'label': 'Protanopia (Red-Green)'},
            {'value': 'tritanopia', 'label': 'Tritanopia (Blue-Yellow)'},
          ],
          onChanged: (value) {
            ref.read(settingsProvider.notifier).setColorBlindType(value);
            AudioManager().playSfx(AudioEvent.buttonClick);
          },
        ),
        _buildSwitchTile(
          title: 'High Contrast',
          subtitle: 'Maximum contrast for better visibility',
          value: settings.highContrast,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).setHighContrast(value);
            AudioManager().playSfx(AudioEvent.buttonClick);
          },
        ),
        _buildSwitchTile(
          title: 'Haptic Feedback',
          subtitle: 'Vibration feedback on mobile devices',
          value: settings.enableHapticFeedback,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).setEnableHapticFeedback(value);
            AudioManager().playSfx(AudioEvent.buttonClick);
          },
        ),
        _buildSliderTile(
          title: 'Text Size',
          subtitle: 'Adjust text size for better readability',
          value: settings.textScaleFactor,
          min: 0.8,
          max: 1.5,
          divisions: 7,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).setTextScaleFactor(value);
            AudioManager().playSfx(AudioEvent.buttonClick);
          },
        ),
      ],
    );
  }

  Widget _buildGameSection() {
    final settings = ref.watch(settingsProvider);

    return _buildSettingsCard(
      title: 'Game',
      icon: Icons.games,
      color: AppColors.pastelPeach,
      children: [
        _buildSwitchTile(
          title: 'Auto Save',
          subtitle: 'Automatically save game progress',
          value: settings.autoSave,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).setAutoSave(value);
            AudioManager().playSfx(AudioEvent.buttonClick);
          },
        ),
        _buildSwitchTile(
          title: 'Show Tutorials',
          subtitle: 'Display helpful tips and guidance',
          value: settings.showTutorials,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).setShowTutorials(value);
            AudioManager().playSfx(AudioEvent.buttonClick);
          },
        ),
        _buildSettingTile(
          title: 'Reset Progress',
          subtitle: 'Clear all saved game data',
          trailing: TextButton(
            onPressed: () => _showResetConfirmation(),
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textAccent,
                  ),
                ),
              ],
            ),
          ),
          // Content
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.buttonSuccess,
            activeTrackColor: AppColors.buttonSuccess.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<Map<String, String>> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.hudBorder.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: const SizedBox(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item['value'],
                  child: Text(item['label']!),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.buttonSuccess,
              inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
              thumbColor: AppColors.buttonSuccess,
              overlayColor: AppColors.buttonSuccess.withValues(alpha: 0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                AudioManager().playSfx(AudioEvent.buttonClick);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pastelRose.withValues(alpha: 0.8),
                foregroundColor: AppColors.textOnPastel,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                AudioManager().playSfx(AudioEvent.buttonClick);
                _resetToDefaults();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonWarning.withValues(alpha: 0.8),
                foregroundColor: AppColors.textOnPastel,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Reset to Defaults',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation() {
    AudioManager().playSfx(AudioEvent.buttonClick);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Progress'),
        content: const Text(
          'Are you sure you want to reset all game progress? This will clear all levels, achievements, and statistics. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              AudioManager().playSfx(AudioEvent.buttonClick);
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              AudioManager().playSfx(AudioEvent.buttonClick);
              Navigator.of(context).pop();
              _resetProgress();
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _resetToDefaults() {
    ref.read(settingsProvider.notifier).resetToDefaults();
  }

  void _resetProgress() {
    // TODO: Implement progress reset
    // This would clear all saved data from SharedPreferences
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Game progress has been reset'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
