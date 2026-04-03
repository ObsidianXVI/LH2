import 'package:flutter/material.dart';
import 'package:lh2_stub/lh2_stub.dart';
import 'package:lh2_app/domain/models/node_template.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';
import 'package:lh2_app/ui/flow_canvas/nodes/node_widgets.dart';

typedef NodeWidgetBuilder = Widget Function(
  LH2Object object,
  NodeTemplate template,
  CanvasItem item, {
  bool isSelected,
  bool isHighlighted,
});

class NodeRendererRegistry {
  final Map<ObjectType, NodeWidgetBuilder> _builders = {};

  NodeRendererRegistry() {
    _registerDefaults();
  }

  void _registerDefaults() {
    // Register specialized renderers for each object type
    register(ObjectType.project, (object, template, item,
        {bool isSelected = false, bool isHighlighted = false}) {
      return ProjectNodeRenderer(
        project: object as Project,
        template: template,
        item: item,
        isSelected: isSelected,
        isHighlighted: isHighlighted,
      );
    });

    register(ObjectType.task, (object, template, item,
        {bool isSelected = false, bool isHighlighted = false}) {
      return TaskNodeRenderer(
        task: object as Task,
        template: template,
        item: item,
        isSelected: isSelected,
        isHighlighted: isHighlighted,
      );
    });

    register(ObjectType.deliverable, (object, template, item,
        {bool isSelected = false, bool isHighlighted = false}) {
      return DeliverableNodeRenderer(
        deliverable: object as Deliverable,
        template: template,
        item: item,
        isSelected: isSelected,
        isHighlighted: isHighlighted,
      );
    });

    register(ObjectType.session, (object, template, item,
        {bool isSelected = false, bool isHighlighted = false}) {
      return SessionNodeRenderer(
        session: object as Session,
        template: template,
        item: item,
        isSelected: isSelected,
        isHighlighted: isHighlighted,
      );
    });

    register(ObjectType.event, (object, template, item,
        {bool isSelected = false, bool isHighlighted = false}) {
      return EventNodeRenderer(
        event: object as Event,
        template: template,
        item: item,
        isSelected: isSelected,
        isHighlighted: isHighlighted,
      );
    });

    register(ObjectType.contextRequirement, (object, template, item,
        {bool isSelected = false, bool isHighlighted = false}) {
      return ContextRequirementNodeRenderer(
        contextRequirement: object as ContextRequirement,
        template: template,
        item: item,
        isSelected: isSelected,
        isHighlighted: isHighlighted,
      );
    });

    register(ObjectType.actualContext, (object, template, item,
        {bool isSelected = false, bool isHighlighted = false}) {
      return ActualContextNodeRenderer(
        actualContext: object as ActualContext,
        template: template,
        item: item,
        isSelected: isSelected,
        isHighlighted: isHighlighted,
      );
    });

    // ProjectGroup is not directly renderable (meta-node)
    // Generic fallback for any unregistered types
    for (final type in ObjectType.values) {
      if (!_builders.containsKey(type)) {
        register(
          type,
          (object, template, item,
                  {bool isSelected = false, bool isHighlighted = false}) =>
              GenericNodeRenderer(
            object: object,
            template: template,
            item: item,
            isSelected: isSelected,
            isHighlighted: isHighlighted,
          ),
        );
      }
    }
  }

  void register(ObjectType type, NodeWidgetBuilder builder) {
    _builders[type] = builder;
  }

  Widget build(
    LH2Object object,
    NodeTemplate template,
    CanvasItem item, {
    bool isSelected = false,
    bool isHighlighted = false,
  }) {
    final builder = _builders[object.type];
    if (builder == null) {
      return Container(
        padding: const EdgeInsets.all(8),
        color: Colors.red.withOpacity(0.2),
        child: Text('No renderer for ${object.type.name}'),
      );
    }
    return builder(object, template, item,
        isSelected: isSelected, isHighlighted: isHighlighted);
  }
}

final nodeRendererRegistry = NodeRendererRegistry();
