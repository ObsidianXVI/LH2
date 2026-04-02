Task 1.1.4-1: Close tab (hover X, delete state)
---

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`). You have access to Flutter and Chrome devtools for debugging, inspection, loggin, profiling, etc.

You have access to the Chrome browser instance, so navigate to `localhost:8080` to access the app if needed. Refresh to show the latest changes for future code changes.

DO NOT modify `system_prompt.md` or `PLAN.md`

Your job is to implement without breaking existing functionality, the specified task:

###### Task 1.1.4-1: Close tab (hover X, delete state) [L2]

```text
Prompt (L2):

Implement tab closing per FEATURES.md §1.1.4.

Requirements:
- Hover tab -> show "x".
- Clicking "x" deletes that tab and discards its configuration/state data.
- Persist deletion in Firestore (WorkspaceRepository.deleteTab).

Edge cases:
- If active tab deleted, switch to nearest neighbor in tab order.
```