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
import 'package:lh2_app/domain/notifiers/marquee_selection_controller.dart';
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
    return Focus(
      autofocus: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        final marqueeNotifier =
            ref.read(marqueeSelectionControllerProvider.notifier);
        if (event.logicalKey == LogicalKeyboardKey.altLeft ||
            event.logicalKey == LogicalKeyboardKey.altRight) {
          if (event is KeyDownEvent || event is KeyRepeatEvent) {
            marqueeNotifier.enterMarqueeMode();
          } else if (event is KeyUpEvent) {
            marqueeNotifier.exitMarqueeMode();
          }
          setState(() {});
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Update viewport size in controller
          final viewportSize =
              Size(constraints.maxWidth, constraints.maxHeight);
          _updateViewportSize(viewportSize);

          return Listener(
            onPointerSignal: (PointerSignalEvent event) {
              if (event is PointerScrollEvent) {
                widget.controller.panBy(event.scrollDelta);
                setState(() {});
              }
            },
            onPointerPanZoomUpdate: (PointerPanZoomUpdateEvent event) {
              if (event.panDelta != Offset.zero) {
                widget.controller.panBy(event.panDelta);
                setState(() {});
              }
              if (event.scale != 1.0) {
                widget.controller.zoomAt(
                  focalScreen: event.position,
                  scaleDelta: event.scale,
                );
                setState(() {});
              }
            },
            child: GestureDetector(
              onTapUp: _handleTapUp,
              onSecondaryTapUp: _handleRightClick,
              onPanStart: _handlePanStart,
              onPanUpdate: _handlePanUpdate,
              onPanEnd: _handlePanEnd,
              behavior: HitTestBehavior.opaque,
              child: MouseRegion(
                cursor: ref.watch(marqueeSelectionControllerProvider).enabled
                    ? SystemMouseCursors.precise
                    : SystemMouseCursors.basic,
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

                    // Marquee selection rectangle (highest in stack)
                    _buildMarqueeOverlay(),

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
      ),
    );
  }

  void _updateViewportSize(Size size) {
    final currentViewport = widget.controller.viewport;
    if (currentViewport.viewportSizePx != size) {
      widget.controller.setViewportSize(size);
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
    return const SizedBox.shrink();
  }

  Widget _buildMarqueeOverlay() {
    final marqueeState = ref.watch(marqueeSelectionControllerProvider);
    if (!marqueeState.enabled || !marqueeState.isDragging) {
      return const SizedBox.shrink();
    }

    final worldRect = marqueeState.worldRect!;
    final screenRect = _worldRectToScreen(worldRect);

    return Positioned.fromRect(
      rect: screenRect,
      child: Container(
        decoration: BoxDecoration(
          color: LH2Colors.selectionBlue.withOpacity(0.15),
          border: Border.all(color: LH2Colors.selectionBlue, width: 1),
        ),
      ),
    );
  }

  // Interaction handlers

  void _handleTapUp(TapUpDetails details) {
    // Only clear selection if we tapped the actual background,
    // not just the widget area (which includes items).
    // In Flutter, onTapUp on a parent background detector often triggers 
    // even if a child detector also triggered, unless we hit-test.
    
    final worldPos = widget.controller.screenToWorld(details.localPosition);
    bool hitItem = false;
    for (final item in widget.controller.items.values) {
      if (item.worldRect.contains(worldPos)) {
        hitItem = true;
        break;
      }
    }

    if (!hitItem && widget.controller.selection.isNotEmpty) {
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
        isShiftPressed || isMetaPressed || isControlPressed;

    if (isMultiSelectModifier) {
      final newSelection = Set<String>.from(widget.controller.selection);
      if (newSelection.contains(itemId)) {
        newSelection.remove(itemId);
      } else {
        newSelection.add(itemId);
      }
      widget.controller.setSelection(newSelection);
    } else {
      widget.controller.setSelection({itemId});
    }
  }

  void _handleItemDragStart(String itemId, DragStartDetails details) {
    ref.read(infoPopupControllerProvider.notifier).close();
    _hoverCloseTimer?.cancel();
    _hoverCloseTimer = null;
  }

  void _handleItemDragUpdate(String itemId, DragUpdateDetails details) {
    final item = widget.controller.items[itemId];
    if (item == null) return;

    final deltaWorld = details.delta / widget.controller.viewport.zoom;
    final newRect = item.worldRect.shift(deltaWorld);
    widget.controller.updateItemRect(itemId, newRect);

    setState(() {});
    _debounceItemPersistence(itemId, newRect);
  }

  Timer? _persistenceTimer;
  final Map<String, Rect> _pendingPersistence = {};

  void _debounceItemPersistence(String itemId, Rect newRect) {
    _pendingPersistence[itemId] = newRect;

    _persistenceTimer?.cancel();
    _persistenceTimer = Timer(const Duration(milliseconds: 500), () async {
      final workspaceState = ref.read(workspaceControllerProvider);
      final workspaceId = workspaceState.workspaceId;
      final tabId = workspaceState.activeTabId;

      if (workspaceId.isEmpty || tabId == null) {
        _pendingPersistence.clear();
        return;
      }

      try {
        final updatedItems = Map<String, Object?>.from(widget.controller.items);
        for (final entry in _pendingPersistence.entries) {
          final itemId = entry.key;
          final newRect = entry.value;
          final item = widget.controller.items[itemId];

          if (item != null) {
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

        final workspaceRepo = ref.read(workspaceRepoProvider);
        await workspaceRepo.updateTab(
          workspaceId,
          tabId,
          WorkspaceTabPatch(items: updatedItems),
        );
      } catch (e) {
        print('Error persisting item positions: $e');
      }

      _pendingPersistence.clear();
    });
  }

  void _addDemoItems() {
    for (final demoItem in DemoCanvasItems.demoItems) {
      widget.controller.addItem(demoItem);
    }
  }

  void _handleRightClick(TapUpDetails details) {
    final crosshairState = ref.read(crosshairModeControllerProvider);
    if (crosshairState.enabled) return;

    _removeContextMenu();

    final worldPosition =
        widget.controller.screenToWorld(details.localPosition);

    final workspaceState = ref.read(workspaceControllerProvider);
    final workspaceId = workspaceState.workspaceId;
    final tabId = workspaceState.activeTabId;

    if (workspaceId.isEmpty || tabId == null) {
      return;
    }

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

  void _handlePanStart(DragStartDetails details) {
    final marqueeNotifier =
        ref.read(marqueeSelectionControllerProvider.notifier);
    final marqueeState = ref.read(marqueeSelectionControllerProvider);

    if (marqueeState.enabled) {
      final worldPoint = widget.controller.screenToWorld(details.localPosition);
      marqueeNotifier.startDragging(worldPoint);
      setState(() {});
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final marqueeNotifier =
        ref.read(marqueeSelectionControllerProvider.notifier);
    final marqueeState = ref.read(marqueeSelectionControllerProvider);

    if (marqueeState.enabled && marqueeState.startWorldPoint != null) {
      final worldPoint = widget.controller.screenToWorld(details.localPosition);
      marqueeNotifier.updateDragging(worldPoint);
      setState(() {});

      final marqueeRect =
          Rect.fromPoints(marqueeState.startWorldPoint!, worldPoint);
      final newSelection = <String>{};
      for (final entry in widget.controller.items.entries) {
        // Use Rect.overlaps or Rect.contains depending on desired behavior.
        // overlaps() is standard for marquee.
        if (marqueeRect.overlaps(entry.value.worldRect)) {
          newSelection.add(entry.key);
        }
      }

      widget.controller.setSelection(newSelection);
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    final marqueeNotifier =
        ref.read(marqueeSelectionControllerProvider.notifier);
    final marqueeState = ref.read(marqueeSelectionControllerProvider);

    if (marqueeState.enabled) {
      marqueeNotifier.endDragging();
      setState(() {});
    }
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
          final screenRect = _worldRectToScreen(hitItem.worldRect);
          infoController.openViewMode(
            itemId: hitItemId,
            anchorScreenRect: screenRect,
          );
        } else {
          _hoverCloseTimer?.cancel();
          _hoverCloseTimer = Timer(const Duration(milliseconds: 300), () {
            final currentState = ref.read(infoPopupControllerProvider);
            if (!currentState.isHovered && _hoveredItemId == null) {
              infoController.close();
            }
          });
        }
      } else if (hitItemId == null) {
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
        _hoverCloseTimer?.cancel();
        _hoverCloseTimer = null;
      }

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
