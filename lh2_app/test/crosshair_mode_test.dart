import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_app/domain/notifiers/crosshair_mode_controller.dart';

void main() {
  group('CrosshairModeController', () {
    test('initial state is correct', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(crosshairModeControllerProvider);
      expect(state.enabled, false);
      expect(state.hoveredItemId, isNull);
    });

    test('toggle() switches enabled state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(crosshairModeControllerProvider.notifier);
      
      notifier.toggle();
      expect(container.read(crosshairModeControllerProvider).enabled, true);
      
      notifier.toggle();
      expect(container.read(crosshairModeControllerProvider).enabled, false);
    });

    test('setEnabled() sets enabled state correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(crosshairModeControllerProvider.notifier);
      
      notifier.setEnabled(true);
      expect(container.read(crosshairModeControllerProvider).enabled, true);
      
      notifier.setEnabled(false);
      expect(container.read(crosshairModeControllerProvider).enabled, false);
    });

    test('setHoveredItemId() updates hovered item', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(crosshairModeControllerProvider.notifier);
      
      notifier.setHoveredItemId('test_node');
      expect(container.read(crosshairModeControllerProvider).hoveredItemId, 'test_node');
      
      notifier.setHoveredItemId(null);
      expect(container.read(crosshairModeControllerProvider).hoveredItemId, isNull);
    });

    test('clear() resets state to default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(crosshairModeControllerProvider.notifier);
      
      notifier.setEnabled(true);
      notifier.setHoveredItemId('node1');
      
      notifier.clear();
      final state = container.read(crosshairModeControllerProvider);
      expect(state.enabled, false);
      expect(state.hoveredItemId, isNull);
    });
  });
}
