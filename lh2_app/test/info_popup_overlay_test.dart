import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_app/ui/info_popup_overlay.dart';
import 'package:lh2_app/domain/notifiers/info_popup_controller.dart';

void main() {
  group('InfoPopupOverlay Widget Tests', () {
    testWidgets('renders nothing when closed', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: InfoPopupOverlay(),
            ),
          ),
        ),
      );

      // Check for the title which shouldn't be there
      expect(find.text('Node Information'), findsNothing);
      expect(find.text('Configure New Node'), findsNothing);
    });

    testWidgets('renders information when open', (tester) async {
      // Set larger surface size to avoid overflow
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer();
      
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: InfoPopupOverlay(),
            ),
          ),
        ),
      );

      container.read(infoPopupControllerProvider.notifier).openViewMode(
            itemId: 'test_item',
            anchorScreenRect: const Rect.fromLTWH(10, 10, 50, 50),
          );

      await tester.pump();

      expect(find.text('Node Information'), findsOneWidget);
      expect(find.text('Item ID: test_item'), findsOneWidget);
    });
  });
}
