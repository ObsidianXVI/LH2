import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';

void main() {
  group('CanvasController Tests', () {
    test('CanvasKind serialization works correctly', () {
      const flowKind = FlowCanvasKind();
      const calendarKind = CalendarCanvasKind();
      
      expect(flowKind.toJson(), equals('flow'));
      expect(calendarKind.toJson(), equals('calendar'));
      
      expect(CanvasKind.fromJson('flow'), isA<FlowCanvasKind>());
      expect(CanvasKind.fromJson('calendar'), isA<CalendarCanvasKind>());
    });

    test('CanvasViewport JSON roundtrip works', () {
      final viewport = CanvasViewport(
        pan: const Offset(100, 200),
        zoom: 2.0,
        viewportSizePx: const Size(800, 600),
      );
      
      final json = viewport.toJson();
      final fromJson = CanvasViewport.fromJson(json);
      
      expect(fromJson.pan, equals(viewport.pan));
      expect(fromJson.zoom, equals(viewport.zoom));
      expect(fromJson.viewportSizePx, equals(viewport.viewportSizePx));
    });

    test('CanvasItem JSON serialization works', () {
      final item = CanvasItem(
        itemId: 'test-item',
        itemType: 'node',
        worldRect: const Rect.fromLTWH(10, 20, 100, 50),
        objectId: 'firestore-doc-id',
      );
      
      final json = item.toJson();
      expect(json['itemType'], equals('node'));
      expect(json['x'], equals(10.0));
      expect(json['y'], equals(20.0));
      expect(json['w'], equals(100.0));
      expect(json['h'], equals(50.0));
      expect(json['objectId'], equals('firestore-doc-id'));
      
      final fromJson = CanvasItem.fromJson('test-item', json);
      expect(fromJson.itemId, equals('test-item'));
      expect(fromJson.itemType, equals('node'));
      expect(fromJson.worldRect, equals(const Rect.fromLTWH(10, 20, 100, 50)));
      expect(fromJson.objectId, equals('firestore-doc-id'));
    });

    test('CanvasLink JSON serialization works', () {
      final link = CanvasLink(
        linkId: 'test-link',
        fromItemId: 'item1',
        toItemId: 'item2',
        linkType: 'dependency',
      );
      
      final json = link.toJson();
      expect(json['fromItemId'], equals('item1'));
      expect(json['toItemId'], equals('item2'));
      expect(json['linkType'], equals('dependency'));
      
      final fromJson = CanvasLink.fromJson('test-link', json);
      expect(fromJson.linkId, equals('test-link'));
      expect(fromJson.fromItemId, equals('item1'));
      expect(fromJson.toItemId, equals('item2'));
      expect(fromJson.linkType, equals('dependency'));
    });

    test('FlowCanvasController JSON serialization matches Appendix B', () {
      final controller = FlowCanvasController(
        viewport: const CanvasViewport(
          pan: Offset(0, 0),
          zoom: 1.0,
          viewportSizePx: Size(800, 600),
        ),
        gridSizePx: 24.0,
      );
      
      final json = controller.toJson();
      
      expect(json['kind'], equals('flow'));
      expect(json['gridSizePx'], equals(24.0));
      
      final viewportJson = json['viewport'] as Map<String, Object?>;
      expect(viewportJson['panX'], equals(0.0));
      expect(viewportJson['panY'], equals(0.0));
      expect(viewportJson['zoom'], equals(1.0));
      
      expect(json['items'], isA<Map<String, Object?>>());
      expect(json['links'], isA<Map<String, Object?>>());
      expect(json['selection'], isA<List<String>>());
    });

    test('CanvasController fromJson creates FlowCanvasController correctly', () {
      final json = {
        'kind': 'flow',
        'viewport': {
          'panX': 0.0,
          'panY': 0.0,
          'zoom': 1.0,
          'viewportWidthPx': 800.0,
          'viewportHeightPx': 600.0,
        },
        'gridSizePx': 24.0,
        'items': {},
        'links': {},
        'selection': [],
      };
      
      final controller = CanvasController.fromJson(json);
      
      expect(controller, isA<FlowCanvasController>());
      expect(controller.kind, isA<FlowCanvasKind>());
      expect(controller.viewport.pan, equals(const Offset(0, 0)));
      expect(controller.viewport.zoom, equals(1.0));
      expect(controller.items, isEmpty);
      expect(controller.links, isEmpty);
      expect(controller.selection, isEmpty);
    });

    test('World to screen coordinate transformation works', () {
      final controller = FlowCanvasController(
        viewport: const CanvasViewport(
          pan: Offset(100, 200),
          zoom: 2.0,
          viewportSizePx: Size(800, 600),
        ),
      );
      
      // World origin (0,0) should be at screen center (400, 300) minus pan offset
      final screen = controller.worldToScreen(const Offset(0, 0));
      expect(screen.dx, closeTo(400.0 - 100 * 2.0, 0.01));
      expect(screen.dy, closeTo(300.0 - 200 * 2.0, 0.01));
    });

    test('Screen to world coordinate transformation works', () {
      final controller = FlowCanvasController(
        viewport: const CanvasViewport(
          pan: Offset(100, 200),
          zoom: 2.0,
          viewportSizePx: Size(800, 600),
        ),
      );
      
      // Screen center (400, 300) should map to world origin plus pan
      final world = controller.screenToWorld(const Offset(400, 300));
      expect(world.dx, closeTo(100.0, 0.01));
      expect(world.dy, closeTo(200.0, 0.01));
    });

    test('Viewport panning works correctly', () {
      final controller = FlowCanvasController(
        viewport: const CanvasViewport(
          pan: Offset(0, 0),
          zoom: 1.0,
          viewportSizePx: Size(800, 600),
        ),
      );
      
      // Pan by 100 pixels to the right (screen coordinates)
      controller.panBy(const Offset(100, 0));
      
      // World should have moved 100 pixels to the left
      expect(controller.viewport.pan.dx, closeTo(-100.0, 0.01));
      expect(controller.viewport.pan.dy, closeTo(0.0, 0.01));
    });

    test('Viewport zooming works correctly', () {
      final controller = FlowCanvasController(
        viewport: const CanvasViewport(
          pan: Offset(0, 0),
          zoom: 1.0,
          viewportSizePx: Size(800, 600),
        ),
      );
      
      // Zoom in by factor of 2 at screen center
      controller.zoomAt(focalScreen: const Offset(400, 300), scaleDelta: 2.0);
      
      expect(controller.viewport.zoom, equals(2.0));
    });

    test('Selection management works correctly', () {
      final controller = FlowCanvasController(
        viewport: const CanvasViewport(
          pan: Offset(0, 0),
          zoom: 1.0,
          viewportSizePx: Size(800, 600),
        ),
      );
      
      // Test setSelection
      controller.setSelection({'item1', 'item2'});
      expect(controller.selection, equals({'item1', 'item2'}));
      
      // Test toggleSelection
      controller.toggleSelection('item3');
      expect(controller.selection, equals({'item1', 'item2', 'item3'}));
      
      controller.toggleSelection('item1');
      expect(controller.selection, equals({'item2', 'item3'}));
    });

    test('Item management works correctly', () {
      final controller = FlowCanvasController(
        viewport: const CanvasViewport(
          pan: Offset(0, 0),
          zoom: 1.0,
          viewportSizePx: Size(800, 600),
        ),
      );
      
      final item = CanvasItem(
        itemId: 'test-item',
        itemType: 'node',
        worldRect: const Rect.fromLTWH(10, 20, 100, 50),
      );
      
      // Add item
      controller.addItem(item);
      expect(controller.items.containsKey('test-item'), isTrue);
      
      // Update item rect
      controller.updateItemRect('test-item', const Rect.fromLTWH(15, 25, 120, 60));
      expect(controller.items['test-item']!.worldRect, equals(const Rect.fromLTWH(15, 25, 120, 60)));
      
      // Remove item
      controller.removeItem('test-item');
      expect(controller.items.containsKey('test-item'), isFalse);
    });

    test('Visible object computation works correctly', () {
      final controller = FlowCanvasController(
        viewport: const CanvasViewport(
          pan: Offset(0, 0),
          zoom: 1.0,
          viewportSizePx: Size(800, 600),
        ),
      );
      
      // Add items at different positions
      controller.addItem(CanvasItem(
        itemId: 'item1',
        itemType: 'node',
        worldRect: const Rect.fromLTWH(0, 0, 100, 100), // Visible (center of viewport)
      ));
      
      controller.addItem(CanvasItem(
        itemId: 'item2',
        itemType: 'node',
        worldRect: const Rect.fromLTWH(1000, 1000, 100, 100), // Not visible
      ));
      
      final visibleIds = controller.computeVisibleObjectIds();
      expect(visibleIds, contains('item1'));
      expect(visibleIds, isNot(contains('item2')));
    });

    test('Grid snapping works correctly', () {
      final controller = FlowCanvasController(
        viewport: const CanvasViewport(
          pan: Offset(0, 0),
          zoom: 1.0,
          viewportSizePx: Size(800, 600),
        ),
        gridSizePx: 24.0,
      );
      
      // Position at (15, 30) should snap to (24, 24)
      final snapped = controller.snapToGrid(const Offset(15, 30));
      expect(snapped.dx, equals(24.0));
      expect(snapped.dy, equals(24.0));
    });
  });
}