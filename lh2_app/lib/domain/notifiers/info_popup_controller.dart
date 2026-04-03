import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_stub/lh2_stub.dart';

/// Mode for the information popup.
enum InfoPopupMode { view, add }

/// State for the information popup.
class InfoPopupState {
  final String? itemId;
  final bool isOpen;
  final InfoPopupMode mode;
  final Rect? anchorScreenRect;
  final ObjectType? objectType;
  final String? templateId;
  final bool isHovered;

  const InfoPopupState({
    this.itemId,
    this.isOpen = false,
    this.mode = InfoPopupMode.view,
    this.anchorScreenRect,
    this.objectType,
    this.templateId,
    this.isHovered = false,
  });

  InfoPopupState copyWith({
    String? itemId,
    bool? isOpen,
    InfoPopupMode? mode,
    Rect? anchorScreenRect,
    ObjectType? objectType,
    String? templateId,
    bool? isHovered,
  }) {
    return InfoPopupState(
      itemId: itemId ?? this.itemId,
      isOpen: isOpen ?? this.isOpen,
      mode: mode ?? this.mode,
      anchorScreenRect: anchorScreenRect ?? this.anchorScreenRect,
      objectType: objectType ?? this.objectType,
      templateId: templateId ?? this.templateId,
      isHovered: isHovered ?? this.isHovered,
    );
  }
}

/// Controller for managing the information popup state.
class InfoPopupController extends Notifier<InfoPopupState> {
  @override
  InfoPopupState build() {
    return const InfoPopupState();
  }

  /// Opens the popup in "add" mode for a newly created item.
  void openAddMode({
    required String itemId,
    required Rect anchorScreenRect,
    required ObjectType objectType,
    required String templateId,
  }) {
    state = InfoPopupState(
      itemId: itemId,
      isOpen: true,
      mode: InfoPopupMode.add,
      anchorScreenRect: anchorScreenRect,
      objectType: objectType,
      templateId: templateId,
    );
  }

  /// Opens the popup in "view" mode for an existing item.
  void openViewMode({
    required String itemId,
    required Rect anchorScreenRect,
    required ObjectType objectType,
  }) {
    state = InfoPopupState(
      itemId: itemId,
      isOpen: true,
      mode: InfoPopupMode.view,
      anchorScreenRect: anchorScreenRect,
      objectType: objectType,
    );
  }

  /// Closes the popup.
  void close() {
    state = state.copyWith(isOpen: false, isHovered: false);
  }

  /// Sets whether the mouse is over the popup itself.
  void setIsHovered(bool isHovered) {
    state = state.copyWith(isHovered: isHovered);
  }
}

/// Provider for [InfoPopupController].
final infoPopupControllerProvider =
    NotifierProvider<InfoPopupController, InfoPopupState>(
  InfoPopupController.new,
);
