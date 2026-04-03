import 'package:flutter/material.dart';
import 'package:lh2_app/ui/theme/tokens.dart';

class CalendarTimescalePainter extends CustomPainter {
  final Offset pan;
  final double zoom;
  final double minutesPerPixel;
  final int ruleIntervalMinutes;
  final Size viewportSize;

  CalendarTimescalePainter({
    required this.pan,
    required this.zoom,
    required this.minutesPerPixel,
    required this.ruleIntervalMinutes,
    required this.viewportSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = LH2Colors.border.withOpacity(0.3)
      ..strokeWidth = 1.0;

    final double pixelSpacing = ruleIntervalMinutes / minutesPerPixel * zoom;
    if (pixelSpacing <= 0) return;

    // Calculate the start of the visible area in world coordinates (minutes)
    // pan.dx is the center of the viewport in world coordinates.
    final double worldViewportWidth = viewportSize.width / zoom;
    final double startMinutes = pan.dx - worldViewportWidth / 2;
    final double endMinutes = pan.dx + worldViewportWidth / 2;

    final double firstRuleMinutes = (startMinutes / ruleIntervalMinutes).ceil() * ruleIntervalMinutes.toDouble();

    for (double m = firstRuleMinutes; m <= endMinutes; m += ruleIntervalMinutes) {
      final double screenX = (m - pan.dx) * zoom + viewportSize.width / 2;
      
      // Vertical rules for timescale
      canvas.drawLine(
        Offset(screenX, 22), // Start below the sticky date markers area (22px high)
        Offset(screenX, viewportSize.height),
        paint,
      );
    }
    
    // Horizontal line separating top bar from timescale
    final separatorPaint = Paint()
      ..color = LH2Colors.border
      ..strokeWidth = 1.0;
    canvas.drawLine(const Offset(0, 22), Offset(viewportSize.width, 22), separatorPaint);
  }

  @override
  bool shouldRepaint(covariant CalendarTimescalePainter oldDelegate) {
    return oldDelegate.pan != pan ||
        oldDelegate.zoom != zoom ||
        oldDelegate.minutesPerPixel != minutesPerPixel ||
        oldDelegate.ruleIntervalMinutes != ruleIntervalMinutes ||
        oldDelegate.viewportSize != viewportSize;
  }
}
