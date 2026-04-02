Task 1.2.3-1: “Hide results in view” toggle

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`). You have access to Flutter and Chrome devtools for debugging, inspection, loggin, profiling, etc.

You have access to the Chrome browser instance, so navigate to `localhost:8080` to access the app if needed. Refresh to show the latest changes for future code changes.

DO NOT modify `system_prompt.md` or `PLAN.md`

Your job is to implement without breaking existing functionality, the specified task:

###### Task 1.2.3-1: “Hide results in view” toggle [L4]

```text
Prompt (L4):

Implement query filtering per FEATURES.md §1.2.3.

Requirement:
- Toggle "Hide results in view" hides query results whose objects are already present in the current viewport.

Define required APIs:
- In CanvasController (Appendix B):
  - Set<String> get visibleObjectIds; // ids of objects currently rendered on canvas
  - Rect get viewportWorldRect;

Implementation shape:
- QueryController stores `hideResultsInView` bool.
- When computing results, if toggle enabled:
  - filter out any result whose objectId ∈ activeCanvasController.visibleObjectIds.

Add tests:
- Unit test for filter logic.
```