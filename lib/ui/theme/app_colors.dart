import 'package:flutter/material.dart';

class AppColors {
  // Background
  static const Color background = Color(0xFF07131F);
  static const Color surface = Color(0xFF102231);
  static const Color surfaceElevated = Color(0xFF163044);

  // Primary
  static const Color primary = Color(0xFF2B8EFF);
  static const Color primaryLight = Color(0xFF5AABFF);
  static const Color primaryDark = Color(0xFF1A6FD4);

  // Feature
  static const Color medicine = Color(0xFF9B59F5);
  static const Color medicineLight = Color(0xFFBD8BFF);
  static const Color medicineDark = Color(0xFF7A3FD9);

  static const Color physio = Color(0xFF22C55E);
  static const Color physioLight = Color(0xFF4ADE80);
  static const Color physioDark = Color(0xFF16A34A);

  static const Color environment = Color(0xFFF97316);
  static const Color environmentLight = Color(0xFFFB923C);
  static const Color environmentDark = Color(0xFFEA6C0C);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94ABBE);
  static const Color textMuted = Color(0xFF4E6F8A);

  // UI
  static const Color border = Color(0xFF1E3A52);
  static const Color divider = Color(0xFF152B3E);
  static const Color overlayDark = Color(0xCC000000);

  // Offline indicator
  static const Color offlineGreen = Color(0xFF22C55E);

  // Card backgrounds
  static Color medicineCard = medicine.withValues(alpha: 0.15);
  static Color physioCard = physio.withValues(alpha: 0.15);
  static Color environmentCard = environment.withValues(alpha: 0.15);
}
