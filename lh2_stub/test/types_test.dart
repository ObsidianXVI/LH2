import 'package:test/test.dart';
import 'package:lh2_stub/lh2_stub.dart';

void main() {
  group('LH2Object JSON round-trip tests', () {
    test('ProjectGroup', () {
      final original = ProjectGroup(
        name: 'Test Group',
        projectsIds: ['proj1', 'proj2'],
      );
      final json = original.toJson();
      final roundtrip = ProjectGroup.fromJson(json);
      expect(roundtrip.toJson(), equals(original.toJson()));
    });

    test('Project', () {
      final original = Project(
        name: 'Test Project',
        deliverablesIds: ['del1'],
        nonDeliverableTasksIds: ['task1'],
      );
      final json = original.toJson();
      final roundtrip = Project.fromJson(json);
      expect(roundtrip.toJson(), equals(original.toJson()));
    });

    test('Deliverable', () {
      final original = Deliverable(
        name: 'Test Deliverable',
        tasksIds: ['task1', 'task2'],
        deadlineTs: 1234567890,
      );
      final json = original.toJson();
      final roundtrip = Deliverable.fromJson(json);
      expect(roundtrip.toJson(), equals(original.toJson()));
    });

    test('Task', () {
      final original = Task(
        name: 'Test Task',
        sessionsIds: ['sess1'],
        taskStatus: TaskStatus.underway,
        outboundDependenciesIds: ['dep1'],
      );
      final json = original.toJson();
      final roundtrip = Task.fromJson(json);
      expect(roundtrip.toJson(), equals(original.toJson()));
    });

    test('ContextRequirement', () {
      final original = ContextRequirement(
        focusLevel: 0.8,
        contiguousMinutesNeeded: 60,
        resourceTags: {'quiet': true, 'computer': true},
      );
      final json = original.toJson();
      final roundtrip = ContextRequirement.fromJson(json);
      expect(roundtrip.toJson(), equals(original.toJson()));
    });

    test('Session', () {
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
      final json = original.toJson();
      final roundtrip = Session.fromJson(json);
      expect(roundtrip.toJson(), equals(original.toJson()));
    });

    test('ActualContext', () {
      final original = ActualContext(
        focusLevel: 0.7,
        contiguousMinutesAvailable: 45,
        resourceTags: {'quiet': true, 'computer': false},
      );
      final json = original.toJson();
      final roundtrip = ActualContext.fromJson(json);
      expect(roundtrip.toJson(), equals(original.toJson()));
    });

    test('Event', () {
      final ac = ActualContext(
        focusLevel: 0.9,
        contiguousMinutesAvailable: null,
        resourceTags: {'meeting': true},
      );
      final original = Event(
        name: 'Test Event',
        description: 'Test Description',
        calendar: 'personal',
        startTs: 1234567890,
        endTs: 1234567990,
        allDay: false,
        actualContext: ac,
      );
      final json = original.toJson();
      final roundtrip = Event.fromJson(json);
      expect(roundtrip.toJson(), equals(original.toJson()));
    });
  });
}