Task 5.3-1: Implement desktop responsiveness utilities (Appendix F) [L2]

---

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`). You have access to Flutter and Chrome devtools for debugging, inspection, loggin, profiling, etc.

Use `flutter run -d web-server --web-hostname localhost --web-port 8080` to run the web server initially.

You have access to the Chrome browser instance, so navigate to `localhost:8080` to access the app. Refresh to show the latest changes for future code changes.

DO NOT modify `system_prompt.md` or `PLAN.md`

Your job is to implement without breaking existing functionality, the specified task:

##### Task 5.3-1: Implement desktop responsiveness utilities (Appendix F) [L2]

```text
Prompt (L2):

Implement the responsiveness strategy for LH2 (desktop-only) exactly as specified in Appendix F.

Deliverables:
- LH2Breakpoints
- Layout constraint helpers for:
  - Query overlay width clamping
  - Canvas min size
  - Crosshair side panel width
```