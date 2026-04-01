Task 6.2-2: Implement FirestoreDBInterface using `.rhog/boilerplate/db_interface.dart` root collections

---

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`). You have access to Flutter and Chrome devtools for debugging, inspection, loggin, profiling, etc.

Use `flutter run -d web-server --web-hostname localhost --web-port 8080` to run the web server initially.

You have access to the Chrome browser instance, so navigate to `localhost:8080` to access the app. Refresh to show the latest changes for future code changes.

Your job is to implement without breaking existing functionality, the specified task:

##### Task 6.2-2: Implement FirestoreDBInterface using `.rhog/boilerplate/db_interface.dart` root collections [L3]

```text
Prompt (L3):

Implement FirestoreDBInterface CRUD exactly following `.rhog/boilerplate/db_interface.dart`.

Requirements:
- Root collections only:
  - projectGroups, projects, deliverables, tasks, sessions, contextRequirements, events, actualContexts
- Use create via set() on auto-id doc.
- Use updateObject via update().
- JSON conversion uses lh2_stub/lib/types.dart toJson/fromJson.

Add:
- Unit tests for JSON round-trip of each LH2Object.
- Integration tests using Firestore emulator for create/get/update/delete for each LH2Object.
```
