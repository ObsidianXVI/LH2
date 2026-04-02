import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../domain/notifiers/query_controller.dart';
import '../../ui/theme/tokens.dart';

/// Left sidebar overlay for query input and results.
class QueryOverlay extends ConsumerStatefulWidget {
  const QueryOverlay({super.key});

  @override
  ConsumerState<QueryOverlay> createState() => _QueryOverlayState();
}

class _QueryOverlayState extends ConsumerState<QueryOverlay> {
  final TextEditingController _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queryState = ref.watch(queryControllerProvider);

    return Container(
      width: double.infinity,
      color: LH2Colors.panel,
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(LH2Theme.spacing(2)),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade600,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: LH2Colors.textPrimary,
                  size: 20,
                ),
                SizedBox(width: LH2Theme.spacing(1)),
                Text(
                  'Query',
                  style: LH2Theme.nodeTitle,
                ),
              ],
            ),
          ),
          // Input
          Padding(
            padding: EdgeInsets.all(LH2Theme.spacing(2)),
            child: TextField(
              controller: _queryController,
              decoration: InputDecoration(
                hintText: 'Enter query and press Enter to run...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(LH2Theme.spacing(1)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: LH2Theme.spacing(2),
                  vertical: LH2Theme.spacing(1.5),
                ),
              ),
              onSubmitted: (query) {
                if (query.trim().isNotEmpty) {
                  ref
                      .read(queryControllerProvider.notifier)
                      .runQuery(query.trim());
                }
                _queryController.clear();
              },
              textInputAction: TextInputAction.search,
            ),
          ),
          // Results
          Expanded(
            child: queryState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : queryState.results.isEmpty
                    ? Center(
                        child: Text(
                          'Press Enter to run a query',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: queryState.results.length,
                        itemBuilder: (context, index) {
                          final result = queryState.results[index];
                          return Card(
                            margin: EdgeInsets.symmetric(
                              horizontal: LH2Theme.spacing(2),
                              vertical: LH2Theme.spacing(0.5),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(LH2Theme.spacing(2)),
                              child: Text(
                                result,
                                style: LH2Theme.body.copyWith(
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
