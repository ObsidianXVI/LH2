/// Example WorkspaceController using the operation framework.
///
/// This demonstrates proper usage of operations from a Riverpod notifier.
/// UI should not directly call Firestore - all mutations go through operations.
///
/// NOTE: This is an example/documentation file showing how to use operations.
/// The actual WorkspaceController will be implemented in later tasks.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_stub/lh2_stub.dart';

import '../../data/workspace_repository.dart';
import '../operations/canvas.dart';
import '../operations/core.dart';
import '../operations/workspace.dart';

/// Example workspace state managed by a controller.
class WorkspaceState {
  final String workspaceId;
  final WorkspaceMeta? meta;
  final List<WorkspaceTabEntry> tabs;
  final String? activeTabId;
  final bool isLoading;
  final LH2OpError? lastError;

  const WorkspaceState({
    required this.workspaceId,
    this.meta,
    this.tabs = const [],
    this.activeTabId,
    this.isLoading = false,
    this.lastError,
  });

  WorkspaceState copyWith({
    String? workspaceId,
    WorkspaceMeta? meta,
    List<WorkspaceTabEntry>? tabs,
    String? activeTabId,
    bool? isLoading,
    LH2OpError? lastError,
  }) {
    return WorkspaceState(
      workspaceId: workspaceId ?? this.workspaceId,
      meta: meta ?? this.meta,
      tabs: tabs ?? this.tabs,
      activeTabId: activeTabId ?? this.activeTabId,
      isLoading: isLoading ?? this.isLoading,
      lastError: lastError,
    );
  }

  /// Gets the active tab entry, if any.
  WorkspaceTabEntry? get activeTab {
    if (activeTabId == null) return null;
    return tabs.where((t) => t.tabId == activeTabId).firstOrNull;
  }
}

/// Example controller demonstrating operation usage patterns.
///
/// This shows three patterns:
/// 1. **Error recovery**: loadWorkspace handles non-fatal errors gracefully
/// 2. **Throw on fatal**: createTab uses runOrThrow to propagate fatal errors
/// 3. **Silent failure**: updateViewport ignores non-fatal errors
///
/// Example usage from UI:
/// ```dart
/// // Read state
/// final state = ref.watch(workspaceControllerProvider('ws-123'));
///
/// // Load workspace (handles errors internally)
/// await ref.read(workspaceControllerProvider('ws-123').notifier).loadWorkspace();
///
/// // Create a new tab (throws on fatal errors)
/// try {
///   final tabId = await ref.read(workspaceControllerProvider('ws-123').notifier)
///       .createTab('flow');
/// } on LH2OpError catch (e) {
///   // Handle fatal error in UI
///   showErrorDialog(e.message);
/// }
///
/// // Update viewport (silent on errors)
/// ref.read(workspaceControllerProvider('ws-123').notifier)
///     .updateViewport(100, 200, 1.5);
/// ```
class ExampleWorkspaceController extends Notifier<WorkspaceState> {
  @override
  WorkspaceState build() {
    return WorkspaceState(workspaceId: '');
  }

  /// Pattern 1: Error Recovery
  /// Loads workspace data using api.workspace.load operation.
  /// Non-fatal errors are captured in state for UI display.
  Future<void> loadWorkspace() async {
    state = state.copyWith(isLoading: true, lastError: null);

    final loadOp = ref.read(workspaceLoadOpProvider);
    final result = await loadOp.run(
      WorkspaceLoadInput(workspaceId: state.workspaceId),
    );

    if (result.ok) {
      final output = result.value!;
      state = state.copyWith(
        meta: output.meta,
        tabs: output.tabs,
        activeTabId: output.meta.activeTabId ?? output.tabs.firstOrNull?.tabId,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        lastError: result.error,
      );

      // Log error for telemetry
      _logError(result.error!);
    }
  }

  /// Pattern 2: Throw on Fatal
  /// Creates a new tab using api.workspace.save operation.
  /// Uses [runOrThrow] to propagate fatal errors to caller.
  Future<String> createTab(String kind) async {
    final saveOp = ref.read(workspaceSaveOpProvider);

    final draft = WorkspaceTabDraft(
      kind: kind,
      title: kind == 'flow'
          ? 'Flow ${state.tabs.length + 1}'
          : 'Calendar ${state.tabs.length + 1}',
      controller: {
        'kind': kind,
        'viewport': {'panX': 0.0, 'panY': 0.0, 'zoom': 1.0},
        if (kind == 'flow') 'gridSizePx': 24,
      },
    );

    // Use runOrThrow to throw on fatal errors
    final output = await runOrThrow(
      saveOp,
      WorkspaceSaveInput(
        workspaceId: state.workspaceId,
        tabs: [WorkspaceTabSaveEntry.newTab(draft)],
      ),
    );

    // Reload workspace to get new tab
    await loadWorkspace();

    return output.createdTabIds.first;
  }

  /// Pattern 3: Silent Failure
  /// Updates the active tab's viewport using api.canvas.updateViewport.
  /// Non-fatal errors are logged but don't affect UI state.
  Future<void> updateViewport(double panX, double panY, double zoom) async {
    final activeTabId = state.activeTabId;
    if (activeTabId == null) return;

    final updateOp = ref.read(canvasUpdateViewportOpProvider);
    final result = await updateOp.run(
      CanvasUpdateViewportInput(
        workspaceId: state.workspaceId,
        tabId: activeTabId,
        panX: panX,
        panY: panY,
        zoom: zoom,
      ),
    );

    if (!result.ok) {
      // Non-fatal: log but don't propagate
      _logError(result.error!);
    }
  }

  /// Adds a canvas item using api.canvas.addItem.
  /// Demonstrates error recovery pattern (non-fatal errors returned in result).
  Future<String?> addCanvasItem({
    required String itemType,
    required Map<String, Object?> worldRect,
    ObjectType? objectType,
    String? templateId,
  }) async {
    final activeTabId = state.activeTabId;
    if (activeTabId == null) {
      state = state.copyWith(
        lastError: const LH2OpError(
          operationId: 'workspace.addCanvasItem',
          errorCode: 'NO_ACTIVE_TAB',
          message: 'No active tab to add item to',
          isFatal: false,
        ),
      );
      return null;
    }

    final addOp = ref.read(canvasAddItemOpProvider);
    final result = await addOp.run(
      CanvasAddItemInput(
        workspaceId: state.workspaceId,
        tabId: activeTabId,
        itemType: itemType,
        objectType: objectType,
        templateId: templateId,
        worldRect: worldRect,
      ),
    );

    if (result.ok) {
      return result.value!.itemId;
    } else {
      state = state.copyWith(lastError: result.error);
      _logError(result.error!);
      return null;
    }
  }

  /// Sets the active tab by ID.
  void setActiveTab(String tabId) {
    state = state.copyWith(activeTabId: tabId);
  }

  /// Clears the last error.
  void clearError() {
    state = state.copyWith(lastError: null);
  }

  /// Logs errors to console for telemetry (Task 7.3-1 will expand this).
  void _logError(LH2OpError error) {
    // JSON format for telemetry
    final logEntry = {
      'ts': DateTime.now().millisecondsSinceEpoch,
      'level': error.isFatal ? 'error' : 'warn',
      'message': error.message,
      'operationId': error.operationId,
      'errorCode': error.errorCode,
      'payload': error.payload,
      'location': error.location,
    };

    // ignore: avoid_print
    print('[LH2 Telemetry] $logEntry');
  }
}

/// Example provider for [ExampleWorkspaceController].
///
/// Usage:
/// ```dart
/// final controller = ref.read(exampleWorkspaceControllerProvider('ws-123').notifier);
/// await controller.loadWorkspace();
/// ```
final exampleWorkspaceControllerProvider =
    NotifierProvider<ExampleWorkspaceController, WorkspaceState>(
  ExampleWorkspaceController.new,
);
