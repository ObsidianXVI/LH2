import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';
import 'package:timezone/data/latest_all.dart' as tz;

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('CalendarCanvasController', () {
    test('Initialization with default values', () {
      final viewport = const CanvasViewport(
        pan: Offset.zero,
        zoom: 1.0,
        viewportSizePx: Size(800, 600),
      );
      final controller = CalendarCanvasController(viewport: viewport);

      expect(controller.minutesPerPixel, 1.0);
      expect(controller.ruleIntervalMinutes, 60);
      expect(controller.anchorStartSgt, isNotNull);
    });

    test('handleCmdScroll expands and squishes timescale', () {
      final viewport = const CanvasViewport(
        pan: Offset.zero,
        zoom: 1.0,
        viewportSizePx: Size(800, 600),
      );
      final controller = CalendarCanvasController(viewport: viewport);

      // Scroll up => squish timescale (more minutes per pixel)
      controller.handleCmdScroll(100.0);
      expect(controller.minutesPerPixel, greaterThan(1.0));

      final midMinutesPerPixel = controller.minutesPerPixel;

      // Scroll down => expand timescale (fewer minutes per pixel)
      controller.handleCmdScroll(-100.0);
      expect(controller.minutesPerPixel, lessThan(midMinutesPerPixel));
    });

    test('Hysteresis logic for ruleIntervalMinutes', () {
      final viewport = const CanvasViewport(
        pan: Offset.zero,
        zoom: 1.0,
        viewportSizePx: Size(800, 600),
      );
      final controller = CalendarCanvasController(
        viewport: viewport,
        minutesPerPixel: 1.0,
        ruleIntervalMinutes: 60,
      );

      // Initial pixel spacing = 60 / 1.0 = 60.0
      // minPx = 60.0, hysteresisFactor = 1.1 => threshold = 60 / 1.1 = 54.54
      
      // Squish a bit, but stay above threshold
      controller.handleCmdScroll(50.0); // minutesPerPixel becomes ~1.05
      expect(controller.ruleIntervalMinutes, 60);

      // Squish more to cross threshold
      // We want nextMinutesPerPixel such that 60 / nextMinutesPerPixel < 54.54
      // nextMinutesPerPixel > 60 / 54.54 = 1.1
      controller.handleCmdScroll(500.0); 
      expect(controller.ruleIntervalMinutes, 120);

      // Expand to cross back
      // MaxPx = 180.0, hysteresisFactor = 1.1 => threshold = 180 * 1.1 = 198.0
      // nextRuleInterval / nextMinutesPerPixel > 198.0
      // 120 / nextMinutesPerPixel > 198.0 => nextMinutesPerPixel < 120 / 198.0 = 0.606
      controller.handleCmdScroll(-1500.0);
      expect(controller.ruleIntervalMinutes, 60);
    });

    test('snapWorldX snaps to 15 minute increments', () {
      final viewport = const CanvasViewport(
        pan: Offset.zero,
        zoom: 1.0,
        viewportSizePx: Size(800, 600),
      );
      final controller = CalendarCanvasController(viewport: viewport);

      expect(controller.snapWorldX(7.0), 0.0);
      expect(controller.snapWorldX(8.0), 15.0);
      expect(controller.snapWorldX(22.0), 15.0);
      expect(controller.snapWorldX(23.0), 30.0);
    });
  });
}
