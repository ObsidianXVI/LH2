import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_app/ui/crosshair_overlay.dart';
import 'package:lh2_app/domain/notifiers/crosshair_mode_controller.dart';
import 'package:lh2_app/ui/flow_canvas/canvas_provider.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';

void main() {
  group('CrosshairOverlay Widget Tests', () {
    testWidgets('renders nothing when disabled', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(children: [CrosshairOverlay()]),
            ),
          ),
        ),
      );

      expect(find.text('Crosshair Mode'), findsNothing);
    });

    testWidgets('renders side panel when enabled', (tester) async {
      // Set larger surface size to avoid overflow
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          activeCanvasControllerProvider.overrideWithValue(
            FlowCanvasController(
              viewport: const CanvasViewport(
                pan: Offset.zero,
                zoom: 1.0,
                viewportSizePx: Size(800, 600),
              ),
              items: {
                'node1': CanvasItem(
                  itemId: 'node1',
                  itemType: 'node',
                  worldRect: const Rect.fromLTWH(0, 0, 100, 100),
                ),
              },
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Stack(children: [CrosshairOverlay()]),
            ),
          ),
        ),
      );

      container.read(crosshairModeControllerProvider.notifier).setEnabled(true);
      container.read(crosshairModeControllerProvider.notifier).setHoveredItemId('node1');

      await tester.pump();

      expect(find.text('Crosshair Mode'), findsOneWidget);
      expect(find.text('Item ID: node1'), findsOneWidget);
    });
  });
}
