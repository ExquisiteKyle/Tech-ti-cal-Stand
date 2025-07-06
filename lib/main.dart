import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_colors.dart';
import 'core/audio/audio_manager.dart';
import 'features/game/domain/models/achievement_manager.dart';
import 'features/game/presentation/screens/main_menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize audio manager
  await AudioManager().initialize();

  // Initialize achievement manager
  await AchievementManager.instance.initialize();

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
    home: const MainMenuScreen(),
  );
}
