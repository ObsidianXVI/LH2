Task 2.5.1-1: Multi-select with Cmd+Shift click + blue outline

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`). You have access to Flutter and Chrome devtools for debugging, inspection, loggin, profiling, etc.

You have access to the Chrome browser instance, so navigate to `localhost:8080` to access the app if needed. Refresh to show the latest changes for future code changes.

DO NOT modify `system_prompt.md` or `PLAN.md`

Your job is to implement without breaking existing functionality, the specified task:

###### Task 2.5.1-1: Multi-select with Cmd+Shift click + blue outline [L4]

```text
Prompt (L4):

Implement Cmd-Shift-Select per FEATURES.md §2.5.1.

Requirements:
- Normal click selects a single node.
- Cmd+Shift + click toggles node in multi-selection set.
- Selected items have a blue outline.
- Right-click menus disable actions that cannot apply to all selected items (greyed out but visible).

Implementation shape:
- CanvasController.selection: Set<String> itemIds
- Selection policy:
  - click without modifiers => selection = {id}
  - Cmd+Shift click => toggle membership

Menu integration:
- Context menu builder receives selection set and computes enabled/disabled actions.
```
