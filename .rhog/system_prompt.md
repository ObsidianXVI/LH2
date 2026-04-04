Node Templates

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`). You have access to Flutter and Chrome devtools for debugging, inspection, loggin, profiling, etc.

Do not use browser or `flutter run` to actually run the app.

DO NOT modify `system_prompt.md` or `PLAN.md`

Your job is to implement without breaking existing functionality, the specified tasks (and dont forget to write tests as well):



##### 2.2.4: Free Drawing and Snap-To-Grid

First of all, allow node and widget addition/manipulation in the same way the Flow Canvas does.
The following features will be added on after this.

###### Task 2.2.4-1: Snap toggle + auto-snap rules (Appendix D) [L4]

```text
Prompt (L4):

Implement freehand vs snap-to-grid per FEATURES.md §2.2.4 and Appendix D.

Rules:
- Default: freehand; moving a node does NOT update its timestamps.
- Holding Cmd before tapping/moving/dragging enables snap-to-grid.
- Snap-to-grid only applies to nodes (not widgets).
- If start or end timestamp has been snapped once:
  - dragging the other end auto-snaps without holding Cmd
  - in this auto-snap mode, holding Cmd DISABLES snapping

Implementation must introduce per-item snap metadata:
- CanvasItemSnapState { bool startSnapped; bool endSnapped; }

When snapping:
- Snap increment is 15 minutes.
- Convert pointer movement -> proposed start/end timestamps -> snap -> update node bounds/time.
```

##### 2.2.5: Snappable Nodes

###### Task 2.2.5-1: Enforce snappable types only [L3]

```text
Prompt (L3):

Implement snappable node enforcement per FEATURES.md §2.2.5.

Only these types snap:
- Deliverable
- Session
- ContextRequirement
- Event

Implementation:
- CanvasItem has objectType.
- CalendarCanvasController.shouldSnap(item): bool based on type.
- If not snappable, ignore snap even if Cmd held.
```

##### 2.2.6: Node Styling Choices

###### Task 2.2.6-1: Calendar-specific node renderer variants + constraints [L4]

```text
Prompt (L4):

Implement Calendar Canvas node styling per FEATURES.md §2.2.6.

Deliverable:
- special placing of out-ports
- can be nested within context-requirement nodes
- root-level deliverables (global deliverables) must not overlap with any other nodes

Session:
- title/description text colour-coded by project colour
- also show the name of the task that it is from

Context Requirement:
- mixed-colour semi-opaque grey + context colour
- dashed border and grey context name
- additional `conditional` port

Event:
- compact 1–2 line layout
- extra height if details exist

Implementation details:
- Add CalendarNodeRendererRegistry separate from Flow.
- Add collision check for root-level deliverables:
  - before committing add/move, check intersect with any existing item bounds
  - if overlap, block and show warning toast/snackbar.
```

---
