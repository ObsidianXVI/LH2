Task 7.1-1: Scaffold Flutter web app

---

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`). You have access to Flutter and Chrome devtools for debugging, inspection, loggin, profiling, etc.

Use `flutter run -d web-server --web-hostname localhost --web-port 8080` to run the web server initially.

You have access to the Chrome browser instance, so navigate to `localhost:8080` to access the app. Refresh to show the latest changes for future code changes.

Your job is to implement without breaking existing functionality, the specified task:

##### Task 7.1-2: Riverpod DI composition root [L4]

- Deliverable:
  - Riverpod provider graph for app singletons: `FirebaseApp`, `FirebaseFirestore`, `FirebaseAuth` (even if auth flow is stubbed), `FirestoreDBInterface`, `LH2API`, caches, workspace repository.
  - Clear layering: UI → application/services → data.
- Prompt:
```text
Prompt (L4):

Implement the LH2 dependency injection and layering using Riverpod.

Constraints:
- Flutter Web.
- Keep layering clear:
  - data/: FirestoreDBInterface, repositories
  - domain/: operations, models (lh2_stub types), controller state
  - ui/: widgets

Implement providers (names are required):
- firebaseAppProvider: FutureProvider<FirebaseApp>
- firestoreProvider: Provider<FirebaseFirestore>
- authProvider: Provider<FirebaseAuth>
- dbProvider: Provider<FirestoreDBInterface>
- lh2ApiProvider: Provider<LH2API>
- workspaceRepoProvider: Provider<WorkspaceRepository>
- caches: Provider<GenericCache<T>> for each LH2Object type (or a typed wrapper)

Include:
- A single file that acts as the composition root (e.g. lib/app/providers.dart).
- Example usage from UI to read LH2API and workspace repo.
```
