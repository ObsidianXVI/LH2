Task 3.1.1-1: Text widget rendering + editing

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`). You have access to Flutter and Chrome devtools for debugging, inspection, loggin, profiling, etc.

You have access to the Chrome browser instance, so navigate to `localhost:8080` to access the app if needed. Refresh to show the latest changes for future code changes.

DO NOT modify `system_prompt.md` or `PLAN.md`

Your job is to implement without breaking existing functionality, the specified task:

###### Task 3.1.1-1: Text widget rendering + editing [L2]

```text
Prompt (L2):

Implement the Text Widget per FEATURES.md §3.1.1.

Requirements:
- Editable text field.
- Style configurable (font size, color) within constraints of LH2 theme.

Data model:
- CanvasItem.kind = widget
- widgetType = text
- config JSON: { text, style: { fontSize, color } }
```