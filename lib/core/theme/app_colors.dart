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

  // Background colors
  static const Color backgroundSoft = Color(0xFFFAF9F6);
  static const Color backgroundCard = Color(0xFFF5F3F0);
  static const Color backgroundOverlay = Color(0xFF2D2A26);

  // Text colors
  static const Color textPrimary = Color(0xFF4A4A4A);
  static const Color textSecondary = Color(0xFF8B8B8B);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2D2A26);

  // Game UI colors
  static const Color hudBackground = Color(0xFFF0E6FF);
  static const Color hudBorder = Color(0xFFD4C5E8);
  static const Color buttonPrimary = Color(0xFFE6B3FF);
  static const Color buttonSecondary = Color(0xFFB3E6FF);
  static const Color buttonSuccess = Color(0xFFB3FFB3);
  static const Color buttonWarning = Color(0xFFFFE6B3);

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
