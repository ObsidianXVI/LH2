Node Templates

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`). You have access to Flutter and Chrome devtools for debugging, inspection, loggin, profiling, etc.

Do not use browser or `flutter run` to actually run the app.

DO NOT modify `system_prompt.md` or `PLAN.md`

Your job is to implement without breaking existing functionality, the specified task (and dont forget to write tests as well):


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

To demonstrate both, create node templates following the Figma designs (style, layout, colours, port positioning and styling) in `.rhog/mockups/node_templates_default.png` for each node type.