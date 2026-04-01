import 'package:flutter/material.dart';

/// LH2 desktop responsiveness utilities (Appendix F in PLAN.md).
///
/// Desktop-only; no mobile support yet.
///
/// Breakpoints:
/// - Small desktop: < 1100px
/// - Standard desktop: 1100–1600px
/// - Large desktop: > 1600px
class LH2Breakpoints {
  /// Small desktop threshold.
  static const double smallDesktop = 1100.0;

  /// Standard desktop max.
  static const double standardDesktopMax = 1600.0;

  /// Large desktop.
  static const double largeDesktop = 1600.0;

  /// Is small desktop?
  static bool isSmallDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width < smallDesktop;

  /// Is standard desktop?
  static bool isStandardDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= smallDesktop &&
      MediaQuery.sizeOf(context).width <= standardDesktopMax;

  /// Is large desktop?
  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width > largeDesktop;
}

/// Layout constraint helpers.
extension LH2ResponsiveHelpers on BuildContext {
  /// Query overlay width: clamp 280-420px.
  double get queryOverlayWidth => (280.0).clampDouble(
        MediaQuery.sizeOf(this).width * 0.25,
        420.0,
      );

  /// Canvas min size: 800x600px.
  Size get canvasMinSize => const Size(800.0, 600.0);

  /// Crosshair side panel width: clamp 320-480px.
  double get crosshairPanelWidth => (320.0).clampDouble(
        MediaQuery.sizeOf(this).width * 0.2,
        480.0,
      );
}

/// Extension for double.clampDouble (missing in Flutter).
extension ClampDouble on num {
  double clampDouble(double low, double high) => this is double
      ? (this as double).clamp(low, high)
      : clamp(low, high).toDouble();
}