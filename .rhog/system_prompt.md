Task 3.1.1-2: Connection model + rendering + persistence (Flow Canvas)

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`). You have access to Flutter and Chrome devtools for debugging, inspection, loggin, profiling, etc.

Do not use browser or `flutter run` to actually run the app.

After each task, run the following command to commit changes:

```
git add .
git commit -m "<Task Name + Code> done"
```

DO NOT modify `system_prompt.md` or `PLAN.md`

Your job is to implement without breaking existing functionality, the specified tasks (and dont forget to write tests after each task, though you dont have to run the tests for now):


###### Task 3.2.1-1: Node template schema + registry + renderer [L4]

```text
Prompt (L4):

Implement node templates per FEATURES.md §3.2.1.

Requirements:
- Node templates customize:
  - which fields of the LH2Object are shown
  - styling (colors, sizes)
  - port layout
- Templates are stored in Firestore workspace (Appendix A).

Define:
- class NodeTemplate { String id; ObjectType objectType; String name; int schemaVersion; Map<String,Object?> renderSpec; }
- renderSpec minimum fields:
  - header: { showTitle: bool }
  - bodyFields: List<String> // e.g. ["name", "taskStatus"]
  - ports: { in: [...], out: [...] }
  - size: { width, height }
  - style: { backgroundColor, borderColor, textColor }

Renderer:
- NodeRendererRegistry: Map<ObjectType, Widget Function(LH2Object, NodeTemplate, CanvasItemState)>
```

##### 3.2.2–3.2.9: Node widgets (initial set) [L2]

```text
Prompt (L2):

Implement baseline node widgets for these LH2Object types:
- ProjectGroup (3.2.2 is a meta-node; see below)
- Project (3.2.3)
- Deliverable (3.2.4)
- Task (3.2.5)
- Session (3.2.6)
- Event (3.2.7)
- ContextRequirement (3.2.8)
- ActualContext (3.2.9)

Constraints:
- Project Group Node (3.2.2) is NOT directly addable; it is used as a grouping/color concept for Project nodes.
- Keep visual styling simple for v0.1.0; Calendar-specific styling happens in v0.2.0.
```

### 4: Keyboard Input

#### 4.1: Keystroke Behaviour Modifiers

##### Task 4.1-1: Modifier state tracker (Cmd/Ctrl/Shift/Alt) [L3]

```text
Prompt (L3):

Implement a global modifier key state tracker.

Requirements:
- Track whether Cmd (Meta), Ctrl, Shift, Alt are currently pressed.
- Expose via Riverpod so canvases can check modifier state during pointer gestures.

Implement:
- ModifierState { bool cmd; bool ctrl; bool shift; bool alt; }
- modifierStateProvider
- A widget near the root (e.g. LH2App) that listens to RawKeyboard events and updates state.

Use cases:
- Cmd+scroll zoom / calendar scaling
- Cmd+Shift multi-select
- Cmd toggles snap-to-grid in calendar
```

#### 4.2: Keyboard Shortcuts

##### Task 4.2-1: Shortcuts engine (Appendix E) [L4]

```text
Prompt (L4):

Implement a rudimentary keyboard shortcuts engine for LH2 (FEATURES.md §4.2) per Appendix E.

Requirements:
- Map keystroke sequences to operations.
- Must route shortcuts to the active canvas/tab.

Implement these types (names required):
- class KeyChord { Set<LogicalKeyboardKey> modifiers; LogicalKeyboardKey key; }
- class KeySequence { List<KeyChord> chords; }
- typedef ShortcutHandler = Future<void> Function(ShortcutContext ctx);
- class ShortcutRegistry { void register(KeySequence seq, ShortcutHandler handler); }
- class ShortcutsEngine { void handleKeyEvent(KeyEvent e); }

Required bindings:
- Cmd+M => enter marquee mode
- Esc => cancel popup / exit modes

Integration:
- Use Focus at root; engine receives events and dispatches.
```

---
