Multiple Tasks

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`). You have access to Flutter and Chrome devtools for debugging, inspection, loggin, profiling, etc.

Do not use browser or `flutter run` to actually run the app.

After each task, run the following command to commit changes:

```
git add .
git commit -m "<Task Name + Code> done"
```

DO NOT modify `system_prompt.md` or `PLAN.md`

Your job is to implement without breaking existing functionality, the specified tasks (and dont forget to write tests after each task, though you dont have to run the tests for now):


#### 2.2: Calendar Canvas

##### 2.2.1: Timescale Overlays

###### Task 2.2.1-1: CalendarCanvasView base + timescale overlay painter (Appendix C) [L4]

```text
Prompt (L4):

Implement Calendar Canvas base per FEATURES.md §2.2.1 and Appendix C.

Requirements:
- Background blank.
- Lowest layer is TimescaleOverlay:
  - equally spaced vertical rules (time rules)
  - except time/date markers are above it.

Implementation shape:
- CalendarCanvasView(widget)
- CalendarTimescalePainter(CustomPainter)
- Layering using Stack:
  1) Timescale overlay (CustomPaint)
  2) Items layer (nodes)
  3) Sticky markers overlay (top)
```

##### 2.2.2: Sticky Datetime Markers

###### Task 2.2.2-1: Sticky time & date markers (top-fixed) [L4]

```text
Prompt (L4):

Implement sticky datetime markers per FEATURES.md §2.2.2 and Appendix C.

Requirements:
- Time and date markers stick to top of viewport despite vertical scrolling.
- Horizontal scrolling moves forward/backward in time.
- Display timezone: SGT (UTC+8).

Implementation details:
- CalendarCanvasController stores:
  - DateTime anchorStartSgt // start of visible week
  - double minutesPerPixel
  - int ruleIntervalMinutes (60, 120, 240, ..., 1440)
  - Offset panWorld (x,y)

- Sticky overlay computes visible columns based on pan/zoom and renders:
  - top row: date markers (e.g. 21 TUE)
  - inside timescale: time markers (e.g. 1200)

Time formatting:
- Use 24h format.
- Ensure SGT display even if browser locale differs (suggest `timezone` package).
```

##### 2.2.3: Time Interval Scaling

###### Task 2.2.3-1: Cmd+scroll time scaling algorithm with thresholds + label density [L4]

```text
Prompt (L4):

Implement time interval scaling per FEATURES.md §2.2.3 and Appendix C.

User interaction:
- Vertical scroll while holding Cmd:
  - scroll up => squish timescale
  - scroll down => expand timescale

Model:
- Canonical scale: minutesPerPixel (double).
- Rules:
  - Base rule interval starts at 60 minutes.
  - Compute pixelSpacing = ruleIntervalMinutes / minutesPerPixel.
  - Keep pixelSpacing within [minPx, maxPx] via changing ruleIntervalMinutes.
    - If pixelSpacing < minPx => ruleIntervalMinutes *= 2 (remove alternating lines)
    - If pixelSpacing > maxPx and ruleIntervalMinutes > 60 => ruleIntervalMinutes /= 2
  - When ruleIntervalMinutes reaches 1440 (24h):
    - time markers become dates (21 TUE, 22 WED)
    - date marker becomes month.

Implementation:
- CalendarCanvasController.handleCmdScroll(double deltaY):
  - minutesPerPixel = clamp(minutesPerPixel * exp(k * deltaY), min, max)
  - recompute ruleIntervalMinutes using hysteresis thresholds to avoid flicker
  - notifyListeners

Update painter:
- Use ruleIntervalMinutes to draw rules + labels.
```

##### 2.2.4: Free Drawing and Snap-To-Grid

###### Task 2.2.4-1: Snap toggle + auto-snap rules (Appendix D) [L4]

```text
Prompt (L4):

Implement freehand vs snap-to-grid per FEATURES.md §2.2.4 and Appendix D.

Rules:
- Default: freehand; moving a node does NOT update its timestamps.
- Holding Cmd before tapping/moving/dragging enables snap-to-grid.
- Snap-to-grid only applies to nodes (not widgets).
- If start or end timestamp has been snapped once:
  - dragging the other end auto-snaps without holding Cmd
  - in this auto-snap mode, holding Cmd DISABLES snapping

Implementation must introduce per-item snap metadata:
- CanvasItemSnapState { bool startSnapped; bool endSnapped; }

When snapping:
- Snap increment is 15 minutes.
- Convert pointer movement -> proposed start/end timestamps -> snap -> update node bounds/time.
```

##### 2.2.5: Snappable Nodes

###### Task 2.2.5-1: Enforce snappable types only [L3]

```text
Prompt (L3):

Implement snappable node enforcement per FEATURES.md §2.2.5.

Only these types snap:
- Deliverable
- Session
- ContextRequirement
- Event

Implementation:
- CanvasItem has objectType.
- CalendarCanvasController.shouldSnap(item): bool based on type.
- If not snappable, ignore snap even if Cmd held.
```

##### 2.2.6: Node Styling Choices

###### Task 2.2.6-1: Calendar-specific node renderer variants + constraints [L4]

```text
Prompt (L4):

Implement Calendar Canvas node styling per FEATURES.md §2.2.6.

Deliverable:
- special placing of out-ports
- can be nested within context-requirement nodes
- root-level deliverables (global deliverables) must not overlap with any other nodes

Session:
- title/description text colour-coded by project colour
- also show the name of the task that it is from

Context Requirement:
- mixed-colour semi-opaque grey + context colour
- dashed border and grey context name
- additional `conditional` port

Event:
- compact 1–2 line layout
- extra height if details exist

Implementation details:
- Add CalendarNodeRendererRegistry separate from Flow.
- Add collision check for root-level deliverables:
  - before committing add/move, check intersect with any existing item bounds
  - if overlap, block and show warning toast/snackbar.
```

---
