Task 2.1.1-1: Implement CanvasController base + FlowCanvasController

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`). You have access to Flutter and Chrome devtools for debugging, inspection, loggin, profiling, etc.

You have access to the Chrome browser instance, so navigate to `localhost:8080` to access the app if needed. Refresh to show the latest changes for future code changes.

DO NOT modify `system_prompt.md` or `PLAN.md`

Your job is to implement without breaking existing functionality, the specified task:

###### Task 2.1.1-1: Implement CanvasController base + FlowCanvasController (Appendix B) [L4]

```text
Prompt (L4):

Implement the CanvasController API + JSON encoding exactly per Appendix B.

Requirements:
- Base CanvasController supports:
  - viewport pan/zoom
  - world<->screen transforms
  - item registry (nodes + widgets)
  - selection set
  - serialization to JSON for workspace persistence

Implement these classes (names required):
- sealed class CanvasKind { flow, calendar }
- class CanvasViewport { Offset pan; double zoom; Size viewportSizePx; }
- abstract class CanvasController extends ChangeNotifier { ... }
- class FlowCanvasController extends CanvasController { double gridSizePx; }

Also implement:
- CanvasController.fromJson(Map json)
- Map<String,Object?> toJson()
- Methods:
  - Offset worldToScreen(Offset world)
  - Offset screenToWorld(Offset screen)
  - void panBy(Offset deltaScreen)
  - void zoomAt({required Offset focalScreen, required double scaleDelta})
  - void setSelection(Set<String> itemIds)
  - Set<String> computeVisibleObjectIds()

Ensure the shape is stable for saving in Firestore WorkspaceTab.controller.
```

# Appendix B — CanvasController API + JSON Shape

## Shared concepts

### CanvasViewport

- `pan`: Offset in world coordinates (world origin shifts by pan).
- `zoom`: scale factor (1.0 default).

### CanvasItem

- `itemId`: string.
- `itemType`: node|widget.
- `worldRect`: Rect (x,y,w,h) in world coordinates.
- `objectId`: Firestore doc id (for nodes).

## Required API surface

```dart
abstract class CanvasController extends ChangeNotifier {
  CanvasKind get kind;
  CanvasViewport get viewport;
  Map<String, CanvasItem> get items;
  Map<String, CanvasLink> get links;
  Set<String> get selection;

  // transforms
  Offset worldToScreen(Offset world);
  Offset screenToWorld(Offset screen);

  // viewport
  void panByScreenDelta(Offset deltaScreen);
  void zoomAt({required Offset focalScreen, required double scaleDelta});
  Rect get viewportWorldRect;

  // items
  void addItem(CanvasItem item);
  void updateItemRect(String itemId, Rect newWorldRect);
  void removeItem(String itemId);

  // selection
  void setSelection(Set<String> itemIds);
  void toggleSelection(String itemId);

  // query filter support
  Set<String> get visibleObjectIds;
  Set<String> computeVisibleObjectIds();

  // persistence
  Map<String, Object?> toJson();
}
```

### FlowCanvasController JSON

```json
{
  "kind": "flow",
  "viewport": {"panX":0,"panY":0,"zoom":1.0},
  "gridSizePx": 24
}
```

### CalendarCanvasController JSON

```json
{
  "kind": "calendar",
  "viewport": {"panX":0,"panY":0,"zoom":1.0},
  "anchorStartSgt": "2026-03-30T00:00:00+08:00",
  "minutesPerPixel": 2.0,
  "ruleIntervalMinutes": 60
}
```

---
