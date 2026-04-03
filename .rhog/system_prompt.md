Node Templates

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`). You have access to Flutter and Chrome devtools for debugging, inspection, loggin, profiling, etc.

Do not use browser or `flutter run` to actually run the app.

DO NOT modify `system_prompt.md` or `PLAN.md`

Your job is to implement without breaking existing functionality, the specified tasks (and dont forget to write tests as well):


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
