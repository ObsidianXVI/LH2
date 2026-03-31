part of lh2.app;

class FS {
  static CollectionReference<JSON> projectGroups = firestore.collection(
    'projectGroups',
  );

  static CollectionReference<JSON> projects = firestore.collection('projects');

  static CollectionReference<JSON> deliverables = firestore.collection(
    'deliverables',
  );

  static CollectionReference<JSON> tasks = firestore.collection('tasks');
  static CollectionReference<JSON> sessions = firestore.collection('sessions');
  static CollectionReference<JSON> contextRequirements = firestore.collection(
    'contextRequirements',
  );
  static CollectionReference<JSON> events = firestore.collection('events');
  static CollectionReference<JSON> actualContexts = firestore.collection(
    'actualContexts',
  );
}

class FirestoreDBInterface
    extends DatabaseInterface<Query<JSON>, List<QueryDocumentSnapshot>> {
  @override
  Future<T> getObject<T extends LH2Object>(String id) async {
    return await detectObjectType(
      T,
      ifProjectGroup: () async =>
          ProjectGroup.fromJson((await FS.projectGroups.doc(id).get()).data()!)
              as T,
      ifProject: () async =>
          Project.fromJson((await FS.projects.doc(id).get()).data()!) as T,
      ifDeliverable: () async =>
          Deliverable.fromJson((await FS.deliverables.doc(id).get()).data()!)
              as T,
      ifTask: () async =>
          Task.fromJson((await FS.tasks.doc(id).get()).data()!) as T,
      ifSession: () async =>
          Session.fromJson((await FS.sessions.doc(id).get()).data()!) as T,
      ifContextRequirement: () async =>
          ContextRequirement.fromJson(
                (await FS.contextRequirements.doc(id).get()).data()!,
              )
              as T,
      ifEvent: () async =>
          Event.fromJson((await FS.events.doc(id).get()).data()!) as T,
      ifActualContext: () async =>
          ActualContext.fromJson(
                (await FS.actualContexts.doc(id).get()).data()!,
              )
              as T,
    );
  }

  @override
  Future<void> updateObject<T extends LH2Object>(String id, T newObject) async {
    await detectObjectType(
      T,
      ifProjectGroup: () async =>
          await FS.projectGroups.doc(id).update(newObject.toJson()),
      ifProject: () async =>
          await FS.projects.doc(id).update(newObject.toJson()),
      ifDeliverable: () async =>
          await FS.deliverables.doc(id).update(newObject.toJson()),
      ifTask: () async => await FS.tasks.doc(id).update(newObject.toJson()),
      ifSession: () async =>
          await FS.sessions.doc(id).update(newObject.toJson()),
      ifContextRequirement: () async =>
          await FS.contextRequirements.doc(id).update(newObject.toJson()),
      ifEvent: () async => await FS.events.doc(id).update(newObject.toJson()),
      ifActualContext: () async =>
          await FS.actualContexts.doc(id).update(newObject.toJson()),
    );
  }

  @override
  Future<String> createAndSetObject<T extends LH2Object>(T object) async {
    late String docId;
    DocumentReference<JSON> createDocIn(CollectionReference<JSON> ref) {
      final docRef = ref.doc();
      docId = docRef.id;
      return docRef;
    }

    await detectObjectType(
      T,
      ifProjectGroup: () async =>
          await createDocIn(FS.projectGroups).set(object.toJson()),
      ifProject: () async =>
          await createDocIn(FS.projects).set(object.toJson()),
      ifDeliverable: () async =>
          await createDocIn(FS.deliverables).set(object.toJson()),
      ifTask: () async => await createDocIn(FS.tasks).set(object.toJson()),
      ifSession: () async =>
          await createDocIn(FS.sessions).set(object.toJson()),
      ifContextRequirement: () async =>
          await createDocIn(FS.contextRequirements).set(object.toJson()),
      ifEvent: () async => await createDocIn(FS.events).set(object.toJson()),
      ifActualContext: () async =>
          await createDocIn(FS.actualContexts).set(object.toJson()),
    );

    return docId;
  }

  @override
  Future<void> deleteObject<T extends LH2Object>(String id) async {
    await detectObjectType(
      T,
      ifProjectGroup: () async => await FS.projectGroups.doc(id).delete(),
      ifProject: () async => await FS.projects.doc(id).delete(),
      ifDeliverable: () async => await FS.deliverables.doc(id).delete(),
      ifTask: () async => await FS.tasks.doc(id).delete(),
      ifSession: () async => await FS.sessions.doc(id).delete(),
      ifContextRequirement: () async =>
          await FS.contextRequirements.doc(id).delete(),
      ifEvent: () async => await FS.events.doc(id).delete(),
      ifActualContext: () async => await FS.actualContexts.doc(id).delete(),
    );
  }

  @override
  Future<List<QueryDocumentSnapshot<JSON>>> runQuery(Query<JSON> query) async =>
      (await query.get()).docs;

  Future<A> detectObjectType<A>(
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
    if (t == ProjectGroup) {
      return ifProjectGroup();
    } else if (t == Project) {
      return ifProject();
    } else if (t == Deliverable) {
      return ifDeliverable();
    } else if (t == Task) {
      return ifTask();
    } else if (t == Session) {
      return ifSession();
    } else if (t == ContextRequirement) {
      return ifContextRequirement();
    } else if (t == Event) {
      return ifEvent();
    } else if (t == ActualContext) {
      return ifActualContext();
    } else {
      throw Exception('Could not detect object type: $t');
    }
  }
}
