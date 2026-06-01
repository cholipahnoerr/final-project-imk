import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary — Terracotta/Warm Orange
  static const Color primary = Color(0xFFD95E38);
  static const Color primaryLight = Color(0xFFE8825E);
  static const Color primaryDark = Color(0xFFB04020);

  // Background — Krem/Off-white
  static const Color background = Color(0xFFFFF8F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5EDE3);

  // Feedback
  static const Color success = Color(0xFF58CC02);
  static const Color successLight = Color(0xFFD7F5B3);
  static const Color error = Color(0xFFFF4B4B);
  static const Color errorLight = Color(0xFFFFDDDD);

  // Text
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textMuted = Color(0xFFAAAAAA);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Gamification accents
  static const Color gold = Color(0xFFFFB800);
  static const Color goldLight = Color(0xFFFFF3CC);
  static const Color goldDark = Color(0xFF8A6200);
  static const Color gems = Color(0xFF1CB0F6);
  static const Color hearts = Color(0xFFFF4B4B);
  static const Color streak = Color(0xFFFF9600);

  // Divider & border
  static const Color divider = Color(0xFFE5E5E5);
  static const Color border = Color(0xFFD0D0D0);

  // Locked state (greyed out)
  static const Color locked = Color(0xFFAFAFAF);
  static const Color lockedBackground = Color(0xFFE8E8E8);
}