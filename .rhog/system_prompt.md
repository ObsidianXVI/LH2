Task 2.1-2: Flow Canvas rendering + interaction (grid, pan/zoom, item drag)

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`). You have access to Flutter and Chrome devtools for debugging, inspection, loggin, profiling, etc.

You have access to the Chrome browser instance, so navigate to `localhost:8080` to access the app if needed. Refresh to show the latest changes for future code changes.

DO NOT modify `system_prompt.md` or `PLAN.md`

Your job is to implement without breaking existing functionality, the specified task:

###### Task 2.1-2: Flow Canvas rendering + interaction (grid, pan/zoom, item drag) [L4]


```text
Prompt (L4):

Implement Flow Canvas per FEATURES.md §2.1.

Requirements:
- Infinite scroll canvas with grid background.
- Pan/zoom interactions:
  - 2-finger scroll to pan bidirectionally
  - Cmd/Ctrl + 2-finger scroll to zoom
  - plain scroll pans (or vertical scroll pans)
- Render items (nodes/widgets) with positions stored in FlowCanvasController.
- Dragging of nodes repositions them. Update their position in realtime AS THEY ARE BEING DRAGGED

Implementation guidance:
- Prefer using `vs_node_view` if feasible.
- Wrap canvas in Listener to capture pointer + scroll signals.
- Maintain a single source of truth for viewport in FlowCanvasController.

Expose these UI components:
- FlowCanvasView(widget) { FlowCanvasController controller; }
- GridBackgroundPainter
```
