Task 2.4.1-1: Info popup view/edit with Save/Cancel and Enter/Esc

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`). You have access to Flutter and Chrome devtools for debugging, inspection, loggin, profiling, etc.

You have access to the Chrome browser instance, so navigate to `localhost:8080` to access the app if needed. Refresh to show the latest changes for future code changes.

DO NOT modify `system_prompt.md` or `PLAN.md`

Your job is to implement without breaking existing functionality, the specified task:

###### Task 2.4.1-1: Info popup view/edit with Save/Cancel and Enter/Esc [L4]


```text
Prompt (L4):

Implement Information Popup per FEATURES.md §2.4.1.

Requirements:
- Clicking a node/widget opens a popup near it.
- Popup shows editable fields for that object/widget.
- Buttons: Cancel / Save.
- Enter OR click outside popup => Save.
- Esc => Cancel.

Implementation shape:
- InfoPopupController (Riverpod notifier) manages:
  - selectedItemId
  - isOpen
  - mode: view|add
  - draft form state
  - anchorScreenRect (for positioning)

- Widget: InfoPopupOverlay
- Field rendering:
  - Use a registry: Map<ObjectType, Widget Function(LH2Object draft, onChanged)>.

Persist:
- Save triggers operations:
  - api.objects.update (for domain objects)
  - api.canvas.updateItem (for widget config)
```
