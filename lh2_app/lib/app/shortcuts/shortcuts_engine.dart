import 'package:flutter/services.dart';
import 'package:collection/collection.dart';

class KeyChord {
  final Set<LogicalKeyboardKey> modifiers;
  final LogicalKeyboardKey key;

  const KeyChord({
    required this.modifiers,
    required this.key,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeyChord &&
          runtimeType == other.runtimeType &&
          const SetEquality().equals(modifiers, other.modifiers) &&
          key == other.key;

  @override
  int get hashCode => const SetEquality().hash(modifiers) ^ key.hashCode;
}

class KeySequence {
  final List<KeyChord> chords;

  const KeySequence({required this.chords});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeySequence &&
          runtimeType == other.runtimeType &&
          const ListEquality().equals(chords, other.chords);

  @override
  int get hashCode => const ListEquality().hash(chords);
}

class ShortcutContext {
  // Add relevant context here (active tab, etc.)
}

typedef ShortcutHandler = Future<void> Function(ShortcutContext ctx);

class ShortcutRegistry {
  final Map<KeySequence, ShortcutHandler> _bindings = {};

  void register(KeySequence seq, ShortcutHandler handler) {
    _bindings[seq] = handler;
  }

  ShortcutHandler? getHandler(KeySequence seq) => _bindings[seq];
}

class ShortcutsEngine {
  final ShortcutRegistry registry;
  List<KeyChord> _currentSequence = [];

  ShortcutsEngine({required this.registry});

  void handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final modifiers = <LogicalKeyboardKey>{};
    if (HardwareKeyboard.instance.isMetaPressed)
      modifiers.add(LogicalKeyboardKey.meta);
    if (HardwareKeyboard.instance.isControlPressed)
      modifiers.add(LogicalKeyboardKey.control);
    if (HardwareKeyboard.instance.isShiftPressed)
      modifiers.add(LogicalKeyboardKey.shift);
    if (HardwareKeyboard.instance.isAltPressed)
      modifiers.add(LogicalKeyboardKey.alt);

    final chord = KeyChord(modifiers: modifiers, key: event.logicalKey);
    _currentSequence.add(chord);

    final seq = KeySequence(chords: List.from(_currentSequence));
    final handler = registry.getHandler(seq);

    if (handler != null) {
      handler(ShortcutContext());
      _currentSequence.clear();
    } else {
      // Check if any registered sequence starts with current partial sequence
      final hasPotentialMatch = registry._bindings.keys.any((registeredSeq) {
        if (registeredSeq.chords.length < _currentSequence.length) return false;
        for (int i = 0; i < _currentSequence.length; i++) {
          if (registeredSeq.chords[i] != _currentSequence[i]) return false;
        }
        return true;
      });

      if (!hasPotentialMatch) {
        _currentSequence.clear();
      }
    }
  }
}
