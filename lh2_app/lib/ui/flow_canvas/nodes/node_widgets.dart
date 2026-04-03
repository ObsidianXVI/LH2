import 'package:flutter/material.dart';
import 'package:lh2_stub/lh2_stub.dart';
import 'package:lh2_app/domain/models/node_template.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';
import 'package:lh2_app/ui/theme/tokens.dart';

/// Base widget for all node types with common styling and behavior
class BaseNodeWidget extends StatelessWidget {
  final LH2Object object;
  final NodeTemplate template;
  final CanvasItem item;
  final Widget child;
  final bool isSelected;
  final bool isHighlighted;

  const BaseNodeWidget({
    super.key,
    required this.object,
    required this.template,
    required this.item,
    required this.child,
    this.isSelected = false,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final spec = template.renderSpec;
    final style = spec['style'] as Map<String, dynamic>? ?? {};

    var backgroundColor =
        _parseColor(style['backgroundColor']) ?? LH2Colors.panel;
    var borderColor = _parseColor(style['borderColor']) ?? LH2Colors.border;
    final textColor = _parseColor(style['textColor']) ?? LH2Colors.textPrimary;

    final size = spec['size'] as Map<String, dynamic>? ?? {};
    final width = (size['width'] as num?)?.toDouble();
    final height = (size['height'] as num?)?.toDouble();

    if (item.disabledByScenario) {
      backgroundColor = backgroundColor.withOpacity(0.5);
    }

    if (isHighlighted) {
      borderColor = LH2Colors.selectionBlue;
    } else if (isSelected) {
      borderColor = LH2Colors.selectionBlue;
    }

    final borderWidth = isHighlighted ? 3.0 : (isSelected ? 2.0 : 1.0);

    return Container(
      width: width,
      height: height,
      foregroundDecoration: item.disabledByScenario
          ? BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            )
          : null,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: item.disabledByScenario ? Colors.grey : borderColor,
          width: borderWidth,
        ),
        borderRadius: BorderRadius.circular(10), // Figma shows 10px radius
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: LH2Colors.selectionBlue.withOpacity(0.12),
                  blurRadius: 8.0,
                )
              ]
            : null,
      ),
      child: IgnorePointer(
        ignoring: item.disabledByScenario,
        child: Opacity(
          opacity: item.disabledByScenario ? 0.5 : 1.0,
          child: DefaultTextStyle(
            style: TextStyle(
              color: textColor,
              fontFamily: 'Menlo',
              fontSize: 12,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Color? _parseColor(dynamic value) {
    if (value == null) return null;
    if (value is int) return Color(value);
    if (value is String) {
      if (value.startsWith('#')) {
        final hex = value.substring(1);
        if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
        if (hex.length == 8) return Color(int.parse(hex, radix: 16));
      }
    }
    return null;
  }
}

/// Generic node renderer for fallback cases
class GenericNodeRenderer extends StatelessWidget {
  final LH2Object object;
  final NodeTemplate template;
  final CanvasItem item;
  final bool isSelected;
  final bool isHighlighted;

  const GenericNodeRenderer({
    super.key,
    required this.object,
    required this.template,
    required this.item,
    this.isSelected = false,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final spec = template.renderSpec;
    final header = spec['header'] as Map<String, dynamic>? ?? {};
    final showTitle = header['showTitle'] as bool? ?? true;
    final bodyFields = spec['bodyFields'] as List<dynamic>? ?? [];

    return BaseNodeWidget(
      object: object,
      template: template,
      item: item,
      isSelected: isSelected,
      isHighlighted: isHighlighted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTitle)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: LH2Colors.border)),
              ),
              child: Text(
                _getDisplayName(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20, // Figma shows 20px for titles
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: bodyFields.map((field) {
                  final value = _getFieldValue(field.toString());
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('$field: $value'),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayName() {
    final json = object.toJson();
    return (json['name'] ?? json['description'] ?? object.type.name).toString();
  }

  String _getFieldValue(String field) {
    final json = object.toJson();
    final value = json[field];
    if (value == null) return 'N/A';
    return value.toString();
  }
}

/// Project node renderer
class ProjectNodeRenderer extends StatelessWidget {
  final Project project;
  final NodeTemplate template;
  final CanvasItem item;
  final bool isSelected;
  final bool isHighlighted;

  const ProjectNodeRenderer({
    super.key,
    required this.project,
    required this.template,
    required this.item,
    this.isSelected = false,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final spec = template.renderSpec;
    final header = spec['header'] as Map<String, dynamic>? ?? {};
    final showTitle = header['showTitle'] as bool? ?? true;

    return BaseNodeWidget(
      object: project,
      template: template,
      item: item,
      isSelected: isSelected,
      isHighlighted: isHighlighted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTitle)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: LH2Colors.border)),
              ),
              child: Text(
                project.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Deliverables', project.deliverablesIds.length.toString()),
                  _buildInfoRow('Tasks', project.nonDeliverableTasksIds.length.toString()),
                  const SizedBox(height: 8),
                  _buildProgressIndicator(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: LH2Colors.textSecondary)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    // Simple progress indicator - can be enhanced with actual progress calculation
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: LH2Colors.panel.withOpacity(0.5),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          const Text('Progress: '),
          const Spacer(),
          Text('8/12', style: const TextStyle(color: LH2Colors.accentBlue)),
        ],
      ),
    );
  }
}

/// Task node renderer
class TaskNodeRenderer extends StatelessWidget {
  final Task task;
  final NodeTemplate template;
  final CanvasItem item;
  final bool isSelected;
  final bool isHighlighted;

  const TaskNodeRenderer({
    super.key,
    required this.task,
    required this.template,
    required this.item,
    this.isSelected = false,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final spec = template.renderSpec;
    final header = spec['header'] as Map<String, dynamic>? ?? {};
    final showTitle = header['showTitle'] as bool? ?? true;

    return BaseNodeWidget(
      object: task,
      template: template,
      item: item,
      isSelected: isSelected,
      isHighlighted: isHighlighted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTitle)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: LH2Colors.border)),
              ),
              child: Text(
                task.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Status', _getStatusText()),
                  _buildInfoRow('Sessions', task.sessionsIds.length.toString()),
                  const SizedBox(height: 8),
                  _buildStatusIndicator(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: LH2Colors.textSecondary)),
          Text(value),
        ],
      ),
    );
  }

  String _getStatusText() {
    switch (task.taskStatus) {
      case TaskStatus.draft:
        return 'Draft';
      case TaskStatus.scheduled:
        return 'Scheduled';
      case TaskStatus.underway:
        return 'Underway';
      case TaskStatus.incomplete:
        return 'Incomplete';
      case TaskStatus.done:
        return 'Done';
      case TaskStatus.adminAttentionNeeded:
        return 'Attention Needed';
    }
  }

  Widget _buildStatusIndicator() {
    Color statusColor;
    switch (task.taskStatus) {
      case TaskStatus.done:
        statusColor = LH2Colors.successGreen;
        break;
      case TaskStatus.underway:
        statusColor = LH2Colors.accentBlue;
        break;
      case TaskStatus.scheduled:
        statusColor = LH2Colors.warningOrange;
        break;
      default:
        statusColor = LH2Colors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('Status: '),
          const Spacer(),
          Text(_getStatusText(), style: TextStyle(color: statusColor)),
        ],
      ),
    );
  }
}

/// Deliverable node renderer
class DeliverableNodeRenderer extends StatelessWidget {
  final Deliverable deliverable;
  final NodeTemplate template;
  final CanvasItem item;
  final bool isSelected;
  final bool isHighlighted;

  const DeliverableNodeRenderer({
    super.key,
    required this.deliverable,
    required this.template,
    required this.item,
    this.isSelected = false,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final spec = template.renderSpec;
    final header = spec['header'] as Map<String, dynamic>? ?? {};
    final showTitle = header['showTitle'] as bool? ?? true;

    return BaseNodeWidget(
      object: deliverable,
      template: template,
      item: item,
      isSelected: isSelected,
      isHighlighted: isHighlighted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTitle)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: LH2Colors.border)),
              ),
              child: Text(
                deliverable.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Tasks', deliverable.tasksIds.length.toString()),
                  _buildInfoRow('Deadline', _formatDeadline()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: LH2Colors.textSecondary)),
          Text(value),
        ],
      ),
    );
  }

  String _formatDeadline() {
    final date = DateTime.fromMillisecondsSinceEpoch(deliverable.deadlineTs);
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Session node renderer
class SessionNodeRenderer extends StatelessWidget {
  final Session session;
  final NodeTemplate template;
  final CanvasItem item;
  final bool isSelected;
  final bool isHighlighted;

  const SessionNodeRenderer({
    super.key,
    required this.session,
    required this.template,
    required this.item,
    this.isSelected = false,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final spec = template.renderSpec;
    final header = spec['header'] as Map<String, dynamic>? ?? {};
    final showTitle = header['showTitle'] as bool? ?? true;

    return BaseNodeWidget(
      object: session,
      template: template,
      item: item,
      isSelected: isSelected,
      isHighlighted: isHighlighted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTitle)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: LH2Colors.border)),
              ),
              child: Text(
                session.description,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Scheduled', _formatScheduledTime()),
                  _buildInfoRow('Focus Level', '${session.contextRequirement.focusLevel}'),
                  _buildInfoRow('Duration', '${session.contextRequirement.contiguousMinutesNeeded} min'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: LH2Colors.textSecondary)),
          Text(value),
        ],
      ),
    );
  }

  String _formatScheduledTime() {
    final date = DateTime.fromMillisecondsSinceEpoch(session.scheduledTs);
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Event node renderer
class EventNodeRenderer extends StatelessWidget {
  final Event event;
  final NodeTemplate template;
  final CanvasItem item;
  final bool isSelected;
  final bool isHighlighted;

  const EventNodeRenderer({
    super.key,
    required this.event,
    required this.template,
    required this.item,
    this.isSelected = false,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final spec = template.renderSpec;
    final header = spec['header'] as Map<String, dynamic>? ?? {};
    final showTitle = header['showTitle'] as bool? ?? true;

    return BaseNodeWidget(
      object: event,
      template: template,
      item: item,
      isSelected: isSelected,
      isHighlighted: isHighlighted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTitle)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: LH2Colors.border)),
              ),
              child: Text(
                event.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          // Events are typically more compact, so less body content
        ],
      ),
    );
  }
}

/// Context Requirement node renderer
class ContextRequirementNodeRenderer extends StatelessWidget {
  final ContextRequirement contextRequirement;
  final NodeTemplate template;
  final CanvasItem item;
  final bool isSelected;
  final bool isHighlighted;

  const ContextRequirementNodeRenderer({
    super.key,
    required this.contextRequirement,
    required this.template,
    required this.item,
    this.isSelected = false,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final spec = template.renderSpec;
    final header = spec['header'] as Map<String, dynamic>? ?? {};
    final showTitle = header['showTitle'] as bool? ?? true;

    return BaseNodeWidget(
      object: contextRequirement,
      template: template,
      item: item,
      isSelected: isSelected,
      isHighlighted: isHighlighted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTitle)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: LH2Colors.border)),
              ),
              child: const Text(
                'Context Requirement',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Focus Level', '${contextRequirement.focusLevel}'),
                  _buildInfoRow('Duration Needed', '${contextRequirement.contiguousMinutesNeeded} min'),
                  const SizedBox(height: 8),
                  _buildResourceTags(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: LH2Colors.textSecondary)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildResourceTags() {
    if (contextRequirement.resourceTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Resource Tags:', style: TextStyle(color: LH2Colors.textSecondary)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: contextRequirement.resourceTags.entries.map((entry) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: LH2Colors.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: LH2Colors.accentBlue.withOpacity(0.3)),
              ),
              child: Text('${entry.key}: ${entry.value}'),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Actual Context node renderer
class ActualContextNodeRenderer extends StatelessWidget {
  final ActualContext actualContext;
  final NodeTemplate template;
  final CanvasItem item;
  final bool isSelected;
  final bool isHighlighted;

  const ActualContextNodeRenderer({
    super.key,
    required this.actualContext,
    required this.template,
    required this.item,
    this.isSelected = false,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final spec = template.renderSpec;
    final header = spec['header'] as Map<String, dynamic>? ?? {};
    final showTitle = header['showTitle'] as bool? ?? true;

    return BaseNodeWidget(
      object: actualContext,
      template: template,
      item: item,
      isSelected: isSelected,
      isHighlighted: isHighlighted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTitle)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: LH2Colors.border)),
              ),
              child: const Text(
                'Actual Context',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Focus Level', '${actualContext.focusLevel}'),
                  const SizedBox(height: 8),
                  _buildResourceTags(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: LH2Colors.textSecondary)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildResourceTags() {
    if (actualContext.resourceTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Resource Tags:', style: TextStyle(color: LH2Colors.textSecondary)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: actualContext.resourceTags.entries.map((entry) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: LH2Colors.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: LH2Colors.successGreen.withOpacity(0.3)),
              ),
              child: Text('${entry.key}: ${entry.value}'),
            );
          }).toList(),
        ),
      ],
    );
  }
}