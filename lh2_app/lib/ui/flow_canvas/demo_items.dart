import 'package:flutter/material.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';

/// Demo items for testing the Flow Canvas
class DemoCanvasItems {
  static List<CanvasItem> get demoItems => [
        CanvasItem(
          itemId: 'demo-1',
          itemType: 'node',
          worldRect: const Rect.fromLTWH(100, 100, 389, 133),
          objectId: 'project-1',
          objectType: 'project',
          config: {'templateId': 'project-default'},
        ),
        CanvasItem(
          itemId: 'demo-2',
          itemType: 'node',
          worldRect: const Rect.fromLTWH(600, 100, 389, 133),
          objectId: 'task-1',
          objectType: 'task',
          config: {'templateId': 'task-default'},
        ),
        CanvasItem(
          itemId: 'demo-3',
          itemType: 'widget',
          worldRect: const Rect.fromLTWH(200, 350, 150, 100),
        ),
        CanvasItem(
          itemId: 'demo-text',
          itemType: 'text',
          worldRect: const Rect.fromLTWH(500, 100, 200, 60),
          config: {
            'text': 'Editable Text Widget',
            'style': {
              'fontSize': 18.0,
              'color': 0xFF2196F3, // blue
            },
          },
        ),
      ];
}
