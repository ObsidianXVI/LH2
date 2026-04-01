import 'package:flutter/material.dart';

import '../ui/theme/tokens.dart';

/// LH2 baseline theme with Menlo font globally, spacing scale, and text styles.
class LH2Theme {
  /// Base spacing unit: 8px.
  static const double baseSpacingPx = 8.0;

  /// Spacing scale.
  static double spacing(double level) =>
      (baseSpacingPx * level).clamp(0.0, 96.0);

  /// Font family for all text: Menlo (monospace).
  static const String fontFamily =
      'Menlo, Monaco, Consolas, "Courier New", monospace';

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

        /// Dark mode using LH2Colors tokens.
        colorScheme: ColorScheme.dark(
          primary: LH2Colors.accentBlue,
          onPrimary: Colors.white,
          secondary: LH2Colors.successGreen,
          onSecondary: Colors.black87,
          surface: LH2Colors.panel,
          onSurface: LH2Colors.textPrimary,
          background: LH2Colors.background,
          onBackground: LH2Colors.textSecondary,
          surfaceVariant: LH2Colors.border,
          onSurfaceVariant: LH2Colors.textSecondary,
          outline: LH2Colors.border,
        ),

        /// Spacing via LH2Theme.spacing().
        useMaterial3: true,

        /// Text styles with tokens.
        textTheme: TextTheme(
          displayLarge:
              nodeTitle.copyWith(fontSize: 32, fontWeight: FontWeight.bold),
          headlineMedium: nodeTitle.copyWith(fontSize: 20),
          bodyLarge: body.copyWith(fontSize: 14),
          bodyMedium: body,
          labelLarge: tabLabel.copyWith(fontSize: 14),
        ),

        /// Custom extensions later.
      );
}
