import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_app/app/providers.dart';
import 'package:lh2_app/domain/models/node_template.dart';
import 'package:lh2_stub/lh2_stub.dart';

final lh2ObjectProvider = FutureProvider.family<LH2Object, String>((ref, objectId) async {
  // Try each cache until we find the object
  // In a real app, we'd have a mapping of ID prefix to type, but for now we brute force or assume
  final caches = [
    ref.read(projectGroupCacheProvider),
    ref.read(projectCacheProvider),
    ref.read(deliverableCacheProvider),
    ref.read(taskCacheProvider),
    ref.read(sessionCacheProvider),
    ref.read(contextRequirementCacheProvider),
    ref.read(eventCacheProvider),
    ref.read(actualContextCacheProvider),
  ];

  for (final cache in caches) {
    try {
      final obj = await cache.get(objectId);
      if (obj != null) return obj;
    } catch (_) {}
  }
  throw Exception('Object not found: $objectId');
});

final nodeTemplateProvider = FutureProvider.family<NodeTemplate, String>((ref, templateId) async {
  final workspaceRepo = ref.read(workspaceRepoProvider);
  // This is a simplification, we need workspaceId
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  
  // Brute force search across types for demo/simplicity
  for (final type in ObjectType.values) {
    final templates = await workspaceRepo.watchNodeTemplates(workspaceId, type).first;
    final tmpl = templates.cast<NodeTemplate?>().firstWhere((t) => t?.id == templateId, orElse: () => null);
    if (tmpl != null) return tmpl;
  }

  // Return a default template if not found
  return NodeTemplate(
    id: 'default',
    objectType: ObjectType.task,
    name: 'Default',
    schemaVersion: 1,
    renderSpec: {
      'header': {'showTitle': true},
      'bodyFields': ['name'],
      'size': {'width': 150, 'height': 80},
    },
  );
});
