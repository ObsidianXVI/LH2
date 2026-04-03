import 'package:lh2_stub/lh2_stub.dart';
import 'package:lh2_app/domain/models/node_template.dart';

/// Default node templates based on Figma designs
/// These templates define the styling, layout, and port configuration for each node type
class DefaultNodeTemplates {
  static List<NodeTemplate> get templates => [
        // Project Node Template
        NodeTemplate(
          schemaVersion: 1,
          id: 'project-default',
          objectType: ObjectType.project,
          name: 'Default Project',
          renderSpec: {
            'header': {
              'showTitle': true,
            },
            'bodyFields': ['name', 'deliverablesIds', 'nonDeliverableTasksIds'],
            'ports': {
              'in': [
                {
                  'portId': 'port-in',
                  'direction': 'in',
                  'portType': 'dependency',
                },
              ],
              'out': [
                {
                  'portId': 'port-out',
                  'direction': 'out',
                  'portType': 'dependency',
                },
              ],
            },
            'size': {
              'width': 389,
              'height': 133,
            },
            'style': {
              'backgroundColor': 0xFF160B2E, // panel color from Figma
              'borderColor': 0xFF8A38F5, // purple accent
              'textColor': 0xFF7652B0, // primary text color
            },
          },
        ),

        // Task Node Template
        NodeTemplate(
          schemaVersion: 1,
          id: 'task-default',
          objectType: ObjectType.task,
          name: 'Default Task',
          renderSpec: {
            'header': {
              'showTitle': true,
            },
            'bodyFields': ['name', 'taskStatus', 'sessionsIds'],
            'ports': {
              'in': [
                {
                  'portId': 'port-in',
                  'direction': 'in',
                  'portType': 'dependency',
                },
              ],
              'out': [
                {
                  'portId': 'port-out',
                  'direction': 'out',
                  'portType': 'dependency',
                },
              ],
            },
            'size': {
              'width': 389,
              'height': 133,
            },
            'style': {
              'backgroundColor': 0xFF160B2E,
              'borderColor': 0xFF3861F5, // blue accent
              'textColor': 0xFF7652B0,
            },
          },
        ),

        // Deliverable Node Template
        NodeTemplate(
          schemaVersion: 1,
          id: 'deliverable-default',
          objectType: ObjectType.deliverable,
          name: 'Default Deliverable',
          renderSpec: {
            'header': {
              'showTitle': true,
            },
            'bodyFields': ['name', 'deadlineTs', 'tasksIds'],
            'ports': {
              'in': [
                {
                  'portId': 'port-in',
                  'direction': 'in',
                  'portType': 'dependency',
                },
              ],
              'out': [
                {
                  'portId': 'port-out',
                  'direction': 'out',
                  'portType': 'dependency',
                },
              ],
            },
            'size': {
              'width': 389,
              'height': 133,
            },
            'style': {
              'backgroundColor': 0xFF160B2E,
              'borderColor': 0xFFF53838, // red accent
              'textColor': 0xFF7652B0,
            },
          },
        ),

        // Session Node Template
        NodeTemplate(
          schemaVersion: 1,
          id: 'session-default',
          objectType: ObjectType.session,
          name: 'Default Session',
          renderSpec: {
            'header': {
              'showTitle': true,
            },
            'bodyFields': ['description', 'scheduledTs'],
            'ports': {
              'in': [
                {
                  'portId': 'port-in',
                  'direction': 'in',
                  'portType': 'dependency',
                },
              ],
              'out': [
                {
                  'portId': 'port-out',
                  'direction': 'out',
                  'portType': 'dependency',
                },
              ],
            },
            'size': {
              'width': 389,
              'height': 133,
            },
            'style': {
              'backgroundColor': 0xFF160B2E,
              'borderColor': 0xFF38F5BF, // teal accent
              'textColor': 0xFF7652B0,
            },
          },
        ),

        // Event Node Template
        NodeTemplate(
          schemaVersion: 1,
          id: 'event-default',
          objectType: ObjectType.event,
          name: 'Default Event',
          renderSpec: {
            'header': {
              'showTitle': true,
            },
            'bodyFields': ['name'],
            'ports': {
              'in': [
                {
                  'portId': 'port-in',
                  'direction': 'in',
                  'portType': 'dependency',
                },
              ],
              'out': [
                {
                  'portId': 'port-out',
                  'direction': 'out',
                  'portType': 'dependency',
                },
              ],
            },
            'size': {
              'width': 389,
              'height': 80, // Smaller height for events
            },
            'style': {
              'backgroundColor': 0xFF2D165D, // Yellow tint for events
              'borderColor': 0xFFD8AD00, // yellow accent
              'textColor': 0xFFD8AD00,
            },
          },
        ),

        // Context Requirement Node Template
        NodeTemplate(
          schemaVersion: 1,
          id: 'context-requirement-default',
          objectType: ObjectType.contextRequirement,
          name: 'Default Context Requirement',
          renderSpec: {
            'header': {
              'showTitle': true,
            },
            'bodyFields': ['focusLevel', 'contiguousMinutesNeeded', 'resourceTags'],
            'ports': {
              'in': [
                {
                  'portId': 'port-in',
                  'direction': 'in',
                  'portType': 'dependency',
                },
              ],
              'out': [
                {
                  'portId': 'port-out',
                  'direction': 'out',
                  'portType': 'dependency',
                },
                {
                  'portId': 'port-conditional',
                  'direction': 'out',
                  'portType': 'conditional',
                },
              ],
            },
            'size': {
              'width': 752,
              'height': 704,
            },
            'style': {
              'backgroundColor': 0xFFB04343, // Semi-transparent red + grey
              'borderColor': 0xFF4C4C4C, // Grey dashed border
              'textColor': 0xFF4C4C4C,
            },
          },
        ),

        // Actual Context Node Template
        NodeTemplate(
          schemaVersion: 1,
          id: 'actual-context-default',
          objectType: ObjectType.actualContext,
          name: 'Default Actual Context',
          renderSpec: {
            'header': {
              'showTitle': true,
            },
            'bodyFields': ['focusLevel', 'resourceTags'],
            'ports': {
              'in': [
                {
                  'portId': 'port-in',
                  'direction': 'in',
                  'portType': 'dependency',
                },
              ],
              'out': [
                {
                  'portId': 'port-out',
                  'direction': 'out',
                  'portType': 'dependency',
                },
              ],
            },
            'size': {
              'width': 389,
              'height': 133,
            },
            'style': {
              'backgroundColor': 0xFF160B2E,
              'borderColor': 0xFF4C4C4C,
              'textColor': 0xFF7652B0,
            },
          },
        ),
      ];
}