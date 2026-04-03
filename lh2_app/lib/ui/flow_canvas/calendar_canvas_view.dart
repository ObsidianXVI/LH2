import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';
import 'package:lh2_app/ui/flow_canvas/calendar_timescale_painter.dart';
import 'package:lh2_app/ui/flow_canvas/link_painter.dart';
import 'package:lh2_app/ui/info_popup_overlay.dart';
import 'package:lh2_app/ui/crosshair_overlay.dart';
import 'package:lh2_app/app/modifier_state.dart';
import 'package:lh2_app/domain/notifiers/marquee_selection_controller.dart';
import 'package:lh2_app/ui/theme/tokens.dart';
import 'package:lh2_app/ui/flow_canvas/sticky_markers_painter.dart';
import 'package:lh2_app/ui/flow_canvas/calendar_node_renderer_registry.dart';
import 'package:lh2_app/ui/flow_canvas/calendar_data_providers.dart';

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
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
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
            if (event is PointerScrollEvent) {
              final modifierState = ref.read(modifierStateProvider);
              if (modifierState.cmd) {
                widget.controller.handleCmdScroll(event.scrollDelta.dy);
              } else {
                widget.controller.panBy(event.scrollDelta);
              }
              setState(() {});
            }
          },
          child: GestureDetector(
            onPanUpdate: (details) {
              widget.controller.panBy(-details.delta);
            },
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                // 1) Timescale overlay (CustomPaint)
                CustomPaint(
                  painter: CalendarTimescalePainter(
                    pan: widget.controller.viewport.pan,
                    zoom: widget.controller.viewport.zoom,
                    minutesPerPixel: widget.controller.minutesPerPixel,
                    ruleIntervalMinutes: widget.controller.ruleIntervalMinutes,
                    viewportSize: viewportSize,
                  ),
                  size: viewportSize,
                ),

                // 2) Items layer (nodes)
                _buildItemsLayer(),

                // Links layer (reusing LinkPainter)
                CustomPaint(
                  painter: LinkPainter(controller: widget.controller),
                  size: viewportSize,
                ),

                // 3) Sticky markers overlay (top) - To be implemented in Task 2.2.2
                _buildStickyMarkersLayer(),

                // Common overlays
                const InfoPopupOverlay(),
                const CrosshairOverlay(),
                _buildMarqueeOverlay(),
              ],
            ),
          ),
        );
      },
    );
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

    Widget content;
    if (item.itemType == 'node' && item.objectId != null) {
      final object = ref.watch(lh2ObjectProvider(item.objectId!));
      final template = ref.watch(nodeTemplateProvider(item.config?['templateId'] ?? 'default'));
      
      content = object.when(
        data: (obj) => template.when(
          data: (tmpl) => calendarNodeRendererRegistry.build(obj, tmpl, item),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text('Error loading template: $e'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error loading object: $e'),
      );
    } else {
      content = Center(
        child: Text(
          item.itemType,
          style: const TextStyle(fontSize: 10, color: LH2Colors.textSecondary),
        ),
      );
    }

    return Positioned(
      left: screenRect.left,
      top: screenRect.top,
      width: screenRect.width,
      height: screenRect.height,
      child: GestureDetector(
        onPanUpdate: (details) {
          final modifierState = ref.read(modifierStateProvider);
          final bool isCmdPressed = modifierState.cmd;

          final deltaWorld = details.delta / widget.controller.viewport.zoom;
          Rect newRect = item.worldRect.shift(deltaWorld);

          // Snapping logic
          bool shouldSnap = false;
          bool startSnapped = item.snap.startSnapped;
          bool endSnapped = item.snap.endSnapped;

          if (widget.controller.shouldSnap(item)) {
            // If either end has been snapped once, auto-snap unless Cmd is held
            if (startSnapped || endSnapped) {
              shouldSnap = !isCmdPressed;
            } else {
              // Default: freehand, Cmd enables snap
              shouldSnap = isCmdPressed;
            }
          }

          if (shouldSnap) {
            // Snap left (start) and right (end)
            final double snappedLeft = widget.controller.snapWorldX(newRect.left);
            final double snappedRight = widget.controller.snapWorldX(newRect.right);

            // Update snap metadata
            startSnapped = true;
            endSnapped = true;

            newRect = Rect.fromLTRB(snappedLeft, newRect.top, snappedRight, newRect.bottom);
          }

          // Collision check for root-level deliverables
          if (item.objectType == 'deliverable' && item.config?['isRoot'] == true) {
             for (final otherItem in widget.controller.items.values) {
               if (otherItem.itemId != item.itemId && otherItem.worldRect.overlaps(newRect)) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Root-level deliverable cannot overlap with other nodes')),
                 );
                 return; // Block move
               }
             }
          }

          widget.controller.updateItemRect(
            itemId,
            newRect,
            snap: CanvasItemSnapState(
              startSnapped: startSnapped,
              endSnapped: endSnapped,
            ),
          );
        },
        onTap: () => widget.controller.setSelection({itemId}),
        child: Container(
          decoration: BoxDecoration(
            color: LH2Colors.panel.withOpacity(0.8),
            border: Border.all(
              color: isSelected ? LH2Colors.selectionBlue : LH2Colors.border,
              width: isSelected ? 2.0 : 1.0,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: content,
        ),
      ),
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
