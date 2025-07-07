import 'package:flutter/material.dart';

/// Accessibility color schemes for different types of color blindness
class AccessibilityColors {
  // Color blind friendly color schemes
  static const Map<String, Map<String, Color>> colorBlindSchemes = {
    'deuteranopia': {
      'primary': Color(0xFF1F77B4), // Blue
      'secondary': Color(0xFFFF7F0E), // Orange
      'success': Color(0xFF2CA02C), // Green
      'warning': Color(0xFFD62728), // Red
      'info': Color(0xFF9467BD), // Purple
      'background': Color(0xFFF7F7F7), // Light gray
      'text': Color(0xFF2F2F2F), // Dark gray
    },
    'protanopia': {
      'primary': Color(0xFF1F77B4), // Blue
      'secondary': Color(0xFFFF7F0E), // Orange
      'success': Color(0xFF2CA02C), // Green
      'warning': Color(0xFFD62728), // Red
      'info': Color(0xFF9467BD), // Purple
      'background': Color(0xFFF7F7F7), // Light gray
      'text': Color(0xFF2F2F2F), // Dark gray
    },
    'tritanopia': {
      'primary': Color(0xFF1F77B4), // Blue
      'secondary': Color(0xFFFF7F0E), // Orange
      'success': Color(0xFF2CA02C), // Green
      'warning': Color(0xFFD62728), // Red
      'info': Color(0xFF9467BD), // Purple
      'background': Color(0xFFF7F7F7), // Light gray
      'text': Color(0xFF2F2F2F), // Dark gray
    },
  };

  // High contrast color scheme
  static const Map<String, Color> highContrastScheme = {
    'primary': Color(0xFF000000), // Black
    'secondary': Color(0xFFFFFFFF), // White
    'success': Color(0xFF00FF00), // Bright green
    'warning': Color(0xFFFF0000), // Bright red
    'info': Color(0xFF0000FF), // Bright blue
    'background': Color(0xFFFFFFFF), // White
    'text': Color(0xFF000000), // Black
  };

  // Game-specific accessibility colors
  static const Map<String, Map<String, Color>> gameAccessibilityColors = {
    'normal': {
      'health': Color(0xFF2ECC71), // Green
      'damage': Color(0xFFE74C3C), // Red
      'gold': Color(0xFFFFD700), // Gold
      'lives': Color(0xFFE74C3C), // Red
      'score': Color(0xFF3498DB), // Blue
      'enemy': Color(0xFF8B4513), // Brown
      'tower': Color(0xFF9B59B6), // Purple
      'projectile': Color(0xFFFFA500), // Orange
    },
    'deuteranopia': {
      'health': Color(0xFF2CA02C), // Green (color blind friendly)
      'damage': Color(0xFFD62728), // Red (color blind friendly)
      'gold': Color(0xFF1F77B4), // Blue (color blind friendly)
      'lives': Color(0xFFD62728), // Red (color blind friendly)
      'score': Color(0xFF9467BD), // Purple (color blind friendly)
      'enemy': Color(0xFF8C564B), // Brown (color blind friendly)
      'tower': Color(0xFFE377C2), // Pink (color blind friendly)
      'projectile': Color(0xFFFF7F0E), // Orange (color blind friendly)
    },
    'high_contrast': {
      'health': Color(0xFF00FF00), // Bright green
      'damage': Color(0xFFFF0000), // Bright red
      'gold': Color(0xFFFFFF00), // Bright yellow
      'lives': Color(0xFFFF0000), // Bright red
      'score': Color(0xFF00FFFF), // Bright cyan
      'enemy': Color(0xFFFF8000), // Bright orange
      'tower': Color(0xFF8000FF), // Bright purple
      'projectile': Color(0xFFFFFF00), // Bright yellow
    },
  };

  /// Get color scheme based on accessibility settings
  static Map<String, Color> getColorScheme({
    String colorBlindType = 'normal',
    bool highContrast = false,
  }) {
    if (highContrast) {
      return highContrastScheme;
    }

    if (colorBlindType != 'normal' &&
        colorBlindSchemes.containsKey(colorBlindType)) {
      return colorBlindSchemes[colorBlindType]!;
    }

    // Return default colors
    return {
      'primary': const Color(0xFF6B4E7D),
      'secondary': const Color(0xFFB0E0E6),
      'success': const Color(0xFF2ECC71),
      'warning': const Color(0xFFE74C3C),
      'info': const Color(0xFF3498DB),
      'background': const Color(0xFFFAF9F6),
      'text': const Color(0xFF2D2A26),
    };
  }

  /// Get game-specific colors based on accessibility settings
  static Map<String, Color> getGameColors({
    String colorBlindType = 'normal',
    bool highContrast = false,
  }) {
    if (highContrast) {
      return gameAccessibilityColors['high_contrast']!;
    }

    if (colorBlindType != 'normal' &&
        gameAccessibilityColors.containsKey(colorBlindType)) {
      return gameAccessibilityColors[colorBlindType]!;
    }

    return gameAccessibilityColors['normal']!;
  }

  /// Check if two colors have sufficient contrast
  static bool hasSufficientContrast(
    Color color1,
    Color color2, {
    double threshold = 4.5,
  }) {
    final luminance1 = color1.computeLuminance();
    final luminance2 = color2.computeLuminance();

    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;

    final contrast = (lighter + 0.05) / (darker + 0.05);
    return contrast >= threshold;
  }

  /// Get accessible text color for a background color
  static Color getAccessibleTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// Get accessible border color for a background color
  static Color getAccessibleBorderColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    if (luminance > 0.7) {
      return Colors.black.withValues(alpha: 0.3);
    } else if (luminance < 0.3) {
      return Colors.white.withValues(alpha: 0.3);
    } else {
      return Colors.grey.withValues(alpha: 0.5);
    }
  }
}

/// Accessibility settings provider
class AccessibilitySettings {
  static AccessibilitySettings? _instance;
  static AccessibilitySettings get instance =>
      _instance ??= AccessibilitySettings._();

  AccessibilitySettings._();

  String _colorBlindType = 'normal';
  bool _highContrast = false;
  double _textScaleFactor = 1.0;
  bool _enableHapticFeedback = true;
  bool _enableScreenReader = false;

  // Getters
  String get colorBlindType => _colorBlindType;
  bool get highContrast => _highContrast;
  double get textScaleFactor => _textScaleFactor;
  bool get enableHapticFeedback => _enableHapticFeedback;
  bool get enableScreenReader => _enableScreenReader;

  // Setters
  void setColorBlindType(String type) {
    _colorBlindType = type;
    _saveSettings();
  }

  void setHighContrast(bool enabled) {
    _highContrast = enabled;
    _saveSettings();
  }

  void setTextScaleFactor(double factor) {
    _textScaleFactor = factor.clamp(0.8, 2.0);
    _saveSettings();
  }

  void setHapticFeedback(bool enabled) {
    _enableHapticFeedback = enabled;
    _saveSettings();
  }

  void setScreenReader(bool enabled) {
    _enableScreenReader = enabled;
    _saveSettings();
  }

  /// Get current color scheme
  Map<String, Color> get currentColorScheme =>
      AccessibilityColors.getColorScheme(
        colorBlindType: _colorBlindType,
        highContrast: _highContrast,
      );

  /// Get current game colors
  Map<String, Color> get currentGameColors => AccessibilityColors.getGameColors(
    colorBlindType: _colorBlindType,
    highContrast: _highContrast,
  );

  /// Load settings from SharedPreferences
  Future<void> loadSettings() async {
    // TODO: Implement SharedPreferences loading
    // For now, use default values
  }

  /// Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    // TODO: Implement SharedPreferences saving
  }

  /// Reset to default settings
  void resetToDefaults() {
    _colorBlindType = 'normal';
    _highContrast = false;
    _textScaleFactor = 1.0;
    _enableHapticFeedback = true;
    _enableScreenReader = false;
    _saveSettings();
  }
}
