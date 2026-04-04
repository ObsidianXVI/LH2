import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';
import 'package:timezone/data/latest_all.dart' as tz;

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('CalendarCanvasController.applyMoveWithSnapping', () {
    CalendarCanvasController makeController() {
      return CalendarCanvasController(
        viewport: const CanvasViewport(
          pan: Offset.zero,
          zoom: 1,
          viewportSizePx: Size(800, 600),
        ),
      );
    }

    test('non-snappable types never snap even with Cmd', () {
      final c = makeController();
      final item = CanvasItem(
        itemId: 'i1',
        itemType: 'node',
        objectType: 'task',
        worldRect: const Rect.fromLTWH(7, 0, 30, 10),
      );

      final moved = c.applyMoveWithSnapping(
        item: item,
        deltaWorld: const Offset(0, 0),
        isCmdPressed: true,
      );

      expect(moved.rect.left, 7);
      expect(moved.snap.startSnapped, isFalse);
      expect(moved.snap.endSnapped, isFalse);
    });

    test('widgets never snap even with Cmd', () {
      final c = makeController();
      final item = CanvasItem(
        itemId: 'w1',
        itemType: 'widget',
        worldRect: const Rect.fromLTWH(7, 0, 30, 10),
      );

      final moved = c.applyMoveWithSnapping(
        item: item,
        deltaWorld: const Offset(10, 0),
        isCmdPressed: true,
      );

      expect(moved.rect.left, 17);
      expect(moved.snap.startSnapped, isFalse);
      expect(moved.snap.endSnapped, isFalse);
    });

    test('default is freehand: without Cmd, no snap and metadata unchanged',
        () {
      final c = makeController();
      final item = CanvasItem(
        itemId: 'n1',
        itemType: 'node',
        objectType: 'event',
        worldRect: const Rect.fromLTWH(7, 0, 30, 10),
        snap: const CanvasItemSnapState(startSnapped: false, endSnapped: false),
      );

      final moved = c.applyMoveWithSnapping(
        item: item,
        deltaWorld: const Offset(0, 0),
        isCmdPressed: false,
      );

      expect(moved.rect.left, 7);
      expect(moved.rect.right, 37);
      expect(moved.snap.startSnapped, isFalse);
      expect(moved.snap.endSnapped, isFalse);
    });

    test('holding Cmd enables snapping and sets snap metadata', () {
      final c = makeController();
      final item = CanvasItem(
        itemId: 'n1',
        itemType: 'node',
        objectType: 'event',
        worldRect: const Rect.fromLTWH(8, 0, 15, 10),
      );

      final moved = c.applyMoveWithSnapping(
        item: item,
        deltaWorld: const Offset(0, 0),
        isCmdPressed: true,
      );

      // left=8 snaps to 15; right=23 snaps to 30
      expect(moved.rect.left, 15);
      expect(moved.rect.right, 30);
      expect(moved.snap.startSnapped, isTrue);
      expect(moved.snap.endSnapped, isTrue);
    });

    test('auto-snap mode: if either end snapped once, snap without Cmd', () {
      final c = makeController();
      final item = CanvasItem(
        itemId: 'n1',
        itemType: 'node',
        objectType: 'session',
        worldRect: const Rect.fromLTWH(8, 0, 15, 10),
        snap: const CanvasItemSnapState(startSnapped: true, endSnapped: false),
      );

      final moved = c.applyMoveWithSnapping(
        item: item,
        deltaWorld: const Offset(0, 0),
        isCmdPressed: false,
      );

      expect(moved.rect.left, 15);
      expect(moved.rect.right, 30);
    });

    test('auto-snap mode: holding Cmd disables snapping', () {
      final c = makeController();
      final item = CanvasItem(
        itemId: 'n1',
        itemType: 'node',
        objectType: 'deliverable',
        worldRect: const Rect.fromLTWH(8, 0, 15, 10),
        snap: const CanvasItemSnapState(startSnapped: true, endSnapped: true),
      );

      final moved = c.applyMoveWithSnapping(
        item: item,
        deltaWorld: const Offset(0, 0),
        isCmdPressed: true,
      );

      expect(moved.rect.left, 8);
      expect(moved.rect.right, 23);
      // metadata preserved
      expect(moved.snap.startSnapped, isTrue);
      expect(moved.snap.endSnapped, isTrue);
    });
  });
}
