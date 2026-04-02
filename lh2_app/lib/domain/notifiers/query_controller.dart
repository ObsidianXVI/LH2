/// Query controller for handling search queries on workspace content.
///
/// Stub implementation: simulates async query with mock results.
/// Future tasks will integrate with LH2API for real querying.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reference to an LH2 object for search results.
class LH2ObjectRef {
  final String id;
  final String name;

  const LH2ObjectRef(this.id, this.name);

  @override
  String toString() => name;
}

/// Abstract Syntax Tree for parsed queries.
class QueryAst {
  final String raw;

  const QueryAst(this.raw);
}

/// Parses a raw query string into a QueryAst.
QueryAst parseQuery(String raw) => QueryAst(raw);

/// Evaluates a QueryAst against cached LH2 objects.
/// Performs simple case-insensitive substring search on object names.
Future<List<LH2ObjectRef>> evaluateQuery(QueryAst ast) async {
  // Simulate async delay
  await Future.delayed(const Duration(seconds: 1));

  // Mock cached LH2 objects (placeholder for real cache integration)
  final allRefs = <LH2ObjectRef>[
    const LH2ObjectRef('pg-1', 'Alpha Project Group'),
    const LH2ObjectRef('p-1', 'Beta Project'),
    const LH2ObjectRef('d-1', 'Gamma Deliverable'),
    const LH2ObjectRef('t-1', 'Delta Task'),
    const LH2ObjectRef('s-1', 'Epsilon Session'),
    const LH2ObjectRef('cr-1', 'Zeta Context Requirement'),
    const LH2ObjectRef('e-1', 'Eta Event'),
    const LH2ObjectRef('ac-1', 'Theta Actual Context'),
    const LH2ObjectRef('pg-2', 'Omega Project Group'),
    const LH2ObjectRef('p-2', 'Sigma Project'),
  ];

  // Case-insensitive substring search
  final lowerQuery = ast.raw.toLowerCase();
  return allRefs
      .where((ref) => ref.name.toLowerCase().contains(lowerQuery))
      .toList();
}

/// Query state.
class QueryState {
  final List<LH2ObjectRef> results;
  final bool isLoading;
  final String? lastQuery;

  const QueryState({
    this.results = const <LH2ObjectRef>[],
    this.isLoading = false,
    this.lastQuery,
  });

  QueryState copyWith({
    List<LH2ObjectRef>? results,
    bool? isLoading,
    String? lastQuery,
  }) {
    return QueryState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      lastQuery: lastQuery ?? this.lastQuery,
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
    final results = await evaluateQuery(ast);

    state = state.copyWith(
      results: results,
      isLoading: false,
      lastQuery: query,
    );
  }

  /// Clears results.
  void clear() {
    state = const QueryState();
  }
}

/// Provider for [QueryController].
final queryControllerProvider =
    NotifierProvider<QueryController, QueryState>(
  QueryController.new,
);