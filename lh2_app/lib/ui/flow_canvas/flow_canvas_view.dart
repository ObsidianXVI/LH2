import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';

import '../../ui/theme/tokens.dart';
import 'grid_background_painter.dart';
import 'demo_items.dart';
import 'canvas_context_menu.dart';

/// Flow Canvas widget that renders an infinite scroll canvas with grid background,
/// pan/zoom interactions, and draggable items.
class FlowCanvasView extends ConsumerStatefulWidget {
  final FlowCanvasController controller;

  const FlowCanvasView({
    super.key,
    required this.controller,
  });

  @override
  ConsumerState<FlowCanvasView> createState() => _FlowCanvasViewState();
}

class _FlowCanvasViewState extends ConsumerState<FlowCanvasView> {
  late Offset _lastPanPosition;
  bool _isPanning = false;
  final Set<String> _selectedItems = {};
  OverlayEntry? _contextMenuOverlay;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _removeContextMenu();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Update viewport size in controller
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        _updateViewportSize(viewportSize);

        return GestureDetector(
          onScaleStart: _handleScaleStart,
          onScaleUpdate: _handleScaleUpdate,
          onTapUp: _handleTapUp,
          onSecondaryTapUp: _handleRightClick,
          child: MouseRegion(
            cursor: _isPanning ? SystemMouseCursors.grabbing : SystemMouseCursors.basic,
            child: Stack(
              children: [
                // Grid background
                CustomPaint(
                  painter: GridBackgroundPainter(
                    pan: widget.controller.viewport.pan,
                    zoom: widget.controller.viewport.zoom,
                    gridSizePx: widget.controller.gridSizePx,
                    viewportSize: viewportSize,
                  ),
                  size: viewportSize,
                ),
                
                // Canvas items layer
                _buildItemsLayer(),
                
                // Selection overlay
                _buildSelectionOverlay(),
                
                // Add demo items button
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    onPressed: _addDemoItems,
                    backgroundColor: LH2Colors.accentBlue,
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateViewportSize(Size size) {
    final currentViewport = widget.controller.viewport;
    if (currentViewport.viewportSizePx != size) {
      // This would need to be implemented in the controller
      // For now, we'll work with the existing viewport
    }
  }

  Widget _buildItemsLayer() {
    return Stack(
      children: [
        for (final entry in widget.controller.items.entries)
          _buildCanvasItem(entry.key, entry.value),
      ],
    );
  }

  Widget _buildCanvasItem(String itemId, CanvasItem item) {
    final screenRect = _worldRectToScreen(item.worldRect);
    
    return Positioned(
      left: screenRect.left,
      top: screenRect.top,
      width: screenRect.width,
      height: screenRect.height,
      child: GestureDetector(
        onPanStart: (details) => _handleItemDragStart(itemId, details),
        onPanUpdate: (details) => _handleItemDragUpdate(itemId, details),
        onTap: () => _handleItemTap(itemId),
        child: Container(
          decoration: BoxDecoration(
            color: LH2Colors.panel,
            border: Border.all(
              color: _selectedItems.contains(itemId) 
                  ? LH2Colors.selectionBlue 
                  : LH2Colors.border,
              width: _selectedItems.contains(itemId) ? 2.0 : 1.0,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              item.itemType,
              style: const TextStyle(
                color: LH2Colors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionOverlay() {
    // This could be expanded to show selection rectangles, etc.
    return const SizedBox.shrink();
  }

  // Interaction handlers
  void _handlePanStart(DragStartDetails details) {
    setState(() {
      _isPanning = true;
      _lastPanPosition = details.localPosition;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isPanning) return;
    
    final delta = details.localPosition - _lastPanPosition;
    _panBy(delta);
    
    setState(() {
      _lastPanPosition = details.localPosition;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _isPanning = false;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    // Clear selection when clicking on empty space
    if (_selectedItems.isNotEmpty) {
      setState(() {
        _selectedItems.clear();
      });
      widget.controller.setSelection({});
    }
  }

  void _handleItemTap(String itemId) {
    setState(() {
      if (HardwareKeyboard.instance.isShiftPressed &&
          HardwareKeyboard.instance.isControlPressed) {
        // Cmd+Shift+Select for multi-selection
        if (_selectedItems.contains(itemId)) {
          _selectedItems.remove(itemId);
        } else {
          _selectedItems.add(itemId);
        }
      } else {
        // Single selection
        _selectedItems.clear();
        _selectedItems.add(itemId);
      }
    });
    widget.controller.setSelection(_selectedItems);
  }

  void _handleItemDragStart(String itemId, DragStartDetails details) {
    // Could implement drag start logic here
  }

  void _handleItemDragUpdate(String itemId, DragUpdateDetails details) {
    final deltaWorld = details.delta / widget.controller.viewport.zoom;
    final item = widget.controller.items[itemId];
    
    if (item != null) {
      final newRect = item.worldRect.shift(deltaWorld);
      widget.controller.updateItemRect(itemId, newRect);
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _lastPanPosition = details.localFocalPoint;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    // Handle panning
    if (details.scale == 1.0 && details.focalPointDelta != Offset.zero) {
      _panBy(details.focalPointDelta);
    }
    
    // Handle zooming
    if (details.scale != 1.0) {
      _zoomAt(details.localFocalPoint, details.scale);
    }
  }

  // Helper methods
  void _addDemoItems() {
    // Add demo items to the canvas for testing
    for (final demoItem in DemoCanvasItems.demoItems) {
      widget.controller.addItem(demoItem);
    }
  }

  void _handleRightClick(TapUpDetails details) {
    // Remove any existing context menu
    _removeContextMenu();

    // Convert screen position to world position for node placement
    final worldPosition = widget.controller.screenToWorld(details.localPosition);

    // Get workspace and tab IDs (these would come from providers in a real app)
    final workspaceId = 'demo-workspace'; // TODO: Get from provider
    final tabId = 'demo-tab'; // TODO: Get from provider

    // Create and show context menu
    _contextMenuOverlay = OverlayEntry(
      builder: (context) => CanvasContextMenu(
        position: details.globalPosition,
        worldPosition: worldPosition,
        workspaceId: workspaceId,
        tabId: tabId,
        onDismiss: _removeContextMenu,
      ),
    );

    Overlay.of(context).insert(_contextMenuOverlay!);
  }

  void _removeContextMenu() {
    _contextMenuOverlay?.remove();
    _contextMenuOverlay = null;
  }

  void _panBy(Offset deltaScreen) {
    widget.controller.panBy(deltaScreen);
  }

  void _zoomAt(Offset focalScreen, double scaleDelta) {
    widget.controller.zoomAt(focalScreen: focalScreen, scaleDelta: scaleDelta);
  }

  Rect _worldRectToScreen(Rect worldRect) {
    final topLeft = _worldToScreen(worldRect.topLeft);
    final bottomRight = _worldToScreen(worldRect.bottomRight);
    
    return Rect.fromPoints(topLeft, bottomRight);
  }

  Offset _worldToScreen(Offset worldPos) {
    return widget.controller.worldToScreen(worldPos);
  }
}