import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lh2_app/ui/theme/tokens.dart';

class StickyMarkersPainter extends CustomPainter {
  final Offset pan;
  final double zoom;
  final double minutesPerPixel;
  final int ruleIntervalMinutes;
  final Size viewportSize;
  final DateTime anchorStartSgt;

  StickyMarkersPainter({
    required this.pan,
    required this.zoom,
    required this.minutesPerPixel,
    required this.ruleIntervalMinutes,
    required this.viewportSize,
    required this.anchorStartSgt,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = const TextStyle(
      color: LH2Colors.textSecondary,
      fontSize: 10,
      fontFamily: 'Menlo',
    );

    final double worldViewportWidth = viewportSize.width / zoom;
    final double startWorldX = pan.dx - worldViewportWidth / 2;
    final double endWorldX = pan.dx + worldViewportWidth / 2;

    final double startMinutes = startWorldX;
    final double firstRuleMinutes = (startMinutes / ruleIntervalMinutes).ceil() * ruleIntervalMinutes.toDouble();

    for (double m = firstRuleMinutes; m <= endWorldX; m += ruleIntervalMinutes) {
      final double screenX = (m - pan.dx) * zoom + viewportSize.width / 2;
      
      // Calculate Time Label
      final DateTime time = anchorStartSgt.add(Duration(minutes: m.toInt()));
      final String timeLabel = DateFormat('HHmm').format(time);

      final textPainter = TextPainter(
        text: TextSpan(text: timeLabel, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      // Draw time marker (inside timescale, slightly below top)
      textPainter.paint(canvas, Offset(screenX + 4, 25));

      // Draw date marker (top row) if it's the start of a day or first visible
      if (m % 1440 == 0 || m == firstRuleMinutes) {
         final String dateLabel = DateFormat('dd EEE').format(time).toUpperCase();
         final datePainter = TextPainter(
          text: TextSpan(text: dateLabel, style: textStyle.copyWith(fontWeight: FontWeight.bold, color: LH2Colors.textPrimary)),
          textDirection: TextDirection.ltr,
        )..layout();
        
        // Background for date marker
        final bgPaint = Paint()..color = LH2Colors.background;
        canvas.drawRect(Rect.fromLTWH(screenX, 0, datePainter.width + 10, 20), bgPaint);
        
        datePainter.paint(canvas, Offset(screenX + 4, 4));
      }
    }
    
    // Draw top bar background
    final barPaint = Paint()..color = LH2Colors.panel.withOpacity(0.9);
    canvas.drawRect(Rect.fromLTWH(0, 0, viewportSize.width, 22), barPaint);
  }

  @override
  bool shouldRepaint(covariant StickyMarkersPainter oldDelegate) {
    return oldDelegate.pan != pan ||
        oldDelegate.zoom != zoom ||
        oldDelegate.minutesPerPixel != minutesPerPixel ||
        oldDelegate.ruleIntervalMinutes != ruleIntervalMinutes ||
        oldDelegate.viewportSize != viewportSize ||
        oldDelegate.anchorStartSgt != anchorStartSgt;
  }
}
