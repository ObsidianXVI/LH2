/// Example WorkspaceController using the operation framework.
///
/// This demonstrates proper usage of operations from a Riverpod notifier.
/// UI should not directly call Firestore - all mutations go through operations.
library;

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_stub/lh2_stub.dart';

import '../../app/providers.dart';
import '../../data/workspace_repository.dart';
import '../operations/canvas.dart';
import '../operations/core.dart';
import '../operations/workspace.dart';

/// Canvas kind for workspace tabs.
///
/// Stored in Firestore as `flow` or `calendar`.
enum CanvasKind {
  flow,
  calendar;

  String get firestoreValue => name;
}

/// Workspace state managed by [WorkspaceController].
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

/// Controller for workspace operations.
///
/// Example usage from UI:
/// ```dart
/// // Read state
/// final state = ref.watch(workspaceControllerProvider);
///
/// // Load workspace
/// ref.read(workspaceControllerProvider.notifier).loadWorkspace('ws-123');
///
/// // Create a new tab (using runOrThrow for fatal errors)
/// try {
///   await ref.read(workspaceControllerProvider.notifier).createTab('flow');
/// } on LH2OpError catch (e) {
///   // Handle fatal error
/// }
/// ```
class WorkspaceController extends Notifier<WorkspaceState> {
  @override
  WorkspaceState build() {
    return WorkspaceState(workspaceId: '');
  }

  /// Loads workspace data using api.workspace.load operation.
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> loadWorkspace(String workspaceId) async {
    state = state.copyWith(isLoading: true, lastError: null);

    final loadOp = ref.read(workspaceLoadOpProvider);
    var result = await loadOp.run(WorkspaceLoadInput(workspaceId: workspaceId));

    // If not found, try to initialize it
    if (!result.ok && result.error?.errorCode == LH2ErrorCodes.notFound) {
      await _initializeNewWorkspace(workspaceId);
      result = await loadOp.run(WorkspaceLoadInput(workspaceId: workspaceId));
    }

    if (result.ok) {
      final output = result.value!;
      state = state.copyWith(
        workspaceId: workspaceId,
        meta: output.meta,
        tabs: output.tabs,
        activeTabId: output.meta.activeTabId ?? output.tabs.firstOrNull?.tabId,
        isLoading: false,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        lastError: result.error,
      );

      // Log error for telemetry
      if (result.error != null) _logError(result.error!);
      return false;
    }
  }

  /// Internal helper to create a brand new workspace with default tabs.
  Future<void> _initializeNewWorkspace(String workspaceId) async {
    final saveOp = ref.read(workspaceSaveOpProvider);

    // Ensure the workspace meta doc exists first.
    // This prevents "Workspace <id> not found" during initial boot.
    final currentUser = await ref.read(currentUserProvider.future);
    await runOrThrow(
      saveOp,
      WorkspaceSaveInput(
        workspaceId: workspaceId,
        meta: WorkspaceMeta(
          schemaVersion: 1,
          ownerUid: currentUser.uid,
          activeTabId: null,
          tabOrder: const [],
        ),
      ),
    );

    // 2. Set workspaceId in state BEFORE creating tabs to avoid recursion
    state = state.copyWith(workspaceId: workspaceId);

    // 3. Create default tabs
    await createTab(CanvasKind.flow, makeActive: true);
    await createTab(CanvasKind.calendar);
  }

  /// Creates a new tab using api.workspace.save operation.
  ///
  /// Uses [runOrThrow] to propagate fatal errors.
  Future<String> createTab(
    CanvasKind kind, {
    bool makeActive = true,
  }) async {
    final workspaceId = state.workspaceId;
    if (workspaceId.isEmpty) {
      throw LH2OpError(
        operationId: 'api.workspace.createTab',
        errorCode: LH2ErrorCodes.preconditionFailed,
        message: 'No workspace loaded; cannot create tab.',
        payload: {'kind': kind.firestoreValue},
        isFatal: true,
      );
    }

    final repo = ref.read(workspaceRepoProvider);

    // Determine next tab number by kind.
    final existingCount =
        state.tabs.where((t) => t.tab.kind == kind.firestoreValue).length;
    final title = switch (kind) {
      CanvasKind.flow => 'Flow ${existingCount + 1}',
      CanvasKind.calendar => 'Calendar ${existingCount + 1}',
    };

    final controller = <String, Object?>{
      'kind': kind.firestoreValue,
      'viewport': {'panX': 0.0, 'panY': 0.0, 'zoom': 1.0},
      if (kind == CanvasKind.flow) 'gridSizePx': 24,
      // Calendar defaults (Appendix B/C) can be expanded later.
    };

    final tabId = await repo.createTab(
      workspaceId,
      WorkspaceTabDraft(
        kind: kind.firestoreValue,
        title: title,
        controller: controller,
      ),
    );

    // Update meta: append tabOrder + optionally set activeTabId.
    final meta = state.meta ?? await repo.getWorkspaceMeta(workspaceId);
    final newTabOrder = [...meta.tabOrder, tabId].cast<String>();
    await repo.upsertWorkspaceMeta(
      workspaceId,
      WorkspaceMeta(
        schemaVersion: meta.schemaVersion,
        ownerUid: meta.ownerUid,
        activeTabId: makeActive ? tabId : (meta.activeTabId ?? tabId),
        tabOrder: newTabOrder,
      ),
    );

    // Optimistically update UI state so the tab appears immediately
    // (Firestore will converge via the next load).
    final newEntry = WorkspaceTabEntry(
      tabId: tabId,
      tab: WorkspaceTab(
        schemaVersion: 1,
        kind: kind.firestoreValue,
        title: title,
        controller: controller,
        items: const {},
        links: const {},
      ),
    );

    state = state.copyWith(
      tabs: [...state.tabs, newEntry],
      activeTabId: makeActive ? tabId : state.activeTabId,
    );

    return tabId;
  }

  /// Updates the active tab's viewport using api.canvas.updateViewport.
  ///
  /// Non-fatal errors are ignored (viewport updates can fail silently).
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
  ///
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
        lastError: LH2OpError(
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

  /// Renames a tab title and persists the change to Firestore.
  ///
  /// Throws [LH2OpError] on validation or precondition failure.
  /// Reverts optimistic update and sets [lastError] on persistence failure.
  Future<void> renameTab(String tabId, String newTitle) async {
    final trimmedTitle = newTitle.trim();
    if (trimmedTitle.isEmpty || trimmedTitle.length < 2) {
      throw LH2OpError(
        operationId: 'workspace.renameTab',
        errorCode: 'INVALID_TITLE',
        message: 'Tab title must be 2+ characters long.',
        payload: {'tabId': tabId, 'newTitle': newTitle},
        isFatal: false,
      );
    }

    if (state.workspaceId.isEmpty) {
      throw LH2OpError(
        operationId: 'workspace.renameTab',
        errorCode: LH2ErrorCodes.preconditionFailed,
        message: 'No workspace loaded.',
        isFatal: true,
      );
    }

    final oldEntry = state.tabs.firstWhereOrNull((t) => t.tabId == tabId);
    if (oldEntry == null) {
      throw LH2OpError(
        operationId: 'workspace.renameTab',
        errorCode: LH2ErrorCodes.notFound,
        message: 'Tab $tabId not found.',
        isFatal: true,
      );
    }

    final oldTitle = oldEntry.tab.title;
    final idx = state.tabs.indexWhere((t) => t.tabId == tabId);

    // Optimistic update
    final newTab = WorkspaceTab(
      schemaVersion: oldEntry.tab.schemaVersion,
      kind: oldEntry.tab.kind,
      title: trimmedTitle,
      controller: oldEntry.tab.controller,
      items: oldEntry.tab.items,
      links: oldEntry.tab.links,
    );
    final newTabs = List<WorkspaceTabEntry>.from(state.tabs);
    newTabs[idx] = WorkspaceTabEntry(tabId: tabId, tab: newTab);
    state = state.copyWith(tabs: newTabs);

    // Persist to Firestore
    final repo = ref.read(workspaceRepoProvider);
    try {
      await repo.updateTab(state.workspaceId, tabId, WorkspaceTabPatch(title: trimmedTitle));
    } catch (e) {
      // Revert on failure
      final revertedTab = WorkspaceTab(
        schemaVersion: oldEntry.tab.schemaVersion,
        kind: oldEntry.tab.kind,
        title: oldTitle,
        controller: oldEntry.tab.controller,
        items: oldEntry.tab.items,
        links: oldEntry.tab.links,
      );
      final revertedTabs = List<WorkspaceTabEntry>.from(state.tabs);
      revertedTabs[idx] = WorkspaceTabEntry(tabId: tabId, tab: revertedTab);
      state = state.copyWith(
        tabs: revertedTabs,
        lastError: LH2OpError(
          operationId: 'workspace.renameTab',
          errorCode: 'PERSISTENCE_FAILED',
          message: 'Failed to save tab rename: ${e.toString()}',
          isFatal: false,
        ),
      );
      rethrow;
    }
  }

  /// Deletes a tab and persists the change.
  ///
  /// Removes tab from state.tabs and meta.tabOrder.
  /// If active tab deleted, switches to nearest neighbor (prefer next, then prev).
  /// Reverts optimistic UI update on persistence failure.
  Future<void> deleteTab(String tabId) async {
    final wsId = state.workspaceId;
    if (wsId.isEmpty) {
      throw LH2OpError(
        operationId: 'workspace.deleteTab',
        errorCode: LH2ErrorCodes.preconditionFailed,
        message: 'No workspace loaded; cannot delete tab.',
        isFatal: true,
      );
    }

    final tabIdx = state.tabs.indexWhere((t) => t.tabId == tabId);
    if (tabIdx == -1) {
      throw LH2OpError(
        operationId: 'workspace.deleteTab',
        errorCode: LH2ErrorCodes.notFound,
        message: 'Tab $tabId not found.',
        isFatal: true,
      );
    }

    if (state.meta == null) {
      throw LH2OpError(
        operationId: 'workspace.deleteTab',
        errorCode: 'NO_META',
        message: 'Workspace meta not loaded.',
        isFatal: true,
      );
    }

    final oldState = state;
    final meta = state.meta!;

    // Compute new active ID (prefer next neighbor, then prev)
    String? newActiveId = state.activeTabId;
    final tabsLength = state.tabs.length;
    if (state.activeTabId == tabId) {
      if (tabIdx < tabsLength - 1) {
        // Prefer next (right)
        newActiveId = state.tabs[tabIdx + 1].tabId;
      } else if (tabIdx > 0) {
        // Then prev (left)
        newActiveId = state.tabs[tabIdx - 1].tabId;
      } else {
        // Single tab
        newActiveId = null;
      }
    }

    // Optimistic UI update
    final newTabs = state.tabs.where((t) => t.tabId != tabId).toList();
    state = state.copyWith(
      tabs: newTabs,
      activeTabId: newActiveId,
    );

    final repo = ref.read(workspaceRepoProvider);
    try {
      // Persist: update meta (remove from tabOrder, set new active)
      final newTabOrder = meta.tabOrder.where((id) => id != tabId).toList();
      final newMeta = WorkspaceMeta(
        schemaVersion: meta.schemaVersion,
        ownerUid: meta.ownerUid,
        activeTabId: newActiveId,
        tabOrder: newTabOrder,
      );
      await repo.upsertWorkspaceMeta(wsId, newMeta);

      // Delete tab document (discards config/state)
      await repo.deleteTab(wsId, tabId);
    } catch (e) {
      // Revert optimistic update
      state = oldState.copyWith(
        lastError: LH2OpError(
          operationId: 'workspace.deleteTab',
          errorCode: 'PERSISTENCE_FAILED',
          message: 'Failed to delete tab: ${e.toString()}',
          isFatal: false,
        ),
      );
      rethrow;
    }
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
    print('[LH2 Telemetry] ${logEntry.toString()}');
  }
}

/// Provider for [WorkspaceController].
final workspaceControllerProvider =
    NotifierProvider<WorkspaceController, WorkspaceState>(
  WorkspaceController.new,
);

/// Provider for the current workspace state (convenience).
///
/// Usage: Watch this provider to get the current workspace state.
/// Call loadWorkspace on the controller to initialize with a workspaceId.
final currentWorkspaceStateProvider = Provider<WorkspaceState>((ref) {
  return ref.watch(workspaceControllerProvider);
});
