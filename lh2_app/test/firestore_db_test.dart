import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lh2_stub/lh2_stub.dart';
import 'package:lh2_app/data/firestore_db_interface.dart';

// These tests require Firebase platform channels + a running Firestore emulator.
// They are disabled by default for `flutter test` runs.
//
// To enable:
//   flutter test --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true test/firestore_db_test.dart
const bool runEmulatorTests =
    bool.fromEnvironment('RUN_FIREBASE_EMULATOR_TESTS', defaultValue: false);

void main() {
  late FirestoreDBInterface db;

  setUpAll(() async {
    if (!runEmulatorTests) return;

    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8081);
    db = FirestoreDBInterface(FirebaseFirestore.instance);
  });

  tearDown(() async {
    // Optional: clear specific docs if ids tracked, but since auto-id and delete, skip
  });

  group('FirestoreDBInterface CRUD integration tests (emulator)', () {
    test('ProjectGroup CRUD', () async {
      if (!runEmulatorTests) return;
      final original = ProjectGroup(
        name: 'Test PG',
        projectsIds: ['p1', 'p2'],
      );
      final id = await db.createAndSetObject(original);
      final got = await db.getObject<ProjectGroup>(id);
      expect(got.toJson(), original.toJson());

      final updated = ProjectGroup(
        name: 'Updated PG',
        projectsIds: ['p3'],
      );
      await db.updateObject(id, updated);
      final gotUpdated = await db.getObject<ProjectGroup>(id);
      expect(gotUpdated.toJson(), updated.toJson());

      await db.deleteObject<ProjectGroup>(id);
      expect(
        () async => await db.getObject<ProjectGroup>(id),
        throwsA(isA<FirebaseException>()),
      );
    });

    test('Project CRUD', () async {
      if (!runEmulatorTests) return;
      final original = Project(
        name: 'Test Project',
        deliverablesIds: ['d1'],
        nonDeliverableTasksIds: ['t1'],
      );
      final id = await db.createAndSetObject(original);
      final got = await db.getObject<Project>(id);
      expect(got.toJson(), original.toJson());

      final updated = Project(
        name: 'Updated Project',
        deliverablesIds: [],
        nonDeliverableTasksIds: ['t2'],
      );
      await db.updateObject(id, updated);
      final gotUpdated = await db.getObject<Project>(id);
      expect(gotUpdated.toJson(), updated.toJson());

      await db.deleteObject<Project>(id);
      expect(
        () async => await db.getObject<Project>(id),
        throwsA(isA<FirebaseException>()),
      );
    });

    test('Deliverable CRUD', () async {
      if (!runEmulatorTests) return;
      final original = Deliverable(
        name: 'Test Deliverable',
        tasksIds: ['t1', 't2'],
        deadlineTs: 1234567890,
      );
      final id = await db.createAndSetObject(original);
      final got = await db.getObject<Deliverable>(id);
      expect(got.toJson(), original.toJson());

      final updated = Deliverable(
        name: 'Updated Deliverable',
        tasksIds: ['t3'],
        deadlineTs: 1234567990,
      );
      await db.updateObject(id, updated);
      final gotUpdated = await db.getObject<Deliverable>(id);
      expect(gotUpdated.toJson(), updated.toJson());

      await db.deleteObject<Deliverable>(id);
      expect(
        () async => await db.getObject<Deliverable>(id),
        throwsA(isA<FirebaseException>()),
      );
    });

    test('Task CRUD', () async {
      if (!runEmulatorTests) return;
      final original = Task(
        name: 'Test Task',
        sessionsIds: ['s1'],
        taskStatus: TaskStatus.draft,
        outboundDependenciesIds: ['dep1'],
      );
      final id = await db.createAndSetObject(original);
      final got = await db.getObject<Task>(id);
      expect(got.toJson(), original.toJson());

      final updated = Task(
        name: 'Updated Task',
        sessionsIds: [],
        taskStatus: TaskStatus.done,
        outboundDependenciesIds: [],
      );
      await db.updateObject(id, updated);
      final gotUpdated = await db.getObject<Task>(id);
      expect(gotUpdated.toJson(), updated.toJson());

      await db.deleteObject<Task>(id);
      expect(
        () async => await db.getObject<Task>(id),
        throwsA(isA<FirebaseException>()),
      );
    });

    test('Session CRUD', () async {
      if (!runEmulatorTests) return;
      final cr = ContextRequirement(
        focusLevel: 0.8,
        contiguousMinutesNeeded: 60,
        resourceTags: {'quiet': true},
      );
      final original = Session(
        description: 'Test Session',
        scheduledTs: 1234567890,
        contextRequirement: cr,
      );
      final id = await db.createAndSetObject(original);
      final got = await db.getObject<Session>(id);
      expect(got.toJson(), original.toJson());

      final updatedCr = ContextRequirement(
        focusLevel: 0.9,
        contiguousMinutesNeeded: 90,
        resourceTags: {'quiet': true, 'tools': true},
      );
      final updated = Session(
        description: 'Updated Session',
        scheduledTs: 1234567990,
        contextRequirement: updatedCr,
      );
      await db.updateObject(id, updated);
      final gotUpdated = await db.getObject<Session>(id);
      expect(gotUpdated.toJson(), updated.toJson());

      await db.deleteObject<Session>(id);
      expect(
        () async => await db.getObject<Session>(id),
        throwsA(isA<FirebaseException>()),
      );
    });

    test('ContextRequirement CRUD', () async {
      if (!runEmulatorTests) return;
      final original = ContextRequirement(
        focusLevel: 0.8,
        contiguousMinutesNeeded: 60,
        resourceTags: {'quiet': true, 'computer': true},
      );
      final id = await db.createAndSetObject(original);
      final got = await db.getObject<ContextRequirement>(id);
      expect(got.toJson(), original.toJson());

      final updated = ContextRequirement(
        focusLevel: 1.0,
        contiguousMinutesNeeded: 120,
        resourceTags: {'focus': true},
      );
      await db.updateObject(id, updated);
      final gotUpdated = await db.getObject<ContextRequirement>(id);
      expect(gotUpdated.toJson(), updated.toJson());

      await db.deleteObject<ContextRequirement>(id);
      expect(
        () async => await db.getObject<ContextRequirement>(id),
        throwsA(isA<FirebaseException>()),
      );
    });

    test('Event CRUD', () async {
      if (!runEmulatorTests) return;
      final ac = ActualContext(
        focusLevel: 0.9,
        contiguousMinutesAvailable: 30,
        resourceTags: {'meeting': true},
      );
      final original = Event(
        name: 'Test Event',
        description: 'Test Desc',
        calendar: 'work',
        startTs: 1234567890,
        endTs: 1234567990,
        allDay: false,
        actualContext: ac,
      );
      final id = await db.createAndSetObject(original);
      final got = await db.getObject<Event>(id);
      expect(got.toJson(), original.toJson());

      final updatedAc = ActualContext(
        focusLevel: null,
        contiguousMinutesAvailable: null,
        resourceTags: {'call': true},
      );
      final updated = Event(
        name: 'Updated Event',
        description: 'Updated Desc',
        calendar: 'personal',
        startTs: 1234568890,
        endTs: 1234568990,
        allDay: true,
        actualContext: updatedAc,
      );
      await db.updateObject(id, updated);
      final gotUpdated = await db.getObject<Event>(id);
      expect(gotUpdated.toJson(), updated.toJson());

      await db.deleteObject<Event>(id);
      expect(
        () async => await db.getObject<Event>(id),
        throwsA(isA<FirebaseException>()),
      );
    });

    test('ActualContext CRUD', () async {
      if (!runEmulatorTests) return;
      final original = ActualContext(
        focusLevel: 0.7,
        contiguousMinutesAvailable: 45,
        resourceTags: {'quiet': true, 'computer': false},
      );
      final id = await db.createAndSetObject(original);
      final got = await db.getObject<ActualContext>(id);
      expect(got.toJson(), original.toJson());

      final updated = ActualContext(
        focusLevel: 0.5,
        contiguousMinutesAvailable: 20,
        resourceTags: {'noisy': true},
      );
      await db.updateObject(id, updated);
      final gotUpdated = await db.getObject<ActualContext>(id);
      expect(gotUpdated.toJson(), updated.toJson());

      await db.deleteObject<ActualContext>(id);
      expect(
        () async => await db.getObject<ActualContext>(id),
        throwsA(isA<FirebaseException>()),
      );
    });
  });
}
