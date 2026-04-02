Task 2.5.2-1: Cmd+M marquee mode

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`). You have access to Flutter and Chrome devtools for debugging, inspection, loggin, profiling, etc.

You have access to the Chrome browser instance, so navigate to `localhost:8080` to access the app if needed. Refresh to show the latest changes for future code changes.

DO NOT modify `system_prompt.md` or `PLAN.md`

Your job is to implement without breaking existing functionality, the specified task:

###### Task 2.5.2-1: Cmd+M marquee mode [L4]

```text
Prompt (L4):

Implement marquee selection per FEATURES.md §2.5.2.

Requirements:
- Press Cmd+M to enter marquee mode.
- First pointer down defines start world point.
- Drag defines translucent selection rectangle.
- All nodes/widgets inside rectangle become selected and get border matching marquee border color.

Implementation shape:
- Shortcuts engine dispatches `Cmd+M` -> enterMarqueeMode()
- MarqueeSelectionController stores:
  - enabled
  - startWorld
  - currentWorld

- During drag, compute selection:
  - for each item with worldBounds intersects marqueeRect => include
```