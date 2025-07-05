import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_colors.dart';

void main() {
  runApp(const ProviderScope(child: TechticalStandApp()));
}

class TechticalStandApp extends StatelessWidget {
  const TechticalStandApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: AppConstants.appName,
    theme: ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: AppColors.primaryGold,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textLight,
      ),
    ),
    home: const GameScreen(),
  );
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(AppConstants.appName), centerTitle: true),
    body: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.games, size: 100, color: AppColors.primaryGold),
          SizedBox(height: 20),
          Text(
            'Techtical Stand',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Tower Defense Game',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
          SizedBox(height: 40),
          Text(
            'Game engine coming soon...',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
  );
}
