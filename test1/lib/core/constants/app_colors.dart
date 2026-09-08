import 'package:flutter/material.dart';

class AppColors {
  // Brand / Primary Colors
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color accent = Color(0xFFF59E0B); // Amber accent

  // Surface & Background Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color cardSurface = Colors.white;
  
  // Status Colors
  static const Color success = Color(0xFF10B981); // Emerald green for completed
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B); // Amber for medium priority / pending
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFEF4444); // Coral red for high priority / delete
  static const Color dangerLight = Color(0xFFFEE2E2);

  // Completion Status Specific Colors
  static const Color statusPending = Color(0xFFF59E0B); // Amber
  static const Color statusStarted = Color(0xFF6366F1); // Indigo Blue
  static const Color statusCompleted = Color(0xFF10B981); // Emerald Green
  static const Color statusDropped = Color(0xFF64748B); // Slate Gray

  // Priority Specific Colors
  static const Color priorityHigh = Color(0xFFEF4444);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow = Color(0xFF3B82F6);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Border & Divider
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);
}
