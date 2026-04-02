/// Query controller for handling search queries on workspace content.
///
/// Stub implementation: simulates async query with mock results.
/// Future tasks will integrate with LH2API for real querying.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Query state.
class QueryState {
  final List<String> results;
  final bool isLoading;
  final String? lastQuery;

  const QueryState({
    this.results = const [],
    this.isLoading = false,
    this.lastQuery,
  });

  QueryState copyWith({
    List<String>? results,
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
  /// Stub: simulates 1s delay, returns mock results.
  Future<void> runQuery(String query) async {
    state = state.copyWith(isLoading: true, lastQuery: query);

    // Simulate async query
    await Future.delayed(const Duration(seconds: 1));

    final mockResults = [
      'Mock result 1 for "$query"',
      'Mock result 2 for "$query"',
      'Mock result 3 for "$query"',
    ];

    state = state.copyWith(
      results: mockResults,
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