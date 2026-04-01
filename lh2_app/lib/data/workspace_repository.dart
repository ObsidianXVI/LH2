/// WorkspaceRepository — Firestore-backed persistence for workspace state.
///
/// Schema follows Appendix A of `.rhog/PLAN.md`:
///   workspaces/{workspaceId}
///     tabs/{tabId}
///     nodeTemplates/{templateId}
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lh2_stub/lh2_stub.dart';

typedef JSON = Map<String, Object?>;

// ---------------------------------------------------------------------------
// Value objects
// ---------------------------------------------------------------------------

/// Metadata stored on the workspace root document.
class WorkspaceMeta {
  final int schemaVersion;
  final String ownerUid;
  final String? activeTabId;
  final List<String> tabOrder;

  const WorkspaceMeta({
    required this.schemaVersion,
    required this.ownerUid,
    this.activeTabId,
    required this.tabOrder,
  });

  factory WorkspaceMeta.fromJson(JSON json) => WorkspaceMeta(
        schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
        ownerUid: json['ownerUid'] as String? ?? '',
        activeTabId: json['activeTabId'] as String?,
        tabOrder: List<String>.from(json['tabOrder'] as List? ?? []),
      );

  JSON toJson() => {
        'schemaVersion': schemaVersion,
        'ownerUid': ownerUid,
        'activeTabId': activeTabId,
        'tabOrder': tabOrder,
      };
}

/// Represents a single canvas tab persisted in Firestore.
class WorkspaceTab {
  final int schemaVersion;
  final String kind; // 'flow' | 'calendar'
  final String title;
  final JSON controller; // CanvasController JSON (Appendix B)
  final JSON items; // map of itemId → CanvasItem JSON
  final JSON links; // map of linkId → CanvasLink JSON

  const WorkspaceTab({
    required this.schemaVersion,
    required this.kind,
    required this.title,
    required this.controller,
    required this.items,
    required this.links,
  });

  factory WorkspaceTab.fromJson(JSON json) => WorkspaceTab(
        schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
        kind: json['kind'] as String? ?? 'flow',
        title: json['title'] as String? ?? 'Untitled',
        controller: (json['controller'] as JSON?) ?? {},
        items: (json['items'] as JSON?) ?? {},
        links: (json['links'] as JSON?) ?? {},
      );

  JSON toJson() => {
        'schemaVersion': schemaVersion,
        'kind': kind,
        'title': title,
        'controller': controller,
        'items': items,
        'links': links,
      };
}

/// Minimal draft used when creating a new tab.
class WorkspaceTabDraft {
  final String kind;
  final String title;
  final JSON controller;

  const WorkspaceTabDraft({
    required this.kind,
    required this.title,
    required this.controller,
  });
}

/// Partial update applied to an existing tab.
class WorkspaceTabPatch {
  final String? title;
  final JSON? controller;
  final JSON? items;
  final JSON? links;

  const WorkspaceTabPatch({
    this.title,
    this.controller,
    this.items,
    this.links,
  });

  JSON toUpdateMap() => {
        if (title != null) 'title': title,
        if (controller != null) 'controller': controller,
        if (items != null) 'items': items,
        if (links != null) 'links': links,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

/// A node template stored in the workspace.
class NodeTemplate {
  final int schemaVersion;
  final String id;
  final ObjectType objectType;
  final String name;
  final JSON renderSpec;

  const NodeTemplate({
    required this.schemaVersion,
    required this.id,
    required this.objectType,
    required this.name,
    required this.renderSpec,
  });

  factory NodeTemplate.fromJson(String id, JSON json) => NodeTemplate(
        schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
        id: id,
        objectType: ObjectType.values.byName(json['objectType'] as String),
        name: json['name'] as String? ?? '',
        renderSpec: (json['renderSpec'] as JSON?) ?? {},
      );

  JSON toJson() => {
        'schemaVersion': schemaVersion,
        'objectType': objectType.name,
        'name': name,
        'renderSpec': renderSpec,
      };
}

// ---------------------------------------------------------------------------
// WorkspaceRepository
// ---------------------------------------------------------------------------

/// Reads and writes workspace state to Firestore.
///
/// All writes to high-frequency fields (viewport pan/zoom) should be debounced
/// by the caller before invoking [updateTab].
class WorkspaceRepository {
  final FirebaseFirestore _db;

  WorkspaceRepository(this._db);

  // ---- collection helpers ----

  DocumentReference<JSON> _workspaceDoc(String workspaceId) =>
      _db.collection('workspaces').doc(workspaceId).withConverter<JSON>(
            fromFirestore: (snap, _) => snap.data()!,
            toFirestore: (data, _) => data,
          );

  CollectionReference<JSON> _tabsCol(String workspaceId) =>
      _workspaceDoc(workspaceId)
          .collection('tabs')
          .withConverter<JSON>(
            fromFirestore: (snap, _) => snap.data()!,
            toFirestore: (data, _) => data,
          );

  CollectionReference<JSON> _templatesCol(String workspaceId) =>
      _workspaceDoc(workspaceId)
          .collection('nodeTemplates')
          .withConverter<JSON>(
            fromFirestore: (snap, _) => snap.data()!,
            toFirestore: (data, _) => data,
          );

  // ---- schema version guard ----

  static const int _supportedSchemaVersion = 1;

  void _assertSchemaVersion(int version, String docPath) {
    if (version > _supportedSchemaVersion) {
      throw StateError(
        'Unsupported schema version $version at $docPath. '
        'Max supported: $_supportedSchemaVersion.',
      );
    }
  }

  // ---- WorkspaceMeta ----

  Stream<WorkspaceMeta> watchWorkspaceMeta(String workspaceId) =>
      _workspaceDoc(workspaceId).snapshots().map((snap) {
        final data = snap.data() ?? {};
        final meta = WorkspaceMeta.fromJson(data);
        _assertSchemaVersion(meta.schemaVersion, snap.reference.path);
        return meta;
      });

  Future<WorkspaceMeta> getWorkspaceMeta(String workspaceId) async {
    final snap = await _workspaceDoc(workspaceId).get();
    final data = snap.data() ?? {};
    final meta = WorkspaceMeta.fromJson(data);
    _assertSchemaVersion(meta.schemaVersion, snap.reference.path);
    return meta;
  }

  Future<void> upsertWorkspaceMeta(
    String workspaceId,
    WorkspaceMeta meta,
  ) async {
    await _workspaceDoc(workspaceId).set(
      {
        ...meta.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ---- WorkspaceTab ----

  Stream<WorkspaceTab> watchTab(String workspaceId, String tabId) =>
      _tabsCol(workspaceId).doc(tabId).snapshots().map((snap) {
        final data = snap.data() ?? {};
        final tab = WorkspaceTab.fromJson(data);
        _assertSchemaVersion(tab.schemaVersion, snap.reference.path);
        return tab;
      });

  Future<WorkspaceTab> getTab(String workspaceId, String tabId) async {
    final snap = await _tabsCol(workspaceId).doc(tabId).get();
    final data = snap.data() ?? {};
    final tab = WorkspaceTab.fromJson(data);
    _assertSchemaVersion(tab.schemaVersion, snap.reference.path);
    return tab;
  }

  Future<String> createTab(
    String workspaceId,
    WorkspaceTabDraft draft,
  ) async {
    final ref = _tabsCol(workspaceId).doc();
    await ref.set({
      'schemaVersion': _supportedSchemaVersion,
      'kind': draft.kind,
      'title': draft.title,
      'controller': draft.controller,
      'items': <String, Object?>{},
      'links': <String, Object?>{},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateTab(
    String workspaceId,
    String tabId,
    WorkspaceTabPatch patch,
  ) async {
    await _tabsCol(workspaceId).doc(tabId).update(patch.toUpdateMap());
  }

  Future<void> deleteTab(String workspaceId, String tabId) async {
    await _tabsCol(workspaceId).doc(tabId).delete();
  }

  // ---- NodeTemplates ----

  Stream<List<NodeTemplate>> watchNodeTemplates(
    String workspaceId,
    ObjectType type,
  ) =>
      _templatesCol(workspaceId)
          .where('objectType', isEqualTo: type.name)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((d) => NodeTemplate.fromJson(d.id, d.data()))
                .toList(),
          );

  Future<void> upsertNodeTemplate(
    String workspaceId,
    NodeTemplate template,
  ) async {
    await _templatesCol(workspaceId).doc(template.id).set(
          template.toJson(),
          SetOptions(merge: true),
        );
  }
}
