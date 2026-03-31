Task 7.1-1: Scaffold Flutter web app

---

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`).

Your job is to implement without breaking existing functionality, the specified task:

## Task 7.1-1: Scaffold Flutter web app + wire `lh2_stub` + disable browser context menu [L2]

- Deliverable:
  - Flutter web app skeleton that boots into `LH2App`.
  - Imports/uses `lh2_stub` types and `LH2API` (from `lh2_stub/lib/api/*`).
  - Disables browser context menu on right-click.
- Prompt:
```text
Prompt:

Goal: Create the LH2 Flutter Web app skeleton.

Requirements:
1) Create a Flutter web app (desktop-first) that boots into a root widget `LH2App`.
2) Add local path dependency on `lh2_stub/` and import `lh2_stub` types (`LH2Object`, `Project`, etc.) and `LH2API`.
3) Disable the browser context menu for right-click on web (so the app can use right-click menus).
4) Add a minimal routing/shell structure but keep everything in a single view for now.

Output:
- File changes for the Flutter app.
- Notes on how right-click context menu is disabled on Flutter Web.
```