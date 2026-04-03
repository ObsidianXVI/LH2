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
            // Handle zooming/scaling if Cmd is held (handled in Task 2.2.3)
            // For now, handle basic panning
            if (event is PointerScrollEvent) {
              widget.controller.panBy(event.scrollDelta);
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

    return Positioned(
      left: screenRect.left,
      top: screenRect.top,
      width: screenRect.width,
      height: screenRect.height,
      child: GestureDetector(
        onPanUpdate: (details) {
          final deltaWorld = details.delta / widget.controller.viewport.zoom;
          widget.controller.updateItemRect(itemId, item.worldRect.shift(deltaWorld));
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
          child: Center(
            child: Text(
              item.itemType,
              style: const TextStyle(fontSize: 10, color: LH2Colors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStickyMarkersLayer() {
    // Placeholder for Task 2.2.2
    return const SizedBox.shrink();
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
