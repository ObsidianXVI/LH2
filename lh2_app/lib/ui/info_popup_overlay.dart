import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_app/domain/notifiers/info_popup_controller.dart';
import 'package:lh2_app/ui/theme/tokens.dart';
import 'package:lh2_app/app/theme.dart';
import 'package:lh2_app/domain/notifiers/crosshair_mode_controller.dart';
import 'package:lh2_app/ui/node_form_overlay.dart';
import 'package:lh2_stub/lh2_stub.dart';
import 'package:lh2_app/domain/operations/objects.dart';
import 'package:lh2_app/domain/operations/core.dart';
import 'package:lh2_app/ui/flow_canvas/canvas_provider.dart';

/// Overlay widget for the information popup.
class InfoPopupOverlay extends ConsumerWidget {
  const InfoPopupOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(infoPopupControllerProvider);
    final crosshairState = ref.watch(crosshairModeControllerProvider);

    // Close info popup when Crosshair Mode is enabled
    if (crosshairState.enabled && state.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(infoPopupControllerProvider.notifier).close();
      });
    }

    if (!state.isOpen || state.anchorScreenRect == null) {
      return const SizedBox.shrink();
    }

    // Basic positioning logic: place it to the right of the anchor
    final left = state.anchorScreenRect!.right + 8;
    final top = state.anchorScreenRect!.top;

    return Stack(
      children: [
        // Background overlay to catch clicks outside (Save on click outside)
        // Only show this in 'add' mode, not in 'view' (hover) mode.
        if (state.mode == InfoPopupMode.add)
          Positioned.fill(
            child: GestureDetector(
              onTap: () =>
                  ref.read(infoPopupControllerProvider.notifier).close(),
              child: Container(color: Colors.transparent),
            ),
          ),
        Positioned(
          left: left,
          top: top,
          child: MouseRegion(
            onEnter: (_) => ref
                .read(infoPopupControllerProvider.notifier)
                .setIsHovered(true),
            onExit: (_) => ref
                .read(infoPopupControllerProvider.notifier)
                .setIsHovered(false),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              color: LH2Colors.panel,
              child: Container(
                width: 300,
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
                        Expanded(
                          child: Text(
                            state.mode == InfoPopupMode.add
                                ? 'Configure New Node'
                                : 'Node Information',
                            style: LH2Theme.nodeTitle.copyWith(
                                fontSize: 12, color: LH2Colors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!crosshairState.enabled)
                          IconButton(
                            icon:
                                const Icon(Icons.visibility_outlined, size: 18),
                            onPressed: () => ref
                                .read(crosshairModeControllerProvider.notifier)
                                .setEnabled(true),
                          ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => ref
                              .read(infoPopupControllerProvider.notifier)
                              .close(),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    if (state.itemId != null && state.objectType != null)
                      _InfoPopupContent(
                        itemId: state.itemId!,
                        objectType: state.objectType!,
                        isEditable: true, // Always editable (add or view mode)
                        onClose: () => ref
                            .read(infoPopupControllerProvider.notifier)
                            .close(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoPopupContent extends ConsumerWidget {
  final String itemId;
  final ObjectType objectType;
  final bool isEditable;
  final VoidCallback onClose;

  const _InfoPopupContent({
    required this.itemId,
    required this.objectType,
    required this.isEditable,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final getOp = ref.watch(objectsGetOpProvider);
    final canvasController = ref.watch(activeCanvasControllerProvider);
    final canvasItem = canvasController?.items[itemId];
    final objectId = canvasItem?.objectId;

    // If the canvas item hasn't been assigned a Firestore objectId yet (common
    // right after creating a node), render a placeholder form instead of
    // attempting to load from Firestore.
    if (objectId == null || objectId.isEmpty) {
      return NodeFormOverlay(
        object: _createPlaceholderObject(objectType),
        objectId: null,
        canvasItemId: itemId,
        isEditable: isEditable,
        onSave: onClose,
      );
    }

    return FutureBuilder<LH2OpResult<ObjectsGetOutput>>(
      future: _fetchWithRetry(getOp, objectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.data == null) {
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
          canvasItemId: itemId,
          isEditable: isEditable,
          onSave: onClose,
        );
      },
    );
  }

  Future<LH2OpResult<ObjectsGetOutput>> _fetchWithRetry(
    ObjectsGetOp getOp,
    String objectId,
  ) async {
    // Initial fetch
    var result = await getOp
        .execute(ObjectsGetInput(objectId: objectId, objectType: objectType));

    // If it fails with not found, retry a few times for newly created nodes
    // to allow Firestore propagation.
    int retries = 3;
    while (!result.ok && retries > 0) {
      await Future.delayed(const Duration(milliseconds: 500));
      result = await getOp
          .execute(ObjectsGetInput(objectId: objectId, objectType: objectType));
      retries--;
    }
    return result;
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
