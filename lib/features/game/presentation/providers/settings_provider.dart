import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings state class
class GameSettings {
  final bool showFPS;
  final bool showDamageNumbers;
  final bool showParticleEffects;
  final bool enableHapticFeedback;
  final String colorBlindType;
  final bool highContrast;
  final double textScaleFactor;
  final bool autoSave;
  final bool showTutorials;

  const GameSettings({
    this.showFPS = false,
    this.showDamageNumbers = true,
    this.showParticleEffects = true,
    this.enableHapticFeedback = true,
    this.colorBlindType = 'normal',
    this.highContrast = false,
    this.textScaleFactor = 1.0,
    this.autoSave = true,
    this.showTutorials = true,
  });

  GameSettings copyWith({
    bool? showFPS,
    bool? showDamageNumbers,
    bool? showParticleEffects,
    bool? enableHapticFeedback,
    String? colorBlindType,
    bool? highContrast,
    double? textScaleFactor,
    bool? autoSave,
    bool? showTutorials,
  }) {
    return GameSettings(
      showFPS: showFPS ?? this.showFPS,
      showDamageNumbers: showDamageNumbers ?? this.showDamageNumbers,
      showParticleEffects: showParticleEffects ?? this.showParticleEffects,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      colorBlindType: colorBlindType ?? this.colorBlindType,
      highContrast: highContrast ?? this.highContrast,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      autoSave: autoSave ?? this.autoSave,
      showTutorials: showTutorials ?? this.showTutorials,
    );
  }
}

/// Settings notifier
class SettingsNotifier extends StateNotifier<GameSettings> {
  SettingsNotifier() : super(const GameSettings()) {
    // Load settings asynchronously, but don't wait for it
    _loadSettings().catchError((error) {
      // Ignore errors during loading, keep default settings
    });
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    if (!mounted) return; // Don't load if already disposed

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return; // Check again after async operation

      state = GameSettings(
        showFPS: prefs.getBool('show_fps') ?? false,
        showDamageNumbers: prefs.getBool('show_damage_numbers') ?? true,
        showParticleEffects: prefs.getBool('show_particle_effects') ?? true,
        enableHapticFeedback: prefs.getBool('enable_haptic_feedback') ?? true,
        colorBlindType: prefs.getString('color_blind_type') ?? 'normal',
        highContrast: prefs.getBool('high_contrast') ?? false,
        textScaleFactor: prefs.getDouble('text_scale_factor') ?? 1.0,
        autoSave: prefs.getBool('auto_save') ?? true,
        showTutorials: prefs.getBool('show_tutorials') ?? true,
      );
    } catch (e) {
      // If loading fails, keep default settings
      if (mounted) {
        state = const GameSettings();
      }
    }
  }

  /// Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    if (!mounted) return; // Don't save if already disposed

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return; // Check again after async operation

      await prefs.setBool('show_fps', state.showFPS);
      await prefs.setBool('show_damage_numbers', state.showDamageNumbers);
      await prefs.setBool('show_particle_effects', state.showParticleEffects);
      await prefs.setBool('enable_haptic_feedback', state.enableHapticFeedback);
      await prefs.setString('color_blind_type', state.colorBlindType);
      await prefs.setBool('high_contrast', state.highContrast);
      await prefs.setDouble('text_scale_factor', state.textScaleFactor);
      await prefs.setBool('auto_save', state.autoSave);
      await prefs.setBool('show_tutorials', state.showTutorials);
    } catch (e) {
      // Handle save error silently
    }
  }

  /// Update FPS display setting
  void setShowFPS(bool show) {
    state = state.copyWith(showFPS: show);
    _saveSettings();
  }

  /// Update damage numbers setting
  void setShowDamageNumbers(bool show) {
    state = state.copyWith(showDamageNumbers: show);
    _saveSettings();
  }

  /// Update particle effects setting
  void setShowParticleEffects(bool show) {
    state = state.copyWith(showParticleEffects: show);
    _saveSettings();
  }

  /// Update haptic feedback setting
  void setEnableHapticFeedback(bool enable) {
    state = state.copyWith(enableHapticFeedback: enable);
    _saveSettings();
  }

  /// Update color blind type setting
  void setColorBlindType(String type) {
    state = state.copyWith(colorBlindType: type);
    _saveSettings();
  }

  /// Update high contrast setting
  void setHighContrast(bool high) {
    state = state.copyWith(highContrast: high);
    _saveSettings();
  }

  /// Update text scale factor setting
  void setTextScaleFactor(double factor) {
    state = state.copyWith(textScaleFactor: factor);
    _saveSettings();
  }

  /// Update auto save setting
  void setAutoSave(bool auto) {
    state = state.copyWith(autoSave: auto);
    _saveSettings();
  }

  /// Update show tutorials setting
  void setShowTutorials(bool show) {
    state = state.copyWith(showTutorials: show);
    _saveSettings();
  }

  /// Reset all settings to defaults
  void resetToDefaults() {
    state = const GameSettings();
    _saveSettings();
  }
}

/// Settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, GameSettings>(
  (ref) => SettingsNotifier(),
);

/// Individual setting providers for easier access
final showFPSProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).showFPS;
});

final showDamageNumbersProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).showDamageNumbers;
});

final showParticleEffectsProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).showParticleEffects;
});

final enableHapticFeedbackProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).enableHapticFeedback;
});

final colorBlindTypeProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).colorBlindType;
});

final highContrastProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).highContrast;
});

final textScaleFactorProvider = Provider<double>((ref) {
  return ref.watch(settingsProvider).textScaleFactor;
});

final autoSaveProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).autoSave;
});

final showTutorialsProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).showTutorials;
});
