import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';

void main() {
  group('CalendarCanvasController', () {
    late CalendarCanvasController controller;

    setUp(() {
      controller = CalendarCanvasController(
        viewport: const CanvasViewport(
          pan: Offset.zero,
          zoom: 1.0,
          viewportSizePx: Size(800, 600),
        ),
      );
    });

    test('initial values', () {
      expect(controller.minutesPerPixel, 1.0);
      expect(controller.ruleIntervalMinutes, 60);
      expect(controller.kind, const CalendarCanvasKind());
    });

    test('handleCmdScroll updates scaling', () {
      // Scroll down (positive delta) -> expand timescale -> minutesPerPixel should increase
      controller.handleCmdScroll(100.0);
      expect(controller.minutesPerPixel, greaterThan(1.0));

      // Scroll up (negative delta) -> squish timescale -> minutesPerPixel should decrease
      final currentScale = controller.minutesPerPixel;
      controller.handleCmdScroll(-100.0);
      expect(controller.minutesPerPixel, lessThan(currentScale));
    });

    test('snapWorldX snaps to 15-minute increments', () {
      expect(controller.snapWorldX(7.0), 0.0);
      expect(controller.snapWorldX(8.0), 15.0);
      expect(controller.snapWorldX(22.0), 15.0);
      expect(controller.snapWorldX(23.0), 30.0);
    });

    test('shouldSnap identifies correct types', () {
      final deliverable = CanvasItem(
        itemId: '1',
        itemType: 'node',
        objectType: 'deliverable',
        worldRect: Rect.zero,
      );
      final widget = CanvasItem(
        itemId: '2',
        itemType: 'widget',
        worldRect: Rect.zero,
      );
      final task = CanvasItem(
        itemId: '3',
        itemType: 'node',
        objectType: 'task',
        worldRect: Rect.zero,
      );

      expect(controller.shouldSnap(deliverable), true);
      expect(controller.shouldSnap(widget), false);
      expect(controller.shouldSnap(task), false);
    });
  });
}
