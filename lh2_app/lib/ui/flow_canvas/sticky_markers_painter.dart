import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lh2_app/ui/theme/tokens.dart';
import 'package:timezone/timezone.dart' as tz;

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
    final singapore = tz.getLocation('Asia/Singapore');
    
    final textStyle = const TextStyle(
      color: LH2Colors.textSecondary,
      fontSize: 10,
      fontFamily: 'Menlo',
    );

    final double worldViewportWidth = viewportSize.width / zoom;
    final double startMinutes = pan.dx - worldViewportWidth / 2;
    final double endMinutes = pan.dx + worldViewportWidth / 2;

    final double firstRuleMinutes =
        (startMinutes / ruleIntervalMinutes).ceil() *
            ruleIntervalMinutes.toDouble();

    // 1. Draw top bar background
    final barPaint = Paint()..color = LH2Colors.panel.withOpacity(0.95);
    canvas.drawRect(Rect.fromLTWH(0, 0, viewportSize.width, 22), barPaint);

    for (double m = firstRuleMinutes;
        m <= endMinutes;
        m += ruleIntervalMinutes) {
      final double screenX = (m - pan.dx) * zoom + viewportSize.width / 2;

      // Calculate Time Label in SGT
      final DateTime timeUtc = anchorStartSgt.add(Duration(minutes: m.toInt()));
      final tz.TZDateTime timeSgt = tz.TZDateTime.from(timeUtc, singapore);

      // Requirement 2.2.3: When ruleIntervalMinutes reaches 1440 (24h):
      // - time markers become dates (21 TUE, 22 WED)
      // - date marker becomes month.
      
      final bool isDayInterval = ruleIntervalMinutes >= 1440;

      if (isDayInterval) {
        // Time markers become dates
        final String dateLabel = DateFormat('dd EEE').format(timeSgt).toUpperCase();
        final textPainter = TextPainter(
          text: TextSpan(text: dateLabel, style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(screenX + 4, 25));

        // Date marker becomes month
        if (timeSgt.day == 1 || m == firstRuleMinutes) {
           final String monthLabel = DateFormat('MMMM yyyy').format(timeSgt).toUpperCase();
           final monthPainter = TextPainter(
             text: TextSpan(
               text: monthLabel,
               style: textStyle.copyWith(fontWeight: FontWeight.bold, color: LH2Colors.textPrimary),
             ),
             textDirection: TextDirection.ltr,
           )..layout();
           
           monthPainter.paint(canvas, Offset(screenX + 4, 4));
        }
      } else {
        // Normal behavior
        final String timeLabel = DateFormat('HHmm').format(timeSgt);
        final textPainter = TextPainter(
          text: TextSpan(text: timeLabel, style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();

        // Draw time marker (inside timescale, slightly below top bar)
        textPainter.paint(canvas, Offset(screenX + 4, 25));

        // Draw date marker (top row) if it's the start of a day or first visible
        // To avoid overcrowding, only draw if it's 00:00 or first visible
        if (timeSgt.hour == 0 && timeSgt.minute == 0 || m == firstRuleMinutes) {
          final String dateLabel = DateFormat('dd EEE').format(timeSgt).toUpperCase();
          final datePainter = TextPainter(
            text: TextSpan(
                text: dateLabel,
                style: textStyle.copyWith(
                    fontWeight: FontWeight.bold, color: LH2Colors.textPrimary)),
            textDirection: TextDirection.ltr,
          )..layout();

          // Ensure date label doesn't overlap with previous one if they are too close
          datePainter.paint(canvas, Offset(screenX + 4, 4));
        }
      }
    }
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
