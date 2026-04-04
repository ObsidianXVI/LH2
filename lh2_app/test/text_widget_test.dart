import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';
import 'package:lh2_app/ui/flow_canvas/demo_items.dart';

void main() {
  group('Text Widget Tests', () {
    test('CanvasItem supports text itemType and config', () {
      const item = CanvasItem(
        itemId: 'text-1',
        itemType: 'text',
        worldRect: Rect.fromLTWH(10, 20, 100, 50),
        config: {
          'text': 'Hello World',
          'style': {
            'fontSize': 20.0,
            'color': 0xFF000000,
          },
        },
      );

      expect(item.itemType, equals('text'));
      expect(item.config, isA<Map<String, dynamic>>());
      expect(item.config!['text'], equals('Hello World'));
      expect(item.config!['style'], isA<Map<String, dynamic>>());
      expect(item.config!['style']['fontSize'], equals(20.0));
      expect(item.config!['style']['color'], equals(0xFF000000));
    });

    test('CanvasItem JSON roundtrip with text config', () {
      const item = CanvasItem(
        itemId: 'text-1',
        itemType: 'text',
        worldRect: Rect.fromLTWH(10, 20, 100, 50),
        config: {
          'text': 'Test Text',
          'style': {
            'fontSize': 18.0,
            'color': 0xFF2196F3,
          },
        },
      );

      final json = item.toJson();
      expect(json['itemType'], equals('text'));
      expect(json['config'], isA<Map<String, dynamic>>());
      final config = json['config'] as Map<String, dynamic>;
      expect(config['text'], equals('Test Text'));
      expect(config['style']['fontSize'], equals(18.0));
      expect(config['style']['color'], equals(0xFF2196F3));

      final fromJson = CanvasItem.fromJson('text-1', json);
      expect(fromJson.itemId, equals('text-1'));
      expect(fromJson.itemType, equals('text'));
      expect(fromJson.config!['text'], equals('Test Text'));
      expect(fromJson.config!['style']['fontSize'], equals(18.0));
      expect(fromJson.config!['style']['color'], equals(0xFF2196F3));
    });

    test('updateItemConfig updates text config', () {
      final controller = FlowCanvasController(
        viewport: const CanvasViewport(
          pan: Offset(0, 0),
          zoom: 1.0,
          viewportSizePx: Size(800, 600),
        ),
      );

      final item = CanvasItem(
        itemId: 'text-1',
        itemType: 'text',
        worldRect: const Rect.fromLTWH(10, 20, 100, 50),
        config: {
          'text': 'Original',
          'style': {
            'fontSize': 16.0,
            'color': 0xFF000000,
          },
        },
      );

      controller.addItem(item);
      expect(controller.items['text-1']!.config!['text'], equals('Original'));

      final newConfig = Map<String, dynamic>.from(item.config!);
      newConfig['text'] = 'Updated';
      controller.updateItemConfig('text-1', newConfig);

      expect(controller.items['text-1']!.config!['text'], equals('Updated'));
      expect(controller.items['text-1']!.config!['style']['fontSize'],
          equals(16.0));
    });

    test('DemoCanvasItems includes text widget', () {
      final items = DemoCanvasItems.demoItems;
      final textItem = items.firstWhere((i) => i.itemType == 'text');
      expect(textItem.itemId, equals('demo-text'));
      expect(textItem.config!['text'], equals('Editable Text Widget'));
      expect(textItem.config!['style']['fontSize'], equals(18.0));
      expect(textItem.config!['style']['color'], equals(0xFF2196F3));
    });

    test('Controller preserves config during updateItemRect', () {
      final controller = FlowCanvasController(
        viewport: const CanvasViewport(
          pan: Offset(0, 0),
          zoom: 1.0,
          viewportSizePx: Size(800, 600),
        ),
      );

      final item = CanvasItem(
        itemId: 'text-1',
        itemType: 'text',
        worldRect: const Rect.fromLTWH(10, 20, 100, 50),
        config: {
          'text': 'Text',
          'style': {
            'fontSize': 16.0,
            'color': 0xFF000000,
          },
        },
      );

      controller.addItem(item);
      controller.updateItemRect('text-1', const Rect.fromLTWH(20, 30, 120, 60));

      final updated = controller.items['text-1']!;
      expect(updated.worldRect, equals(const Rect.fromLTWH(20, 30, 120, 60)));
      expect(updated.config!['text'], equals('Text'));
      expect(updated.config!['style']['fontSize'], equals(16.0));
    });

    test('Controller handles missing config gracefully', () {
      final controller = FlowCanvasController(
        viewport: const CanvasViewport(
          pan: Offset(0, 0),
          zoom: 1.0,
          viewportSizePx: Size(800, 600),
        ),
      );

      final item = CanvasItem(
        itemId: 'text-1',
        itemType: 'text',
        worldRect: const Rect.fromLTWH(10, 20, 100, 50),
      );

      controller.addItem(item);
      expect(controller.items['text-1']!.config, isNull);

      final newConfig = {'text': 'New Text'};
      controller.updateItemConfig('text-1', newConfig);

      expect(controller.items['text-1']!.config!['text'], equals('New Text'));
    });
  });
}
