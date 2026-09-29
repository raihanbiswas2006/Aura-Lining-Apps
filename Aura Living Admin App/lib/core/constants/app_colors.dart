import 'package:flutter/material.dart';

/// Aura Living Admin App Color Tokens
/// Nordic Minimalist Palette with Administrative Semantics
class AppColors {
  AppColors._();

  // Canvas & Surfaces
  static const Color canvas = Color(0xFFFAF9F6); // Warm Alabaster canvas matching web
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF4F2ED);

  // Typography & Content
  static const Color textPrimary = Color(0xFF14171A); // Web Charcoal
  static const Color textSecondary = Color(0xFF6B7280); // Web Muted
  static const Color textMuted = Color(0xFF9CA3AF);

  // Borders & Dividers
  static const Color border = Color(0xFFE4E7EB); // Web Border
  static const Color borderSubtle = Color(0xFFF3F4F6);

  // Brand / Accent - Signature Web Forest Pine Green
  static const Color primaryOlive = Color(0xFF1F4E43); // Web Primary Green
  static const Color primaryOliveLight = Color(0xFF286355);
  static const Color primaryOliveDark = Color(0xFF183E35);
  static const Color primaryCharcoal = Color(0xFF14171A);

  // Semantic State - Success / In-Stock
  static const Color success = Color(0xFF15803D);
  static const Color successBg = Color(0xFFDCFCE7);

  // Semantic State - Warning / Low-Stock
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFEF3C7);

  // Semantic State - Danger / Out-of-Stock / Destructive
  static const Color danger = Color(0xFFC2222E); // Web Red
  static const Color dangerBg = Color(0xFFFEE2E2);

  // Semantic State - Neutral / Draft / Processing
  static const Color neutral = Color(0xFF475569);
  static const Color neutralBg = Color(0xFFF1F5F9);

  // Accent Blue / Info
  static const Color info = Color(0xFF0369A1);
  static const Color infoBg = Color(0xFFE0F2FE);
}
