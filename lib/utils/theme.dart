import 'package:flutter/material.dart';

/// App color palette - inspired by miAlarm's blue/dark theme.
class AppColors {
  static const primary = Color(0xFF1565C0);      // Deep blue
  static const primaryDark = Color(0xFF0D47A1);
  static const accent = Color(0xFF42A5F5);
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF1E1E1E);
  static const card = Color(0xFF2C2C2C);

  static const armed = Color(0xFF4CAF50);         // Green
  static const disarmed = Color(0xFFEF5350);      // Red
  static const homeArm = Color(0xFFFF9800);       // Orange
  static const sleepArm = Color(0xFF7E57C2);      // Purple
  static const bypassed = Color(0xFFFFC107);      // Amber
  static const alert = Color(0xFFD32F2F);         // Dark red

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B0B0);
  static const textMuted = Color(0xFF757575);
}

/// Returns the color for a partition state.
Color partitionStateColor(String state) => switch (state) {
      'armed' => AppColors.armed,
      'disarmed' => AppColors.disarmed,
      'home_arm' => AppColors.homeArm,
      'sleep_arm' => AppColors.sleepArm,
      _ => AppColors.textMuted,
    };

/// Returns the color for a zone state.
Color zoneStateColor(String state) => switch (state) {
      'closed' => AppColors.armed,
      'open' => AppColors.disarmed,
      'bypassed' => AppColors.bypassed,
      'tamper' => AppColors.alert,
      _ => AppColors.textMuted,
    };

final appTheme = ThemeData(
  brightness: Brightness.dark,
  colorSchemeSeed: AppColors.primary,
  scaffoldBackgroundColor: AppColors.background,
  cardTheme: const CardThemeData(
    color: AppColors.card,
    elevation: 2,
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.surface,
    elevation: 0,
    centerTitle: false,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.surface,
    indicatorColor: AppColors.primary.withValues(alpha: 0.3),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.card,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
);
