/// Integration tests using Firestore emulator for create/get/update/delete.
///
/// Run with: flutter test test/firestore_integration_test.dart
/// Requires Firestore emulator running on localhost:8081.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lh2_app/data/firestore_db_interface.dart';
import 'package:lh2_stub/lh2_stub.dart';

void main() {
  late FirebaseFirestore firestore;
  late FirestoreDBInterface db;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    // Connect to emulator
    firestore = FirebaseFirestore.instance;
    firestore.useFirestoreEmulator('localhost', 8081);
    firestore.settings = const Settings(
      persistenceEnabled: false,
      sslEnabled: false,
    );

    db = FirestoreDBInterface(firestore);
  });

  setUp(() async {
    // Clean up all collections before each test
    final collections = [
      'projectGroups',
      'projects',
      'deliverables',
      'tasks',
      'sessions',
      'contextRequirements',
      'events',
      'actualContexts',
    ];
    for (final col in collections) {
      final snapshot = await firestore.collection(col).get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
  });

  group('FirestoreDBInterface CRUD - ProjectGroup', () {
    test('create, get, update, delete', () async {
      // Create
      const original = ProjectGroup(
        name: 'Test Group',
        projectsIds: ['proj1', 'proj2'],
      );
      final id = await db.createAndSetObject(original);
      expect(id, isNotEmpty);

      // Get
      final fetched = await db.getObject<ProjectGroup>(id);
      expect(fetched.name, original.name);
      expect(fetched.projectsIds, original.projectsIds);

      // Update
      const updated = ProjectGroup(
        name: 'Updated Group',
        projectsIds: ['proj1', 'proj2', 'proj3'],
      );
      await db.updateObject(id, updated);
      final fetchedUpdated = await db.getObject<ProjectGroup>(id);
      expect(fetchedUpdated.name, updated.name);
      expect(fetchedUpdated.projectsIds, updated.projectsIds);

      // Delete
      await db.deleteObject<ProjectGroup>(id);
      await expectLater(
        db.getObject<ProjectGroup>(id),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('FirestoreDBInterface CRUD - Project', () {
    test('create, get, update, delete', () async {
      const original = Project(
        name: 'Test Project',
        deliverablesIds: ['del1'],
        nonDeliverableTasksIds: ['task1'],
      );
      final id = await db.createAndSetObject(original);
      expect(id, isNotEmpty);

      final fetched = await db.getObject<Project>(id);
      expect(fetched.name, original.name);

      const updated = Project(
        name: 'Updated Project',
        deliverablesIds: ['del1', 'del2'],
        nonDeliverableTasksIds: ['task1', 'task2'],
      );
      await db.updateObject(id, updated);
      final fetchedUpdated = await db.getObject<Project>(id);
      expect(fetchedUpdated.name, updated.name);

      await db.deleteObject<Project>(id);
    });
  });

  group('FirestoreDBInterface CRUD - Deliverable', () {
    test('create, get, update, delete', () async {
      const original = Deliverable(
        name: 'Test Deliverable',
        tasksIds: ['task1'],
        deadlineTs: 1234567890,
      );
      final id = await db.createAndSetObject(original);
      expect(id, isNotEmpty);

      final fetched = await db.getObject<Deliverable>(id);
      expect(fetched.name, original.name);
      expect(fetched.deadlineTs, original.deadlineTs);

      const updated = Deliverable(
        name: 'Updated Deliverable',
        tasksIds: ['task1', 'task2'],
        deadlineTs: 1234567900,
      );
      await db.updateObject(id, updated);
      final fetchedUpdated = await db.getObject<Deliverable>(id);
      expect(fetchedUpdated.name, updated.name);

      await db.deleteObject<Deliverable>(id);
    });
  });

  group('FirestoreDBInterface CRUD - Task', () {
    test('create, get, update, delete', () async {
      const original = Task(
        name: 'Test Task',
        sessionsIds: ['sess1'],
        taskStatus: TaskStatus.draft,
        outboundDependenciesIds: [],
      );
      final id = await db.createAndSetObject(original);
      expect(id, isNotEmpty);

      final fetched = await db.getObject<Task>(id);
      expect(fetched.name, original.name);
      expect(fetched.taskStatus, TaskStatus.draft);

      const updated = Task(
        name: 'Updated Task',
        sessionsIds: ['sess1', 'sess2'],
        taskStatus: TaskStatus.scheduled,
        outboundDependenciesIds: ['task2'],
      );
      await db.updateObject(id, updated);
      final fetchedUpdated = await db.getObject<Task>(id);
      expect(fetchedUpdated.taskStatus, TaskStatus.scheduled);

      await db.deleteObject<Task>(id);
    });
  });

  group('FirestoreDBInterface CRUD - Session', () {
    test('create, get, update, delete', () async {
      const original = Session(
        description: 'Test Session',
        scheduledTs: 1234567890,
        contextRequirement: ContextRequirement(
          focusLevel: 0.8,
          contiguousMinutesNeeded: 60,
          resourceTags: {'desk': true},
        ),
      );
      final id = await db.createAndSetObject(original);
      expect(id, isNotEmpty);

      final fetched = await db.getObject<Session>(id);
      expect(fetched.description, original.description);
      expect(fetched.contextRequirement.focusLevel, 0.8);

      const updated = Session(
        description: 'Updated Session',
        scheduledTs: 1234567900,
        contextRequirement: ContextRequirement(
          focusLevel: 0.9,
          contiguousMinutesNeeded: 90,
          resourceTags: {'desk': true, 'quiet': true},
        ),
      );
      await db.updateObject(id, updated);
      final fetchedUpdated = await db.getObject<Session>(id);
      expect(fetchedUpdated.contextRequirement.focusLevel, 0.9);

      await db.deleteObject<Session>(id);
    });
  });

  group('FirestoreDBInterface CRUD - ContextRequirement', () {
    test('create, get, update, delete', () async {
      const original = ContextRequirement(
        focusLevel: 0.8,
        contiguousMinutesNeeded: 60,
        resourceTags: {'desk': true},
      );
      final id = await db.createAndSetObject(original);
      expect(id, isNotEmpty);

      final fetched = await db.getObject<ContextRequirement>(id);
      expect(fetched.focusLevel, 0.8);

      const updated = ContextRequirement(
        focusLevel: 0.95,
        contiguousMinutesNeeded: 120,
        resourceTags: {'desk': true, 'monitor': true},
      );
      await db.updateObject(id, updated);
      final fetchedUpdated = await db.getObject<ContextRequirement>(id);
      expect(fetchedUpdated.focusLevel, 0.95);

      await db.deleteObject<ContextRequirement>(id);
    });
  });

  group('FirestoreDBInterface CRUD - Event', () {
    test('create, get, update, delete', () async {
      const original = Event(
        name: 'Test Event',
        description: 'Meeting',
        calendar: 'work',
        startTs: 1234567890,
        endTs: 1234571490,
        allDay: false,
        actualContext: ActualContext(
          focusLevel: 0.5,
          contiguousMinutesAvailable: 30,
          resourceTags: {'office': true},
        ),
      );
      final id = await db.createAndSetObject(original);
      expect(id, isNotEmpty);

      final fetched = await db.getObject<Event>(id);
      expect(fetched.name, original.name);
      expect(fetched.allDay, false);
      expect(fetched.actualContext.focusLevel, 0.5);

      const updated = Event(
        name: 'Updated Event',
        description: 'Updated Meeting',
        calendar: 'personal',
        startTs: 1234567900,
        endTs: 1234571500,
        allDay: true,
        actualContext: ActualContext(
          focusLevel: 0.7,
          contiguousMinutesAvailable: 60,
          resourceTags: {'home': true},
        ),
      );
      await db.updateObject(id, updated);
      final fetchedUpdated = await db.getObject<Event>(id);
      expect(fetchedUpdated.allDay, true);
      expect(fetchedUpdated.actualContext.focusLevel, 0.7);

      await db.deleteObject<Event>(id);
    });
  });

  group('FirestoreDBInterface CRUD - ActualContext', () {
    test('create, get, update, delete', () async {
      const original = ActualContext(
        focusLevel: 0.7,
        contiguousMinutesAvailable: 45,
        resourceTags: {'home': true},
      );
      final id = await db.createAndSetObject(original);
      expect(id, isNotEmpty);

      final fetched = await db.getObject<ActualContext>(id);
      expect(fetched.focusLevel, 0.7);

      const updated = ActualContext(
        focusLevel: null,
        contiguousMinutesAvailable: null,
        resourceTags: {},
      );
      await db.updateObject(id, updated);
      final fetchedUpdated = await db.getObject<ActualContext>(id);
      expect(fetchedUpdated.focusLevel, isNull);

      await db.deleteObject<ActualContext>(id);
    });
  });
}