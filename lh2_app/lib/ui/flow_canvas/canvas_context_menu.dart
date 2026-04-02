import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_app/data/workspace_repository.dart';
import 'package:lh2_app/domain/operations/canvas.dart';
import 'package:lh2_app/domain/operations/core.dart';
import 'package:lh2_stub/lh2_stub.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../ui/theme/tokens.dart';
import 'demo_providers.dart';

/// Context menu for the flow canvas with "Add Node" functionality
class CanvasContextMenu extends ConsumerStatefulWidget {
  final Offset position;
  final VoidCallback onDismiss;
  final String workspaceId;
  final String tabId;
  final Offset worldPosition;

  const CanvasContextMenu({
    super.key,
    required this.position,
    required this.onDismiss,
    required this.workspaceId,
    required this.tabId,
    required this.worldPosition,
  });

  @override
  ConsumerState<CanvasContextMenu> createState() => _CanvasContextMenuState();
}

class _CanvasContextMenuState extends ConsumerState<CanvasContextMenu> {
  String? _hoveredNodeType;
  String? _hoveredTemplateId;
  Timer? _hoverTimer;
  Timer? _menuDismissTimer;
  static const Duration _hoverDelay = Duration(milliseconds: 100);
  static const Duration _menuDismissDelay = Duration(milliseconds: 500);

  Widget _buildMainMenu() {
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
            onTap: () {
              // Don't dismiss on tap, let hover handle submenu
            },
          ),
          // Add more context menu items here as needed
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    String text, {
    required Function(bool) onHover,
    VoidCallback? onTap,
    bool hasSubmenu = false,
  }) {
    return MouseRegion(
      onEnter: (_) {
        _hoverTimer?.cancel();
        _menuDismissTimer?.cancel();
        _hoverTimer = Timer(_hoverDelay, () => onHover(true));
      },
      onExit: (_) {
        _hoverTimer?.cancel();
        // Do not reset hover state here, let level MouseRegion handle dismissal
      },
      child: GestureDetector(
        onTap: onTap,
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
                  color: LH2Colors.textPrimary,
                  fontSize: 14,
                ),
              ),
              if (hasSubmenu) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_right,
                  size: 16,
                  color: LH2Colors.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(CanvasContextMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset hover state when menu position changes
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
    // Build submenu structure when hovering starts
  }

  // Build the node types submenu
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
            onTap: () {
              // Don't dismiss, let template submenu show
            },
            hasSubmenu: true,
          );
        }).toList(),
      ),
    );
  }

  // Build the templates submenu for a specific node type
  Widget _buildTemplatesMenu(ObjectType nodeType) {
    return Consumer(
      builder: (context, ref, child) {
        // Use demo provider for testing - in production this would use the real provider
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
          error: (error, stack) => Container(
            decoration: BoxDecoration(
              color: LH2Colors.panel,
              border: Border.all(color: LH2Colors.border),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.all(16),
            child: Text('Error loading templates: $error'),
          ),
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

  // Get the complete menu structure with submenus
  List<Widget> _buildMenuHierarchy() {
    final widgets = <Widget>[];

    // Main menu with hover protection
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

    // Node types submenu - visible if 'Add Node' or any node type is hovered
    if (_hoveredNodeType != null) {
      widgets.add(
        Positioned(
          left: widget.position.dx + 100, // Reduced offset for closer spacing
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

    // Templates submenu - closer spacing with hover protection
    if (_hoveredNodeType != null && _hoveredNodeType != 'add_node') {
      try {
        final nodeType = ObjectType.values.byName(_hoveredNodeType!);
        widgets.add(
          Positioned(
            left: widget.position.dx + 200, // Reduced offset for closer spacing
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
          // Background overlay to catch clicks outside
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onDismiss,
              child: Container(color: Colors.transparent),
            ),
          ),

          // Menu hierarchy
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
      // Create a new canvas item using the template
      final canvasAddItemOp = ref.read(canvasAddItemOpProvider);

      // Calculate world rect for the new item (centered on right-click position)
      final worldRect = {
        'x': widget.worldPosition.dx - 60, // Center the 120x80 item
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
        widget.onDismiss();

        // TODO: Open Information Popup in "Adding Information" mode
        // This will be implemented when the Information Popup is available
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${template.name} node'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw result.error ?? Exception('Unknown error');
      }
    } catch (e) {
      widget.onDismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add node: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Provider for watching node templates by type
final nodeTemplatesProvider =
    StreamProvider.family<List<NodeTemplate>, (String, ObjectType)>(
        (ref, params) {
  final (workspaceId, objectType) = params;
  final workspaceRepo = ref.watch(workspaceRepoProvider);
  return workspaceRepo.watchNodeTemplates(workspaceId, objectType);
});

/// Demo provider for testing - uses mock templates
final demoNodeTemplatesProvider =
    StreamProvider.family<List<NodeTemplate>, (String, ObjectType)>(
        (ref, params) {
  final (workspaceId, objectType) = params;

  // For demo purposes, return mock templates
  final allTemplates = [
    NodeTemplate(
      schemaVersion: 1,
      id: '${objectType.name}-basic',
      objectType: objectType,
      name: 'Basic ${objectType.name}',
      renderSpec: {'color': '#4CAF50', 'icon': 'folder'},
    ),
    NodeTemplate(
      schemaVersion: 1,
      id: '${objectType.name}-advanced',
      objectType: objectType,
      name: 'Advanced ${objectType.name}',
      renderSpec: {'color': '#2196F3', 'icon': 'work'},
    ),
  ];

  return Stream.value(allTemplates);
});
