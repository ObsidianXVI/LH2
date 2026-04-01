Task 7.3-1: Telemetry logger (console JSON)

---

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`). You have access to Flutter and Chrome devtools for debugging, inspection, loggin, profiling, etc.

Use `flutter run -d web-server --web-hostname localhost --web-port 8080` to run the web server initially.

You have access to the Chrome browser instance, so navigate to `localhost:8080` to access the app. Refresh to show the latest changes for future code changes.

Your job is to implement without breaking existing functionality, the specified task:

##### Task 7.3-1: Telemetry logger (console JSON) [L3]

- Deliverable:
  - Console-only JSON telemetry logs with: error message, operation id, payload, code location.
- Prompt:
```text
Prompt (L3):

Implement LH2 telemetry instrumentation (FEATURES.md §7.3.1).

Requirements:
- Log JSON to console only.
- For any LH2OpError, produce a JSON object with:
  - ts (epoch millis)
  - level ("error"|"warn")
  - message
  - operationId
  - errorCode
  - payload (JSON)
  - location (string like "lib/.../file.dart:Class.method")

Implement:
- class Telemetry { void error(LH2OpError e); void warn(...); }
- helper `String captureLocation(StackTrace st, {int maxFrames = 8})`

Ensure logging is used by the operation framework (Appendix G).
```
