Task 6.2-3: Workspace persistence repository

---

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`). You have access to Flutter and Chrome devtools for debugging, inspection, loggin, profiling, etc.

Use `flutter run -d web-server --web-hostname localhost --web-port 8080` to run the web server initially.

You have access to the Chrome browser instance, so navigate to `localhost:8080` to access the app. Refresh to show the latest changes for future code changes.

DO NOT modify `system_prompt.md` or `PLAN.md`

Your job is to implement without breaking existing functionality, the specified task:

##### Task 6.2-3: Workspace persistence repository (Firestore) [L4]


- Deliverable:
  - WorkspaceRepository that reads/writes workspace state using the schema in Appendix A.
  - Snapshot listeners for workspace and active tab state.
- Prompt:
```text
Prompt (L4):

Implement the Firestore-backed WorkspaceRepository for LH2.

Use the exact schema specified in Appendix A (workspaces root collection + subcollections).

Implement these APIs (names required):
- class WorkspaceRepository {
    Stream<WorkspaceMeta> watchWorkspaceMeta(String workspaceId);
    Future<WorkspaceMeta> getWorkspaceMeta(String workspaceId);
    Future<void> upsertWorkspaceMeta(String workspaceId, WorkspaceMeta meta);

    Stream<WorkspaceTab> watchTab(String workspaceId, String tabId);
    Future<WorkspaceTab> getTab(String workspaceId, String tabId);
    Future<String> createTab(String workspaceId, WorkspaceTabDraft draft);
    Future<void> updateTab(String workspaceId, String tabId, WorkspaceTabPatch patch);
    Future<void> deleteTab(String workspaceId, String tabId);

    Stream<List<NodeTemplate>> watchNodeTemplates(String workspaceId, ObjectType type);
    Future<void> upsertNodeTemplate(String workspaceId, NodeTemplate template);
  }

Also:
- Add schemaVersion fields + a migration hook (no migrations needed yet; just scaffolding).
- Implement debounced save for high-frequency writes (viewport pan/zoom).
```
