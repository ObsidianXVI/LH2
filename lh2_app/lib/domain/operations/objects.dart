/// Object operations for LH2.
///
/// Operations:
///   - api.objects.get
///   - api.objects.update
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_stub/lh2_stub.dart';

import '../../app/providers.dart';
import '../../data/cache.dart';
import '../../data/firestore_db_interface.dart';
import 'core.dart';

// ============================================================================
// api.objects.get
// ============================================================================

/// Input for [ObjectsGetOp].
class ObjectsGetInput {
  final String objectId;
  final ObjectType objectType;
  final bool useCache;

  const ObjectsGetInput({
    required this.objectId,
    required this.objectType,
    this.useCache = true,
  });

  Map<String, Object?> toJson() => {
        'objectId': objectId,
        'objectType': objectType.name,
        'useCache': useCache,
      };
}

/// Output for [ObjectsGetOp].
class ObjectsGetOutput<T extends LH2Object> {
  final T object;

  const ObjectsGetOutput({required this.object});

  Map<String, Object?> toJson() => {
        'objectType': object.type.name,
        'object': object.toJson(),
      };
}

/// Retrieves a domain object by ID, with caching support.
///
/// Operation ID: api.objects.get
class ObjectsGetOp extends LH2Operation<ObjectsGetInput, ObjectsGetOutput> {
  final GenericCache<ProjectGroup> _projectGroupCache;
  final GenericCache<Project> _projectCache;
  final GenericCache<Deliverable> _deliverableCache;
  final GenericCache<Task> _taskCache;
  final GenericCache<Session> _sessionCache;
  final GenericCache<ContextRequirement> _contextRequirementCache;
  final GenericCache<Event> _eventCache;
  final GenericCache<ActualContext> _actualContextCache;

  ObjectsGetOp({
    required GenericCache<ProjectGroup> projectGroupCache,
    required GenericCache<Project> projectCache,
    required GenericCache<Deliverable> deliverableCache,
    required GenericCache<Task> taskCache,
    required GenericCache<Session> sessionCache,
    required GenericCache<ContextRequirement> contextRequirementCache,
    required GenericCache<Event> eventCache,
    required GenericCache<ActualContext> actualContextCache,
  })  : _projectGroupCache = projectGroupCache,
        _projectCache = projectCache,
        _deliverableCache = deliverableCache,
        _taskCache = taskCache,
        _sessionCache = sessionCache,
        _contextRequirementCache = contextRequirementCache,
        _eventCache = eventCache,
        _actualContextCache = actualContextCache;

  @override
  String get operationId => 'api.objects.get';

  @override
  Future<LH2OpResult<ObjectsGetOutput>> run(ObjectsGetInput input) async {
    try {
      if (input.objectId.isEmpty) {
        return LH2OpResult.error(
          createError(
            errorCode: LH2ErrorCodes.invalidInput,
            message: 'objectId cannot be empty',
            payload: input.toJson(),
            isFatal: false,
          ),
        );
      }

      late final LH2Object object;

      // Use cache if enabled - cache delegates to _db.getObject<T> on miss
      object = await _getFromCache(input.objectType, input.objectId);

      return LH2OpResult.ok(ObjectsGetOutput(object: object));
    } on StateError catch (e) {
      // Not found
      return LH2OpResult.error(
        createError(
          errorCode: LH2ErrorCodes.notFound,
          message: 'Object ${input.objectId} of type ${input.objectType.name} not found',
          payload: input.toJson(),
          cause: e,
          isFatal: false,
        ),
      );
    } catch (e) {
      return LH2OpResult.error(
        createError(
          errorCode: LH2ErrorCodes.databaseError,
          message: 'Failed to get object: ${e.toString()}',
          payload: input.toJson(),
          cause: e,
          isFatal: true,
        ),
      );
    }
  }

  Future<LH2Object> _getFromCache(ObjectType type, String id) async {
    switch (type) {
      case ObjectType.projectGroup:
        return _projectGroupCache.get(id);
      case ObjectType.project:
        return _projectCache.get(id);
      case ObjectType.deliverable:
        return _deliverableCache.get(id);
      case ObjectType.task:
        return _taskCache.get(id);
      case ObjectType.session:
        return _sessionCache.get(id);
      case ObjectType.contextRequirement:
        return _contextRequirementCache.get(id);
      case ObjectType.event:
        return _eventCache.get(id);
      case ObjectType.actualContext:
        return _actualContextCache.get(id);
    }
  }
}

/// Provider for [ObjectsGetOp].
final objectsGetOpProvider = Provider<ObjectsGetOp>((ref) {
  return ObjectsGetOp(
    projectGroupCache: ref.watch(projectGroupCacheProvider),
    projectCache: ref.watch(projectCacheProvider),
    deliverableCache: ref.watch(deliverableCacheProvider),
    taskCache: ref.watch(taskCacheProvider),
    sessionCache: ref.watch(sessionCacheProvider),
    contextRequirementCache: ref.watch(contextRequirementCacheProvider),
    eventCache: ref.watch(eventCacheProvider),
    actualContextCache: ref.watch(actualContextCacheProvider),
  );
});

// ============================================================================
// api.objects.update
// ============================================================================

/// Input for [ObjectsUpdateOp].
class ObjectsUpdateInput<T extends LH2Object> {
  final String objectId;
  final ObjectType objectType;
  final Map<String, Object?> data;
  final bool invalidateCache;

  const ObjectsUpdateInput({
    required this.objectId,
    required this.objectType,
    required this.data,
    this.invalidateCache = true,
  });

  Map<String, Object?> toJson() => {
        'objectId': objectId,
        'objectType': objectType.name,
        'data': data,
        'invalidateCache': invalidateCache,
      };
}

/// Output for [ObjectsUpdateOp].
class ObjectsUpdateOutput {
  final bool success;

  const ObjectsUpdateOutput({required this.success});

  Map<String, Object?> toJson() => {'success': success};
}

/// Updates a domain object.
///
/// Operation ID: api.objects.update
class ObjectsUpdateOp extends LH2Operation<ObjectsUpdateInput, ObjectsUpdateOutput> {
  final FirebaseFirestore _firestore;
  final GenericCache<ProjectGroup> _projectGroupCache;
  final GenericCache<Project> _projectCache;
  final GenericCache<Deliverable> _deliverableCache;
  final GenericCache<Task> _taskCache;
  final GenericCache<Session> _sessionCache;
  final GenericCache<ContextRequirement> _contextRequirementCache;
  final GenericCache<Event> _eventCache;
  final GenericCache<ActualContext> _actualContextCache;

  ObjectsUpdateOp({
    required FirebaseFirestore firestore,
    required GenericCache<ProjectGroup> projectGroupCache,
    required GenericCache<Project> projectCache,
    required GenericCache<Deliverable> deliverableCache,
    required GenericCache<Task> taskCache,
    required GenericCache<Session> sessionCache,
    required GenericCache<ContextRequirement> contextRequirementCache,
    required GenericCache<Event> eventCache,
    required GenericCache<ActualContext> actualContextCache,
  })  : _firestore = firestore,
        _projectGroupCache = projectGroupCache,
        _projectCache = projectCache,
        _deliverableCache = deliverableCache,
        _taskCache = taskCache,
        _sessionCache = sessionCache,
        _contextRequirementCache = contextRequirementCache,
        _eventCache = eventCache,
        _actualContextCache = actualContextCache;

  @override
  String get operationId => 'api.objects.update';

  @override
  Future<LH2OpResult<ObjectsUpdateOutput>> run(ObjectsUpdateInput input) async {
    try {
      if (input.objectId.isEmpty) {
        return LH2OpResult.error(
          createError(
            errorCode: LH2ErrorCodes.invalidInput,
            message: 'objectId cannot be empty',
            payload: input.toJson(),
            isFatal: false,
          ),
        );
      }

      if (input.data.isEmpty) {
        return LH2OpResult.error(
          createError(
            errorCode: LH2ErrorCodes.invalidInput,
            message: 'Update data cannot be empty',
            payload: input.toJson(),
            isFatal: false,
          ),
        );
      }

      // Perform partial update directly via Firestore
      // We use the collection reference directly since we're doing a partial map update
      await _updateObjectRaw(input.objectType, input.objectId, input.data);

      // Invalidate cache if requested
      if (input.invalidateCache) {
        _invalidateCache(input.objectType, input.objectId);
      }

      return LH2OpResult.ok(const ObjectsUpdateOutput(success: true));
    } on StateError catch (e) {
      // Not found
      return LH2OpResult.error(
        createError(
          errorCode: LH2ErrorCodes.notFound,
          message: 'Object ${input.objectId} of type ${input.objectType.name} not found',
          payload: input.toJson(),
          cause: e,
          isFatal: false,
        ),
      );
    } catch (e) {
      return LH2OpResult.error(
        createError(
          errorCode: LH2ErrorCodes.databaseError,
          message: 'Failed to update object: ${e.toString()}',
          payload: input.toJson(),
          cause: e,
          isFatal: true,
        ),
      );
    }
  }

  void _invalidateCache(ObjectType type, String id) {
    switch (type) {
      case ObjectType.projectGroup:
        _projectGroupCache.invalidate(id);
        break;
      case ObjectType.project:
        _projectCache.invalidate(id);
        break;
      case ObjectType.deliverable:
        _deliverableCache.invalidate(id);
        break;
      case ObjectType.task:
        _taskCache.invalidate(id);
        break;
      case ObjectType.session:
        _sessionCache.invalidate(id);
        break;
      case ObjectType.contextRequirement:
        _contextRequirementCache.invalidate(id);
        break;
      case ObjectType.event:
        _eventCache.invalidate(id);
        break;
      case ObjectType.actualContext:
        _actualContextCache.invalidate(id);
        break;
    }
  }

  /// Performs a raw partial update to Firestore without type safety.
  /// Used for partial updates where we only have a Map, not a full object.
  Future<void> _updateObjectRaw(
    ObjectType type,
    String id,
    Map<String, Object?> data,
  ) async {
    final collection = switch (type) {
      ObjectType.projectGroup => FS.projectGroups(_firestore),
      ObjectType.project => FS.projects(_firestore),
      ObjectType.deliverable => FS.deliverables(_firestore),
      ObjectType.task => FS.tasks(_firestore),
      ObjectType.session => FS.sessions(_firestore),
      ObjectType.contextRequirement => FS.contextRequirements(_firestore),
      ObjectType.event => FS.events(_firestore),
      ObjectType.actualContext => FS.actualContexts(_firestore),
    };

    await collection.doc(id).update(data);
  }
}

/// Provider for [ObjectsUpdateOp].
final objectsUpdateOpProvider = Provider<ObjectsUpdateOp>((ref) {
  return ObjectsUpdateOp(
    firestore: ref.watch(firestoreProvider),
    projectGroupCache: ref.watch(projectGroupCacheProvider),
    projectCache: ref.watch(projectCacheProvider),
    deliverableCache: ref.watch(deliverableCacheProvider),
    taskCache: ref.watch(taskCacheProvider),
    sessionCache: ref.watch(sessionCacheProvider),
    contextRequirementCache: ref.watch(contextRequirementCacheProvider),
    eventCache: ref.watch(eventCacheProvider),
    actualContextCache: ref.watch(actualContextCacheProvider),
  );
});
