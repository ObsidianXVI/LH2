/// Query controller for handling search queries on workspace content.
///
/// Stub implementation: simulates async query with mock results.
/// Future tasks will integrate with LH2API for real querying.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_stub/lh2_stub.dart';
import 'canvas_controller.dart';

/// Reference to an LH2 object for search results.
class LH2ObjectRef {
  final String id;
  final String name;

  const LH2ObjectRef(this.id, this.name);

  @override
  String toString() => name;
}

/// Abstract Syntax Tree for parsed queries.
sealed class QueryNode {
  const QueryNode();
}

class TypeQueryNode extends QueryNode {
  final ObjectType type;
  const TypeQueryNode(this.type);
}

class StatusQueryNode extends QueryNode {
  final TaskStatus status;
  const StatusQueryNode(this.status);
}

class TextQueryNode extends QueryNode {
  final String text;
  const TextQueryNode(this.text);
}

class DateQueryNode extends QueryNode {
  final DateTime start;
  final DateTime end;
  const DateQueryNode(this.start, this.end);
}

class QueryAst {
  final List<QueryNode> nodes;
  final String raw;
  final List<String> errors;

  const QueryAst({
    required this.nodes,
    required this.raw,
    this.errors = const [],
  });
}

/// Parses a raw query string into a QueryAst.
QueryAst parseQuery(String raw) {
  final nodes = <QueryNode>[];
  final errors = <String>[];

  // Simple regex-based parser for the initial implementation
  final parts = _splitQuery(raw);

  for (final part in parts) {
    if (part.startsWith('type:')) {
      final typeStr = part.substring(5);
      try {
        final type = ObjectType.values.byName(typeStr);
        nodes.add(TypeQueryNode(type));
      } catch (_) {
        errors.add('Invalid type: $typeStr');
        nodes.add(TextQueryNode(part)); // Fallback to text
      }
    } else if (part.startsWith('status:')) {
      final statusStr = part.substring(7);
      try {
        final status = TaskStatus.values.byName(statusStr);
        nodes.add(StatusQueryNode(status));
      } catch (_) {
        errors.add('Invalid status: $statusStr');
        nodes.add(TextQueryNode(part)); // Fallback to text
      }
    } else if (part.startsWith('date:')) {
      final dateStr = part.substring(5);
      final range = _parseDateRange(dateStr);
      if (range != null) {
        nodes.add(DateQueryNode(range.$1, range.$2));
      } else {
        errors.add('Invalid date range: $dateStr');
        nodes.add(TextQueryNode(part)); // Fallback to text
      }
    } else {
      // Text or bare words
      var text = part;
      if (text.startsWith('"') && text.endsWith('"') && text.length >= 2) {
        text = text.substring(1, text.length - 1);
      }
      nodes.add(TextQueryNode(text));
    }
  }

  return QueryAst(nodes: nodes, raw: raw, errors: errors);
}

List<String> _splitQuery(String raw) {
  final parts = <String>[];
  final regex = RegExp(r'([^\s"]+|"[^"]*")');
  final matches = regex.allMatches(raw);
  for (final match in matches) {
    parts.add(match.group(0)!);
  }
  return parts;
}

(DateTime, DateTime)? _parseDateRange(String dateStr) {
  final rangeRegex = RegExp(r'^(\d{4}-\d{2}-\d{2})\.\.(\d{4}-\d{2}-\d{2})$');
  final match = rangeRegex.firstMatch(dateStr);
  if (match != null) {
    final start = DateTime.tryParse(match.group(1)!);
    final end = DateTime.tryParse(match.group(2)!);
    if (start != null && end != null) {
      return (start, end);
    }
  }
  return null;
}

/// Evaluates a QueryAst against cached LH2 objects.
///
/// Note: evaluation currently doesn't depend on Riverpod reads, but we keep a
/// handle so we can later read typed caches/providers. For testability we
/// accept any object (e.g. a [ProviderContainer] in tests).
Future<List<LH2ObjectRef>> evaluateQuery(QueryAst ast, Object ref) async {
  // In a real implementation, this would fetch all objects from caches
  // and apply the filters from ast.nodes.

  // For now, we simulate by getting all objects from the "mock" list
  // but applying the real filtering logic.

  final allObjects = await _fetchAllObjects(ref);

  var results = allObjects;

  for (final node in ast.nodes) {
    results = results.where((obj) {
      if (node is TypeQueryNode) {
        return obj.type == node.type;
      } else if (node is StatusQueryNode) {
        if (obj is Task) {
          return obj.taskStatus == node.status;
        }
        return false;
      } else if (node is TextQueryNode) {
        final name = _getObjectName(obj).toLowerCase();
        return name.contains(node.text.toLowerCase());
      } else if (node is DateQueryNode) {
        final timestamp = _getObjectTimestamp(obj);
        if (timestamp == null) return false;
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return date.isAfter(node.start.subtract(const Duration(seconds: 1))) &&
            date.isBefore(node.end.add(const Duration(days: 1)));
      }
      return true;
    }).toList();
  }

  // Stable ordering: by type then name
  results.sort((a, b) {
    final typeCompare = a.type.index.compareTo(b.type.index);
    if (typeCompare != 0) return typeCompare;
    return _getObjectName(a).compareTo(_getObjectName(b));
  });

  return results
      .map((obj) => LH2ObjectRef(_getObjectId(obj, ref), _getObjectName(obj)))
      .toList();
}

String _getObjectName(LH2Object obj) {
  if (obj is ProjectGroup) return obj.name;
  if (obj is Project) return obj.name;
  if (obj is Deliverable) return obj.name;
  if (obj is Task) return obj.name;
  if (obj is Session) return obj.description;
  if (obj is Event) return obj.name;
  return obj.type.name;
}

int? _getObjectTimestamp(LH2Object obj) {
  if (obj is Deliverable) return obj.deadlineTs;
  if (obj is Session) return obj.scheduledTs;
  if (obj is Event) return obj.startTs;
  return null;
}

// Helper to get ID - in a real app, LH2Object would have an 'id' field.
// Since it's missing in the stub, we have to map it or assume it's available.
// For the purpose of this task, we'll assume we can find it.
String _getObjectId(LH2Object obj, Object ref) {
  // This is a bit of a hack since ID is not in the model but in Firestore
  return 'id-${obj.hashCode}';
}

Future<List<LH2Object>> _fetchAllObjects(Object ref) async {
  // Mock fetching from all caches
  final results = <LH2Object>[
    const ProjectGroup(name: 'Alpha Project Group', projectsIds: []),
    const Project(
      name: 'Beta Project',
      deliverablesIds: [],
      nonDeliverableTasksIds: [],
    ),
    const Deliverable(
      name: 'Gamma Deliverable',
      tasksIds: [],
      deadlineTs: 1741017600000,
    ), // 2025-03-04
    const Task(
      name: 'Delta Task',
      sessionsIds: [],
      taskStatus: TaskStatus.underway,
      outboundDependenciesIds: [],
    ),
    const Session(
      description: 'Epsilon Session',
      scheduledTs: 1741017600000,
      contextRequirement: ContextRequirement(
        focusLevel: 1,
        contiguousMinutesNeeded: 30,
        resourceTags: {},
      ),
    ),
    const Event(
      name: 'Eta Event',
      description: '',
      calendar: '',
      startTs: 1741017600000,
      endTs: 1741021200000,
      allDay: false,
      actualContext: ActualContext(
        focusLevel: 1,
        contiguousMinutesAvailable: 60,
        resourceTags: {},
      ),
    ),
  ];
  return results;
}

/// Query state.
class QueryState {
  final List<LH2ObjectRef> results;
  final bool isLoading;
  final String? lastQuery;
  final bool hideResultsInView;

  const QueryState({
    this.results = const <LH2ObjectRef>[],
    this.isLoading = false,
    this.lastQuery,
    this.hideResultsInView = false,
  });

  QueryState copyWith({
    List<LH2ObjectRef>? results,
    bool? isLoading,
    String? lastQuery,
    bool? hideResultsInView,
  }) {
    return QueryState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      lastQuery: lastQuery ?? this.lastQuery,
      hideResultsInView: hideResultsInView ?? this.hideResultsInView,
    );
  }
}

/// Controller for query operations.
class QueryController extends Notifier<QueryState> {
  @override
  QueryState build() {
    return const QueryState();
  }

  /// Runs a query and updates results.
  ///
  /// Parses the query, evaluates it against cached objects,
  /// and updates the state with results.
  Future<void> runQuery(String query) async {
    state = state.copyWith(isLoading: true, lastQuery: query);

    final ast = parseQuery(query);
    final rawResults = await evaluateQuery(ast, ref);

    final canvasCtrl = ref.read(activeCanvasControllerProvider);
    List<LH2ObjectRef> filteredResults = rawResults;
    if (state.hideResultsInView) {
      final visibleIds = canvasCtrl.visibleObjectIds;
      filteredResults =
          rawResults.where((r) => !visibleIds.contains(r.id)).toList();
    }

    state = state.copyWith(
      results: filteredResults,
      isLoading: false,
      lastQuery: query,
    );
  }

  /// Clears results.
  void clear() {
    state = const QueryState();
  }

  /// Sets whether to hide results already in view.
  void setHideResultsInView(bool value) {
    state = state.copyWith(hideResultsInView: value);
  }
}

/// Provider for [QueryController].
final queryControllerProvider = NotifierProvider<QueryController, QueryState>(
  QueryController.new,
);
