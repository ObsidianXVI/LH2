import 'package:flutter_test/flutter_test.dart';
import 'package:lh2_app/app/modifier_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('ModifierState tracker updates state on key events', (WidgetTester tester) async {
    final container = ProviderContainer();
    
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ModifierTracker(
            child: SizedBox(),
          ),
        ),
      ),
    );

    // Simulate Cmd (Meta) key down
    await tester.sendKeyEvent(LogicalKeyboardKey.metaLeft);
    expect(container.read(modifierStateProvider).cmd, true);

    // Simulate Cmd (Meta) key up
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    expect(container.read(modifierStateProvider).cmd, false);

    // Simulate Shift key down
    await tester.sendKeyEvent(LogicalKeyboardKey.shiftLeft);
    expect(container.read(modifierStateProvider).shift, true);
  });
}
