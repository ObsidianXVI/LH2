/// Firestore implementation of [DatabaseInterface].
///
/// Root collections follow the schema in `.rhog/boilerplate/db_interface.dart`.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lh2_stub/lh2_stub.dart';

typedef JSON = Map<String, Object?>;

// ---------------------------------------------------------------------------
// Collection references
// ---------------------------------------------------------------------------

/// Namespace for all root Firestore collection references.
class FS {
  FS._();

  static CollectionReference<JSON> _col(
    FirebaseFirestore db,
    String name,
  ) =>
      db.collection(name).withConverter<JSON>(
            fromFirestore: (snap, _) => snap.data()!,
            toFirestore: (data, _) => data,
          );

  static CollectionReference<JSON> projectGroups(FirebaseFirestore db) =>
      _col(db, 'projectGroups');
  static CollectionReference<JSON> projects(FirebaseFirestore db) =>
      _col(db, 'projects');
  static CollectionReference<JSON> deliverables(FirebaseFirestore db) =>
      _col(db, 'deliverables');
  static CollectionReference<JSON> tasks(FirebaseFirestore db) =>
      _col(db, 'tasks');
  static CollectionReference<JSON> sessions(FirebaseFirestore db) =>
      _col(db, 'sessions');
  static CollectionReference<JSON> contextRequirements(
    FirebaseFirestore db,
  ) =>
      _col(db, 'contextRequirements');
  static CollectionReference<JSON> events(FirebaseFirestore db) =>
      _col(db, 'events');
  static CollectionReference<JSON> actualContexts(FirebaseFirestore db) =>
      _col(db, 'actualContexts');
}

// ---------------------------------------------------------------------------
// FirestoreDBInterface
// ---------------------------------------------------------------------------

/// Concrete [DatabaseInterface] backed by Cloud Firestore.
class FirestoreDBInterface
    extends DatabaseInterface<Query<JSON>, List<QueryDocumentSnapshot<JSON>>> {
  final FirebaseFirestore _db;

  FirestoreDBInterface(this._db);

  // ---- helpers ----

  Future<A> _dispatch<A>(
    Type t, {
    required Future<A> Function() ifProjectGroup,
    required Future<A> Function() ifProject,
    required Future<A> Function() ifDeliverable,
    required Future<A> Function() ifTask,
    required Future<A> Function() ifSession,
    required Future<A> Function() ifContextRequirement,
    required Future<A> Function() ifEvent,
    required Future<A> Function() ifActualContext,
  }) {
    if (t == ProjectGroup) return ifProjectGroup();
    if (t == Project) return ifProject();
    if (t == Deliverable) return ifDeliverable();
    if (t == Task) return ifTask();
    if (t == Session) return ifSession();
    if (t == ContextRequirement) return ifContextRequirement();
    if (t == Event) return ifEvent();
    if (t == ActualContext) return ifActualContext();
    throw ArgumentError('Unknown LH2Object type: $t');
  }

  // ---- CRUD ----

  @override
  Future<T> getObject<T extends LH2Object>(String id) async {
    return _dispatch<T>(
      T,
      ifProjectGroup: () async =>
          ProjectGroup.fromJson(
            (await FS.projectGroups(_db).doc(id).get()).data()!,
          ) as T,
      ifProject: () async =>
          Project.fromJson(
            (await FS.projects(_db).doc(id).get()).data()!,
          ) as T,
      ifDeliverable: () async =>
          Deliverable.fromJson(
            (await FS.deliverables(_db).doc(id).get()).data()!,
          ) as T,
      ifTask: () async =>
          Task.fromJson(
            (await FS.tasks(_db).doc(id).get()).data()!,
          ) as T,
      ifSession: () async =>
          Session.fromJson(
            (await FS.sessions(_db).doc(id).get()).data()!,
          ) as T,
      ifContextRequirement: () async =>
          ContextRequirement.fromJson(
            (await FS.contextRequirements(_db).doc(id).get()).data()!,
          ) as T,
      ifEvent: () async =>
          Event.fromJson(
            (await FS.events(_db).doc(id).get()).data()!,
          ) as T,
      ifActualContext: () async =>
          ActualContext.fromJson(
            (await FS.actualContexts(_db).doc(id).get()).data()!,
          ) as T,
    );
  }

  @override
  Future<void> updateObject<T extends LH2Object>(
    String id,
    T newObject,
  ) async {
    await _dispatch<void>(
      T,
      ifProjectGroup: () =>
          FS.projectGroups(_db).doc(id).update(newObject.toJson()),
      ifProject: () => FS.projects(_db).doc(id).update(newObject.toJson()),
      ifDeliverable: () =>
          FS.deliverables(_db).doc(id).update(newObject.toJson()),
      ifTask: () => FS.tasks(_db).doc(id).update(newObject.toJson()),
      ifSession: () => FS.sessions(_db).doc(id).update(newObject.toJson()),
      ifContextRequirement: () =>
          FS.contextRequirements(_db).doc(id).update(newObject.toJson()),
      ifEvent: () => FS.events(_db).doc(id).update(newObject.toJson()),
      ifActualContext: () =>
          FS.actualContexts(_db).doc(id).update(newObject.toJson()),
    );
  }

  @override
  Future<String> createAndSetObject<T extends LH2Object>(T object) async {
    late String docId;

    DocumentReference<JSON> newDoc(CollectionReference<JSON> col) {
      final ref = col.doc();
      docId = ref.id;
      return ref;
    }

    await _dispatch<void>(
      T,
      ifProjectGroup: () =>
          newDoc(FS.projectGroups(_db)).set(object.toJson()),
      ifProject: () => newDoc(FS.projects(_db)).set(object.toJson()),
      ifDeliverable: () =>
          newDoc(FS.deliverables(_db)).set(object.toJson()),
      ifTask: () => newDoc(FS.tasks(_db)).set(object.toJson()),
      ifSession: () => newDoc(FS.sessions(_db)).set(object.toJson()),
      ifContextRequirement: () =>
          newDoc(FS.contextRequirements(_db)).set(object.toJson()),
      ifEvent: () => newDoc(FS.events(_db)).set(object.toJson()),
      ifActualContext: () =>
          newDoc(FS.actualContexts(_db)).set(object.toJson()),
    );

    return docId;
  }

  @override
  Future<void> deleteObject<T extends LH2Object>(String id) async {
    await _dispatch<void>(
      T,
      ifProjectGroup: () => FS.projectGroups(_db).doc(id).delete(),
      ifProject: () => FS.projects(_db).doc(id).delete(),
      ifDeliverable: () => FS.deliverables(_db).doc(id).delete(),
      ifTask: () => FS.tasks(_db).doc(id).delete(),
      ifSession: () => FS.sessions(_db).doc(id).delete(),
      ifContextRequirement: () =>
          FS.contextRequirements(_db).doc(id).delete(),
      ifEvent: () => FS.events(_db).doc(id).delete(),
      ifActualContext: () => FS.actualContexts(_db).doc(id).delete(),
    );
  }

  @override
  Future<List<QueryDocumentSnapshot<JSON>>> runQuery(
    Query<JSON> query,
  ) async =>
      (await query.get()).docs;
}
