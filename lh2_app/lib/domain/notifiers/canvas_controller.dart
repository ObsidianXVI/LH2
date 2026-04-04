library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'workspace_controller.dart';

/// Legacy CanvasController for backward compatibility
/// This maintains the original interface expected by existing code
class CanvasController {
  CanvasController(this.ref);

  final Ref ref;

  /// IDs of objects currently rendered on the canvas (active tab items).
  Set<String> get visibleObjectIds {
    final wsState = ref.read(currentWorkspaceStateProvider);
    final activeTab = wsState.activeTab;
    return activeTab?.tab.items.keys.cast<String>().toSet() ?? const <String>{};
  }

  /// World rect of the current viewport.
  Rect get viewportWorldRect {
    final wsState = ref.read(currentWorkspaceStateProvider);
    final activeTab = wsState.activeTab;
    if (activeTab == null) return Rect.zero;

    final controllerData = activeTab.tab.controller;
    final viewportData = controllerData['viewport'] as Map<String, Object?>? ??
        const <String, Object?>{};
    final panX = (viewportData['panX'] as num?)?.toDouble() ?? 0.0;
    final panY = (viewportData['panY'] as num?)?.toDouble() ?? 0.0;
    final zoom = (viewportData['zoom'] as num?)?.toDouble() ?? 1.0;

    const canvasPxSize = Size(800, 600);
    final worldSize =
        Size(canvasPxSize.width / zoom, canvasPxSize.height / zoom);
    return Rect.fromLTWH(panX, panY, worldSize.width, worldSize.height);
  }
}

/// Provider for the active canvas controller.
final activeCanvasControllerProvider = Provider<CanvasController>(
  (ref) => CanvasController(ref),
);
