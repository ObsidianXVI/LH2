import 'package:flutter/material.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';
import 'package:lh2_app/ui/theme/tokens.dart';

class LinkPainter extends CustomPainter {
  final CanvasController controller;

  LinkPainter({required this.controller}) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = LH2Colors.accentBlue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final link in controller.links.values) {
      final fromItem = controller.items[link.fromItemId];
      final toItem = controller.items[link.toItemId];

      if (fromItem == null || toItem == null) continue;

      final fromPortPos = _getPortPosition(fromItem, link.fromPortId);
      final toPortPos = _getPortPosition(toItem, link.toPortId);

      final fromScreen = controller.worldToScreen(fromPortPos);
      final toScreen = controller.worldToScreen(toPortPos);

      _drawLink(canvas, fromScreen, toScreen, paint);
    }

    // Draw pending link
    if (controller.pendingFromItemId != null && controller.pendingFromPortId != null) {
      final fromItem = controller.items[controller.pendingFromItemId];
      if (fromItem != null) {
        final fromPortPos = _getPortPosition(fromItem, controller.pendingFromPortId!);
        final fromScreen = controller.worldToScreen(fromPortPos);
        
        // We need the current mouse position in world coordinates
        // For now, we'll just skip drawing the pending link line itself here 
        // OR we'd need to pass the mouse position to the painter.
        // Let's assume we'll pass the mouse position via a dedicated overlay if needed, 
        // or add it to the controller.
      }
    }
  }

  Offset _getPortPosition(CanvasItem item, String portId) {
    // Basic implementation: 
    // portId ending with 'in' -> left side
    // portId ending with 'out' -> right side
    // In a real impl, this would look up the NodeTemplate port specs.
    
    if (portId.contains('out')) {
      return Offset(item.worldRect.right, item.worldRect.top + item.worldRect.height / 2);
    } else {
      return Offset(item.worldRect.left, item.worldRect.top + item.worldRect.height / 2);
    }
  }

  void _drawLink(Canvas canvas, Offset from, Offset to, Paint paint) {
    final path = Path()
      ..moveTo(from.dx, from.dy);
    
    // Cubic bezier for a nice curved link
    final controlPoint1 = Offset(from.dx + (to.dx - from.dx) / 2, from.dy);
    final controlPoint2 = Offset(from.dx + (to.dx - from.dx) / 2, to.dy);
    
    path.cubicTo(
      controlPoint1.dx, controlPoint1.dy,
      controlPoint2.dx, controlPoint2.dy,
      to.dx, to.dy,
    );
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LinkPainter oldDelegate) => true;
}
