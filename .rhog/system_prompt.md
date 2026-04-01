Task 6.3.2-1: Key strategy guidelines + utility helpers [L2]

---

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`). You have access to Flutter and Chrome devtools for debugging, inspection, loggin, profiling, etc.

Use `flutter run -d web-server --web-hostname localhost --web-port 8080` to run the web server initially.

You have access to the Chrome browser instance, so navigate to `localhost:8080` to access the app. Refresh to show the latest changes for future code changes.

DO NOT modify `system_prompt.md` or `PLAN.md`

Your job is to implement without breaking existing functionality, the specified task:

##### Task 6.3.2-1: Key strategy guidelines + utility helpers [L2]

```text
Prompt (L2):

Add a small set of guidelines and utility helpers for using Keys in LH2 to reduce rebuilds.

Include:
- When to use ValueKey(objectId), ObjectKey(model), and GlobalKey.
- A helper like `Key canvasItemKey(CanvasItem item)`.
- Example usage in a node list builder.
```
