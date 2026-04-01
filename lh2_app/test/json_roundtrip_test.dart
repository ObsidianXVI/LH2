import 'package:flutter_test/flutter_test.dart';
import 'package:lh2_stub/lh2_stub.dart';

void main() {
  test('ProjectGroup JSON round-trip', () {
    const original = ProjectGroup(
      name: 'Test Group',
      projectsIds: ['proj1', 'proj2'],
    );
    final json = original.toJson();
    expect(json, equals({
      'type': 'projectGroup',
      'name': 'Test Group',
      'projectsIds': ['proj1', 'proj2'],
    }));
    
    final restored = ProjectGroup.fromJson(json);
    expect(restored.name, equals(original.name));
    expect(restored.projectsIds, equals(original.projectsIds));
  });

  test('Project JSON round-trip', () {
    const original = Project(
      name: 'Test Project',
      deliverablesIds: ['del1'],
      nonDeliverableTasksIds: ['task1'],
    );
    final json = original.toJson();
    final restored = Project.fromJson(json);
    expect(restored.name, equals(original.name));
    expect(restored.deliverablesIds, equals(original.deliverablesIds));
    expect(restored.nonDeliverableTasksIds, equals(original.nonDeliverableTasksIds));
  });

  test('Deliverable JSON round-trip', () {
    const original = Deliverable(
      name: 'Test Deliverable',
      tasksIds: ['task1'],
      deadlineTs: 1234567890,
    );
    final json = original.toJson();
    final restored = Deliverable.fromJson(json);
    expect(restored.name, equals(original.name));
    expect(restored.tasksIds, equals(original.tasksIds));
    expect(restored.deadlineTs, equals(original.deadlineTs));
  });

  test('Task JSON round-trip', () {
    const original = Task(
      name: 'Test Task',
      sessionsIds: ['sess1'],
      taskStatus: TaskStatus.scheduled,
      outboundDependenciesIds: ['task2'],
    );
    final json = original.toJson();
    final restored = Task.fromJson(json);
    expect(restored.name, equals(original.name));
    expect(restored.sessionsIds, equals(original.sessionsIds));
    expect(restored.taskStatus, equals(original.taskStatus));
    expect(restored.outboundDependenciesIds, equals(original.outboundDependenciesIds));
  });

  test('Session JSON round-trip', () {
    const original = Session(
      description: 'Test Session',
      scheduledTs: 1234567890,
      contextRequirement: ContextRequirement(
        focusLevel: 0.8,
        contiguousMinutesNeeded: 60,
        resourceTags: {'desk': true},
      ),
    );
    final json = original.toJson();
    final restored = Session.fromJson(json);
    expect(restored.description, equals(original.description));
    expect(restored.scheduledTs, equals(original.scheduledTs));
    expect(restored.contextRequirement.focusLevel, equals(0.8));
  });

  test('ContextRequirement JSON round-trip', () {
    const original = ContextRequirement(
      focusLevel: 0.9,
      contiguousMinutesNeeded: 120,
      resourceTags: {'monitor': true},
    );
    final json = original.toJson();
    final restored = ContextRequirement.fromJson(json);
    expect(restored.focusLevel, equals(0.9));
    expect(restored.contiguousMinutesNeeded, equals(120));
    expect(restored.resourceTags, equals({'monitor': true}));
  });

  test('Event JSON round-trip', () {
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
    expect(restored.name, equals(original.name));
    expect(restored.allDay, equals(false));
    expect(restored.actualContext.focusLevel, equals(0.5));
  });

  test('ActualContext JSON round-trip', () {
    const original = ActualContext(
      focusLevel: 0.7,
      contiguousMinutesAvailable: 45,
      resourceTags: {'home': true},
    );
    final json = original.toJson();
    final restored = ActualContext.fromJson(json);
    expect(restored.focusLevel, equals(0.7));
    expect(restored.contiguousMinutesAvailable, equals(45));
    expect(restored.resourceTags, equals({'home': true}));
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
}
