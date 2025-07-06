import 'package:flutter/material.dart';

/// Pastel color palette for Techtical Stand game
class AppColors {
  // Primary pastel colors
  static const Color pastelLavender = Color(0xFFE6E6FA);
  static const Color pastelMint = Color(0xFFB8E6B8);
  static const Color pastelPeach = Color(0xFFFFDAB9);
  static const Color pastelSky = Color(0xFFB0E0E6);
  static const Color pastelRose = Color(0xFFFFB6C1);
  static const Color pastelLemon = Color(0xFFFFFACD);

  // Alias colors for compatibility
  static const Color primary = pastelLavender;
  static const Color secondary = pastelSky;
  static const Color backgroundLight = backgroundSoft;

  // Background colors
  static const Color backgroundSoft = Color(0xFFFAF9F6);
  static const Color backgroundCard = Color(0xFFF5F3F0);
  static const Color backgroundOverlay = Color(0xFF2D2A26);

  // Text colors - Enhanced for better contrast while maintaining pastel theme
  static const Color textPrimary = Color(
    0xFF2D2A26,
  ); // Dark brown - excellent contrast
  static const Color textSecondary = Color(
    0xFF5A5A5A,
  ); // Medium gray - good contrast
  static const Color textLight = Color(
    0xFFFFFFFF,
  ); // Pure white - for dark backgrounds
  static const Color textDark = Color(
    0xFF1A1A1A,
  ); // Very dark - maximum contrast
  static const Color textOnPastel = Color(
    0xFF2D2A26,
  ); // Dark brown - perfect for pastel backgrounds
  static const Color textAccent = Color(
    0xFF6B4E7D,
  ); // Deep purple - complements pastels
  static const Color textSuccess = Color(
    0xFF2E7D32,
  ); // Dark green - for success states
  static const Color textWarning = Color(
    0xFFE65100,
  ); // Dark orange - for warnings
  static const Color textError = Color(0xFFD32F2F); // Dark red - for errors

  // Game UI colors - Enhanced for better contrast
  static const Color hudBackground = Color(
    0xFFF8F5FF,
  ); // Lighter pastel for better contrast
  static const Color hudBorder = Color(
    0xFFB8A9D9,
  ); // Deeper border for definition
  static const Color buttonPrimary = Color(
    0xFFD1B3E6,
  ); // Slightly deeper pastel
  static const Color buttonSecondary = Color(
    0xFF9FDDE6,
  ); // Slightly deeper pastel
  static const Color buttonSuccess = Color(
    0xFF9FE6B3,
  ); // Slightly deeper pastel
  static const Color buttonWarning = Color(
    0xFFE6D19F,
  ); // Slightly deeper pastel
  static const Color buttonDisabled = Color(
    0xFFE8E8E8,
  ); // Light gray for disabled state
  static const Color cardBackground = Color(
    0xFFFCFAFF,
  ); // Very light background for cards
  static const Color cardBorder = Color(0xFFE0D4F7); // Soft border for cards

  // Game element colors
  static const Color gridLine = Color(0xFFE6E6E6);
  static const Color pauseOverlay = Color(0x80F5F3F0);

  // Status colors
  static const Color healthGreen = Color(0xFF90EE90);
  static const Color goldYellow = Color(0xFFFFF8DC);
  static const Color waveBlue = Color(0xFFADD8E6);
  static const Color scorePurple = Color(0xFFDDA0DD);

  // Tower colors (pastel)
  static const Color archerTower = Color(0xFFD2B48C);
  static const Color cannonTower = Color(0xFFC0C0C0);
  static const Color magicTower = Color(0xFFDDA0DD);
  static const Color sniperTower = Color(0xFF98FB98);

  // Enemy colors (pastel)
  static const Color goblinEnemy = Color(0xFF98FB98);
  static const Color orcEnemy = Color(0xFFFFB6C1);
  static const Color trollEnemy = Color(0xFFDDA0DD);
  static const Color bossEnemy = Color(0xFFCD5C5C);

  // Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFAF9F6), Color(0xFFF0E6FF), Color(0xFFE6F3FF)],
  );

  static const LinearGradient hudGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF0E6FF), Color(0xFFE6B3FF)],
  );
}
