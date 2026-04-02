Task 1.2.2-1: Accept-any-text placeholder parser (no grammar yet)

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`). You have access to Flutter and Chrome devtools for debugging, inspection, loggin, profiling, etc.

You have access to the Chrome browser instance, so navigate to `localhost:8080` to access the app if needed. Refresh to show the latest changes for future code changes.

DO NOT modify `system_prompt.md` or `PLAN.md`

Your job is to implement without breaking existing functionality, the specified task:

###### Task 1.2.2-1: Accept-any-text placeholder parser (no grammar yet) [L3]

```text
Prompt (L3):

Implement a placeholder query parser/evaluator for now:
- Accept any text input.
- Perform a simple case-insensitive substring search across cached LH2 objects.

Define:
- class QueryAst { String raw; }
- QueryAst parseQuery(String raw) => QueryAst(raw)
- Future<List<LH2ObjectRef>> evaluateQuery(QueryAst ast)

Integrate with QueryOverlay: on Enter -> parse + evaluate.
```