import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for marquee selection.
class MarqueeSelectionState {
  final bool enabled;
  final Offset? startWorldPoint;
  final Offset? currentWorldPoint;

  const MarqueeSelectionState({
    this.enabled = false,
    this.startWorldPoint,
    this.currentWorldPoint,
  });

  bool get isDragging => startWorldPoint != null && currentWorldPoint != null;

  Rect? get worldRect {
    if (!isDragging) return null;
    return Rect.fromPoints(startWorldPoint!, currentWorldPoint!);
  }

  MarqueeSelectionState copyWith({
    bool? enabled,
    Offset? startWorldPoint,
    Offset? currentWorldPoint,
    bool clearPoints = false,
  }) {
    return MarqueeSelectionState(
      enabled: enabled ?? this.enabled,
      startWorldPoint: clearPoints ? null : (startWorldPoint ?? this.startWorldPoint),
      currentWorldPoint: clearPoints ? null : (currentWorldPoint ?? this.currentWorldPoint),
    );
  }
}

/// Controller for marquee selection.
class MarqueeSelectionController extends Notifier<MarqueeSelectionState> {
  @override
  MarqueeSelectionState build() {
    return const MarqueeSelectionState();
  }

  void enterMarqueeMode() {
    state = state.copyWith(enabled: true);
  }

  void exitMarqueeMode() {
    state = const MarqueeSelectionState(enabled: false);
  }

  void toggleMarqueeMode() {
    state = state.copyWith(enabled: !state.enabled);
  }

  void startDragging(Offset worldPoint) {
    state = state.copyWith(startWorldPoint: worldPoint, currentWorldPoint: worldPoint);
  }

  void updateDragging(Offset worldPoint) {
    state = state.copyWith(currentWorldPoint: worldPoint);
  }

  void endDragging() {
    state = state.copyWith(clearPoints: true);
  }
}

/// Provider for MarqueeSelectionController.
final marqueeSelectionControllerProvider =
    NotifierProvider<MarqueeSelectionController, MarqueeSelectionState>(
  MarqueeSelectionController.new,
);
