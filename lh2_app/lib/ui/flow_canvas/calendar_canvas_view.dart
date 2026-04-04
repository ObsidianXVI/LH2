import 'package:flutter/gestures.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';
import 'package:lh2_app/domain/notifiers/crosshair_mode_controller.dart';
import 'package:lh2_app/domain/notifiers/info_popup_controller.dart';
import 'package:lh2_app/ui/flow_canvas/calendar_timescale_painter.dart';
import 'package:lh2_app/ui/flow_canvas/link_painter.dart';
import 'package:lh2_app/ui/info_popup_overlay.dart';
import 'package:lh2_app/ui/crosshair_overlay.dart';
import 'package:lh2_app/app/modifier_state.dart';
import 'package:lh2_app/domain/notifiers/marquee_selection_controller.dart';
import 'package:lh2_app/ui/theme/tokens.dart';
import 'package:lh2_app/ui/flow_canvas/sticky_markers_painter.dart';
import 'package:lh2_app/ui/flow_canvas/canvas_context_menu.dart';
import 'package:lh2_app/domain/notifiers/workspace_controller.dart';
import 'package:flutter/services.dart';
import 'package:lh2_app/app/providers.dart';
import 'package:lh2_app/data/workspace_repository.dart';
import 'package:lh2_app/domain/models/node_template_ports.dart';
import 'package:lh2_app/domain/operations/canvas.dart';
import 'package:lh2_app/ui/flow_canvas/query_board.dart';
import 'package:lh2_app/ui/flow_canvas/nodes/node_canvas_item.dart';
import 'dart:async';
import 'package:lh2_stub/lh2_stub.dart';

class CalendarCanvasView extends ConsumerStatefulWidget {
  final CalendarCanvasController controller;

  const CalendarCanvasView({
    super.key,
    required this.controller,
  });

  @override
  ConsumerState<CalendarCanvasView> createState() => _CalendarCanvasViewState();
}

class _CalendarCanvasViewState extends ConsumerState<CalendarCanvasView> {
  OverlayEntry? _contextMenuOverlay;
  final FocusNode _canvasFocusNode = FocusNode(debugLabel: 'calendar_canvas');

  bool _isBackgroundPanning = false;

  String? _hoveredItemId;
  Timer? _hoverCloseTimer;

  // Track drag state for nodes to avoid snap-locking
  final Map<String, Rect> _dragStartRects = {};
  final Map<String, Offset> _dragCumulativeDeltas = {};

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);

    // Avoid autofocus-based focus traversal on web before layout is complete.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _canvasFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _removeContextMenu();
    _canvasFocusNode.dispose();
    _hoverCloseTimer?.cancel();
    _persistenceTimer?.cancel();
    super.dispose();
  }

  void _removeContextMenu() {
    _contextMenuOverlay?.remove();
    _contextMenuOverlay = null;
  }

  void _handleRightClick(TapUpDetails details) {
    _removeContextMenu();

    final worldPosition =
        widget.controller.screenToWorld(details.localPosition);

    final workspaceState = ref.read(workspaceControllerProvider);
    final workspaceId = workspaceState.workspaceId;
    final tabId = workspaceState.activeTabId;

    if (workspaceId.isEmpty || tabId == null) {
      return;
    }

    // Select item under cursor if any.
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

  void _handleTapUp(TapUpDetails details) {
    // Only clear selection if we tapped the actual background.
    final worldPos = widget.controller.screenToWorld(details.localPosition);
    bool hitItem = false;
    for (final it in widget.controller.items.values) {
      if (it.worldRect.contains(worldPos)) {
        hitItem = true;
        break;
      }
    }
    if (!hitItem && widget.controller.selection.isNotEmpty) {
      widget.controller.setSelection({});
    }
  }

  bool _hitAnyItemAtWorld(Offset worldPos) {
    for (final it in widget.controller.items.values) {
      if (it.worldRect.contains(worldPos)) return true;
    }
    return false;
  }

  void _handleItemTap(String itemId) {
    final item = widget.controller.items[itemId];
    if (item == null) return;

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

  // --- Linking helpers (parity with FlowCanvasView) ---

  ObjectType _inferObjectTypeEnum(CanvasItem item) {
    final declared = item.objectType;
    if (declared != null) {
      try {
        return ObjectType.values.byName(declared);
      } catch (_) {
        // ignore and fall back
      }
    }

    // Try byName if itemType looks like an ObjectType
    try {
      return ObjectType.values.byName(item.itemType);
    } catch (_) {
      return ObjectType.project;
    }
  }

  String _inferObjectType(CanvasItem item) => _inferObjectTypeEnum(item).name;

  bool _isValidLinkTargetWithPorts(String targetItemId) {
    final fromItemId = widget.controller.pendingFromItemId;
    final fromPortId = widget.controller.pendingFromPortId;
    if (fromItemId == null || fromPortId == null) return false;
    if (fromItemId == targetItemId) return false;

    final fromItem = widget.controller.items[fromItemId];
    final toItem = widget.controller.items[targetItemId];
    if (fromItem == null || toItem == null) return false;
    if (toItem.itemType != 'node') return false;

    final fromPorts =
        NodeTemplatePorts.getPortsForObjectType(_inferObjectType(fromItem));
    final toPorts =
        NodeTemplatePorts.getPortsForObjectType(_inferObjectType(toItem));

    final fromPort = fromPorts.where((p) => p.portId == fromPortId).firstOrNull;
    final toPort = toPorts.where((p) => p.portId == 'port-in').firstOrNull;
    if (fromPort == null || toPort == null) return false;
    return NodeTemplatePorts.arePortsCompatible(fromPort, toPort);
  }

  Future<void> _addLink(
    String fromId,
    String fromPort,
    String toId,
    String toPort,
  ) async {
    final workspaceState = ref.read(workspaceControllerProvider);
    final workspaceId = workspaceState.workspaceId;
    final tabId = workspaceState.activeTabId;
    if (workspaceId.isEmpty || tabId == null) return;

    // Optimistic render.
    final optimisticId =
        'link_local_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond % 1000}';
    widget.controller.addLink(
      CanvasLink(
        linkId: optimisticId,
        fromItemId: fromId,
        fromPortId: fromPort,
        toItemId: toId,
        toPortId: toPort,
        relationType: 'outboundDependency',
      ),
    );

    final op = ref.read(canvasAddLinkOpProvider);
    final result = await op.run(CanvasAddLinkInput(
      workspaceId: workspaceId,
      tabId: tabId,
      fromItemId: fromId,
      fromPortId: fromPort,
      toItemId: toId,
      toPortId: toPort,
      relationType: 'outboundDependency',
    ));

    if (result.ok) {
      final persistedId = result.value!.linkId;
      if (persistedId != optimisticId) {
        widget.controller.removeLink(optimisticId);
        widget.controller.addLink(
          CanvasLink(
            linkId: persistedId,
            fromItemId: fromId,
            fromPortId: fromPort,
            toItemId: toId,
            toPortId: toPort,
            relationType: 'outboundDependency',
          ),
        );
      }
    } else {
      widget.controller.removeLink(optimisticId);
    }
  }

  void _handlePortTap(String itemId, String portId) {
    // Output ports start linking mode.
    if (portId.contains('out') || portId.contains('conditional')) {
      widget.controller.startLinking(itemId, portId);
      return;
    }

    final pendingFrom = widget.controller.pendingFromItemId;
    final pendingFromPort = widget.controller.pendingFromPortId;
    if (pendingFrom == null || pendingFromPort == null) return;

    if (pendingFrom == itemId) {
      widget.controller.cancelLinking();
      return;
    }

    final fromItem = widget.controller.items[pendingFrom];
    final toItem = widget.controller.items[itemId];
    if (fromItem == null || toItem == null) {
      widget.controller.cancelLinking();
      return;
    }

    final fromPorts =
        NodeTemplatePorts.getPortsForObjectType(_inferObjectType(fromItem));
    final toPorts =
        NodeTemplatePorts.getPortsForObjectType(_inferObjectType(toItem));

    final fromPortSpec =
        fromPorts.where((p) => p.portId == pendingFromPort).firstOrNull;
    final toPortSpec = toPorts.where((p) => p.portId == portId).firstOrNull;
    if (fromPortSpec != null &&
        toPortSpec != null &&
        NodeTemplatePorts.arePortsCompatible(fromPortSpec, toPortSpec)) {
      _addLink(pendingFrom, pendingFromPort, itemId, portId);
    }

    widget.controller.cancelLinking();
  }

  void _handleLinkingClick(String targetItemId) {
    final fromItemId = widget.controller.pendingFromItemId;
    final fromPortId = widget.controller.pendingFromPortId;

    if (fromItemId != null &&
        fromPortId != null &&
        fromItemId != targetItemId &&
        _isValidLinkTargetWithPorts(targetItemId)) {
      _addLink(fromItemId, fromPortId, targetItemId, 'port-in');
    }
    widget.controller.cancelLinking();
  }

  Widget _buildPort(String itemId, String portId, Color color, bool isLinking) {
    final bool isOutput =
        portId.contains('out') || portId.contains('conditional');
    return MouseRegion(
      cursor: isOutput ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _handlePortTap(itemId, portId),
        child: GestureDetector(
          onTap: () => _handlePortTap(itemId, portId),
          behavior: HitTestBehavior.translucent,
          child: Container(
            width: 28,
            height: 28,
            color: Colors.transparent,
            child: Center(
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildItemPorts(
      String itemId, CanvasItem item, Rect screenRect, bool isLinking) {
    final ports = <Widget>[];
    const hitAreaSize = 28.0;
    const halfHitArea = hitAreaSize / 2;
    const padding = halfHitArea; // Parent is padded by this amount

    ports.add(
      Positioned(
        left: 0, // Outer edge of padding
        top: padding + (screenRect.height / 2) - halfHitArea,
        child: _buildPort(itemId, 'port-in', Colors.red, isLinking),
      ),
    );

    ports.add(
      Positioned(
        right: 0,
        top: padding + (screenRect.height / 2) - halfHitArea,
        child: _buildPort(itemId, 'port-out', Colors.green, isLinking),
      ),
    );

    if (item.objectType == 'contextRequirement') {
      ports.add(
        Positioned(
          left: padding + (screenRect.width / 2) - halfHitArea,
          bottom: 0,
          child:
              _buildPort(itemId, 'port-conditional', Colors.orange, isLinking),
        ),
      );
    }

    return ports;
  }

  // --- Drag persistence (parity with FlowCanvasView) ---

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
        final baseItems = workspaceState.activeTab?.tab.items ?? const {};
        final updatedItems = Map<String, Object?>.from(baseItems);
        for (final entry in _pendingPersistence.entries) {
          final id = entry.key;
          final rect = entry.value;
          final item = widget.controller.items[id];
          if (item == null) continue;

          updatedItems[id] = {
            'schemaVersion': 1,
            'itemId': id,
            'itemType': item.itemType,
            'worldRect': {
              'x': rect.left,
              'y': rect.top,
              'w': rect.width,
              'h': rect.height,
            },
            'snap': {
              'startSnapped': item.snap.startSnapped,
              'endSnapped': item.snap.endSnapped,
            },
            if (item.objectId != null) 'objectId': item.objectId,
            if (item.objectType != null) 'objectType': item.objectType,
            if (item.config != null) 'config': item.config,
          };
        }

        final repo = ref.read(workspaceRepoProvider);
        await repo.updateTab(
          workspaceId,
          tabId,
          WorkspaceTabPatch(items: updatedItems),
        );
      } catch (e) {
        // ignore: avoid_print
        print('Error persisting calendar item positions: $e');
      }

      _pendingPersistence.clear();
    });
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

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _canvasFocusNode,
      autofocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
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
      child: LayoutBuilder(builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

        // Update viewport size in controller if it changed
        if (widget.controller.viewport.viewportSizePx != viewportSize) {
          // Use a post-frame callback to avoid build-time updates
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.controller.setViewportSize(viewportSize);
          });
        }

        return Listener(
          onPointerSignal: (event) {
            if (event is PointerSignalEvent) {
              if (event is PointerScrollEvent) {
                final modifierState = ref.read(modifierStateProvider);
                if (modifierState.cmd) {
                  widget.controller.handleCmdScroll(event.scrollDelta.dy);
                } else {
                  // Horizontal scrolling moves forward/backward in time (pan X)
                  // Vertical scrolling moves up/down (pan Y)
                  widget.controller.panBy(event.scrollDelta);
                }
                setState(() {});
              }
            }
          },
          onPointerMove: (event) {
            // Track cursor while linking so the pending link can render.
            if (widget.controller.pendingFromItemId != null) {
              widget.controller.updatePendingPointerScreen(event.localPosition);
            }
          },
          onPointerPanZoomUpdate: (PointerPanZoomUpdateEvent event) {
            if (event.panDelta != Offset.zero) {
              widget.controller.panBy(event.panDelta);
              setState(() {});
            }
          },
          child: GestureDetector(
            onTapUp: (details) {
              // Close menu when clicking elsewhere.
              if (_contextMenuOverlay != null) _removeContextMenu();
              _handleTapUp(details);
            },
            onSecondaryTapUp: _handleRightClick,
            onPanStart: (details) {
              final marqueeState = ref.read(marqueeSelectionControllerProvider);
              if (marqueeState.enabled) {
                _isBackgroundPanning = false;
                _handlePanStart(details);
                return;
              }

              // Only pan the background when the drag starts on empty space.
              final worldPos =
                  widget.controller.screenToWorld(details.localPosition);
              _isBackgroundPanning = !_hitAnyItemAtWorld(worldPos);
            },
            onPanUpdate: (details) {
              final marqueeState = ref.read(marqueeSelectionControllerProvider);
              if (marqueeState.enabled) {
                _handlePanUpdate(details);
              } else if (_isBackgroundPanning) {
                widget.controller.panBy(-details.delta);
              }
            },
            onPanEnd: (details) {
              final marqueeState = ref.read(marqueeSelectionControllerProvider);
              if (marqueeState.enabled) {
                _handlePanEnd(details);
              }
              _isBackgroundPanning = false;
            },
            behavior: HitTestBehavior.opaque,
            child: MouseRegion(
              cursor: ref.watch(marqueeSelectionControllerProvider).enabled
                  ? SystemMouseCursors.precise
                  : SystemMouseCursors.basic,
              onHover: _handleHover,
              child: Stack(
                children: [
                  // 1) Timescale overlay (CustomPaint) - Lowest layer
                  CustomPaint(
                    painter: CalendarTimescalePainter(
                      pan: widget.controller.viewport.pan,
                      zoom: widget.controller.viewport.zoom,
                      minutesPerPixel: widget.controller.minutesPerPixel,
                      ruleIntervalMinutes:
                          widget.controller.ruleIntervalMinutes,
                      viewportSize: viewportSize,
                    ),
                    size: viewportSize,
                  ),

                  // 2) Items layer (nodes)
                  _buildItemsLayer(),

                  // Links layer (reusing LinkPainter)
                  IgnorePointer(
                    ignoring: true,
                    child: CustomPaint(
                      painter: LinkPainter(controller: widget.controller),
                      size: viewportSize,
                    ),
                  ),

                  // 3) Sticky markers overlay (top)
                  IgnorePointer(
                    ignoring: true,
                    child: _buildStickyMarkersLayer(),
                  ),

                  // Common overlays
                  const InfoPopupOverlay(),
                  const CrosshairOverlay(),
                  _buildMarqueeOverlay(),
                ],
              ),
            ),
          ),
        );
      }),
    );
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

    if (widget.controller.pendingFromItemId != null) {
      if (hitItemId != null && hitItem != null && hitItemId != widget.controller.pendingFromItemId && _isValidLinkTargetWithPorts(hitItemId)) {
        // Preview snap to input port
        final targetPortWorld = Offset(
            hitItem.worldRect.left,
            hitItem.worldRect.top + hitItem.worldRect.height / 2);
        widget.controller.updatePendingPointerScreen(
            widget.controller.worldToScreen(targetPortWorld));
      } else {
        widget.controller.updatePendingPointerScreen(event.localPosition);
      }
    }

    final crosshairNotifier =
        ref.read(crosshairModeControllerProvider.notifier);
    final crosshairState = ref.read(crosshairModeControllerProvider);
    final infoController = ref.read(infoPopupControllerProvider.notifier);
    final infoState = ref.read(infoPopupControllerProvider);

    if (crosshairState.enabled) {
      if (!crosshairState.panelHovered) {
        crosshairNotifier.setHoveredItemId(hitItemId);
      }
      return;
    }

    if (_hoveredItemId != hitItemId) {
      _hoveredItemId = hitItemId;
      if (widget.controller.pendingFromItemId != null) {
        // If linking, trigger rebuild to show highlight immediately
        setState(() {});
      }
      if (hitItemId != null && hitItem != null) {
        _hoverCloseTimer?.cancel();
        final screenRect = _worldRectToScreen(hitItem.worldRect);
        infoController.openViewMode(
          itemId: hitItemId,
          anchorScreenRect: screenRect,
          objectType: _inferObjectTypeEnum(hitItem),
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
    final isLinking = widget.controller.pendingFromItemId != null;
    final isPotentialTarget = isLinking && _isValidLinkTargetWithPorts(itemId);
    final isHighlighted =
        isLinking && isPotentialTarget && _hoveredItemId == itemId;

    final opacity = (isLinking &&
            !isPotentialTarget &&
            widget.controller.pendingFromItemId != itemId)
        ? 0.3
        : 1.0;

    Widget content;
    if (item.itemType == 'queryBoard') {
      content = QueryBoardWidget(itemId: itemId, controller: widget.controller);
    } else if (item.itemType == 'node') {
      // Use the Flow canvas node renderer for full styling parity.
      content = NodeCanvasItem(
        itemId: itemId,
        item: item,
        isSelected: isSelected,
        isHighlighted: isHighlighted,
      );
    } else {
      content = Center(
        child: Text(
          item.itemType,
          style: const TextStyle(fontSize: 10, color: LH2Colors.textSecondary),
        ),
      );
    }

    const hitAreaPadding = 28.0;
    const halfPadding = hitAreaPadding / 2;

    return Positioned(
      left: screenRect.left - halfPadding,
      top: screenRect.top - halfPadding,
      width: screenRect.width + hitAreaPadding,
      height: screenRect.height + hitAreaPadding,
      child: MouseRegion(
        cursor: isLinking
            ? (isPotentialTarget
                ? SystemMouseCursors.click
                : SystemMouseCursors.forbidden)
            : SystemMouseCursors.basic,
        child: Opacity(
          opacity: opacity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: halfPadding,
                top: halfPadding,
                width: screenRect.width,
                height: screenRect.height,
                child: GestureDetector(
                  onPanStart: (_) {
                  // Close hover popup while dragging (parity with Flow).
                  ref.read(infoPopupControllerProvider.notifier).close();
                  _hoverCloseTimer?.cancel();
                  _hoverCloseTimer = null;
                  
                  _dragStartRects[itemId] = item.worldRect;
                  _dragCumulativeDeltas[itemId] = Offset.zero;
                },
                onPanUpdate: (details) {
                  // Do not drag while linking.
                  if (isLinking) return;

                  final startRect = _dragStartRects[itemId];
                  if (startRect == null) return;

                  _dragCumulativeDeltas[itemId] = _dragCumulativeDeltas[itemId]! + details.delta;
                  final cumulativeDelta = _dragCumulativeDeltas[itemId]!;

                  final totalDeltaWorld = Offset(
                    cumulativeDelta.dx * widget.controller.minutesPerPixel,
                    cumulativeDelta.dy / widget.controller.viewport.zoom,
                  );

                  // Create a temporary item with the starting rect so the total delta is applied properly
                  final baseItem = CanvasItem(
                    itemId: item.itemId,
                    itemType: item.itemType,
                    worldRect: startRect,
                    objectId: item.objectId,
                    objectType: item.objectType,
                    config: item.config,
                    snap: item.snap,
                    disabledByScenario: item.disabledByScenario,
                  );

                  final moved = widget.controller.applyMoveWithSnapping(
                    item: baseItem,
                    deltaWorld: totalDeltaWorld,
                    isCmdPressed: ref.read(modifierStateProvider).cmd,
                  );

                  Rect newRect = moved.rect;
                  CanvasItemSnapState newSnap = moved.snap;

                  // Collision check for root-level deliverables
                  if (item.objectType == 'deliverable' &&
                      item.config?['isRoot'] == true) {
                    if (widget.controller.rootDeliverableWouldOverlap(
                      proposedRect: newRect,
                      ignoreItemId: item.itemId,
                    )) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Root-level deliverable cannot overlap with other nodes'),
                        ),
                      );
                      return; // Block move
                    }
                  }

                    widget.controller.updateItemRect(
                      itemId,
                      newRect,
                      snap: newSnap,
                    );
                    _debounceItemPersistence(itemId, newRect);
                  },
                  onPanEnd: (_) {
                    _dragStartRects.remove(itemId);
                    _dragCumulativeDeltas.remove(itemId);
                  },
                  onPanCancel: () {
                    _dragStartRects.remove(itemId);
                    _dragCumulativeDeltas.remove(itemId);
                  },
                  onTap: () => isLinking
                      ? _handleLinkingClick(itemId)
                      : _handleItemTap(itemId),
                  behavior: HitTestBehavior.opaque,
                  child: item.itemType == 'node'
                      ? content
                      : _defaultItemFrame(isSelected, content),
                ),
              ),
              if (item.itemType == 'node')
                ..._buildItemPorts(itemId, item, screenRect, isLinking),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultItemFrame(bool isSelected, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: LH2Colors.panel.withOpacity(0.8),
        border: Border.all(
          color: isSelected ? LH2Colors.selectionBlue : LH2Colors.border,
          width: isSelected ? 2.0 : 1.0,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }

  Widget _buildStickyMarkersLayer() {
    return LayoutBuilder(builder: (context, constraints) {
      final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
      return CustomPaint(
        painter: StickyMarkersPainter(
          pan: widget.controller.viewport.pan,
          zoom: widget.controller.viewport.zoom,
          minutesPerPixel: widget.controller.minutesPerPixel,
          ruleIntervalMinutes: widget.controller.ruleIntervalMinutes,
          viewportSize: viewportSize,
          anchorStartSgt: widget.controller.anchorStartSgt,
        ),
        size: viewportSize,
      );
    });
  }

  Widget _buildMarqueeOverlay() {
    final marqueeState = ref.watch(marqueeSelectionControllerProvider);
    if (!marqueeState.enabled || !marqueeState.isDragging) {
      return const SizedBox.shrink();
    }
    final screenRect = _worldRectToScreen(marqueeState.worldRect!);
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

  Rect _worldRectToScreen(Rect worldRect) {
    final topLeft = widget.controller.worldToScreen(worldRect.topLeft);
    final bottomRight = widget.controller.worldToScreen(worldRect.bottomRight);
    return Rect.fromPoints(topLeft, bottomRight);
  }
}
