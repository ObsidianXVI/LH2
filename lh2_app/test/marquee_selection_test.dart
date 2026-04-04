import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_app/domain/notifiers/marquee_selection_controller.dart';

void main() {
  group('MarqueeSelectionController', () {
    test('initial state is correct', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(marqueeSelectionControllerProvider);
      expect(state.enabled, false);
      expect(state.isDragging, false);
    });

    test('enterMarqueeMode() enables mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(marqueeSelectionControllerProvider.notifier);

      notifier.enterMarqueeMode();
      expect(container.read(marqueeSelectionControllerProvider).enabled, true);
    });

    test('dragging updates state correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(marqueeSelectionControllerProvider.notifier);

      notifier.startDragging(const Offset(10, 10));
      var state = container.read(marqueeSelectionControllerProvider);
      expect(state.isDragging, true);
      expect(state.startWorldPoint, const Offset(10, 10));
      expect(state.currentWorldPoint, const Offset(10, 10));

      notifier.updateDragging(const Offset(50, 50));
      state = container.read(marqueeSelectionControllerProvider);
      expect(state.currentWorldPoint, const Offset(50, 50));
      expect(state.worldRect, const Rect.fromLTRB(10, 10, 50, 50));

      notifier.endDragging();
      state = container.read(marqueeSelectionControllerProvider);
      expect(state.isDragging, false);
      expect(state.startWorldPoint, isNull);
    });

    test('toggleMarqueeMode() works', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(marqueeSelectionControllerProvider.notifier);

      notifier.toggleMarqueeMode();
      expect(container.read(marqueeSelectionControllerProvider).enabled, true);

      notifier.toggleMarqueeMode();
      expect(container.read(marqueeSelectionControllerProvider).enabled, false);
    });
  });
}
