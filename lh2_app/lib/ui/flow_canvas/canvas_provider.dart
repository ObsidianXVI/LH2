import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';
import 'package:lh2_app/domain/notifiers/workspace_controller.dart';
import 'demo_items.dart';

/// Provider for the active canvas controller based on the current workspace state.
final activeCanvasControllerProvider = Provider<FlowCanvasController?>((ref) {
  final workspaceState = ref.watch(workspaceControllerProvider);
  final activeTab = workspaceState.activeTab;
  
  if (activeTab == null) return null;
  
  // Create a FlowCanvasController from the tab's controller data
  final controllerData = activeTab.tab.controller;
  final kind = controllerData['kind'] as String?;
  
  if (kind != 'flow') return null;
  
  return FlowCanvasController.fromJson({
    'kind': 'flow',
    'viewport': controllerData['viewport'] ?? {
      'panX': 0.0,
      'panY': 0.0,
      'zoom': 1.0,
      'viewportWidthPx': 800.0,
      'viewportHeightPx': 600.0,
    },
    'gridSizePx': controllerData['gridSizePx'] ?? 24.0,
    'items': activeTab.tab.items,
    'links': activeTab.tab.links,
    'selection': const <String>[],
  });
});