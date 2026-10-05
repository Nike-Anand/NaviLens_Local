import 'package:flutter/material.dart';

class AppColors {
  // ── Backgrounds ────────────────────────────────────────────────────
  static const Color background     = Color(0xFF060F1A); // deep navy-black
  static const Color surface        = Color(0xFF0D1F30); // lifted surface
  static const Color surfaceElevated = Color(0xFF122840); // hover / sheet
  static const Color glass          = Color(0x1AFFFFFF); // frosted glass overlay

  // ── Primary (blue) ─────────────────────────────────────────────────
  static const Color primary      = Color(0xFF3B9EFF); // vivid sky-blue
  static const Color primaryLight = Color(0xFF70BBFF);
  static const Color primaryDark  = Color(0xFF1A72D4);
  static const Color primaryGlow  = Color(0x403B9EFF); // glow alpha

  // ── Medicine (purple) ──────────────────────────────────────────────
  static const Color medicine      = Color(0xFFA855F7); // rich violet
  static const Color medicineLight = Color(0xFFC084FC);
  static const Color medicineDark  = Color(0xFF7C3AED);
  static const Color medicineGlow  = Color(0x40A855F7);

  // ── Physio (green) ─────────────────────────────────────────────────
  static const Color physio      = Color(0xFF22D3A0); // teal-green
  static const Color physioLight = Color(0xFF4EEAB8);
  static const Color physioDark  = Color(0xFF14A87E);
  static const Color physioGlow  = Color(0x4022D3A0);

  // ── Environment (orange) ───────────────────────────────────────────
  static const Color environment      = Color(0xFFF97316); // warm amber-orange
  static const Color environmentLight = Color(0xFFFB923C);
  static const Color environmentDark  = Color(0xFFE05F0A);
  static const Color environmentGlow  = Color(0x40F97316);

  // ── Status ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22D3A0);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error   = Color(0xFFFF4D6A);

  // ── Text ───────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF0F6FF);
  static const Color textSecondary = Color(0xFF8AACCA);
  static const Color textMuted     = Color(0xFF3F6380);

  // ── UI chrome ──────────────────────────────────────────────────────
  static const Color border      = Color(0xFF152E45);
  static const Color borderGlow  = Color(0xFF1E4668);
  static const Color divider     = Color(0xFF0F2435);
  static const Color overlayDark = Color(0xCC000000);

  // ── Offline indicator ──────────────────────────────────────────────
  static const Color offlineGreen = Color(0xFF22D3A0);

  // ── Gradient stop pairs (used by GradientBox helpers) ──────────────
  static List<Color> primaryGradient    = [primary, medicine];
  static List<Color> medicineGradient   = [medicineDark, medicine];
  static List<Color> physioGradient     = [physioDark, physio];
  static List<Color> environmentGradient = [environmentDark, environment];

  // ── Translucent card backgrounds ───────────────────────────────────
  static Color medicineCard    = medicine.withValues(alpha: 0.13);
  static Color physioCard      = physio.withValues(alpha: 0.13);
  static Color environmentCard = environment.withValues(alpha: 0.13);
}
