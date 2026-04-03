import 'package:flutter/material.dart';
import 'package:lh2_stub/lh2_stub.dart';
import 'package:lh2_app/domain/models/node_template.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';
import 'package:lh2_app/ui/flow_canvas/nodes/node_widgets.dart';
import 'package:lh2_app/ui/theme/tokens.dart';

typedef NodeWidgetBuilder = Widget Function(
  LH2Object object,
  NodeTemplate template,
  CanvasItem item,
);

class CalendarNodeRendererRegistry {
  final Map<ObjectType, NodeWidgetBuilder> _builders = {};

  CalendarNodeRendererRegistry() {
    _registerDefaults();
  }

  void _registerDefaults() {
    register(ObjectType.deliverable, _buildDeliverable);
    register(ObjectType.session, _buildSession);
    register(ObjectType.contextRequirement, _buildContextRequirement);
    register(ObjectType.event, _buildEvent);
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
      return GenericNodeRenderer(object: object, template: template, item: item);
    }
    return builder(object, template, item);
  }

  Widget _buildDeliverable(LH2Object object, NodeTemplate template, CanvasItem item) {
    return BaseNodeWidget(
      object: object,
      template: template,
      item: item,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              (object.toJson()['name'] ?? 'Deliverable').toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          // Special out-port placement can be handled here if needed
        ],
      ),
    );
  }

  Widget _buildSession(LH2Object object, NodeTemplate template, CanvasItem item) {
    final data = object.toJson();
    final projectColor = data['projectColor'] as int? ?? LH2Colors.accentBlue.value;
    return BaseNodeWidget(
      object: object,
      template: template,
      item: item,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (data['name'] ?? 'Session').toString(),
              style: TextStyle(color: Color(projectColor), fontWeight: FontWeight.bold),
            ),
            if (data['taskName'] != null)
              Text(
                'Task: ${data['taskName']}',
                style: const TextStyle(fontSize: 10, color: LH2Colors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextRequirement(LH2Object object, NodeTemplate template, CanvasItem item) {
    final data = object.toJson();
    final contextColor = data['contextColor'] as int? ?? Colors.grey.value;
    return Container(
      decoration: BoxDecoration(
        color: Color.lerp(Colors.grey, Color(contextColor), 0.5)!.withOpacity(0.5),
        border: Border.all(color: Colors.grey, style: BorderStyle.solid), // Dashed border needs a custom painter or package, using solid for now
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          (data['contextName'] ?? 'Context').toString(),
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildEvent(LH2Object object, NodeTemplate template, CanvasItem item) {
    final data = object.toJson();
    final details = data['details'] as String?;
    return BaseNodeWidget(
      object: object,
      template: template,
      item: item,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (data['name'] ?? 'Event').toString(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
            if (details != null && details.isNotEmpty)
              Expanded(
                child: Text(
                  details,
                  style: const TextStyle(fontSize: 9, color: LH2Colors.textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

final calendarNodeRendererRegistry = CalendarNodeRendererRegistry();
