import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_app/domain/notifiers/crosshair_mode_controller.dart';
import 'package:lh2_app/ui/flow_canvas/canvas_provider.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';
import 'package:lh2_app/ui/theme/tokens.dart';
import 'package:lh2_app/app/theme.dart';
import 'package:lh2_app/ui/node_form_overlay.dart';
import 'package:lh2_stub/lh2_stub.dart';
import 'package:lh2_app/domain/operations/objects.dart';
import 'package:lh2_app/domain/operations/core.dart';

/// Overlay for crosshair mode side panel.
class CrosshairOverlay extends ConsumerWidget {
  const CrosshairOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use select to only rebuild on specific state changes, not every cursor movement
    final enabled = ref.watch(crosshairModeControllerProvider.select((s) => s.enabled));
    final hoveredItemId = ref.watch(crosshairModeControllerProvider.select((s) => s.hoveredItemId));
    final lastHoveredItemId = ref.watch(crosshairModeControllerProvider.select((s) => s.lastHoveredItemId));
    final linkDraft = ref.watch(crosshairModeControllerProvider.select((s) => s.linkDraft));
    
    final canvasController = ref.watch(activeCanvasControllerProvider);

    if (!enabled) {
      return const SizedBox.shrink();
    }

    final effectiveHoveredItemId = hoveredItemId ?? lastHoveredItemId;
    final hoveredItem = canvasController?.items[effectiveHoveredItemId];

    return Positioned(
      right: 16,
      top: 16,
      child: MouseRegion(
        onEnter: (_) {
          // Use read (not watch) to avoid triggering rebuilds
          ref.read(crosshairModeControllerProvider.notifier).setPanelHovered(true);
        },
        onExit: (_) {
          // Use read (not watch) to avoid triggering rebuilds
          ref.read(crosshairModeControllerProvider.notifier).setPanelHovered(false);
        },
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          color: LH2Colors.panel,
          child: Container(
            width: 300,
            constraints: const BoxConstraints(maxHeight: 500),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: LH2Colors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Crosshair Mode',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => ref
                          .read(crosshairModeControllerProvider.notifier)
                          .setEnabled(false),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                if (hoveredItem == null)
                  const Text('No item under cursor',
                      style: TextStyle(color: Colors.grey))
                else ...[
                  _CrosshairItemContent(
                    canvasItem: hoveredItem,
                    objectType: _parseObjectType(
                      hoveredItem.objectType ?? hoveredItem.itemType,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Position: (${hoveredItem.worldRect.left.toStringAsFixed(0)}, ${hoveredItem.worldRect.top.toStringAsFixed(0)})',
                      style: LH2Theme.body.copyWith(
                          fontSize: 10, color: LH2Colors.textSecondary)),
                  Text(
                      'Size: ${hoveredItem.worldRect.width.toStringAsFixed(0)} x ${hoveredItem.worldRect.height.toStringAsFixed(0)}',
                      style: LH2Theme.body.copyWith(
                          fontSize: 10, color: LH2Colors.textSecondary)),
                ],
                if (linkDraft != null) ...[
                  const SizedBox(height: 16),
                  const Text('Link Draft:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                      'Start: ${linkDraft['startItemId'] ?? 'unknown'}'),
                  Text(
                      'Type: ${linkDraft['linkType'] ?? 'default'}'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  ObjectType _parseObjectType(String name) {
    try {
      return ObjectType.values.byName(name);
    } catch (_) {
      // Fallback for legacy/generic nodes
      return ObjectType.project;
    }
  }
}

class _CrosshairItemContent extends ConsumerWidget {
  final CanvasItem canvasItem;
  final ObjectType objectType;

  const _CrosshairItemContent({
    required this.canvasItem,
    required this.objectType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final getOp = ref.watch(objectsGetOpProvider);

    final objectId = canvasItem.objectId;

    // If we don't have an objectId yet (common right after creating a node),
    // render a placeholder form instead of fetching.
    if (objectId == null || objectId.isEmpty) {
      return NodeFormOverlay(
        object: _createPlaceholderObject(objectType),
        objectId: null,
        canvasItemId: canvasItem.itemId,
        isEditable: true,
      );
    }

    return FutureBuilder<LH2OpResult<ObjectsGetOutput>>(
      future: getOp
          .execute(ObjectsGetInput(objectId: objectId, objectType: objectType)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || snapshot.data?.ok == false) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
                'Error loading object: ${snapshot.error ?? snapshot.data?.error?.message}',
                style: LH2Theme.body.copyWith(color: LH2Colors.dangerRed)),
          );
        }

        final object = snapshot.data!.value!.object;

        return NodeFormOverlay(
          object: object,
          objectId: objectId,
          canvasItemId: canvasItem.itemId,
          isEditable: true, // Allow editing from crosshair panel
        );
      },
    );
  }

  LH2Object _createPlaceholderObject(ObjectType type) {
    switch (type) {
      case ObjectType.project:
        return const Project(
          name: 'New Project',
          deliverablesIds: [],
          nonDeliverableTasksIds: [],
        );
      case ObjectType.task:
        return const Task(
          name: 'New Task',
          sessionsIds: [],
          taskStatus: TaskStatus.draft,
          outboundDependenciesIds: [],
        );
      case ObjectType.deliverable:
        return Deliverable(
          name: 'New Deliverable',
          tasksIds: [],
          deadlineTs: DateTime.now().millisecondsSinceEpoch,
        );
      case ObjectType.session:
        return Session(
          description: 'New Session',
          scheduledTs: DateTime.now().millisecondsSinceEpoch,
          contextRequirement: const ContextRequirement(
            focusLevel: 0.5,
            contiguousMinutesNeeded: 30,
            resourceTags: {},
          ),
        );
      case ObjectType.event:
        return Event(
          name: 'New Event',
          description: '',
          calendar: 'default',
          startTs: DateTime.now().millisecondsSinceEpoch,
          endTs: DateTime.now().millisecondsSinceEpoch + 3600000,
          allDay: false,
          actualContext: const ActualContext(
            focusLevel: 0.5,
            contiguousMinutesAvailable: 60,
            resourceTags: {},
          ),
        );
      case ObjectType.contextRequirement:
        return const ContextRequirement(
          focusLevel: 0.5,
          contiguousMinutesNeeded: 30,
          resourceTags: {},
        );
      case ObjectType.actualContext:
        return const ActualContext(
          focusLevel: 0.5,
          contiguousMinutesAvailable: 60,
          resourceTags: {},
        );
      case ObjectType.projectGroup:
        return const ProjectGroup(
          name: 'New Group',
          projectsIds: [],
        );
    }
  }
}
