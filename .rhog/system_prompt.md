Task 1.1.2-1: Create tab via right-click menu (Flow vs Calendar)

---

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`). You have access to Flutter and Chrome devtools for debugging, inspection, loggin, profiling, etc.

Use `flutter run -d web-server --web-hostname localhost --web-port 8080` to run the web server initially.

You have access to the Chrome browser instance, so navigate to `localhost:8080` to access the app. Refresh to show the latest changes for future code changes.

DO NOT modify `system_prompt.md` or `PLAN.md`

Your job is to implement without breaking existing functionality, the specified task:

###### Task 1.1.2-1: Create tab via right-click menu (Flow vs Calendar) [L2]

```text
Prompt (L2):

Implement tab creation per FEATURES.md §1.1.2.

Requirements:
- "Create new tab" triggers a context menu asking: Flow Canvas or Calendar Canvas.
- On selection, create a tab persisted to Firestore workspace (Appendix A):
  - kind = flow|calendar
  - default title (e.g. "Flow 1", "Calendar 1")
  - default controller state (Appendix B)

Implement:
- WorkspaceController (Riverpod Notifier) with method `createTab(CanvasKind kind)`
- Use WorkspaceRepository.createTab()
```