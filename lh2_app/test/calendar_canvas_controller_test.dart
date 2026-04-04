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

      // With fixed 12 columns visible: minutesPerPixel = (12 * interval) / viewportWidth
      // => 12*60/800 = 0.9
      expect(controller.minutesPerPixel, closeTo(0.9, 1e-6));
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

      final initialMinutesPerPixel = controller.minutesPerPixel;

      // Scroll up => squish timescale (more time per column)
      // With scroll-accumulator threshold, small deltas should NOT change rung.
      controller.handleCmdScroll(100.0);
      expect(controller.ruleIntervalMinutes, 60);

      // Exceed threshold
      controller.handleCmdScroll(200.0);
      expect(controller.ruleIntervalMinutes, 120);
      expect(controller.minutesPerPixel, greaterThan(initialMinutesPerPixel));

      final midMinutesPerPixel = controller.minutesPerPixel;

      // Scroll down => expand timescale (less time per column)
      controller.handleCmdScroll(-400.0);
      expect(controller.ruleIntervalMinutes, 60);
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
      // minPx = 40.0, hysteresisFactor = 1.1 => threshold = 40 / 1.1 = 36.36

      // With fixed 12 columns visible:
      expect(controller.minutesPerPixel, closeTo(0.9, 1e-6));

      // With accumulator, small scroll does not step.
      controller.handleCmdScroll(50.0);
      expect(controller.ruleIntervalMinutes, 60);

      // Exceed threshold to step.
      controller.handleCmdScroll(200.0);
      expect(controller.ruleIntervalMinutes, 120);

      // Squish more to cross threshold
      // We want nextMinutesPerPixel such that 60 / nextMinutesPerPixel < 36.36
      // nextMinutesPerPixel > 60 / 36.36 = 1.65
      controller.handleCmdScroll(800.0);
      expect(controller.ruleIntervalMinutes, greaterThanOrEqualTo(240));

      // Expand to cross back
      // MaxPx = 360.0, hysteresisFactor = 1.1 => threshold = 360 * 1.1 = 396.0
      // nextRuleInterval / nextMinutesPerPixel > 396.0
      // 120 / nextMinutesPerPixel > 396.0 => nextMinutesPerPixel < 120 / 396.0 = 0.303
      controller.handleCmdScroll(-2500.0);
      // Zooming in enough should allow the interval ladder to step back down.
      // With the fixed-12-columns model, interval changes are discrete;
      // one scroll event steps down by one rung.
      expect(controller.ruleIntervalMinutes, 60);
    });

    test('Zoom out range reaches 1 week and keeps 12 columns', () {
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

      // Repeatedly squeeze to reach 1 week (10080 mins)
      // 60 -> 120 -> 240 -> 480 -> 960 -> 1920 -> 3840 -> 7680 -> 10080 (clamped)
      // We need to scroll enough each time to cross the 40px/1.1 threshold.

      for (int i = 0; i < 30; i++) {
        controller.handleCmdScroll(1000.0);
      }

      expect(controller.ruleIntervalMinutes, 10080);

      // minutesPerPixel should be derived to keep 12 columns:
      // 12*10080/800 = 151.2
      expect(controller.minutesPerPixel, closeTo(151.2, 1e-3));
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
