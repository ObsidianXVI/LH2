import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_app/app/providers.dart';
import 'package:lh2_app/data/workspace_repository.dart';
import 'package:lh2_stub/lh2_stub.dart';

import 'demo_templates.dart';

/// Demo provider that serves node templates for testing
/// In a real app, these would come from Firestore
final demoNodeTemplatesProvider = StreamProvider.family<List<NodeTemplate>, (String, ObjectType)>((ref, params) {
  final (workspaceId, objectType) = params;
  
  // For demo purposes, return templates based on object type
  final allTemplates = DemoNodeTemplates.demoTemplates;
  final filteredTemplates = allTemplates.where((template) => template.objectType == objectType).toList();
  
  return Stream.value(filteredTemplates);
});

/// Demo provider that combines real and demo templates
/// This would be used in development to have templates available
final enhancedNodeTemplatesProvider = StreamProvider.family<List<NodeTemplate>, (String, ObjectType)>((ref, params) {
  final (workspaceId, objectType) = params;
  final workspaceRepo = ref.watch(workspaceRepoProvider);
  
  // In development, combine real templates with demo ones
  // In production, just use the real ones
  const isDevelopment = true;
  
  if (isDevelopment) {
    // Get both real and demo templates
    final realTemplatesStream = workspaceRepo.watchNodeTemplates(workspaceId, objectType);
    final demoTemplates = DemoNodeTemplates.demoTemplates
        .where((template) => template.objectType == objectType)
        .toList();
    
    return realTemplatesStream.map((realTemplates) {
      // Combine real and demo templates, prioritizing real ones
      final combined = <NodeTemplate>[];
      combined.addAll(realTemplates);
      
      // Add demo templates that don't conflict with real ones
      for (final demoTemplate in demoTemplates) {
        if (!realTemplates.any((real) => real.id == demoTemplate.id)) {
          combined.add(demoTemplate);
        }
      }
      
      return combined;
    });
  } else {
    // In production, just use real templates
    return workspaceRepo.watchNodeTemplates(workspaceId, objectType);
  }
});