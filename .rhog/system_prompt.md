Task 3.1.1-2: Connection model + rendering + persistence (Flow Canvas)

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`). You have access to Flutter and Chrome devtools for debugging, inspection, loggin, profiling, etc.

Do not use browser or `flutter run` to actually run the app.

DO NOT modify `system_prompt.md` or `PLAN.md`

Your job is to implement without breaking existing functionality, the specified task (and dont forget to write tests as well):


###### Task 3.1.2-1: Query board (fixed width, resizable height, rename title, edit query) [L4]

```text
Prompt (L4):

Implement Query Board Widget per FEATURES.md §3.1.2.

Requirements:
- Shows latest results of a query string.
- Board title rename: double click in-place.
- Edit button opens a small editor for the query string.
- Height resizable (drag handle), width fixed.

Data model:
- widgetType = queryBoard
- config JSON:
  { title, queryText, widthPx (fixed), heightPx, hideResultsInView (bool?) }

Integration:
- Query evaluation is placeholder now (v0.1.0). Use QueryController.evaluate(ast) to update board.
```