import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../domain/notifiers/canvas_controller.dart';
import '../domain/notifiers/canvas_controller_impl.dart' as impl;
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
  int _selectedIndex = -1;
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inputFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _onEnterPressed() {
    final queryState = ref.read(queryControllerProvider);
    if (_selectedIndex >= 0 && _selectedIndex < queryState.results.length) {
      final selected = queryState.results[_selectedIndex];
      // Logic for selecting and focusing item on canvas
      final canvasCtrl = ref.read(activeCanvasControllerProvider);
      // In the current implementation, we need to handle the selection via the workspace state
      // or if the active controller supports it.
      // For now, we'll just print to console to verify the selection intent.
      debugPrint('Selecting item: ${selected.id}');
      // Additional logic to "focus" (e.g. pan viewport to item) could be added here
    } else {
      final query = _queryController.text.trim();
      if (query.isNotEmpty) {
        ref.read(queryControllerProvider.notifier).runQuery(query);
        setState(() {
          _selectedIndex = -1;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final queryState = ref.watch(queryControllerProvider);

    return Container(
      width: double.infinity,
      color: LH2Colors.panel,
      child: KeyboardListener(
        focusNode: FocusNode(), // Dummy focus node for listener
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              setState(() {
                _selectedIndex = (_selectedIndex + 1).clamp(-1, queryState.results.length - 1);
              });
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              setState(() {
                _selectedIndex = (_selectedIndex - 1).clamp(-1, queryState.results.length - 1);
              });
            } else if (event.logicalKey == LogicalKeyboardKey.enter) {
              _onEnterPressed();
            }
          }
        },
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
                  const Spacer(),
                  // Toggle with clear visual state
                  Row(
                    children: [
                      Text(
                        'Hide in view',
                        style: LH2Theme.body.copyWith(fontSize: 10),
                      ),
                      Switch(
                        value: queryState.hideResultsInView,
                        onChanged: (val) {
                          ref.read(queryControllerProvider.notifier).setHideResultsInView(val);
                        },
                        activeColor: LH2Colors.accentBlue,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Input
            Padding(
              padding: EdgeInsets.all(LH2Theme.spacing(2)),
              child: TextField(
                controller: _queryController,
                focusNode: _inputFocusNode,
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
                onSubmitted: (_) => _onEnterPressed(),
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
                            final isSelected = index == _selectedIndex;
                            return Card(
                              color: isSelected ? LH2Colors.selectionBlue.withOpacity(0.3) : null,
                              margin: EdgeInsets.symmetric(
                                horizontal: LH2Theme.spacing(2),
                                vertical: LH2Theme.spacing(0.5),
                              ),
                              shape: isSelected
                                  ? RoundedRectangleBorder(
                                      side: BorderSide(color: LH2Colors.selectionBlue, width: 2),
                                      borderRadius: BorderRadius.circular(LH2Theme.spacing(1)),
                                    )
                                  : null,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedIndex = index;
                                  });
                                  _onEnterPressed();
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(LH2Theme.spacing(2)),
                                  child: Text(
                                    result.toString(),
                                    style: LH2Theme.body.copyWith(
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
