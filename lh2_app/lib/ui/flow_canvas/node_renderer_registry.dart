import 'package:flutter/material.dart';
import 'package:lh2_stub/lh2_stub.dart';
import 'package:lh2_app/domain/models/node_template.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';
import 'package:lh2_app/ui/flow_canvas/nodes/node_widgets.dart';

typedef NodeWidgetBuilder = Widget Function(
  LH2Object object,
  NodeTemplate template,
  CanvasItem item,
);

class NodeRendererRegistry {
  final Map<ObjectType, NodeWidgetBuilder> _builders = {};

  NodeRendererRegistry() {
    _registerDefaults();
  }

  void _registerDefaults() {
    for (final type in ObjectType.values) {
      if (type == ObjectType.projectGroup) continue;
      register(
        type,
        (object, template, item) => GenericNodeRenderer(
          object: object,
          template: template,
          item: item,
        ),
      );
    }
  }

  void register(ObjectType type, NodeWidgetBuilder builder) {
    _builders[type] = builder;
  }

  Widget build(
    LH2Object object,
    NodeTemplate template,
    CanvasItem item,
  ) {
    final builder = _builders[object.type];
    if (builder == null) {
      return Container(
        padding: const EdgeInsets.all(8),
        color: Colors.red.withOpacity(0.2),
        child: Text('No renderer for ${object.type.name}'),
      );
    }
    return builder(object, template, item);
  }
}

final nodeRendererRegistry = NodeRendererRegistry();
