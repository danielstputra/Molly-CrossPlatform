import 'package:flutter/material.dart';

/// Palet warna mewah "Obsidian & Liquid Gold" yang terinspirasi dari Apple Human Interface Guidelines (HIG)
/// dengan sentuhan identitas warna gelap dan emas elegan Molly.
class AppColors {
  // Latar Belakang Utama (Obsidian Cosmic)
  static const Color bgPrimary = Color(0xFF0B0D13);
  static const Color bgSecondary = Color(0xFF11141E);
  static const Color bgSurface = Color(0xFF161B27);
  static const Color bgGlass = Color(0x66161B27); // Semi-transparent untuk frosted blur

  // Aliases for compatibility
  static const Color background = bgPrimary;
  static const Color surface = bgSurface;
  static const Color surfaceElevated = bgSurface;
  static const Color glassBorder = borderGlass;
  static const Color textTertiary = textMuted;

  // Aksen Emas Mewah (Liquid Gold)
  static const Color gold = Color(0xFFEAB308);
  static const Color goldLight = Color(0xFFFDE047);
  static const Color goldDark = Color(0xFFCA8A04);
  static const Color goldGlow = Color(0x40EAB308);

  // Gradien Emas Elegan
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFDE047), Color(0xFFEAB308), Color(0xFFCA8A04)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradien Glassmorphism Apple HIG
  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x1AFFFFFF),
      Color(0x08FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Border & Garis Halus
  static const Color borderGlass = Color(0x1FFFFFFF); // 0.8px border
  static const Color borderGold = Color(0x4DEAB308);

  // Warna Teks
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textGold = Color(0xFFFACC15);

  // Warna Status
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF38BDF8);
}
