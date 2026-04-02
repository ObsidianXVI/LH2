import 'package:flutter/material.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';

/// Demo items for testing the Flow Canvas
class DemoCanvasItems {
  static List<CanvasItem> get demoItems => [
    CanvasItem(
      itemId: 'demo-1',
      itemType: 'node',
      worldRect: const Rect.fromLTWH(100, 100, 120, 80),
      objectId: 'project-1',
    ),
    CanvasItem(
      itemId: 'demo-2',
      itemType: 'node',
      worldRect: const Rect.fromLTWH(300, 200, 120, 80),
      objectId: 'task-1',
    ),
    CanvasItem(
      itemId: 'demo-3',
      itemType: 'widget',
      worldRect: const Rect.fromLTWH(200, 350, 150, 100),
    ),
  ];
}