import 'package:lh2_app/data/workspace_repository.dart';
import 'package:lh2_stub/lh2_stub.dart';

/// Demo node templates for testing the context menu
class DemoNodeTemplates {
  static List<NodeTemplate> get demoTemplates => [
    // Project templates
    NodeTemplate(
      schemaVersion: 1,
      id: 'project-basic',
      objectType: ObjectType.project,
      name: 'Basic Project',
      renderSpec: {
        'color': '#4CAF50',
        'icon': 'folder',
        'showProgress': true,
      },
    ),
    NodeTemplate(
      schemaVersion: 1,
      id: 'project-complex',
      objectType: ObjectType.project,
      name: 'Complex Project',
      renderSpec: {
        'color': '#2196F3',
        'icon': 'work',
        'showProgress': true,
        'showTeam': true,
      },
    ),
    
    // Task templates
    NodeTemplate(
      schemaVersion: 1,
      id: 'task-simple',
      objectType: ObjectType.task,
      name: 'Simple Task',
      renderSpec: {
        'color': '#FF9800',
        'icon': 'assignment',
        'showStatus': true,
      },
    ),
    NodeTemplate(
      schemaVersion: 1,
      id: 'task-detailed',
      objectType: ObjectType.task,
      name: 'Detailed Task',
      renderSpec: {
        'color': '#FF5722',
        'icon': 'assignment_turned_in',
        'showStatus': true,
        'showDependencies': true,
      },
    ),
    
    // Deliverable templates
    NodeTemplate(
      schemaVersion: 1,
      id: 'deliverable-milestone',
      objectType: ObjectType.deliverable,
      name: 'Milestone Deliverable',
      renderSpec: {
        'color': '#9C27B0',
        'icon': 'flag',
        'showDeadline': true,
      },
    ),
    
    // Session templates
    NodeTemplate(
      schemaVersion: 1,
      id: 'session-focus',
      objectType: ObjectType.session,
      name: 'Focus Session',
      renderSpec: {
        'color': '#00BCD4',
        'icon': 'timer',
        'showDuration': true,
      },
    ),
    
    // Event templates
    NodeTemplate(
      schemaVersion: 1,
      id: 'event-meeting',
      objectType: ObjectType.event,
      name: 'Meeting Event',
      renderSpec: {
        'color': '#E91E63',
        'icon': 'event',
        'showTime': true,
      },
    ),
    
    // Context Requirement templates
    NodeTemplate(
      schemaVersion: 1,
      id: 'context-deep-work',
      objectType: ObjectType.contextRequirement,
      name: 'Deep Work Context',
      renderSpec: {
        'color': '#795548',
        'icon': 'psychology',
        'showFocusLevel': true,
      },
    ),
    
    // Actual Context templates
    NodeTemplate(
      schemaVersion: 1,
      id: 'actual-context-current',
      objectType: ObjectType.actualContext,
      name: 'Current Context',
      renderSpec: {
        'color': '#607D8B',
        'icon': 'location_on',
        'showResources': true,
      },
    ),
  ];
}