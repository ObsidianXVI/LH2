import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for crosshair mode.
class CrosshairModeState {
  final bool enabled;
  final String? hoveredItemId;
  final String? lastHoveredItemId;
  final Map<String, Object?>? linkDraft;
  final bool panelHovered;

  const CrosshairModeState({
    this.enabled = false,
    this.hoveredItemId,
    this.lastHoveredItemId,
    this.linkDraft,
    this.panelHovered = false,
  });

  CrosshairModeState copyWith({
    bool? enabled,
    String? hoveredItemId,
    String? lastHoveredItemId,
    Map<String, Object?>? linkDraft,
    bool? panelHovered,
  }) {
    return CrosshairModeState(
      enabled: enabled ?? this.enabled,
      hoveredItemId: hoveredItemId ?? this.hoveredItemId,
      lastHoveredItemId: lastHoveredItemId ?? this.lastHoveredItemId,
      linkDraft: linkDraft ?? this.linkDraft,
      panelHovered: panelHovered ?? this.panelHovered,
    );
  }
}

/// Controller for crosshair mode.
class CrosshairModeController extends Notifier<CrosshairModeState> {
  @override
  CrosshairModeState build() {
    return const CrosshairModeState();
  }

  void toggle() {
    state = state.copyWith(enabled: !state.enabled);
  }

  void setEnabled(bool enabled) {
    state = state.copyWith(enabled: enabled);
  }

  void setHoveredItemId(String? itemId) {
    // Preserve the last hovered item ID when cursor moves off nodes
    final newLastHoveredItemId = itemId ?? state.lastHoveredItemId;

    state = CrosshairModeState(
      enabled: state.enabled,
      hoveredItemId: itemId,
      lastHoveredItemId: newLastHoveredItemId,
      linkDraft: state.linkDraft,
      panelHovered: state.panelHovered,
    );
  }

  void setLinkDraft(Map<String, Object?>? draft) {
    state = CrosshairModeState(
      enabled: state.enabled,
      hoveredItemId: state.hoveredItemId,
      lastHoveredItemId: state.lastHoveredItemId,
      linkDraft: draft,
      panelHovered: state.panelHovered,
    );
  }

  void setPanelHovered(bool hovered) {
    state = CrosshairModeState(
      enabled: state.enabled,
      hoveredItemId: state.hoveredItemId,
      lastHoveredItemId: state.lastHoveredItemId,
      linkDraft: state.linkDraft,
      panelHovered: hovered,
    );
  }

  void clear() {
    state = const CrosshairModeState();
  }
}

/// Provider for CrosshairModeController.
final crosshairModeControllerProvider =
    NotifierProvider<CrosshairModeController, CrosshairModeState>(
  CrosshairModeController.new,
);
