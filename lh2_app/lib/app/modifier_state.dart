import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ModifierState {
  final bool cmd;
  final bool ctrl;
  final bool shift;
  final bool alt;

  const ModifierState({
    this.cmd = false,
    this.ctrl = false,
    this.shift = false,
    this.alt = false,
  });

  ModifierState copyWith({
    bool? cmd,
    bool? ctrl,
    bool? shift,
    bool? alt,
  }) {
    return ModifierState(
      cmd: cmd ?? this.cmd,
      ctrl: ctrl ?? this.ctrl,
      shift: shift ?? this.shift,
      alt: alt ?? this.alt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModifierState &&
          runtimeType == other.runtimeType &&
          cmd == other.cmd &&
          ctrl == other.ctrl &&
          shift == other.shift &&
          alt == other.alt;

  @override
  int get hashCode => cmd.hashCode ^ ctrl.hashCode ^ shift.hashCode ^ alt.hashCode;
}

class ModifierStateNotifier extends Notifier<ModifierState> {
  @override
  ModifierState build() => const ModifierState();

  void handleKeyEvent(KeyEvent event) {
    final bool isPressed = event is KeyDownEvent || event is KeyRepeatEvent;
    
    if (event.logicalKey == LogicalKeyboardKey.metaLeft || 
        event.logicalKey == LogicalKeyboardKey.metaRight) {
      state = state.copyWith(cmd: isPressed);
    } else if (event.logicalKey == LogicalKeyboardKey.controlLeft || 
               event.logicalKey == LogicalKeyboardKey.controlRight) {
      state = state.copyWith(ctrl: isPressed);
    } else if (event.logicalKey == LogicalKeyboardKey.shiftLeft || 
               event.logicalKey == LogicalKeyboardKey.shiftRight) {
      state = state.copyWith(shift: isPressed);
    } else if (event.logicalKey == LogicalKeyboardKey.altLeft || 
               event.logicalKey == LogicalKeyboardKey.altRight) {
      state = state.copyWith(alt: isPressed);
    }
  }
}

final modifierStateProvider = NotifierProvider<ModifierStateNotifier, ModifierState>(() {
  return ModifierStateNotifier();
});

class ModifierTracker extends ConsumerWidget {
  final Widget child;

  const ModifierTracker({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        ref.read(modifierStateProvider.notifier).handleKeyEvent(event);
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}
