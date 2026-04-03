/// Canvas operations for LH2.
///
/// Operations:
///   - api.canvas.addItem
///   - api.canvas.updateViewport
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_stub/lh2_stub.dart';

import '../../app/providers.dart';
import '../../data/workspace_repository.dart';
import 'core.dart';

typedef JSON = Map<String, Object?>;

// ============================================================================
// api.canvas.addItem
// ============================================================================

/// Input for [CanvasAddItemOp].
class CanvasAddItemInput {
  final String workspaceId;
  final String tabId;
  final String itemType; // 'node' | 'widget'
  final ObjectType? objectType; // for nodes
  final String? objectId; // for nodes with existing objects
  final String? templateId; // for node rendering
  final JSON? widgetConfig; // for widgets
  final JSON worldRect; // {x, y, w, h}

  const CanvasAddItemInput({
    required this.workspaceId,
    required this.tabId,
    required this.itemType,
    this.objectType,
    this.objectId,
    this.templateId,
    this.widgetConfig,
    required this.worldRect,
  });

  Map<String, Object?> toJson() => {
        'workspaceId': workspaceId,
        'tabId': tabId,
        'itemType': itemType,
        if (objectType != null) 'objectType': objectType!.name,
        if (objectId != null) 'objectId': objectId,
        if (templateId != null) 'templateId': templateId,
        if (widgetConfig != null) 'widgetConfig': widgetConfig,
        'worldRect': worldRect,
      };
}

/// Output for [CanvasAddItemOp].
class CanvasAddItemOutput {
  final String itemId;

  const CanvasAddItemOutput({required this.itemId});

  Map<String, Object?> toJson() => {'itemId': itemId};
}

/// Adds a new item (node or widget) to the canvas.
///
/// Operation ID: api.canvas.addItem
class CanvasAddItemOp extends LH2Operation<CanvasAddItemInput, CanvasAddItemOutput> {
  final WorkspaceRepository _repo;

  CanvasAddItemOp(this._repo);

  @override
  String get operationId => 'api.canvas.addItem';

  @override
  Future<LH2OpResult<CanvasAddItemOutput>> execute(CanvasAddItemInput input) async {
    try {
      // Validate input
      if (input.workspaceId.isEmpty || input.tabId.isEmpty) {
        return LH2OpResult.error(
          createError(
            errorCode: LH2ErrorCodes.invalidInput,
            message: 'workspaceId and tabId are required',
            payload: input.toJson(),
            isFatal: false,
          ),
        );
      }

      if (!['node', 'widget'].contains(input.itemType)) {
        return LH2OpResult.error(
          createError(
            errorCode: LH2ErrorCodes.invalidInput,
            message: 'itemType must be "node" or "widget"',
            payload: input.toJson(),
            isFatal: false,
          ),
        );
      }

      if (input.itemType == 'node' && input.objectType == null) {
        return LH2OpResult.error(
          createError(
            errorCode: LH2ErrorCodes.invalidInput,
            message: 'objectType is required for nodes',
            payload: input.toJson(),
            isFatal: false,
          ),
        );
      }

      // Generate item ID
      final itemId = '${input.itemType}_${DateTime.now().millisecondsSinceEpoch}_${_randomSuffix()}';

      // Build item data
      final itemData = <String, Object?>{
        'schemaVersion': 1,
        'itemId': itemId,
        'itemType': input.itemType,
        'worldRect': input.worldRect,
        'snap': {'startSnapped': false, 'endSnapped': false},
        if (input.objectType != null) 'objectType': input.objectType!.name,
        if (input.objectId != null) 'objectId': input.objectId,
        if (input.templateId != null) 'templateId': input.templateId,
        if (input.widgetConfig != null) 'widgetConfig': input.widgetConfig,
      };

      // Get current tab to merge items
      final currentTab = await _repo.getTab(input.workspaceId, input.tabId);

      // Update with new item
      final updatedItems = Map<String, Object?>.from(currentTab.items);
      updatedItems[itemId] = itemData;

      await _repo.updateTab(
        input.workspaceId,
        input.tabId,
        WorkspaceTabPatch(items: updatedItems),
      );

      return LH2OpResult.ok(CanvasAddItemOutput(itemId: itemId));
    } catch (e) {
      return LH2OpResult.error(
        createError(
          errorCode: LH2ErrorCodes.databaseError,
          message: 'Failed to add canvas item: ${e.toString()}',
          payload: input.toJson(),
          cause: e,
          isFatal: true,
        ),
      );
    }
  }

  String _randomSuffix() {
    return '${DateTime.now().microsecond % 1000}';
  }
}

/// Provider for [CanvasAddItemOp].
final canvasAddItemOpProvider = Provider<CanvasAddItemOp>((ref) {
  final repo = ref.watch(workspaceRepoProvider);
  return CanvasAddItemOp(repo);
});

// ============================================================================
// api.canvas.updateViewport
// ============================================================================

/// Input for [CanvasUpdateViewportOp].
class CanvasUpdateViewportInput {
  final String workspaceId;
  final String tabId;
  final double panX;
  final double panY;
  final double zoom;

  const CanvasUpdateViewportInput({
    required this.workspaceId,
    required this.tabId,
    required this.panX,
    required this.panY,
    required this.zoom,
  });

  Map<String, Object?> toJson() => {
        'workspaceId': workspaceId,
        'tabId': tabId,
        'panX': panX,
        'panY': panY,
        'zoom': zoom,
      };
}

/// Output for [CanvasUpdateViewportOp].
class CanvasUpdateViewportOutput {
  final bool success;

  const CanvasUpdateViewportOutput({required this.success});

  Map<String, Object?> toJson() => {'success': success};
}

/// Updates the canvas viewport (pan/zoom).
///
/// This is a high-frequency operation that should be debounced by the caller.
///
/// Operation ID: api.canvas.updateViewport
class CanvasUpdateViewportOp
    extends LH2Operation<CanvasUpdateViewportInput, CanvasUpdateViewportOutput> {
  final WorkspaceRepository _repo;

  CanvasUpdateViewportOp(this._repo);

  @override
  String get operationId => 'api.canvas.updateViewport';

  @override
  Future<LH2OpResult<CanvasUpdateViewportOutput>> execute(
    CanvasUpdateViewportInput input,
  ) async {
    try {
      // Validate zoom bounds
      const minZoom = 0.1;
      const maxZoom = 5.0;
      final clampedZoom = input.zoom.clamp(minZoom, maxZoom);

      // Get current tab to preserve existing controller data
      final currentTab = await _repo.getTab(input.workspaceId, input.tabId);

      // Merge viewport update into existing controller
      final updatedController = Map<String, Object?>.from(currentTab.controller);
      updatedController['viewport'] = {
        'panX': input.panX,
        'panY': input.panY,
        'zoom': clampedZoom,
      };

      await _repo.updateTab(
        input.workspaceId,
        input.tabId,
        WorkspaceTabPatch(controller: updatedController),
      );

      return LH2OpResult.ok(const CanvasUpdateViewportOutput(success: true));
    } catch (e) {
      // Non-fatal: viewport updates can fail silently
      return LH2OpResult.error(
        createError(
          errorCode: LH2ErrorCodes.databaseError,
          message: 'Failed to update viewport: ${e.toString()}',
          payload: input.toJson(),
          cause: e,
          isFatal: false,
        ),
      );
    }
  }
}

/// Provider for [CanvasUpdateViewportOp].
final canvasUpdateViewportOpProvider = Provider<CanvasUpdateViewportOp>((ref) {
  final repo = ref.watch(workspaceRepoProvider);
  return CanvasUpdateViewportOp(repo);
});

// ============================================================================
// api.canvas.addLink
// ============================================================================

/// Input for [CanvasAddLinkOp].
class CanvasAddLinkInput {
  final String workspaceId;
  final String tabId;
  final String fromItemId;
  final String fromPortId;
  final String toItemId;
  final String toPortId;
  final String relationType;

  const CanvasAddLinkInput({
    required this.workspaceId,
    required this.tabId,
    required this.fromItemId,
    required this.fromPortId,
    required this.toItemId,
    required this.toPortId,
    required this.relationType,
  });

  Map<String, Object?> toJson() => {
        'workspaceId': workspaceId,
        'tabId': tabId,
        'fromItemId': fromItemId,
        'fromPortId': fromPortId,
        'toItemId': toItemId,
        'toPortId': toPortId,
        'relationType': relationType,
      };
}

/// Output for [CanvasAddLinkOp].
class CanvasAddLinkOutput {
  final String linkId;

  const CanvasAddLinkOutput({required this.linkId});

  Map<String, Object?> toJson() => {'linkId': linkId};
}

/// Adds a new link between canvas items.
///
/// Operation ID: api.canvas.addLink
class CanvasAddLinkOp
    extends LH2Operation<CanvasAddLinkInput, CanvasAddLinkOutput> {
  final WorkspaceRepository _repo;

  CanvasAddLinkOp(this._repo);

  @override
  String get operationId => 'api.canvas.addLink';

  @override
  Future<LH2OpResult<CanvasAddLinkOutput>> execute(
    CanvasAddLinkInput input,
  ) async {
    try {
      if (input.workspaceId.isEmpty || input.tabId.isEmpty) {
        return LH2OpResult.error(
          createError(
            errorCode: LH2ErrorCodes.invalidInput,
            message: 'workspaceId and tabId are required',
            payload: input.toJson(),
            isFatal: false,
          ),
        );
      }

      final linkId = 'link_${DateTime.now().millisecondsSinceEpoch}';
      final linkData = {
        'linkId': linkId,
        'fromItemId': input.fromItemId,
        'fromPortId': input.fromPortId,
        'toItemId': input.toItemId,
        'toPortId': input.toPortId,
        'relationType': input.relationType,
      };

      final currentTab = await _repo.getTab(input.workspaceId, input.tabId);
      final updatedLinks = Map<String, Object?>.from(currentTab.links);
      updatedLinks[linkId] = linkData;

      await _repo.updateTab(
        input.workspaceId,
        input.tabId,
        WorkspaceTabPatch(links: updatedLinks),
      );

      return LH2OpResult.ok(CanvasAddLinkOutput(linkId: linkId));
    } catch (e) {
      return LH2OpResult.error(
        createError(
          errorCode: LH2ErrorCodes.databaseError,
          message: 'Failed to add link: ${e.toString()}',
          payload: input.toJson(),
          cause: e,
          isFatal: true,
        ),
      );
    }
  }
}

/// Provider for [CanvasAddLinkOp].
final canvasAddLinkOpProvider = Provider<CanvasAddLinkOp>((ref) {
  final repo = ref.watch(workspaceRepoProvider);
  return CanvasAddLinkOp(repo);
});

// ============================================================================
// api.canvas.deleteLink
// ============================================================================

/// Input for [CanvasDeleteLinkOp].
class CanvasDeleteLinkInput {
  final String workspaceId;
  final String tabId;
  final String linkId;

  const CanvasDeleteLinkInput({
    required this.workspaceId,
    required this.tabId,
    required this.linkId,
  });

  Map<String, Object?> toJson() => {
        'workspaceId': workspaceId,
        'tabId': tabId,
        'linkId': linkId,
      };
}

/// Output for [CanvasDeleteLinkOp].
class CanvasDeleteLinkOutput {
  final bool success;

  const CanvasDeleteLinkOutput({required this.success});

  Map<String, Object?> toJson() => {'success': success};
}

/// Deletes a link from the canvas.
///
/// Operation ID: api.canvas.deleteLink
class CanvasDeleteLinkOp
    extends LH2Operation<CanvasDeleteLinkInput, CanvasDeleteLinkOutput> {
  final WorkspaceRepository _repo;

  CanvasDeleteLinkOp(this._repo);

  @override
  String get operationId => 'api.canvas.deleteLink';

  @override
  Future<LH2OpResult<CanvasDeleteLinkOutput>> execute(
    CanvasDeleteLinkInput input,
  ) async {
    try {
      if (input.workspaceId.isEmpty || input.tabId.isEmpty || input.linkId.isEmpty) {
        return LH2OpResult.error(
          createError(
            errorCode: LH2ErrorCodes.invalidInput,
            message: 'workspaceId, tabId, and linkId are required',
            payload: input.toJson(),
            isFatal: false,
          ),
        );
      }

      final currentTab = await _repo.getTab(input.workspaceId, input.tabId);
      final updatedLinks = Map<String, Object?>.from(currentTab.links);
      updatedLinks.remove(input.linkId);

      await _repo.updateTab(
        input.workspaceId,
        input.tabId,
        WorkspaceTabPatch(links: updatedLinks),
      );

      return LH2OpResult.ok(const CanvasDeleteLinkOutput(success: true));
    } catch (e) {
      return LH2OpResult.error(
        createError(
          errorCode: LH2ErrorCodes.databaseError,
          message: 'Failed to delete link: ${e.toString()}',
          payload: input.toJson(),
          cause: e,
          isFatal: true,
        ),
      );
    }
  }
}

/// Provider for [CanvasDeleteLinkOp].
final canvasDeleteLinkOpProvider = Provider<CanvasDeleteLinkOp>((ref) {
  final repo = ref.watch(workspaceRepoProvider);
  return CanvasDeleteLinkOp(repo);
});

// ============================================================================
// api.canvas.removeItems
// ============================================================================

/// Input for [CanvasRemoveItemsOp].
class CanvasRemoveItemsInput {
  final String workspaceId;
  final String tabId;
  final List<String> itemIds;

  const CanvasRemoveItemsInput({
    required this.workspaceId,
    required this.tabId,
    required this.itemIds,
  });

  Map<String, Object?> toJson() => {
        'workspaceId': workspaceId,
        'tabId': tabId,
        'itemIds': itemIds,
      };
}

/// Output for [CanvasRemoveItemsOp].
class CanvasRemoveItemsOutput {
  final bool success;

  const CanvasRemoveItemsOutput({required this.success});

  Map<String, Object?> toJson() => {'success': success};
}

/// Removes items from the canvas.
///
/// Operation ID: api.canvas.removeItems
class CanvasRemoveItemsOp
    extends LH2Operation<CanvasRemoveItemsInput, CanvasRemoveItemsOutput> {
  final WorkspaceRepository _repo;

  CanvasRemoveItemsOp(this._repo);

  @override
  String get operationId => 'api.canvas.removeItems';

  @override
  Future<LH2OpResult<CanvasRemoveItemsOutput>> execute(
    CanvasRemoveItemsInput input,
  ) async {
    try {
      if (input.workspaceId.isEmpty || input.tabId.isEmpty) {
        return LH2OpResult.error(
          createError(
            errorCode: LH2ErrorCodes.invalidInput,
            message: 'workspaceId and tabId are required',
            payload: input.toJson(),
            isFatal: false,
          ),
        );
      }

      // Get current tab to filter items
      final currentTab = await _repo.getTab(input.workspaceId, input.tabId);

      // Filter out removed items
      final updatedItems = Map<String, Object?>.from(currentTab.items);
      for (final itemId in input.itemIds) {
        updatedItems.remove(itemId);
      }

      await _repo.updateTab(
        input.workspaceId,
        input.tabId,
        WorkspaceTabPatch(items: updatedItems),
      );

      return LH2OpResult.ok(const CanvasRemoveItemsOutput(success: true));
    } catch (e) {
      return LH2OpResult.error(
        createError(
          errorCode: LH2ErrorCodes.databaseError,
          message: 'Failed to remove canvas items: ${e.toString()}',
          payload: input.toJson(),
          cause: e,
          isFatal: true,
        ),
      );
    }
  }
}

/// Provider for [CanvasRemoveItemsOp].
final canvasRemoveItemsOpProvider = Provider<CanvasRemoveItemsOp>((ref) {
  final repo = ref.watch(workspaceRepoProvider);
  return CanvasRemoveItemsOp(repo);
});
