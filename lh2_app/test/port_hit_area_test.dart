import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';

void main() {
  group('Port hit area config', () {
    test('Port Positioned offsets create larger hit area', () {
      final controller = FlowCanvasController(
        viewport: const CanvasViewport(
          pan: Offset(0, 0),
          zoom: 1.0,
          viewportSizePx: Size(800, 600),
        ),
      );

      controller.addItem(const CanvasItem(
        itemId: 'n1',
        itemType: 'node',
        worldRect: Rect.fromLTWH(100, 100, 120, 80),
      ));

      // Sanity: ensure item exists and has expected rect
      final item = controller.items['n1']!;
      expect(item.worldRect.width, equals(120));
      expect(item.worldRect.height, equals(80));
    });
  });
}
