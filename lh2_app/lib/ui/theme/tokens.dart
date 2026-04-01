import 'package:flutter/material.dart';

/// LH2 design tokens: colors.
///
/// Placeholder palette matching Figma intent (dark mode).
/// Structure ready for Figma exact values (e.g., from tokens plugin).
///
/// Update values manually or automate via Figma export.
class LH2Colors {
  /// Page background (darkest).
  static const Color background = Color(0xFF0A0A0A);

  /// Panels, cards, surfaces.
  static const Color panel = Color(0xFF121212);

  /// Subtle borders, dividers.
  static const Color border = Color(0xFF2A2A2A);

  /// Primary text.
  static const Color textPrimary = Color(0xFFE0E0E0);

  /// Secondary text, labels.
  static const Color textSecondary = Color(0xFF9E9E9E);

  /// Accent blue (primary action, links).
  static const Color accentBlue = Color(0xFF4FC3F7);

  /// Selection, hover highlights.
  static const Color selectionBlue = Color(0xFF1976D2);

  /// Danger, errors, deletes.
  static const Color dangerRed = Color(0xFFE57373);

  /// Success, positive.
  static const Color successGreen = Color(0xFF81C784);

  /// Warnings.
  static const Color warningOrange = Color(0xFFFFB74D);

  /// Muted overlays.
  static const Color overlay = Color(0x80000000);

  /// Grid lines (very subtle).
  static const Color grid = Color(0xFF2D2D2D);
}