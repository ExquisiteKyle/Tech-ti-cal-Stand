import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_colors.dart';
import 'core/game/game_engine.dart';

void main() {
  runApp(const ProviderScope(child: TechticalStandApp()));
}

class TechticalStandApp extends StatelessWidget {
  const TechticalStandApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: AppConstants.appName,
    theme: ThemeData(
      primarySwatch: Colors.purple,
      primaryColor: AppColors.pastelLavender,
      scaffoldBackgroundColor: AppColors.backgroundSoft,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.hudBackground,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: AppColors.textDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.backgroundCard,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    home: const GameEngine(),
  );
}
