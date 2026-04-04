import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';
import 'package:lh2_app/domain/notifiers/query_controller.dart';

class QueryBoardWidget extends ConsumerStatefulWidget {
  final String itemId;
  final CanvasController controller;

  const QueryBoardWidget({
    super.key,
    required this.itemId,
    required this.controller,
  });

  @override
  ConsumerState<QueryBoardWidget> createState() => _QueryBoardWidgetState();
}

class _QueryBoardWidgetState extends ConsumerState<QueryBoardWidget> {
  bool _editingTitle = false;
  late TextEditingController _titleController;
  late TextEditingController _queryController;

  @override
  void initState() {
    super.initState();
    final item = widget.controller.items[widget.itemId]!;
    final config = item.config ?? {};
    _titleController =
        TextEditingController(text: config['title'] ?? 'Query Board');
    _queryController = TextEditingController(text: config['queryText'] ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  void _updateTitle() {
    final item = widget.controller.items[widget.itemId]!;
    final newConfig = Map<String, dynamic>.from(item.config ?? {});
    newConfig['title'] = _titleController.text;
    widget.controller.updateItemConfig(widget.itemId, newConfig);
    setState(() {
      _editingTitle = false;
    });
  }

  void _updateQuery() {
    final item = widget.controller.items[widget.itemId]!;
    final newConfig = Map<String, dynamic>.from(item.config ?? {});
    newConfig['queryText'] = _queryController.text;
    widget.controller.updateItemConfig(widget.itemId, newConfig);
  }

  void _runQuery() {
    final query = _queryController.text;
    if (query.isNotEmpty) {
      ref.read(queryControllerProvider.notifier).runQuery(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.controller.items[widget.itemId]!;
    final config = item.config ?? {};
    final title = config['title'] as String? ?? 'Query Board';
    final hideResults = config['hideResultsInView'] as bool? ?? false;

    final queryState = ref.watch(queryControllerProvider);
    final results = queryState.results;
    final isLoading = queryState.isLoading;

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          // Header with title and edit button
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: _editingTitle
                      ? TextField(
                          controller: _titleController,
                          autofocus: true,
                          onSubmitted: (_) => _updateTitle(),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: Theme.of(context).textTheme.headlineSmall,
                        )
                      : GestureDetector(
                          onDoubleTap: () {
                            setState(() {
                              _editingTitle = true;
                            });
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _titleController.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: _titleController.text.length,
                              );
                            });
                          },
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Edit Query'),
                        content: TextField(
                          controller: _queryController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Enter query, e.g. type:task',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              _updateQuery();
                              _runQuery();
                              Navigator.pop(ctx);
                            },
                            child: const Text('Run'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Results area
          Expanded(
            child: hideResults
                ? const Center(child: Text('Results hidden'))
                : isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : results.isEmpty
                        ? const Center(child: Text('No results'))
                        : ListView.builder(
                            itemCount: results.length,
                            itemBuilder: (ctx, i) => ListTile(
                              title: Text(results[i].toString()),
                              dense: true,
                            ),
                          ),
          ),
          // Resize handle
          GestureDetector(
            onPanUpdate: (details) {
              final zoom = widget.controller.viewport.zoom;
              final deltaHeight = details.delta.dy / zoom;
              final newHeight =
                  math.max(100.0, item.worldRect.height + deltaHeight);
              final newRect = Rect.fromLTWH(
                item.worldRect.left,
                item.worldRect.top,
                item.worldRect.width,
                newHeight,
              );
              widget.controller.updateItemRect(widget.itemId, newRect);
              // Update config heightPx
              final newConfig = Map<String, dynamic>.from(config);
              newConfig['heightPx'] = newHeight.round();
              widget.controller.updateItemConfig(widget.itemId, newConfig);
            },
            child: Container(
              height: 8,
              color: Colors.grey,
              child: const Icon(Icons.drag_handle, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
