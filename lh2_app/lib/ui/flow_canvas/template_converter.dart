import 'package:lh2_app/data/workspace_repository.dart' as repo;
import 'package:lh2_app/domain/models/node_template.dart' as domain;
import 'package:lh2_stub/lh2_stub.dart';

/// Converts between domain NodeTemplate and repository NodeTemplate
class TemplateConverter {
  /// Converts from domain NodeTemplate to repository NodeTemplate
  static repo.NodeTemplate toRepository(domain.NodeTemplate domainTemplate) {
    return repo.NodeTemplate(
      schemaVersion: domainTemplate.schemaVersion,
      id: domainTemplate.id,
      objectType: domainTemplate.objectType,
      name: domainTemplate.name,
      renderSpec: domainTemplate.renderSpec,
    );
  }

  /// Converts from repository NodeTemplate to domain NodeTemplate
  static domain.NodeTemplate toDomain(repo.NodeTemplate repoTemplate) {
    return domain.NodeTemplate(
      schemaVersion: repoTemplate.schemaVersion,
      id: repoTemplate.id,
      objectType: repoTemplate.objectType,
      name: repoTemplate.name,
      renderSpec: repoTemplate.renderSpec,
    );
  }

  /// Converts a list of domain NodeTemplates to repository NodeTemplates
  static List<repo.NodeTemplate> toRepositoryList(
      List<domain.NodeTemplate> domainTemplates) {
    return domainTemplates.map(toRepository).toList();
  }

  /// Converts a list of repository NodeTemplates to domain NodeTemplates
  static List<domain.NodeTemplate> toDomainList(
      List<repo.NodeTemplate> repoTemplates) {
    return repoTemplates.map(toDomain).toList();
  }
}
