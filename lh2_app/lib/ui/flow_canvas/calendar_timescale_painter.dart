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
      ..color = LH2Colors.border.withOpacity(0.5)
      ..strokeWidth = 1.0;

    final double pixelSpacing = ruleIntervalMinutes / minutesPerPixel * zoom;
    if (pixelSpacing <= 0) return;

    // Calculate the start of the visible area in world coordinates
    final double worldViewportWidth = viewportSize.width / zoom;
    final double startWorldX = pan.dx - worldViewportWidth / 2;
    final double endWorldX = pan.dx + worldViewportWidth / 2;

    // Convert world X to minutes from an arbitrary epoch if needed, 
    // but here we just use world X as minutes for simplicity of the rule drawing.
    // The actual time mapping will be handled by the controller/view.
    
    final double startMinutes = startWorldX;
    final double firstRuleMinutes = (startMinutes / ruleIntervalMinutes).ceil() * ruleIntervalMinutes.toDouble();

    for (double m = firstRuleMinutes; m <= endWorldX; m += ruleIntervalMinutes) {
      final double screenX = (m - pan.dx) * zoom + viewportSize.width / 2;
      canvas.drawLine(
        Offset(screenX, 0),
        Offset(screenX, viewportSize.height),
        paint,
      );
    }
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
