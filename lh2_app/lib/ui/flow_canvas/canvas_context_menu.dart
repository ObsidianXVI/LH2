import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_app/data/workspace_repository.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';
import 'package:lh2_app/domain/operations/canvas.dart';
import 'package:lh2_app/domain/operations/core.dart';
import 'package:lh2_app/domain/operations/telemetry.dart';
import 'package:lh2_stub/lh2_stub.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../ui/theme/tokens.dart';
import '../info_popup_overlay.dart';
import 'canvas_provider.dart';
import 'demo_providers.dart';
import '../../domain/notifiers/info_popup_controller.dart';

/// Context menu for the flow canvas with "Add Node" and selection-aware actions.
class CanvasContextMenu extends ConsumerStatefulWidget {
  final Offset position;
  final VoidCallback onDismiss;
  final String workspaceId;
  final String tabId;
  final Offset worldPosition;
  final Set<String> selection;
  final FlowCanvasController controller;

  const CanvasContextMenu({
    super.key,
    required this.position,
    required this.onDismiss,
    required this.workspaceId,
    required this.tabId,
    required this.worldPosition,
    required this.selection,
    required this.controller,
  });

  @override
  ConsumerState<CanvasContextMenu> createState() => _CanvasContextMenuState();
}

class _CanvasContextMenuState extends ConsumerState<CanvasContextMenu> {
  String? _hoveredNodeType;
  // ignore: unused_field
  String? _hoveredTemplateId;
  Timer? _hoverTimer;
  Timer? _menuDismissTimer;
  static const Duration _hoverDelay = Duration(milliseconds: 100);
  static const Duration _menuDismissDelay = Duration(milliseconds: 500);

  Widget _buildMainMenu() {
    final bool hasSelection = widget.selection.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: LH2Colors.panel,
        border: Border.all(color: LH2Colors.border),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMenuItem(
            'Add Node',
            onHover: (hovering) {
              setState(() {
                _hoveredNodeType = hovering ? 'add_node' : null;
              });
            },
            onTap: () {},
            hasSubmenu: true,
          ),
          const Divider(height: 1, color: LH2Colors.border),
          _buildMenuItem(
            'Delete Selected',
            enabled: hasSelection,
            onHover: (_) {},
            onTap: hasSelection ? _deleteSelected : null,
          ),
          _buildMenuItem(
            'Clear Selection',
            enabled: hasSelection,
            onHover: (_) {},
            onTap: hasSelection ? _clearSelection : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    String text, {
    required Function(bool) onHover,
    VoidCallback? onTap,
    bool hasSubmenu = false,
    bool enabled = true,
  }) {
    return MouseRegion(
      onEnter: (_) {
        _hoverTimer?.cancel();
        _menuDismissTimer?.cancel();
        if (enabled) {
          _hoverTimer = Timer(_hoverDelay, () => onHover(true));
        }
      },
      onExit: (_) {
        _hoverTimer?.cancel();
      },
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: LH2Colors.panel,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: LH2Theme.body.copyWith(
                  color: enabled ? LH2Colors.textPrimary : LH2Colors.textSecondary,
                  fontSize: 14,
                ),
              ),
              if (hasSubmenu) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_right,
                  size: 16,
                  color: enabled ? LH2Colors.textSecondary : LH2Colors.textSecondary.withOpacity(0.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _clearSelection() {
    widget.controller.setSelection({});
    widget.onDismiss();
  }

  Future<void> _deleteSelected() async {
    try {
      final canvasRemoveItemsOp = ref.read(canvasRemoveItemsOpProvider);

      final input = CanvasRemoveItemsInput(
        workspaceId: widget.workspaceId,
        tabId: widget.tabId,
        itemIds: widget.selection.toList(),
      );

      final result = await canvasRemoveItemsOp.execute(input);

      if (result.ok) {
        widget.onDismiss();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted ${widget.selection.length} items')),
        );
      } else {
        throw result.error ??
            LH2OpError(
              operationId: 'api.canvas.removeItems',
              errorCode: 'UNKNOWN_ERROR',
              message: 'Unknown error deleting items',
              isFatal: true,
            );
      }
    } catch (e) {
      widget.onDismiss();
      Telemetry.warn(
        'ui.canvas.context_menu',
        'Failed to delete items: $e',
        stackTrace: StackTrace.current,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete items: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(CanvasContextMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position) {
      setState(() {
        _hoveredNodeType = null;
        _hoveredTemplateId = null;
      });
    }
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _menuDismissTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  Widget _buildNodeTypesMenu() {
    final nodeTypes = [
      ObjectType.project,
      ObjectType.deliverable,
      ObjectType.task,
      ObjectType.session,
      ObjectType.event,
      ObjectType.contextRequirement,
      ObjectType.actualContext,
    ];

    return Container(
      decoration: BoxDecoration(
        color: LH2Colors.panel,
        border: Border.all(color: LH2Colors.border),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: nodeTypes.map((type) {
          return _buildMenuItem(
            _formatObjectTypeName(type),
            onHover: (hovering) {
              setState(() {
                _hoveredNodeType = hovering ? type.name : null;
              });
            },
            onTap: () {},
            hasSubmenu: true,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTemplatesMenu(ObjectType nodeType) {
    return Consumer(
      builder: (context, ref, child) {
        final templatesAsync = ref
            .watch(demoNodeTemplatesProvider((widget.workspaceId, nodeType)));

        return templatesAsync.when(
          loading: () => Container(
            decoration: BoxDecoration(
              color: LH2Colors.panel,
              border: Border.all(color: LH2Colors.border),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.all(16),
            child: const CircularProgressIndicator(),
          ),
          error: (error, stack) {
            Telemetry.warn(
              'ui.canvas.context_menu',
              'Error loading templates: $error',
              stackTrace: stack,
            );
            return Container(
              decoration: BoxDecoration(
                color: LH2Colors.panel,
                border: Border.all(color: LH2Colors.border),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(16),
              child: Text('Error loading templates: $error'),
            );
          },
          data: (templates) {
            if (templates.isEmpty) {
              return Container(
                decoration: BoxDecoration(
                  color: LH2Colors.panel,
                  border: Border.all(color: LH2Colors.border),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No templates available',
                  style: LH2Theme.body.copyWith(
                    color: LH2Colors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: LH2Colors.panel,
                border: Border.all(color: LH2Colors.border),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: templates.map((template) {
                  return _buildMenuItem(
                    template.name,
                    onHover: (hovering) {
                      setState(() {
                        _hoveredTemplateId = hovering ? template.id : null;
                      });
                    },
                    onTap: () => _onTemplateSelected(template),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildMenuHierarchy() {
    final widgets = <Widget>[];

    widgets.add(
      Positioned(
        left: widget.position.dx,
        top: widget.position.dy,
        child: MouseRegion(
          onEnter: (_) {
            _menuDismissTimer?.cancel();
          },
          onExit: (_) {
            _menuDismissTimer?.cancel();
            _menuDismissTimer = Timer(_menuDismissDelay, () {
              if (mounted) {
                widget.onDismiss();
              }
            });
          },
          child: _buildMainMenu(),
        ),
      ),
    );

    if (_hoveredNodeType != null) {
      widgets.add(
        Positioned(
          left: widget.position.dx + 160,
          top: widget.position.dy,
          child: MouseRegion(
            onEnter: (_) {
              _menuDismissTimer?.cancel();
            },
            onExit: (_) {
              _menuDismissTimer?.cancel();
              _menuDismissTimer = Timer(_menuDismissDelay, () {
                if (mounted) {
                  widget.onDismiss();
                }
              });
            },
            child: _buildNodeTypesMenu(),
          ),
        ),
      );
    }

    if (_hoveredNodeType != null && _hoveredNodeType != 'add_node') {
      try {
        final nodeType = ObjectType.values.byName(_hoveredNodeType!);
        widgets.add(
          Positioned(
            left: widget.position.dx + 320,
            top: widget.position.dy,
            child: MouseRegion(
              onEnter: (_) {
                _menuDismissTimer?.cancel();
              },
              onExit: (_) {
                _menuDismissTimer?.cancel();
                _menuDismissTimer = Timer(_menuDismissDelay, () {
                  if (mounted) {
                    widget.onDismiss();
                  }
                });
              },
              child: _buildTemplatesMenu(nodeType),
            ),
          ),
        );
      } catch (e) {
        // Invalid node type, ignore
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onDismiss,
              onSecondaryTap: widget.onDismiss,
              child: Container(color: Colors.transparent),
            ),
          ),
          ..._buildMenuHierarchy(),
        ],
      ),
    );
  }

  String _formatObjectTypeName(ObjectType type) {
    return type.name
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Future<void> _onTemplateSelected(NodeTemplate template) async {
    try {
      final canvasAddItemOp = ref.read(canvasAddItemOpProvider);

      final worldRect = {
        'x': widget.worldPosition.dx - 60,
        'y': widget.worldPosition.dy - 40,
        'w': 120,
        'h': 80,
      };

      final input = CanvasAddItemInput(
        workspaceId: widget.workspaceId,
        tabId: widget.tabId,
        itemType: 'node',
        objectType: template.objectType,
        templateId: template.id,
        worldRect: worldRect,
      );

      final result = await canvasAddItemOp.execute(input);

      if (result.ok) {
        final itemId = result.value!.itemId;
        widget.onDismiss();

        final controller = ref.read(activeCanvasControllerProvider);
        if (controller != null) {
          final itemRectWorld = Rect.fromLTWH(
            worldRect['x'] as double,
            worldRect['y'] as double,
            worldRect['w'] as double,
            worldRect['h'] as double,
          );

          final topLeft = controller.worldToScreen(itemRectWorld.topLeft);
          final bottomRight =
              controller.worldToScreen(itemRectWorld.bottomRight);
          final screenRect = Rect.fromPoints(topLeft, bottomRight);

          ref.read(infoPopupControllerProvider.notifier).openAddMode(
                itemId: itemId,
                anchorScreenRect: screenRect,
                objectType: template.objectType,
                templateId: template.id,
              );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${template.name} node'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw result.error ??
            LH2OpError(
              operationId: 'api.canvas.addItem',
              errorCode: 'UNKNOWN_ERROR',
              message: 'Unknown error adding node',
              isFatal: true,
            );
      }
    } catch (e) {
      widget.onDismiss();

      if (e is LH2OpError) {
        Telemetry.error(e);
      } else {
        Telemetry.warn(
          'ui.canvas.context_menu',
          'Failed to add node: $e',
          stackTrace: StackTrace.current,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add node: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
