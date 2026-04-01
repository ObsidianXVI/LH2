Task 6.1-1: Minimal auth bootstrap (no auth flows)

---

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`). You have access to Flutter and Chrome devtools for debugging, inspection, loggin, profiling, etc.

Use `flutter run -d web-server --web-hostname localhost --web-port 8080` to run the web server initially.

You have access to the Chrome browser instance, so navigate to `localhost:8080` to access the app. Refresh to show the latest changes for future code changes.

Your job is to implement without breaking existing functionality, the specified task:

##### Task 6.1-1: Minimal auth bootstrap (no auth flows) [L3]


- Deliverable:
  - A “current user” concept used for workspace ownership, without building UI auth flows.
  - Supports emulator.
- Prompt:
```text
Prompt (L3):

Implement a minimal auth bootstrap for LH2 without UI auth flows.

Requirements:
- App can run without user interaction to sign in.
- For local dev, use one of:
  - Anonymous sign-in, OR
  - Hardcoded UID in secrets/.env

Implement:
- class CurrentUser { String uid; }
- currentUserProvider: FutureProvider<CurrentUser>

This UID will be stored on workspace documents (Appendix A), but domain collections remain root collections.
```