import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lh2_app/ui/flow_canvas/node_renderer_registry.dart';
import 'package:lh2_app/ui/flow_canvas/nodes/node_widgets.dart';
import 'package:lh2_app/domain/models/node_template.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';
import 'package:lh2_stub/lh2_stub.dart';

void main() {
  group('NodeRendererRegistry', () {
    late NodeRendererRegistry registry;

    setUp(() {
      registry = NodeRendererRegistry();
    });

    test('should register all required object types', () {
      // Create a test template
      final template = NodeTemplate(
        schemaVersion: 1,
        id: 'test-template',
        objectType: ObjectType.project,
        name: 'Test Template',
        renderSpec: {},
      );

      // Create test objects for each type
      final project = Project(
        name: 'Test Project',
        deliverablesIds: ['deliv1', 'deliv2'],
        nonDeliverableTasksIds: ['task1', 'task2'],
      );

      final task = Task(
        name: 'Test Task',
        sessionsIds: ['session1'],
        taskStatus: TaskStatus.underway,
        outboundDependenciesIds: [],
      );

      final deliverable = Deliverable(
        name: 'Test Deliverable',
        tasksIds: ['task1', 'task2'],
        deadlineTs: DateTime.now().millisecondsSinceEpoch,
      );

      final session = Session(
        description: 'Test Session',
        scheduledTs: DateTime.now().millisecondsSinceEpoch,
        contextRequirement: ContextRequirement(
          focusLevel: 0.8,
          contiguousMinutesNeeded: 120,
          resourceTags: {'quiet': true, 'desk': true},
        ),
      );

      final event = Event(
        name: 'Test Event',
        description: 'Test Event Description',
        calendar: 'default',
        startTs: DateTime.now().millisecondsSinceEpoch,
        endTs: DateTime.now().millisecondsSinceEpoch + 3600000, // +1 hour
        allDay: false,
        actualContext: const ActualContext(
          focusLevel: 0.5,
          contiguousMinutesAvailable: 60,
          resourceTags: {},
        ),
      );

      final contextRequirement = ContextRequirement(
        focusLevel: 0.9,
        contiguousMinutesNeeded: 90,
        resourceTags: {'quiet': true},
      );

      final actualContext = ActualContext(
        focusLevel: 0.7,
        contiguousMinutesAvailable: 120,
        resourceTags: {'desk': true, 'coffee': true},
      );

      // Test each object type
      final testItem = CanvasItem(
        itemId: 'test-item',
        itemType: 'node',
        worldRect: Rect.fromLTWH(100, 100, 200, 150),
        objectId: 'test-object',
        disabledByScenario: false,
      );

      // Test project renderer
      final projectWidget = registry.build(project, template, testItem);
      expect(projectWidget, isA<ProjectNodeRenderer>());

      // Test task renderer
      final taskWidget = registry.build(task, template, testItem);
      expect(taskWidget, isA<TaskNodeRenderer>());

      // Test deliverable renderer
      final deliverableWidget = registry.build(deliverable, template, testItem);
      expect(deliverableWidget, isA<DeliverableNodeRenderer>());

      // Test session renderer
      final sessionWidget = registry.build(session, template, testItem);
      expect(sessionWidget, isA<SessionNodeRenderer>());

      // Test event renderer
      final eventWidget = registry.build(event, template, testItem);
      expect(eventWidget, isA<EventNodeRenderer>());

      // Test context requirement renderer
      final contextWidget =
          registry.build(contextRequirement, template, testItem);
      expect(contextWidget, isA<ContextRequirementNodeRenderer>());

      // Test actual context renderer
      final actualContextWidget =
          registry.build(actualContext, template, testItem);
      expect(actualContextWidget, isA<ActualContextNodeRenderer>());
    });

    test('should handle project group correctly', () {
      // ProjectGroup should not be directly renderable
      final projectGroup = ProjectGroup(
        name: 'Test Group',
        projectsIds: ['proj1', 'proj2'],
      );

      final template = NodeTemplate(
        schemaVersion: 1,
        id: 'test-template',
        objectType: ObjectType.projectGroup,
        name: 'Test Template',
        renderSpec: {},
      );

      final testItem = CanvasItem(
        itemId: 'test-item',
        itemType: 'node',
        worldRect: Rect.fromLTWH(100, 100, 200, 150),
        objectId: 'test-object',
        disabledByScenario: false,
      );

      // Should fall back to generic renderer
      final widget = registry.build(projectGroup, template, testItem);
      expect(widget, isA<GenericNodeRenderer>());
    });

    test('should allow custom renderer registration', () {
      final customRenderer =
          (LH2Object object, NodeTemplate template, CanvasItem item,
              {bool isSelected = false, bool isHighlighted = false}) {
        return Container(child: Text('Custom Renderer'));
      };

      registry.register(ObjectType.project, customRenderer);

      final project = Project(
        name: 'Test Project',
        deliverablesIds: [],
        nonDeliverableTasksIds: [],
      );

      final template = NodeTemplate(
        schemaVersion: 1,
        id: 'test-template',
        objectType: ObjectType.project,
        name: 'Test Template',
        renderSpec: {},
      );

      final testItem = CanvasItem(
        itemId: 'test-item',
        itemType: 'node',
        worldRect: Rect.fromLTWH(100, 100, 200, 150),
        objectId: 'test-object',
        disabledByScenario: false,
      );

      final widget = registry.build(project, template, testItem);
      expect(widget, isA<Container>());
      expect((widget as Container).child, isA<Text>());
      expect(((widget.child as Text).data), 'Custom Renderer');
    });

    test('should handle unknown object types gracefully', () {
      // Create a mock object with a type that might not be registered
      final projectGroup = ProjectGroup(
        name: 'Test Group',
        projectsIds: ['proj1', 'proj2'],
      );

      final template = NodeTemplate(
        schemaVersion: 1,
        id: 'test-template',
        objectType: ObjectType.projectGroup,
        name: 'Test Template',
        renderSpec: {},
      );

      final testItem = CanvasItem(
        itemId: 'test-item',
        itemType: 'node',
        worldRect: Rect.fromLTWH(100, 100, 200, 150),
        objectId: 'test-object',
        disabledByScenario: false,
      );

      // Should not throw and should return some widget (falls back to generic)
      expect(() => registry.build(projectGroup, template, testItem),
          returnsNormally);
    });

    test('should handle disabled items correctly', () {
      final project = Project(
        name: 'Test Project',
        deliverablesIds: [],
        nonDeliverableTasksIds: [],
      );

      final template = NodeTemplate(
        schemaVersion: 1,
        id: 'test-template',
        objectType: ObjectType.project,
        name: 'Test Template',
        renderSpec: {
          'style': {
            'backgroundColor': 0xFF160B2E,
            'borderColor': 0xFF8A38F5,
            'textColor': 0xFF7652B0,
          },
        },
      );

      final disabledItem = CanvasItem(
        itemId: 'test-item',
        itemType: 'node',
        worldRect: Rect.fromLTWH(100, 100, 200, 150),
        objectId: 'test-object',
        disabledByScenario: true,
      );

      final enabledItem = CanvasItem(
        itemId: 'test-item',
        itemType: 'node',
        worldRect: Rect.fromLTWH(100, 100, 200, 150),
        objectId: 'test-object',
        disabledByScenario: false,
      );

      // Both should render without throwing
      expect(() => registry.build(project, template, disabledItem),
          returnsNormally);
      expect(() => registry.build(project, template, enabledItem),
          returnsNormally);
    });
  });
}
