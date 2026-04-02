import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_app/domain/notifiers/crosshair_mode_controller.dart';
import 'package:lh2_app/ui/flow_canvas/canvas_provider.dart';
import 'package:lh2_app/ui/theme/tokens.dart';
import 'package:lh2_app/app/theme.dart';

/// Overlay for crosshair mode side panel.
class CrosshairOverlay extends ConsumerWidget {
  const CrosshairOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crosshairState = ref.watch(crosshairModeControllerProvider);
    final canvasController = ref.watch(activeCanvasControllerProvider);

    if (!crosshairState.enabled) {
      return const SizedBox.shrink();
    }

    final hoveredItemId = crosshairState.hoveredItemId;
    final hoveredItem = canvasController?.items[hoveredItemId];

    return Positioned(
      right: 16,
      top: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: LH2Colors.panel,
        child: Container(
          width: 300,
          constraints: const BoxConstraints(maxHeight: 500),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: LH2Colors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Crosshair Mode',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => ref.read(crosshairModeControllerProvider.notifier).setEnabled(false),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              if (hoveredItem == null)
                const Text('No item under cursor', style: TextStyle(color: Colors.grey))
              else ...[
                Text('Item ID: ${hoveredItem.itemId}', style: LH2Theme.body),
                Text('Type: ${hoveredItem.itemType}', style: LH2Theme.body),
                Text('Position: (${hoveredItem.worldRect.left.toStringAsFixed(0)}, ${hoveredItem.worldRect.top.toStringAsFixed(0)})', style: LH2Theme.body),
                Text('Size: ${hoveredItem.worldRect.width.toStringAsFixed(0)} x ${hoveredItem.worldRect.height.toStringAsFixed(0)}', style: LH2Theme.body),
              ],
              if (crosshairState.linkDraft != null) ...[
                const SizedBox(height: 16),
                const Text('Link Draft:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Start: ${crosshairState.linkDraft!['startItemId'] ?? 'unknown'}'),
                Text('Type: ${crosshairState.linkDraft!['linkType'] ?? 'default'}'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}