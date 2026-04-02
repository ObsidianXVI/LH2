import 'package:flutter/material.dart';
import 'package:lh2_app/ui/theme/tokens.dart';

/// Custom painter for drawing the grid background on the flow canvas.
class GridBackgroundPainter extends CustomPainter {
  final Offset pan;
  final double zoom;
  final double gridSizePx;
  final Size viewportSize;

  GridBackgroundPainter({
    required this.pan,
    required this.zoom,
    required this.gridSizePx,
    required this.viewportSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = LH2Colors.grid
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Calculate the visible world bounds
    final halfWidth = size.width / (2 * zoom);
    final halfHeight = size.height / (2 * zoom);
    final worldLeft = pan.dx - halfWidth;
    final worldTop = pan.dy - halfHeight;
    final worldRight = pan.dx + halfWidth;
    final worldBottom = pan.dy + halfHeight;

    // Calculate grid spacing in world coordinates
    final gridWorldSize = gridSizePx / zoom;

    // Calculate the starting grid positions
    final startGridX = (worldLeft / gridWorldSize).floor() * gridWorldSize;
    final startGridY = (worldTop / gridWorldSize).floor() * gridWorldSize;

    // Draw vertical lines
    for (double x = startGridX; x <= worldRight; x += gridWorldSize) {
      final screenX = (x - pan.dx) * zoom + size.width / 2;
      if (screenX >= 0 && screenX <= size.width) {
        canvas.drawLine(
          Offset(screenX, 0),
          Offset(screenX, size.height),
          paint,
        );
      }
    }

    // Draw horizontal lines
    for (double y = startGridY; y <= worldBottom; y += gridWorldSize) {
      final screenY = (y - pan.dy) * zoom + size.height / 2;
      if (screenY >= 0 && screenY <= size.height) {
        canvas.drawLine(
          Offset(0, screenY),
          Offset(size.width, screenY),
          paint,
        );
      }
    }

    // Draw origin crosshair (optional, for debugging)
    _drawOriginCrosshair(canvas, size);
  }

  void _drawOriginCrosshair(Canvas canvas, Size size) {
    final originPaint = Paint()
      ..color = LH2Colors.accentBlue.withValues(alpha: 0.3)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final originScreen = _worldToScreen(const Offset(0, 0), size);
    
    if (originScreen.dx >= 0 && originScreen.dx <= size.width) {
      canvas.drawLine(
        Offset(originScreen.dx, 0),
        Offset(originScreen.dx, size.height),
        originPaint,
      );
    }
    
    if (originScreen.dy >= 0 && originScreen.dy <= size.height) {
      canvas.drawLine(
        Offset(0, originScreen.dy),
        Offset(size.width, originScreen.dy),
        originPaint,
      );
    }
  }

  Offset _worldToScreen(Offset worldPos, Size size) {
    return (worldPos - pan) * zoom + Offset(size.width / 2, size.height / 2);
  }

  @override
  bool shouldRepaint(GridBackgroundPainter oldDelegate) {
    return pan != oldDelegate.pan ||
           zoom != oldDelegate.zoom ||
           gridSizePx != oldDelegate.gridSizePx ||
           viewportSize != oldDelegate.viewportSize;
  }
}