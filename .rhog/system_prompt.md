Task 2.4.3-1: Information overlay on hover and Crosshair overlay side panel

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`). You have access to Flutter and Chrome devtools for debugging, inspection, loggin, profiling, etc.

You have access to the Chrome browser instance, so navigate to `localhost:8080` to access the app if needed. Refresh to show the latest changes for future code changes.

DO NOT modify `system_prompt.md` or `PLAN.md`

Your job is to implement without breaking existing functionality, the specified task:

###### Task 2.4.3-1: Information overlay on hover and Crosshair overlay side panel [L4]

```text
Prompt (L4):

Implement Information overlay (same as Info popup when new node is added) whenver a node is hovered over.

Implement Crosshair Mode per FEATURES.md §2.4.3.

Requirements:
- Clicking crosshair icon on Info Popup activates Crosshair Mode.
- A fixed-size side overlay appears on the right.
- The overlay shows info fields for whatever item the cursor is hovering.
- While in crosshair mode:
  - clicking/hovering does NOT open popups
  - if user is creating a link, show starting node + link data in the side panel

Implementation shape:
- CrosshairModeController with:
  - enabled bool
  - hoveredItemId
  - linkDraft (optional)

- Hook into canvas hover events:
  - onPointerHover -> hit-test item -> set hoveredItemId
```
