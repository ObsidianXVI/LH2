part of lh2.stub;

typedef JSON = Map<String, Object?>;

enum ObjectType {
  projectGroup,
  project,
  deliverable,
  task,
  session,
  event,
  contextRequirement,
  actualContext,
}

enum TaskStatus {
  draft,
  scheduled,
  underway,
  incomplete,
  done,
  adminAttentionNeeded,
}

enum RelationType {
  outboundDependency,
  labelledArrow,
  booleanDecisionPoint,
  multiDecisionPoint,
}

sealed class LH2Object {
  final ObjectType type;

  const LH2Object(this.type);

  JSON toJson();
}

class ProjectGroup extends LH2Object {
  final String name;
  final List<String> projectsIds;

  const ProjectGroup({
    required this.name,
    required this.projectsIds,
  }) : super(ObjectType.projectGroup);

  factory ProjectGroup.fromJson(JSON json) {
    return ProjectGroup(
      name: json['name'] as String,
      projectsIds: List<String>.from(json['projectsIds'] as List),
    );
  }

  @override
  JSON toJson() => {
    'type': type.name,
    'name': name,
    'projectsIds': projectsIds,
  };
}

class Project extends LH2Object {
  final String name;
  final List<String> deliverablesIds;
  final List<String> nonDeliverableTasksIds;

  const Project({
    required this.name,
    required this.deliverablesIds,
    required this.nonDeliverableTasksIds,
  }) : super(ObjectType.project);

  factory Project.fromJson(JSON json) {
    return Project(
      name: json['name'] as String,
      deliverablesIds: List<String>.from(json['deliverablesIds'] as List),
      nonDeliverableTasksIds: List<String>.from(
        json['nonDeliverableTasksIds'] as List,
      ),
    );
  }

  @override
  JSON toJson() => {
    'type': type.name,
    'name': name,
    'deliverablesIds': deliverablesIds,
    'nonDeliverableTasksIds': nonDeliverableTasksIds,
  };
}

class Deliverable extends LH2Object {
  final String name;
  final List<String> tasksIds;
  final int deadlineTs;

  const Deliverable({
    required this.name,
    required this.tasksIds,
    required this.deadlineTs,
  }) : super(ObjectType.deliverable);

  factory Deliverable.fromJson(JSON json) {
    return Deliverable(
      name: json['name'] as String,
      tasksIds: List<String>.from(json['tasksIds'] as List),
      deadlineTs: json['deadlineTs'] as int,
    );
  }

  @override
  JSON toJson() => {
    'type': type.name,
    'name': name,
    'tasksIds': tasksIds,
    'deadlineTs': deadlineTs,
  };
}

class Task extends LH2Object {
  final String name;
  final List<String> sessionsIds;
  final TaskStatus taskStatus;

  /// IDs of the [Task]s that depend on [this] to be completed
  final List<String> outboundDependenciesIds;

  const Task({
    required this.name,
    required this.sessionsIds,
    required this.taskStatus,
    required this.outboundDependenciesIds,
  }) : super(ObjectType.task);

  factory Task.fromJson(JSON json) {
    return Task(
      name: json['name'] as String,
      sessionsIds: List<String>.from(json['sessionsIds'] as List),
      taskStatus: TaskStatus.values.byName(json['taskStatus'] as String),
      outboundDependenciesIds: List<String>.from(
        json['outboundDependenciesIds'] as List,
      ),
    );
  }

  @override
  JSON toJson() => {
    'type': type.name,
    'name': name,
    'sessionsIds': sessionsIds,
    'taskStatus': taskStatus.name,
    'outboundDependenciesIds': outboundDependenciesIds,
  };
}

class Session extends LH2Object {
  final String description;
  final int scheduledTs;
  final ContextRequirement contextRequirement;

  const Session({
    required this.description,
    required this.scheduledTs,
    required this.contextRequirement,
  }) : super(ObjectType.session);

  factory Session.fromJson(JSON json) {
    return Session(
      description: json['description'] as String,
      scheduledTs: json['scheduledTs'] as int,
      contextRequirement: ContextRequirement.fromJson(
        json['contextRequirement'] as JSON,
      ),
    );
  }

  @override
  JSON toJson() => {
    'type': type.name,
    'description': description,
    'scheduledTs': scheduledTs,
    'contextRequirement': contextRequirement.toJson(),
  };
}

class ContextRequirement extends LH2Object {
  final double focusLevel;
  final int contiguousMinutesNeeded;
  final Map<String, bool> resourceTags;

  const ContextRequirement({
    required this.focusLevel,
    required this.contiguousMinutesNeeded,
    required this.resourceTags,
  }) : super(ObjectType.contextRequirement);

  factory ContextRequirement.fromJson(JSON json) {
    return ContextRequirement(
      focusLevel: (json['focusLevel'] as num).toDouble(),
      contiguousMinutesNeeded: json['contiguousMinutesNeeded'] as int,
      resourceTags: Map<String, bool>.from(json['resourceTags'] as Map),
    );
  }

  @override
  JSON toJson() => {
    'type': type.name,
    'focusLevel': focusLevel,
    'contiguousMinutesNeeded': contiguousMinutesNeeded,
    'resourceTags': resourceTags,
  };
}

class Event extends LH2Object {
  final String name;
  final String description;
  final String calendar;
  final int startTs;
  final int endTs;
  final bool allDay;
  final ActualContext actualContext;

  const Event({
    required this.name,
    required this.description,
    required this.calendar,
    required this.startTs,
    required this.endTs,
    required this.allDay,
    required this.actualContext,
  }) : super(ObjectType.event);

  factory Event.fromJson(JSON json) {
    return Event(
      name: json['name'] as String,
      description: json['description'] as String,
      calendar: json['calendar'] as String,
      startTs: json['startTs'] as int,
      endTs: json['endTs'] as int,
      allDay: json['allDay'] as bool,
      actualContext: ActualContext.fromJson(json['actualContext'] as JSON),
    );
  }

  @override
  JSON toJson() => {
    'type': type.name,
    'name': name,
    'description': description,
    'calendar': calendar,
    'startTs': startTs,
    'endTs': endTs,
    'allDay': allDay,
    'actualContext': actualContext.toJson(),
  };
}

class ActualContext extends LH2Object {
  final double? focusLevel;
  final int? contiguousMinutesAvailable;
  final Map<String, bool> resourceTags;

  const ActualContext({
    required this.focusLevel,
    required this.contiguousMinutesAvailable,
    required this.resourceTags,
  }) : super(ObjectType.actualContext);

  factory ActualContext.fromJson(JSON json) {
    return ActualContext(
      focusLevel: (json['focusLevel'] as num?)?.toDouble(),
      contiguousMinutesAvailable: json['contiguousMinutesAvailable'] as int?,
      resourceTags: Map<String, bool>.from(json['resourceTags'] as Map),
    );
  }

  @override
  JSON toJson() => {
    'type': type.name,
    'focusLevel': focusLevel,
    'contiguousMinutesAvailable': contiguousMinutesAvailable,
    'resourceTags': resourceTags,
  };
}

abstract class LH2Relation {
  final RelationType type;
  final List<String> targets;

  const LH2Relation(this.type, {required this.targets});

  JSON toJson();
}

class OutboundDependency extends LH2Relation {
  const OutboundDependency({required super.targets})
    : super(RelationType.outboundDependency);

  factory OutboundDependency.fromJson(JSON json) {
    return OutboundDependency(
      targets: List<String>.from(json['targets'] as List),
    );
  }

  @override
  JSON toJson() => {
    'type': type.name,
    'targets': targets,
  };
}

class LabelledArrow extends LH2Relation {
  final List<String> labels;

  const LabelledArrow({
    required this.labels,
    required super.targets,
  }) : super(RelationType.labelledArrow);

  factory LabelledArrow.fromJson(JSON json) {
    return LabelledArrow(
      labels: List<String>.from(json['labels'] as List),
      targets: List<String>.from(json['targets'] as List),
    );
  }

  @override
  JSON toJson() => {
    'type': type.name,
    'labels': labels,
    'targets': targets,
  };
}

/// Each target in [targets] will point to a key in [decisionTargets], which would be a label of a decision point.
class BooleanDecisionPoint extends LH2Relation {
  /// Each value in [decisionTargets] would point to a list: `[targetIdOfTrueOption, targetIdOfFalseOption]`
  final Map<String, List<String>> decisionTargets;

  const BooleanDecisionPoint({
    required this.decisionTargets,
    required super.targets,
  }) : super(RelationType.booleanDecisionPoint);

  factory BooleanDecisionPoint.fromJson(JSON json) {
    return BooleanDecisionPoint(
      decisionTargets: (json['decisionTargets'] as Map).map(
        (key, value) => MapEntry(
          key as String,
          List<String>.from(value as List),
        ),
      ),
      targets: List<String>.from(json['targets'] as List),
    );
  }

  @override
  JSON toJson() => {
    'type': type.name,
    'decisionTargets': decisionTargets,
    'targets': targets,
  };
}

/// Each target in [targets] will point to a key in [decisionTargets], which would be a label of a decision point.
class MultiDecisionPoint extends LH2Relation {
  /// Each value in [decisionTargets] would point to a map: `{labelOfOutcome: targetIdOfOption, ...}`
  final Map<String, Map<String, String>> decisionTargets;

  const MultiDecisionPoint({
    required this.decisionTargets,
    required super.targets,
  }) : super(RelationType.multiDecisionPoint);

  factory MultiDecisionPoint.fromJson(JSON json) {
    return MultiDecisionPoint(
      decisionTargets: (json['decisionTargets'] as Map).map(
        (key, value) => MapEntry(
          key as String,
          Map<String, String>.from(value as Map),
        ),
      ),
      targets: List<String>.from(json['targets'] as List),
    );
  }

  @override
  JSON toJson() => {
    'type': type.name,
    'decisionTargets': decisionTargets,
    'targets': targets,
  };
}
