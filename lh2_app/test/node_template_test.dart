import 'package:flutter_test/flutter_test.dart';
import 'package:lh2_app/ui/flow_canvas/node_templates_default.dart';
import 'package:lh2_app/domain/models/node_template.dart';
import 'package:lh2_stub/lh2_stub.dart';

void main() {
  group('DefaultNodeTemplates', () {
    test('should create all required templates', () {
      final templates = DefaultNodeTemplates.templates;

      expect(templates.length, 7); // All object types except projectGroup

      // Check that all required object types are covered
      final objectTypes = templates.map((t) => t.objectType).toSet();
      expect(objectTypes.contains(ObjectType.project), isTrue);
      expect(objectTypes.contains(ObjectType.task), isTrue);
      expect(objectTypes.contains(ObjectType.deliverable), isTrue);
      expect(objectTypes.contains(ObjectType.session), isTrue);
      expect(objectTypes.contains(ObjectType.event), isTrue);
      expect(objectTypes.contains(ObjectType.contextRequirement), isTrue);
      expect(objectTypes.contains(ObjectType.actualContext), isTrue);
      expect(objectTypes.contains(ObjectType.projectGroup), isFalse);
    });

    test('project template should have correct structure', () {
      final projectTemplate = DefaultNodeTemplates.templates
          .firstWhere((t) => t.objectType == ObjectType.project);

      expect(projectTemplate.id, 'project-default');
      expect(projectTemplate.name, 'Default Project');
      expect(projectTemplate.schemaVersion, 1);

      final renderSpec = projectTemplate.renderSpec;
      expect(renderSpec['header']['showTitle'], isTrue);
      expect(renderSpec['bodyFields'], contains('name'));
      expect(renderSpec['bodyFields'], contains('deliverablesIds'));
      expect(renderSpec['bodyFields'], contains('nonDeliverableTasksIds'));

      final ports = renderSpec['ports'];
      expect(ports['in'].length, 1);
      expect(ports['out'].length, 1);
      expect(ports['in'][0]['portType'], 'dependency');
      expect(ports['out'][0]['portType'], 'dependency');

      final size = renderSpec['size'];
      expect(size['width'], 389);
      expect(size['height'], 133);

      final style = renderSpec['style'];
      expect(style['backgroundColor'], 0xFF160B2E);
      expect(style['borderColor'], 0xFF8A38F5);
      expect(style['textColor'], 0xFF7652B0);
    });

    test('task template should have correct structure', () {
      final taskTemplate = DefaultNodeTemplates.templates
          .firstWhere((t) => t.objectType == ObjectType.task);

      expect(taskTemplate.id, 'task-default');
      expect(taskTemplate.name, 'Default Task');

      final renderSpec = taskTemplate.renderSpec;
      expect(renderSpec['bodyFields'], contains('name'));
      expect(renderSpec['bodyFields'], contains('taskStatus'));
      expect(renderSpec['bodyFields'], contains('sessionsIds'));

      final style = renderSpec['style'];
      expect(style['borderColor'], 0xFF3861F5); // Blue accent
    });

    test('deliverable template should have correct structure', () {
      final deliverableTemplate = DefaultNodeTemplates.templates
          .firstWhere((t) => t.objectType == ObjectType.deliverable);

      expect(deliverableTemplate.id, 'deliverable-default');
      expect(deliverableTemplate.name, 'Default Deliverable');

      final renderSpec = deliverableTemplate.renderSpec;
      expect(renderSpec['bodyFields'], contains('name'));
      expect(renderSpec['bodyFields'], contains('deadlineTs'));
      expect(renderSpec['bodyFields'], contains('tasksIds'));

      final style = renderSpec['style'];
      expect(style['borderColor'], 0xFFF53838); // Red accent
    });

    test('session template should have correct structure', () {
      final sessionTemplate = DefaultNodeTemplates.templates
          .firstWhere((t) => t.objectType == ObjectType.session);

      expect(sessionTemplate.id, 'session-default');
      expect(sessionTemplate.name, 'Default Session');

      final renderSpec = sessionTemplate.renderSpec;
      expect(renderSpec['bodyFields'], contains('description'));
      expect(renderSpec['bodyFields'], contains('scheduledTs'));

      final style = renderSpec['style'];
      expect(style['borderColor'], 0xFF38F5BF); // Teal accent
    });

    test('event template should have correct structure', () {
      final eventTemplate = DefaultNodeTemplates.templates
          .firstWhere((t) => t.objectType == ObjectType.event);

      expect(eventTemplate.id, 'event-default');
      expect(eventTemplate.name, 'Default Event');

      final renderSpec = eventTemplate.renderSpec;
      expect(renderSpec['bodyFields'], contains('name'));

      final size = renderSpec['size'];
      expect(size['height'], 80); // Smaller height for events

      final style = renderSpec['style'];
      expect(style['backgroundColor'], 0xFF2D165D); // Yellow tint
      expect(style['borderColor'], 0xFFD8AD00); // Yellow accent
      expect(style['textColor'], 0xFFD8AD00);
    });

    test('context requirement template should have correct structure', () {
      final contextTemplate = DefaultNodeTemplates.templates
          .firstWhere((t) => t.objectType == ObjectType.contextRequirement);

      expect(contextTemplate.id, 'context-requirement-default');
      expect(contextTemplate.name, 'Default Context Requirement');

      final renderSpec = contextTemplate.renderSpec;
      expect(renderSpec['bodyFields'], contains('focusLevel'));
      expect(renderSpec['bodyFields'], contains('contiguousMinutesNeeded'));
      expect(renderSpec['bodyFields'], contains('resourceTags'));

      final ports = renderSpec['ports'];
      expect(ports['out'].length, 2); // Has conditional port
      expect(ports['out'][1]['portType'], 'conditional');

      final size = renderSpec['size'];
      expect(size['width'], 752);
      expect(size['height'], 704);

      final style = renderSpec['style'];
      expect(style['borderColor'], 0xFF4C4C4C); // Grey dashed border
    });

    test('actual context template should have correct structure', () {
      final actualContextTemplate = DefaultNodeTemplates.templates
          .firstWhere((t) => t.objectType == ObjectType.actualContext);

      expect(actualContextTemplate.id, 'actual-context-default');
      expect(actualContextTemplate.name, 'Default Actual Context');

      final renderSpec = actualContextTemplate.renderSpec;
      expect(renderSpec['bodyFields'], contains('focusLevel'));
      expect(renderSpec['bodyFields'], contains('resourceTags'));

      final style = renderSpec['style'];
      expect(style['borderColor'], 0xFF4C4C4C);
    });

    test('templates should be JSON serializable', () {
      final templates = DefaultNodeTemplates.templates;

      for (final template in templates) {
        final json = template.toJson();
        expect(json['id'], isNotNull);
        expect(json['objectType'], isNotNull);
        expect(json['name'], isNotNull);
        expect(json['schemaVersion'], isNotNull);
        expect(json['renderSpec'], isNotNull);

        // Test round-trip serialization
        final fromJson = NodeTemplate.fromJson(json);
        expect(fromJson.id, template.id);
        expect(fromJson.objectType, template.objectType);
        expect(fromJson.name, template.name);
        expect(fromJson.schemaVersion, template.schemaVersion);
      }
    });
  });
}
