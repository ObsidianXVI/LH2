import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_app/app/providers.dart';
import 'package:lh2_app/data/workspace_repository.dart';
import 'package:lh2_stub/lh2_stub.dart';

import 'demo_templates.dart';
import 'node_templates_default.dart';
import 'template_converter.dart';

/// Demo provider that serves node templates for testing
/// In a real app, these would come from Firestore
final demoNodeTemplatesProvider = StreamProvider.family<List<NodeTemplate>, (String, ObjectType)>((ref, params) {
  final (workspaceId, objectType) = params;
  
  // Use the new default templates instead of demo templates
  final allTemplates = DefaultNodeTemplates.templates;
  final filteredTemplates = allTemplates.where((template) => template.objectType == objectType).toList();
  
  // Convert domain templates to repository templates
  final repoTemplates = TemplateConverter.toRepositoryList(filteredTemplates);
  
  return Stream.value(repoTemplates);
});

/// Demo provider that combines real and demo templates
/// This would be used in development to have templates available
final enhancedNodeTemplatesProvider = StreamProvider.family<List<NodeTemplate>, (String, ObjectType)>((ref, params) {
  final (workspaceId, objectType) = params;
  final workspaceRepo = ref.watch(workspaceRepoProvider);
  
  // In development, combine real templates with default ones
  // In production, just use the real ones
  const isDevelopment = true;
  
  if (isDevelopment) {
    // Get both real and default templates
    final realTemplatesStream = workspaceRepo.watchNodeTemplates(workspaceId, objectType);
    final defaultTemplates = DefaultNodeTemplates.templates
        .where((template) => template.objectType == objectType)
        .toList();
    
    return realTemplatesStream.map((realTemplates) {
      // Convert real templates to domain format for comparison
      final realDomainTemplates = TemplateConverter.toDomainList(realTemplates);
      
      // Combine real and default templates, prioritizing real ones
      final combined = <NodeTemplate>[];
      combined.addAll(realTemplates);
      
      // Add default templates that don't conflict with real ones
      for (final defaultTemplate in defaultTemplates) {
        if (!realDomainTemplates.any((real) => real.id == defaultTemplate.id)) {
          // Convert default template to repository format and add
          combined.add(TemplateConverter.toRepository(defaultTemplate));
        }
      }
      
      return combined;
    });
  } else {
    // In production, just use real templates
    return workspaceRepo.watchNodeTemplates(workspaceId, objectType);
  }
});
