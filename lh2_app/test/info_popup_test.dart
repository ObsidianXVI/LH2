import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_app/domain/notifiers/info_popup_controller.dart';
import 'package:lh2_stub/lh2_stub.dart';

void main() {
  group('InfoPopupController', () {
    test('initial state is closed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(infoPopupControllerProvider);
      expect(state.isOpen, false);
      expect(state.isHovered, false);
    });

    test('openAddMode() sets correct state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(infoPopupControllerProvider.notifier);

      notifier.openAddMode(
        itemId: 'new_item',
        anchorScreenRect: const Rect.fromLTWH(10, 10, 50, 50),
        objectType: ObjectType.task,
        templateId: 'task-basic',
      );

      final state = container.read(infoPopupControllerProvider);
      expect(state.isOpen, true);
      expect(state.mode, InfoPopupMode.add);
      expect(state.itemId, 'new_item');
      expect(state.objectType, ObjectType.task);
    });

    test('openViewMode() sets correct state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(infoPopupControllerProvider.notifier);

      notifier.openViewMode(
        itemId: 'existing_item',
        anchorScreenRect: const Rect.fromLTWH(100, 100, 20, 20),
        objectType: ObjectType.task,
      );

      final state = container.read(infoPopupControllerProvider);
      expect(state.isOpen, true);
      expect(state.mode, InfoPopupMode.view);
      expect(state.itemId, 'existing_item');
      expect(state.objectType, ObjectType.task);
    });

    test('close() resets isOpen and isHovered', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(infoPopupControllerProvider.notifier);

      notifier.openViewMode(
        itemId: 'id',
        anchorScreenRect: Rect.zero,
        objectType: ObjectType.task,
      );
      notifier.setIsHovered(true);
      
      notifier.close();
      final state = container.read(infoPopupControllerProvider);
      expect(state.isOpen, false);
      expect(state.isHovered, false);
    });

    test('setIsHovered() updates hover state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(infoPopupControllerProvider.notifier);

      notifier.setIsHovered(true);
      expect(container.read(infoPopupControllerProvider).isHovered, true);
      
      notifier.setIsHovered(false);
      expect(container.read(infoPopupControllerProvider).isHovered, false);
    });
  });
}
