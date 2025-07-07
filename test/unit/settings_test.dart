import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:techtical_stand/features/game/presentation/providers/settings_provider.dart';

void main() {
  group('Settings Provider Tests', () {
    test('Default settings are correct', () {
      final container = ProviderContainer();
      final settings = container.read(settingsProvider);

      expect(settings.showFPS, false);
      expect(settings.showDamageNumbers, true);
      expect(settings.showParticleEffects, true);
      expect(settings.enableHapticFeedback, true);
      expect(settings.colorBlindType, 'normal');
      expect(settings.highContrast, false);
      expect(settings.textScaleFactor, 1.0);
      expect(settings.autoSave, true);
      expect(settings.showTutorials, true);

      container.dispose();
    });

    test('FPS setting can be toggled', () {
      final container = ProviderContainer();

      // Initially false
      expect(container.read(showFPSProvider), false);

      // Toggle to true
      container.read(settingsProvider.notifier).setShowFPS(true);
      expect(container.read(showFPSProvider), true);

      // Toggle back to false
      container.read(settingsProvider.notifier).setShowFPS(false);
      expect(container.read(showFPSProvider), false);

      container.dispose();
    });

    test('Settings can be reset to defaults', () {
      final container = ProviderContainer();

      // Change some settings
      container.read(settingsProvider.notifier).setShowFPS(true);
      container.read(settingsProvider.notifier).setShowDamageNumbers(false);
      container.read(settingsProvider.notifier).setColorBlindType('protanopia');

      // Verify changes
      expect(container.read(showFPSProvider), true);
      expect(container.read(showDamageNumbersProvider), false);
      expect(container.read(colorBlindTypeProvider), 'protanopia');

      // Reset to defaults
      container.read(settingsProvider.notifier).resetToDefaults();

      // Verify reset
      expect(container.read(showFPSProvider), false);
      expect(container.read(showDamageNumbersProvider), true);
      expect(container.read(colorBlindTypeProvider), 'normal');

      container.dispose();
    });

    test('Individual setting providers work correctly', () {
      final container = ProviderContainer();

      // Test showFPSProvider
      container.read(settingsProvider.notifier).setShowFPS(true);
      expect(container.read(showFPSProvider), true);

      // Test showDamageNumbersProvider
      container.read(settingsProvider.notifier).setShowDamageNumbers(false);
      expect(container.read(showDamageNumbersProvider), false);

      // Test showParticleEffectsProvider
      container.read(settingsProvider.notifier).setShowParticleEffects(false);
      expect(container.read(showParticleEffectsProvider), false);

      // Test enableHapticFeedbackProvider
      container.read(settingsProvider.notifier).setEnableHapticFeedback(false);
      expect(container.read(enableHapticFeedbackProvider), false);

      // Test colorBlindTypeProvider
      container
          .read(settingsProvider.notifier)
          .setColorBlindType('deuteranopia');
      expect(container.read(colorBlindTypeProvider), 'deuteranopia');

      // Test highContrastProvider
      container.read(settingsProvider.notifier).setHighContrast(true);
      expect(container.read(highContrastProvider), true);

      // Test textScaleFactorProvider
      container.read(settingsProvider.notifier).setTextScaleFactor(1.5);
      expect(container.read(textScaleFactorProvider), 1.5);

      // Test autoSaveProvider
      container.read(settingsProvider.notifier).setAutoSave(false);
      expect(container.read(autoSaveProvider), false);

      // Test showTutorialsProvider
      container.read(settingsProvider.notifier).setShowTutorials(false);
      expect(container.read(showTutorialsProvider), false);

      container.dispose();
    });
  });
}
