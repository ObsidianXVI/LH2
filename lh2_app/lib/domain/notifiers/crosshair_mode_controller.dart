import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for crosshair mode.
class CrosshairModeState {
  final bool enabled;
  final String? hoveredItemId;
  final Map<String, Object?>? linkDraft;

  const CrosshairModeState({
    this.enabled = false,
    this.hoveredItemId,
    this.linkDraft,
  });

  CrosshairModeState copyWith({
    bool? enabled,
    String? hoveredItemId,
    Map<String, Object?>? linkDraft,
  }) {
    return CrosshairModeState(
      enabled: enabled ?? this.enabled,
      hoveredItemId: hoveredItemId ?? this.hoveredItemId,
      linkDraft: linkDraft ?? this.linkDraft,
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
    state = state.copyWith(hoveredItemId: itemId);
  }

  void setLinkDraft(Map<String, Object?>? draft) {
    state = state.copyWith(linkDraft: draft);
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