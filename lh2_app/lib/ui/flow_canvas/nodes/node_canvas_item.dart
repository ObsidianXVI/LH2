import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_app/app/providers.dart';
import 'package:lh2_app/domain/models/node_template.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';
import 'package:lh2_app/ui/flow_canvas/node_renderer_registry.dart';
import 'package:lh2_app/ui/flow_canvas/node_templates_default.dart';
import 'package:lh2_stub/lh2_stub.dart';

class NodeCanvasItem extends ConsumerWidget {
  final String itemId;
  final CanvasItem item;
  final bool isSelected;
  final bool isHighlighted;

  const NodeCanvasItem({
    super.key,
    required this.itemId,
    required this.item,
    this.isSelected = false,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final objectTypeStr = item.objectType;
    final objectId = item.objectId;

    if (objectTypeStr == null) {
      return _buildError('Missing object type');
    }

    final objectType = ObjectType.values.byName(objectTypeStr);
    final templateId = item.config?['templateId'] as String?;

    // Find the template
    final template = _findTemplate(objectType, templateId);

    if (objectId == null) {
      // If objectId is missing, it's a new node being configured.
      // Show a placeholder object so the template design is visible.
      final placeholder = _createPlaceholderObject(objectType);
      return nodeRendererRegistry.build(placeholder, template, item,
          isSelected: isSelected, isHighlighted: isHighlighted);
    }

    // Fetch the object based on its type
    final objectAsync = ref.watch(objectProvider((objectType, objectId)));

    return objectAsync.when(
      data: (object) {
        if (object == null) {
          // Fallback to placeholder if object not found (e.g. still being created)
          final placeholder = _createPlaceholderObject(objectType);
          return nodeRendererRegistry.build(placeholder, template, item,
              isSelected: isSelected, isHighlighted: isHighlighted);
        }
        return nodeRendererRegistry.build(object, template, item,
            isSelected: isSelected, isHighlighted: isHighlighted);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => _buildError('Error: $err'),
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

  NodeTemplate _findTemplate(ObjectType objectType, String? templateId) {
    if (templateId != null) {
      final template = DefaultNodeTemplates.templates.firstWhere(
        (t) => t.id == templateId,
        orElse: () => DefaultNodeTemplates.templates.firstWhere(
          (t) => t.objectType == objectType,
          orElse: () => DefaultNodeTemplates.templates.first,
        ),
      );
      return template;
    }

    // Default to the first template of the correct type
    return DefaultNodeTemplates.templates.firstWhere(
      (t) => t.objectType == objectType,
      orElse: () => DefaultNodeTemplates.templates.first,
    );
  }

  Widget _buildError(String message) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.red.withOpacity(0.1),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.red, fontSize: 10),
        ),
      ),
    );
  }
}
