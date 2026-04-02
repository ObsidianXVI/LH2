import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_app/domain/notifiers/info_popup_controller.dart';
import 'package:lh2_app/ui/theme/tokens.dart';
import 'package:lh2_app/app/theme.dart';
import 'package:lh2_app/domain/notifiers/crosshair_mode_controller.dart';

/// Overlay widget for the information popup.
class InfoPopupOverlay extends ConsumerWidget {
  const InfoPopupOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(infoPopupControllerProvider);
    final crosshairState = ref.watch(crosshairModeControllerProvider);

    if (!state.isOpen || state.anchorScreenRect == null) {
      return const SizedBox.shrink();
    }

    // Basic positioning logic: place it to the right of the anchor
    final left = state.anchorScreenRect!.right + 8;
    final top = state.anchorScreenRect!.top;

    return Stack(
      children: [
        // Background overlay to catch clicks outside (Save on click outside)
        // Only show this in 'add' mode, not in 'view' (hover) mode.
        if (state.mode == InfoPopupMode.add)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => ref.read(infoPopupControllerProvider.notifier).close(),
              child: Container(color: Colors.transparent),
            ),
          ),
        Positioned(
          left: left,
          top: top,
          child: MouseRegion(
            onEnter: (_) =>
                ref.read(infoPopupControllerProvider.notifier).setIsHovered(true),
            onExit: (_) => ref
                .read(infoPopupControllerProvider.notifier)
                .setIsHovered(false),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              color: LH2Colors.panel,
              child: Container(
                width: 300,
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
                        Text(
                          state.mode == InfoPopupMode.add
                              ? 'Configure New Node'
                              : 'Node Information',
                          style: LH2Theme.nodeTitle,
                        ),
                        if (!crosshairState.enabled)
                          IconButton(
                            icon:
                                const Icon(Icons.visibility_outlined, size: 18),
                            onPressed: () => ref
                                .read(crosshairModeControllerProvider.notifier)
                                .setEnabled(true),
                          ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => ref
                              .read(infoPopupControllerProvider.notifier)
                              .close(),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text('Item ID: ${state.itemId}', style: LH2Theme.body),
                    Text('Type: ${state.objectType?.name}',
                        style: LH2Theme.body),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => ref
                              .read(infoPopupControllerProvider.notifier)
                              .close(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(infoPopupControllerProvider.notifier)
                              .close(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LH2Colors.accentBlue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
