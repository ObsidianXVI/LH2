/// Workspace operations for LH2.
///
/// Operations:
///   - api.workspace.load
///   - api.workspace.save
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/workspace_repository.dart';
import 'core.dart';

// ============================================================================
// api.workspace.load
// ============================================================================

/// Input for [WorkspaceLoadOp].
class WorkspaceLoadInput {
  final String workspaceId;

  const WorkspaceLoadInput({required this.workspaceId});

  Map<String, Object?> toJson() => {'workspaceId': workspaceId};
}

/// Output for [WorkspaceLoadOp].
class WorkspaceLoadOutput {
  final WorkspaceMeta meta;
  final List<WorkspaceTabEntry> tabs;

  const WorkspaceLoadOutput({required this.meta, required this.tabs});

  Map<String, Object?> toJson() => {
        'meta': meta.toJson(),
        'tabs': tabs.map((t) => t.toJson()).toList(),
      };
}

/// A single tab entry in the workspace load result.
class WorkspaceTabEntry {
  final String tabId;
  final WorkspaceTab tab;

  const WorkspaceTabEntry({required this.tabId, required this.tab});

  Map<String, Object?> toJson() => {
        'tabId': tabId,
        'tab': tab.toJson(),
      };
}

/// Loads workspace metadata and all tabs.
///
/// Operation ID: api.workspace.load
class WorkspaceLoadOp extends LH2Operation<WorkspaceLoadInput, WorkspaceLoadOutput> {
  final WorkspaceRepository _repo;

  WorkspaceLoadOp(this._repo);

  @override
  String get operationId => 'api.workspace.load';

  @override
  Future<LH2OpResult<WorkspaceLoadOutput>> run(WorkspaceLoadInput input) async {
    try {
      if (input.workspaceId.isEmpty) {
        return LH2OpResult.error(
          createError(
            errorCode: LH2ErrorCodes.invalidInput,
            message: 'workspaceId cannot be empty',
            payload: input.toJson(),
            isFatal: false,
          ),
        );
      }

      // Load workspace metadata
      final meta = await _repo.getWorkspaceMeta(input.workspaceId);

      // Load all tabs
      final tabOrder = meta.tabOrder;
      final tabs = <WorkspaceTabEntry>[];

      for (final tabId in tabOrder) {
        try {
          final tab = await _repo.getTab(input.workspaceId, tabId);
          tabs.add(WorkspaceTabEntry(tabId: tabId, tab: tab));
        } catch (e) {
          // Skip missing tabs but log via error
          return LH2OpResult.error(
            createError(
              errorCode: LH2ErrorCodes.notFound,
              message: 'Tab $tabId not found in workspace ${input.workspaceId}',
              payload: {'tabId': tabId, ...input.toJson()},
              cause: e,
              isFatal: false,
            ),
          );
        }
      }

      return LH2OpResult.ok(
        WorkspaceLoadOutput(meta: meta, tabs: tabs),
      );
    } catch (e) {
      return LH2OpResult.error(
        createError(
          errorCode: LH2ErrorCodes.databaseError,
          message: 'Failed to load workspace: ${e.toString()}',
          payload: input.toJson(),
          cause: e,
          isFatal: true,
        ),
      );
    }
  }
}

/// Provider for [WorkspaceLoadOp].
final workspaceLoadOpProvider = Provider<WorkspaceLoadOp>((ref) {
  final repo = ref.watch(workspaceRepoProvider);
  return WorkspaceLoadOp(repo);
});

// ============================================================================
// api.workspace.save
// ============================================================================

/// Input for [WorkspaceSaveOp].
class WorkspaceSaveInput {
  final String workspaceId;
  final WorkspaceMeta? meta;
  final List<WorkspaceTabSaveEntry>? tabs;

  const WorkspaceSaveInput({
    required this.workspaceId,
    this.meta,
    this.tabs,
  });

  Map<String, Object?> toJson() => {
        'workspaceId': workspaceId,
        if (meta != null) 'meta': meta!.toJson(),
        if (tabs != null) 'tabs': tabs!.map((t) => t.toJson()).toList(),
      };
}

/// A single tab entry to save.
class WorkspaceTabSaveEntry {
  final String? tabId; // null for new tabs
  final WorkspaceTabDraft? draft; // for new tabs
  final WorkspaceTabPatch? patch; // for existing tabs

  const WorkspaceTabSaveEntry.newTab(WorkspaceTabDraft this.draft)
      : tabId = null,
        patch = null;

  const WorkspaceTabSaveEntry.update(this.tabId, WorkspaceTabPatch this.patch)
      : draft = null,
        assert(tabId != null);

  Map<String, Object?> toJson() => {
        'tabId': tabId,
        if (draft != null) 'draft': draft.toString(),
        if (patch != null) 'patch': patch!.toUpdateMap(),
      };
}

/// Output for [WorkspaceSaveOp].
class WorkspaceSaveOutput {
  final bool metaSaved;
  final int tabsSaved;
  final List<String> createdTabIds;

  const WorkspaceSaveOutput({
    required this.metaSaved,
    required this.tabsSaved,
    required this.createdTabIds,
  });

  Map<String, Object?> toJson() => {
        'metaSaved': metaSaved,
        'tabsSaved': tabsSaved,
        'createdTabIds': createdTabIds,
      };
}

/// Saves workspace metadata and/or tabs.
///
/// Operation ID: api.workspace.save
class WorkspaceSaveOp extends LH2Operation<WorkspaceSaveInput, WorkspaceSaveOutput> {
  final WorkspaceRepository _repo;

  WorkspaceSaveOp(this._repo);

  @override
  String get operationId => 'api.workspace.save';

  @override
  Future<LH2OpResult<WorkspaceSaveOutput>> run(WorkspaceSaveInput input) async {
    try {
      if (input.workspaceId.isEmpty) {
        return LH2OpResult.error(
          createError(
            errorCode: LH2ErrorCodes.invalidInput,
            message: 'workspaceId cannot be empty',
            payload: input.toJson(),
            isFatal: false,
          ),
        );
      }

      bool metaSaved = false;
      int tabsSaved = 0;
      final createdTabIds = <String>[];

      // Save metadata if provided
      if (input.meta != null) {
        await _repo.upsertWorkspaceMeta(input.workspaceId, input.meta!);
        metaSaved = true;
      }

      // Save tabs if provided
      if (input.tabs != null) {
        for (final entry in input.tabs!) {
          if (entry.draft != null) {
            // Create new tab
            final newId = await _repo.createTab(input.workspaceId, entry.draft!);
            createdTabIds.add(newId);
            tabsSaved++;
          } else if (entry.tabId != null && entry.patch != null) {
            // Update existing tab
            await _repo.updateTab(input.workspaceId, entry.tabId!, entry.patch!);
            tabsSaved++;
          }
        }
      }

      return LH2OpResult.ok(
        WorkspaceSaveOutput(
          metaSaved: metaSaved,
          tabsSaved: tabsSaved,
          createdTabIds: createdTabIds,
        ),
      );
    } catch (e) {
      return LH2OpResult.error(
        createError(
          errorCode: LH2ErrorCodes.databaseError,
          message: 'Failed to save workspace: ${e.toString()}',
          payload: input.toJson(),
          cause: e,
          isFatal: true,
        ),
      );
    }
  }
}

/// Provider for [WorkspaceSaveOp].
final workspaceSaveOpProvider = Provider<WorkspaceSaveOp>((ref) {
  final repo = ref.watch(workspaceRepoProvider);
  return WorkspaceSaveOp(repo);
});