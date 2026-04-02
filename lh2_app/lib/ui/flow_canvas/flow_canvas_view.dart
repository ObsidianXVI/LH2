import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';
import 'package:lh2_app/domain/notifiers/workspace_controller.dart';
import 'package:lh2_app/domain/operations/canvas.dart';
import 'package:lh2_app/domain/operations/core.dart';

import '../../ui/theme/tokens.dart';
import '../../data/workspace_repository.dart';
import 'grid_background_painter.dart';
import 'demo_items.dart';
import 'canvas_context_menu.dart';
import '../info_popup_overlay.dart';
import '../crosshair_overlay.dart';
import 'package:lh2_app/domain/notifiers/crosshair_mode_controller.dart';
import 'package:lh2_app/domain/notifiers/info_popup_controller.dart';
import '../../app/providers.dart';

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
  OverlayEntry? _contextMenuOverlay;
  String? _hoveredItemId;
  Timer? _hoverCloseTimer;

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

        return Listener(
          onPointerSignal: (PointerSignalEvent event) {
            if (event is PointerScrollEvent) {
              // Two-finger scroll panning (trackpad/mouse wheel).
              // Note: we intentionally pan in BOTH axes and do not require
              // pointer-down dragging, since pointer drag is reserved for
              // moving nodes/widgets.
              widget.controller.panBy(event.scrollDelta);
              // Trigger rebuild to update grid and items
              setState(() {});
            }
          },
          onPointerPanZoomUpdate: (PointerPanZoomUpdateEvent event) {
            // Trackpad pinch/2-finger gestures on desktop/web.
            // We handle these at the Listener level to avoid competing with
            // item drag gestures (child GestureDetectors) in the gesture arena.
            //
            // - pan: two-finger pan gesture
            // - scale: pinch-to-zoom
            if (event.panDelta != Offset.zero) {
              widget.controller.panBy(event.panDelta);
              // Trigger rebuild to update grid and items
              setState(() {});
            }
            if (event.scale != 1.0) {
              widget.controller.zoomAt(
                focalScreen: event.position,
                scaleDelta: event.scale,
              );
              // Trigger rebuild to update grid and items
              setState(() {});
            }
          },
          child: GestureDetector(
            // Keep taps/right-click, but remove scale handlers so node dragging
            // stays smooth.
            onTapUp: _handleTapUp,
            onSecondaryTapUp: _handleRightClick,
            behavior: HitTestBehavior.opaque,
            child: MouseRegion(
              cursor: SystemMouseCursors.basic,
              onHover: _handleHover,
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

                  // Information Popup
                  const InfoPopupOverlay(),

                  // Crosshair Overlay
                  const CrosshairOverlay(),

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
    final isSelected = widget.controller.selection.contains(itemId);

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
              color: isSelected ? LH2Colors.selectionBlue : LH2Colors.border,
              width: isSelected ? 2.0 : 1.0,
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

  void _handleTapUp(TapUpDetails details) {
    // Clear selection when clicking on empty space
    if (widget.controller.selection.isNotEmpty) {
      widget.controller.setSelection({});
    }
  }

  void _handleItemTap(String itemId) {
    final bool isShiftPressed = HardwareKeyboard.instance
            .isLogicalKeyPressed(LogicalKeyboardKey.shiftLeft) ||
        HardwareKeyboard.instance
            .isLogicalKeyPressed(LogicalKeyboardKey.shiftRight);
    final bool isMetaPressed = HardwareKeyboard.instance
            .isLogicalKeyPressed(LogicalKeyboardKey.metaLeft) ||
        HardwareKeyboard.instance
            .isLogicalKeyPressed(LogicalKeyboardKey.metaRight);
    final bool isControlPressed = HardwareKeyboard.instance
            .isLogicalKeyPressed(LogicalKeyboardKey.controlLeft) ||
        HardwareKeyboard.instance
            .isLogicalKeyPressed(LogicalKeyboardKey.controlRight);

    final bool isMultiSelectModifier =
        isShiftPressed && (isMetaPressed || isControlPressed);

    if (isMultiSelectModifier) {
      // Cmd+Shift+Select for multi-selection toggle
      final newSelection = Set<String>.from(widget.controller.selection);
      if (newSelection.contains(itemId)) {
        newSelection.remove(itemId);
      } else {
        newSelection.add(itemId);
      }
      widget.controller.setSelection(newSelection);
    } else {
      // Single selection
      widget.controller.setSelection({itemId});
    }
  }

  void _handleItemDragStart(String itemId, DragStartDetails details) {
    // No-op for now.
    // Dragging is handled incrementally in _handleItemDragUpdate using
    // DragUpdateDetails.delta for smooth realtime movement.
  }

  void _handleItemDragUpdate(String itemId, DragUpdateDetails details) {
    // Update in realtime by applying the incremental screen-space delta.
    //
    // NOTE: Do NOT use details.localPosition here because it's relative to the
    // item widget itself (which is moving), which can cause lag/jumps and make
    // the drag feel like it only updates on drag end.
    final item = widget.controller.items[itemId];
    if (item == null) return;

    final deltaWorld = details.delta / widget.controller.viewport.zoom;
    final newRect = item.worldRect.shift(deltaWorld);
    widget.controller.updateItemRect(itemId, newRect);

    // Trigger rebuild to show item movement in real-time
    setState(() {});

    // Debounce persistence to Firestore (high-frequency updates)
    _debounceItemPersistence(itemId, newRect);
  }

  Timer? _persistenceTimer;
  final Map<String, Rect> _pendingPersistence = {};

  void _debounceItemPersistence(String itemId, Rect newRect) {
    _pendingPersistence[itemId] = newRect;

    _persistenceTimer?.cancel();
    _persistenceTimer = Timer(const Duration(milliseconds: 500), () async {
      // Persist all pending changes to Firestore
      final workspaceState = ref.read(workspaceControllerProvider);
      final workspaceId = workspaceState.workspaceId;
      final tabId = workspaceState.activeTabId;

      if (workspaceId.isEmpty || tabId == null) {
        _pendingPersistence.clear();
        return;
      }

      try {
        // Build updated items map with new positions
        final updatedItems = Map<String, Object?>.from(widget.controller.items);
        for (final entry in _pendingPersistence.entries) {
          final itemId = entry.key;
          final newRect = entry.value;
          final item = widget.controller.items[itemId];

          if (item != null) {
            // Update the item's worldRect in the items map
            updatedItems[itemId] = {
              'schemaVersion': 1,
              'itemId': itemId,
              'itemType': item.itemType,
              'worldRect': {
                'x': newRect.left,
                'y': newRect.top,
                'w': newRect.width,
                'h': newRect.height,
              },
              'snap': {'startSnapped': false, 'endSnapped': false},
              if (item.objectId != null) 'objectId': item.objectId,
            };
          }
        }

        // Persist items to Firestore
        final workspaceRepo = ref.read(workspaceRepoProvider);
        await workspaceRepo.updateTab(
          workspaceId,
          tabId,
          WorkspaceTabPatch(items: updatedItems),
        );
      } catch (e) {
        // Log error but don't crash
        print('Error persisting item positions: $e');
      }

      _pendingPersistence.clear();
    });
  }

  // Scale gestures are intentionally handled via Listener's
  // onPointerPanZoomUpdate to avoid competing with item dragging.

  // Helper methods
  void _addDemoItems() {
    // Add demo items to the canvas for testing
    for (final demoItem in DemoCanvasItems.demoItems) {
      widget.controller.addItem(demoItem);
    }
  }

  void _handleRightClick(TapUpDetails details) {
    final crosshairState = ref.read(crosshairModeControllerProvider);
    if (crosshairState.enabled) return;

    // Remove any existing context menu
    _removeContextMenu();

    // Convert screen position to world position for node placement
    final worldPosition =
        widget.controller.screenToWorld(details.localPosition);

    // Get real workspace and tab IDs from the workspace controller
    final workspaceState = ref.read(workspaceControllerProvider);
    final workspaceId = workspaceState.workspaceId;
    final tabId = workspaceState.activeTabId;

    if (workspaceId.isEmpty || tabId == null) {
      // Cannot show context menu without a workspace or active tab
      return;
    }

    // If the right-click is over a node, and that node isn't selected,
    // select it first (exclusive selection unless modifiers are used, 
    // but right-click usually implies context for what's under it).
    String? hitItemId;
    for (final entry in widget.controller.items.entries.toList().reversed) {
      if (entry.value.worldRect.contains(worldPosition)) {
        hitItemId = entry.key;
        break;
      }
    }

    if (hitItemId != null && !widget.controller.selection.contains(hitItemId)) {
      widget.controller.setSelection({hitItemId});
    }

    // Create and show context menu
    _contextMenuOverlay = OverlayEntry(
      builder: (context) => CanvasContextMenu(
        position: details.globalPosition,
        worldPosition: worldPosition,
        workspaceId: workspaceId,
        tabId: tabId,
        selection: Set.from(widget.controller.selection),
        controller: widget.controller,
        onDismiss: _removeContextMenu,
      ),
    );

    Overlay.of(context).insert(_contextMenuOverlay!);
  }

  void _removeContextMenu() {
    _contextMenuOverlay?.remove();
    _contextMenuOverlay = null;
  }

  void _handleHover(PointerHoverEvent event) {
    final worldPos = widget.controller.screenToWorld(event.localPosition);
    String? hitItemId;
    CanvasItem? hitItem;
    for (final entry in widget.controller.items.entries.toList().reversed) {
      if (entry.value.worldRect.contains(worldPos)) {
        hitItemId = entry.key;
        hitItem = entry.value;
        break;
      }
    }

    final crosshairNotifier =
        ref.read(crosshairModeControllerProvider.notifier);
    final crosshairState = ref.read(crosshairModeControllerProvider);
    final infoController = ref.read(infoPopupControllerProvider.notifier);
    final infoState = ref.read(infoPopupControllerProvider);

    if (crosshairState.enabled) {
      crosshairNotifier.setHoveredItemId(hitItemId);
    } else {
      if (_hoveredItemId != hitItemId) {
        _hoveredItemId = hitItemId;
        if (hitItemId != null && hitItem != null) {
          _hoverCloseTimer?.cancel();
          // Calculate screen rect for the hit item
          final screenRect = _worldRectToScreen(hitItem.worldRect);
          infoController.openViewMode(
            itemId: hitItemId,
            anchorScreenRect: screenRect,
          );
        } else {
          // If we left a node, start a timer to close the popup,
          // unless the mouse is already over the popup.
          _hoverCloseTimer?.cancel();
          _hoverCloseTimer = Timer(const Duration(milliseconds: 300), () {
            final currentState = ref.read(infoPopupControllerProvider);
            if (!currentState.isHovered && _hoveredItemId == null) {
              infoController.close();
            }
          });
        }
      } else if (hitItemId == null) {
        // We are still not hovering any node, but we might have moved from node to gap.
        // If the popup is hovered, don't do anything.
        if (!infoState.isHovered &&
            infoState.isOpen &&
            _hoverCloseTimer == null) {
          _hoverCloseTimer = Timer(const Duration(milliseconds: 300), () {
            final currentState = ref.read(infoPopupControllerProvider);
            if (!currentState.isHovered && _hoveredItemId == null) {
              infoController.close();
            }
          });
        }
      } else {
        // Still hovering the same node, cancel any pending close timer.
        _hoverCloseTimer?.cancel();
        _hoverCloseTimer = null;
      }

      // If the popup is hovered, always cancel the timer.
      if (infoState.isHovered) {
        _hoverCloseTimer?.cancel();
        _hoverCloseTimer = null;
      }
    }
  }

  // ignore: unused_element
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
