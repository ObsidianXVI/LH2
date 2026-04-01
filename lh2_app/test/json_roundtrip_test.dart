/// Unit tests for JSON round-trip of each LH2Object.
import 'package:flutter_test/flutter_test.dart';
import 'package:lh2_stub/lh2_stub.dart';

void main() {
  group('LH2Object JSON round-trip', () {
    test('ProjectGroup', () {
      const original = ProjectGroup(
        name: 'Test Group',
        projectsIds: ['proj1', 'proj2'],
      );
      final json = original.toJson();
      final restored = ProjectGroup.fromJson(json);
      expect(restored.name, original.name);
      expect(restored.projectsIds, original.projectsIds);
    });

    test('Project', () {
      const original = Project(
        name: 'Test Project',
        deliverablesIds: ['del1', 'del2'],
        nonDeliverableTasksIds: ['task1'],
      );
      final json = original.toJson();
      final restored = Project.fromJson(json);
      expect(restored.name, original.name);
      expect(restored.deliverablesIds, original.deliverablesIds);
      expect(restored.nonDeliverableTasksIds, original.nonDeliverableTasksIds);
    });

    test('Deliverable', () {
      const original = Deliverable(
        name: 'Test Deliverable',
        tasksIds: ['task1', 'task2'],
        deadlineTs: 1234567890,
      );
      final json = original.toJson();
      final restored = Deliverable.fromJson(json);
      expect(restored.name, original.name);
      expect(restored.tasksIds, original.tasksIds);
      expect(restored.deadlineTs, original.deadlineTs);
    });

    test('Task', () {
      const original = Task(
        name: 'Test Task',
        sessionsIds: ['sess1'],
        taskStatus: TaskStatus.scheduled,
        outboundDependenciesIds: ['task2'],
      );
      final json = original.toJson();
      final restored = Task.fromJson(json);
      expect(restored.name, original.name);
      expect(restored.sessionsIds, original.sessionsIds);
      expect(restored.taskStatus, original.taskStatus);
      expect(restored.outboundDependenciesIds, original.outboundDependenciesIds);
    });

    test('Session', () {
      const original = Session(
        description: 'Test Session',
        scheduledTs: 1234567890,
        contextRequirement: ContextRequirement(
          focusLevel: 0.8,
          contiguousMinutesNeeded: 60,
          resourceTags: {'desk': true, 'quiet': false},
        ),
      );
      final json = original.toJson();
      final restored = Session.fromJson(json);
      expect(restored.description, original.description);
      expect(restored.scheduledTs, original.scheduledTs);
      expect(restored.contextRequirement.focusLevel,
          original.contextRequirement.focusLevel);
      expect(restored.contextRequirement.contiguousMinutesNeeded,
          original.contextRequirement.contiguousMinutesNeeded);
      expect(restored.contextRequirement.resourceTags,
          original.contextRequirement.resourceTags);
    });

    test('ContextRequirement', () {
      const original = ContextRequirement(
        focusLevel: 0.9,
        contiguousMinutesNeeded: 120,
        resourceTags: {'monitor': true},
      );
      final json = original.toJson();
      final restored = ContextRequirement.fromJson(json);
      expect(restored.focusLevel, original.focusLevel);
      expect(restored.contiguousMinutesNeeded,
          original.contiguousMinutesNeeded);
      expect(restored.resourceTags, original.resourceTags);
    });

    test('Event', () {
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
      final json = original.toJson();
      final restored = Event.fromJson(json);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.calendar, original.calendar);
      expect(restored.startTs, original.startTs);
      expect(restored.endTs, original.endTs);
      expect(restored.allDay, original.allDay);
      expect(restored.actualContext.focusLevel,
          original.actualContext.focusLevel);
      expect(restored.actualContext.contiguousMinutesAvailable,
          original.actualContext.contiguousMinutesAvailable);
      expect(restored.actualContext.resourceTags,
          original.actualContext.resourceTags);
    });

    test('ActualContext', () {
      const original = ActualContext(
        focusLevel: 0.7,
        contiguousMinutesAvailable: 45,
        resourceTags: {'home': true},
      );
      final json = original.toJson();
      final restored = ActualContext.fromJson(json);
      expect(restored.focusLevel, original.focusLevel);
      expect(restored.contiguousMinutesAvailable,
          original.contiguousMinutesAvailable);
      expect(restored.resourceTags, original.resourceTags);
    });

    test('ActualContext with null fields', () {
      const original = ActualContext(
        focusLevel: null,
        contiguousMinutesAvailable: null,
        resourceTags: {},
      );
      final json = original.toJson();
      final restored = ActualContext.fromJson(json);
      expect(restored.focusLevel, isNull);
      expect(restored.contiguousMinutesAvailable, isNull);
      expect(restored.resourceTags, isEmpty);
    });
  });
}