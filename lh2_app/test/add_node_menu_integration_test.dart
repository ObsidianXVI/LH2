import 'package:flutter_test/flutter_test.dart';
import 'package:lh2_app/ui/flow_canvas/node_templates_default.dart';
import 'package:lh2_app/ui/flow_canvas/template_converter.dart';
import 'package:lh2_app/data/workspace_repository.dart' as repo;
import 'package:lh2_stub/lh2_stub.dart';

void main() {
  group('Add Node Menu Integration', () {
    test('default templates should be available and correctly styled', () {
      // Get all default templates
      final defaultTemplates = DefaultNodeTemplates.templates;
      
      // Verify we have templates for all required object types
      final objectTypes = [
        ObjectType.project,
        ObjectType.task,
        ObjectType.deliverable,
        ObjectType.session,
        ObjectType.event,
        ObjectType.contextRequirement,
        ObjectType.actualContext,
      ];
      
      for (final objectType in objectTypes) {
        final templates = defaultTemplates.where((t) => t.objectType == objectType).toList();
        expect(templates, isNotEmpty, reason: 'Should have templates for $objectType');
      }
      
      // Test project template specifically
      final projectTemplate = defaultTemplates.firstWhere((t) => t.id == 'project-default');
      expect(projectTemplate.objectType, ObjectType.project);
      expect(projectTemplate.name, 'Default Project');
      
      final style = projectTemplate.renderSpec['style'] as Map<String, dynamic>?;
      expect(style?['borderColor'], 0xFF8A38F5); // Purple accent from Figma
    });

    test('template converter should work correctly', () {
      // Get a domain template
      final domainTemplate = DefaultNodeTemplates.templates
          .firstWhere((t) => t.objectType == ObjectType.task);
      
      // Convert to repository format
      final repoTemplate = TemplateConverter.toRepository(domainTemplate);
      
      // Verify conversion worked
      expect(repoTemplate.id, domainTemplate.id);
      expect(repoTemplate.objectType, domainTemplate.objectType);
      expect(repoTemplate.name, domainTemplate.name);
      
      // Verify the renderSpec is preserved
      expect(repoTemplate.renderSpec, equals(domainTemplate.renderSpec));
    });

    test('context requirement template should have conditional port', () {
      final contextTemplate = DefaultNodeTemplates.templates
          .firstWhere((t) => t.id == 'context-requirement-default');
      
      final ports = contextTemplate.renderSpec['ports'] as Map<String, dynamic>?;
      final outPorts = ports?['out'] as List<dynamic>?;
      
      // Should have both regular out port and conditional port
      expect(outPorts?.length, 2);
      expect(outPorts?.any((p) => p['portType'] == 'conditional'), isTrue);
    });

    test('event template should be compact (smaller height)', () {
      final eventTemplate = DefaultNodeTemplates.templates
          .firstWhere((t) => t.id == 'event-default');
      
      final size = eventTemplate.renderSpec['size'] as Map<String, dynamic>?;
      expect(size?['height'], 80); // Smaller height for events
    });

    test('all templates should have proper port configuration', () {
      final objectTypes = [
        ObjectType.project,
        ObjectType.task,
        ObjectType.deliverable,
        ObjectType.session,
        ObjectType.event,
        ObjectType.actualContext,
      ];
      
      for (final objectType in objectTypes) {
        final template = DefaultNodeTemplates.templates
            .firstWhere((t) => t.objectType == objectType);
        
        final ports = template.renderSpec['ports'] as Map<String, dynamic>?;
        expect(ports?['in'], isA<List<dynamic>>());
        expect(ports?['out'], isA<List<dynamic>>());
        expect(ports?['in']?.length, greaterThan(0));
        expect(ports?['out']?.length, greaterThan(0));
      }
    });

    test('templates should follow Figma color scheme', () {
      // Project: Purple accent
      final projectTemplate = DefaultNodeTemplates.templates
          .firstWhere((t) => t.id == 'project-default');
      final projectStyle = projectTemplate.renderSpec['style'] as Map<String, dynamic>?;
      expect(projectStyle?['borderColor'], 0xFF8A38F5);
      
      // Task: Blue accent
      final taskTemplate = DefaultNodeTemplates.templates
          .firstWhere((t) => t.id == 'task-default');
      final taskStyle = taskTemplate.renderSpec['style'] as Map<String, dynamic>?;
      expect(taskStyle?['borderColor'], 0xFF3861F5);
      
      // Deliverable: Red accent
      final deliverableTemplate = DefaultNodeTemplates.templates
          .firstWhere((t) => t.id == 'deliverable-default');
      final deliverableStyle = deliverableTemplate.renderSpec['style'] as Map<String, dynamic>?;
      expect(deliverableStyle?['borderColor'], 0xFFF53838);
      
      // Session: Teal accent
      final sessionTemplate = DefaultNodeTemplates.templates
          .firstWhere((t) => t.id == 'session-default');
      final sessionStyle = sessionTemplate.renderSpec['style'] as Map<String, dynamic>?;
      expect(sessionStyle?['borderColor'], 0xFF38F5BF);
      
      // Event: Yellow accent
      final eventTemplate = DefaultNodeTemplates.templates
          .firstWhere((t) => t.id == 'event-default');
      final eventStyle = eventTemplate.renderSpec['style'] as Map<String, dynamic>?;
      expect(eventStyle?['borderColor'], 0xFFD8AD00);
    });
  });
}
