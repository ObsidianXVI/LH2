import 'package:flutter/material.dart';

/// LH2 baseline theme with Menlo font globally, spacing scale, and text styles.
class LH2Theme {
  /// Base spacing unit: 8px.
  static const double baseSpacingPx = 8.0;

  /// Spacing scale.
  static double spacing(int level) => baseSpacingPx * level.clamp(0, 12);

  /// Font family for all text: Menlo (monospace).
  static const String fontFamily = 'Menlo, Monaco, Consolas, "Courier New", monospace';

  /// Tab labels.
  static const TextStyle tabLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  /// Node titles.
  static const TextStyle nodeTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  /// Body text.
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13.0,
    height: 1.4,
  );

  /// Material [ThemeData] with LH2 baseline.
  ///
  /// Placeholder colors; update later from Figma tokens.
  static ThemeData get materialTheme => ThemeData(
    /// Menlo globally.
    fontFamily: fontFamily,

    /// Dark mode baseline.
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2196F3), // LH2 blue
      brightness: Brightness.dark,
      primary: const Color(0xFF2196F3),
      secondary: const Color(0xFF4CAF50),
      surface: const Color(0xFF121212),
      background: const Color(0xFF0D0D0D),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFFBDBDBD),
      onBackground: const Color(0xFFBDBDBD),
    ),

    /// Spacing via MediaQuery? Use LH2Theme.spacing() in widgets.
    useMaterial3: true,

    /// Text styles inherit fontFamily.
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 14),
      bodyMedium: TextStyle(fontSize: 13),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ).apply(
      fontFamily: fontFamily,
      bodyColor: const Color(0xFFBDBDBD),
      displayColor: Colors.white,
    ),

    /// Custom extensions can be added later.
  );
}