import 'package:flutter/material.dart';
import 'package:lh2_stub/lh2_stub.dart';
import 'package:lh2_app/domain/models/node_template.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';
import 'package:lh2_app/ui/flow_canvas/nodes/node_widgets.dart';
import 'package:lh2_app/ui/theme/tokens.dart';

/// Lightweight dashed border painter (no external deps).
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;
  final double radius;

  const _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1,
    this.dashLength = 6,
    this.dashGap = 4,
    this.radius = 10,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final double next = (dist + dashLength).clamp(0, metric.length);
        canvas.drawPath(metric.extractPath(dist, next), paint);
        dist += dashLength + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.dashGap != dashGap ||
        oldDelegate.radius != radius;
  }
}

class _DashedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double radius;
  final double strokeWidth;

  const _DashedBorder({
    required this.child,
    required this.color,
    this.radius = 10,
    this.strokeWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color,
        radius: radius,
        strokeWidth: strokeWidth,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}

typedef NodeWidgetBuilder = Widget Function(
  LH2Object object,
  NodeTemplate template,
  CanvasItem item, {
  bool isSelected,
  bool isHighlighted,
});

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
    CanvasItem item, {
    bool isSelected = false,
    bool isHighlighted = false,
  }) {
    final builder = _builders[object.type];
    if (builder == null) {
      return GenericNodeRenderer(
        object: object,
        template: template,
        item: item,
        isSelected: isSelected,
        isHighlighted: isHighlighted,
      );
    }
    return builder(
      object,
      template,
      item,
      isSelected: isSelected,
      isHighlighted: isHighlighted,
    );
  }

  Widget _buildDeliverable(
      LH2Object object, NodeTemplate template, CanvasItem item,
      {bool isSelected = false, bool isHighlighted = false}) {
    // Deliverable styling notes (FEATURES.md §2.2.6):
    // - special placing of out-ports (we render a visual anchor; port hit areas
    //   are handled by the canvas view).
    // - can be nested within context-requirement nodes (render-only concern).
    return BaseNodeWidget(
      object: object,
      template: template,
      item: item,
      isSelected: isSelected,
      isHighlighted: isHighlighted,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 26, 10),
            child: Text(
              (object.toJson()['name'] ?? 'Deliverable').toString(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          // Visual out-port anchor (top-right), kept inside the node bounds.
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: LH2Colors.accentBlue.withOpacity(0.9),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSession(LH2Object object, NodeTemplate template, CanvasItem item,
      {bool isSelected = false, bool isHighlighted = false}) {
    final data = object.toJson();
    // NOTE: `projectColor` and `taskName` are currently stored on the object
    // JSON by upstream demo/data layers.
    final projectColor =
        data['projectColor'] as int? ?? LH2Colors.accentBlue.value;
    final Color color = Color(projectColor);
    return BaseNodeWidget(
      object: object,
      template: template,
      item: item,
      isSelected: isSelected,
      isHighlighted: isHighlighted,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (data['name'] ?? 'Session').toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            if (data['description'] != null)
              Text(
                (data['description'] ?? '').toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: color.withOpacity(0.9)),
              ),
            if (data['taskName'] != null)
              Text(
                'Task: ${data['taskName']}',
                style: const TextStyle(
                    fontSize: 10, color: LH2Colors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextRequirement(
      LH2Object object, NodeTemplate template, CanvasItem item,
      {bool isSelected = false, bool isHighlighted = false}) {
    final data = object.toJson();
    final contextColor = data['contextColor'] as int? ?? Colors.grey.value;
    final baseGrey = Colors.grey.shade700;
    final tint = Color(contextColor);
    final fill = Color.lerp(baseGrey, tint, 0.35)!.withOpacity(0.35);

    return BaseNodeWidget(
      object: object,
      template: template,
      item: item,
      isSelected: isSelected,
      isHighlighted: isHighlighted,
      child: _DashedBorder(
        color: baseGrey.withOpacity(0.85),
        child: Container(
          color: fill,
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (data['contextName'] ?? 'Context').toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: baseGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              // Visual-only conditional port indicator.
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: baseGrey.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'conditional',
                    style:
                        TextStyle(fontSize: 10, color: LH2Colors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEvent(LH2Object object, NodeTemplate template, CanvasItem item,
      {bool isSelected = false, bool isHighlighted = false}) {
    final data = object.toJson();
    final details =
        (data['details'] as String?) ?? (data['description'] as String?);
    final bool hasDetails = details != null && details.trim().isNotEmpty;
    return BaseNodeWidget(
      object: object,
      template: template,
      item: item,
      isSelected: isSelected,
      isHighlighted: isHighlighted,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (data['name'] ?? 'Event').toString(),
              maxLines: hasDetails ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
            if (hasDetails) ...[
              const SizedBox(height: 2),
              Text(
                details!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9,
                  color: LH2Colors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final calendarNodeRendererRegistry = CalendarNodeRendererRegistry();
