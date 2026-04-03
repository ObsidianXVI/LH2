import 'package:flutter/material.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';
import 'package:lh2_app/ui/theme/tokens.dart';

class LinkPainter extends CustomPainter {
  final CanvasController controller;

  LinkPainter({required this.controller}) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    // Main stroke paint for links
    final paint = Paint()
      ..color = LH2Colors.accentBlue
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Endpoint fill and border paints to make links visually prominent
    final endpointFill = Paint()
      ..color = LH2Colors.accentBlue
      ..style = PaintingStyle.fill;

    final endpointBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final link in controller.links.values) {
      final fromItem = controller.items[link.fromItemId];
      final toItem = controller.items[link.toItemId];

      if (fromItem == null || toItem == null) continue;

      final fromPortPos = _getPortPosition(fromItem, link.fromPortId);
      final toPortPos = _getPortPosition(toItem, link.toPortId);

      final fromScreen = controller.worldToScreen(fromPortPos);
      final toScreen = controller.worldToScreen(toPortPos);

      _drawLink(canvas, fromScreen, toScreen, paint);

      // Draw endpoints to visually anchor the link to ports
      const endpointRadius = 6.0;
      canvas.drawCircle(fromScreen, endpointRadius, endpointFill);
      canvas.drawCircle(fromScreen, endpointRadius, endpointBorder);
      canvas.drawCircle(toScreen, endpointRadius, endpointFill);
      canvas.drawCircle(toScreen, endpointRadius, endpointBorder);
    }

    // Draw pending link
    if (controller.pendingFromItemId != null &&
        controller.pendingFromPortId != null &&
        controller.pendingPointerScreen != null) {
      final fromItem = controller.items[controller.pendingFromItemId];
      if (fromItem != null) {
        final fromPortPos =
            _getPortPosition(fromItem, controller.pendingFromPortId!);
        final fromScreen = controller.worldToScreen(fromPortPos);

        final toScreen = controller.pendingPointerScreen!;

        final pendingPaint = Paint()
          ..color = LH2Colors.accentBlue.withOpacity(0.6)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

        _drawLink(canvas, fromScreen, toScreen, pendingPaint);
      }
    }
  }

  Offset _getPortPosition(CanvasItem item, String portId) {
    // Basic implementation:
    // portId ending with 'in' -> left side
    // portId ending with 'out' -> right side
    // In a real impl, this would look up the NodeTemplate port specs.

    if (portId.contains('out')) {
      return Offset(
          item.worldRect.right, item.worldRect.top + item.worldRect.height / 2);
    } else {
      return Offset(
          item.worldRect.left, item.worldRect.top + item.worldRect.height / 2);
    }
  }

  void _drawLink(Canvas canvas, Offset from, Offset to, Paint paint) {
    final path = Path()..moveTo(from.dx, from.dy);

    // Cubic bezier for a nice curved link
    final controlPoint1 = Offset(from.dx + (to.dx - from.dx) / 2, from.dy);
    final controlPoint2 = Offset(from.dx + (to.dx - from.dx) / 2, to.dy);

    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      to.dx,
      to.dy,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LinkPainter oldDelegate) => true;
}
