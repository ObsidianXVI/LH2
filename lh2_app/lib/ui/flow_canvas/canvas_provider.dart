import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';
import 'package:lh2_app/domain/notifiers/workspace_controller.dart';

/// Provider for the active canvas controller based on the current workspace state.
final activeCanvasControllerProvider = Provider<CanvasController?>((ref) {
  final workspaceState = ref.watch(workspaceControllerProvider);
  final activeTab = workspaceState.activeTab;

  if (activeTab == null) return null;

  // Create the appropriate CanvasController from the tab's controller data
  final controllerData = activeTab.tab.controller;
  final kind = controllerData['kind'] as String?;

  if (kind == 'flow') {
    return FlowCanvasController.fromJson({
      'kind': 'flow',
      'viewport': controllerData['viewport'] ??
          {
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
  } else if (kind == 'calendar') {
    return CalendarCanvasController.fromJson({
      'kind': 'calendar',
      'viewport': controllerData['viewport'] ??
          {
            'panX': 0.0,
            'panY': 0.0,
            'zoom': 1.0,
            'viewportWidthPx': 800.0,
            'viewportHeightPx': 600.0,
          },
      'anchorStartSgt': controllerData['anchorStartSgt'],
      'minutesPerPixel': controllerData['minutesPerPixel'] ?? 1.0,
      'ruleIntervalMinutes': controllerData['ruleIntervalMinutes'] ?? 60,
      'items': activeTab.tab.items,
      'links': activeTab.tab.links,
      'selection': const <String>[],
    });
  }

  return null;
});
