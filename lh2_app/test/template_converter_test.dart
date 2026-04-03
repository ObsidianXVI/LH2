import 'package:flutter_test/flutter_test.dart';
import 'package:lh2_app/ui/flow_canvas/template_converter.dart';
import 'package:lh2_app/ui/flow_canvas/node_templates_default.dart';
import 'package:lh2_app/data/workspace_repository.dart' as repo;
import 'package:lh2_stub/lh2_stub.dart';

void main() {
  group('TemplateConverter', () {
    test('should convert domain template to repository template', () {
      // Get a domain template
      final domainTemplates = DefaultNodeTemplates.templates;
      final domainTemplate = domainTemplates.firstWhere(
        (t) => t.objectType == ObjectType.project,
      );

      // Convert to repository template
      final repoTemplate = TemplateConverter.toRepository(domainTemplate);

      // Verify conversion
      expect(repoTemplate.id, domainTemplate.id);
      expect(repoTemplate.objectType, domainTemplate.objectType);
      expect(repoTemplate.name, domainTemplate.name);
      expect(repoTemplate.schemaVersion, domainTemplate.schemaVersion);
      expect(repoTemplate.renderSpec, domainTemplate.renderSpec);
    });

    test('should convert repository template to domain template', () {
      // Create a repository template
      final repoTemplate = repo.NodeTemplate(
        schemaVersion: 1,
        id: 'test-template',
        objectType: ObjectType.task,
        name: 'Test Task',
        renderSpec: {
          'header': {'showTitle': true},
          'bodyFields': ['name', 'status'],
        },
      );

      // Convert to domain template
      final domainTemplate = TemplateConverter.toDomain(repoTemplate);

      // Verify conversion
      expect(domainTemplate.id, repoTemplate.id);
      expect(domainTemplate.objectType, repoTemplate.objectType);
      expect(domainTemplate.name, repoTemplate.name);
      expect(domainTemplate.schemaVersion, repoTemplate.schemaVersion);
      expect(domainTemplate.renderSpec, repoTemplate.renderSpec);
    });

    test('should convert list of domain templates to repository templates', () {
      // Get domain templates
      final domainTemplates = DefaultNodeTemplates.templates;

      // Convert list
      final repoTemplates = TemplateConverter.toRepositoryList(domainTemplates);

      // Verify conversion
      expect(repoTemplates.length, domainTemplates.length);
      for (int i = 0; i < domainTemplates.length; i++) {
        expect(repoTemplates[i].id, domainTemplates[i].id);
        expect(repoTemplates[i].objectType, domainTemplates[i].objectType);
        expect(repoTemplates[i].name, domainTemplates[i].name);
      }
    });

    test('should convert list of repository templates to domain templates', () {
      // Create repository templates
      final repoTemplates = [
        repo.NodeTemplate(
          schemaVersion: 1,
          id: 'template-1',
          objectType: ObjectType.project,
          name: 'Project 1',
          renderSpec: {},
        ),
        repo.NodeTemplate(
          schemaVersion: 1,
          id: 'template-2',
          objectType: ObjectType.task,
          name: 'Task 1',
          renderSpec: {},
        ),
      ];

      // Convert list
      final domainTemplates = TemplateConverter.toDomainList(repoTemplates);

      // Verify conversion
      expect(domainTemplates.length, repoTemplates.length);
      for (int i = 0; i < repoTemplates.length; i++) {
        expect(domainTemplates[i].id, repoTemplates[i].id);
        expect(domainTemplates[i].objectType, repoTemplates[i].objectType);
        expect(domainTemplates[i].name, repoTemplates[i].name);
      }
    });

    test('should handle all default templates', () {
      // Get all default templates
      final domainTemplates = DefaultNodeTemplates.templates;

      // Convert all to repository format
      final repoTemplates = TemplateConverter.toRepositoryList(domainTemplates);

      // Verify all object types are covered
      final objectTypes = domainTemplates.map((t) => t.objectType).toSet();
      final repoObjectTypes = repoTemplates.map((t) => t.objectType).toSet();

      expect(repoObjectTypes, equals(objectTypes));
      expect(repoTemplates.length, domainTemplates.length);
    });

    test('should preserve renderSpec during conversion', () {
      // Get a template with complex renderSpec
      final domainTemplate = DefaultNodeTemplates.templates
          .firstWhere((t) => t.objectType == ObjectType.contextRequirement);

      // Convert to repository and back
      final repoTemplate = TemplateConverter.toRepository(domainTemplate);
      final backToDomain = TemplateConverter.toDomain(repoTemplate);

      // Verify renderSpec is preserved
      expect(backToDomain.renderSpec, equals(domainTemplate.renderSpec));
      expect(backToDomain.renderSpec['ports'], isNotNull);
      expect(backToDomain.renderSpec['size'], isNotNull);
      expect(backToDomain.renderSpec['style'], isNotNull);
    });
  });
}