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


### 1: Interface Layout

#### 1.2: Query Box

##### 1.2.2: Query Syntax

###### Task 1.2.2-2: Real query grammar + parser + AST [L4]

```text
Prompt (L4):

Implement an initial query grammar and parser for LH2 (FEATURES.md §1.2.2).

Constraints:
- Keep it minimal but structured.
- Must still accept arbitrary raw text as fallback.

Proposed syntax (implement):
- type:<project|task|deliverable|session|event|contextRequirement|actualContext>
- status:<draft|scheduled|underway|incomplete|done|adminAttentionNeeded>
- text:"..." or bare words
- date:<YYYY-MM-DD..YYYY-MM-DD>

Implement:
- sealed class QueryNode
- QueryAst { List<QueryNode> nodes; String raw; }
- parseQuery(String raw) -> QueryAst + list of parse errors

Evaluation:
- Evaluate against in-memory cached objects (6.3.1).
- Return stable ordering (by type then name).
```

##### 1.2.1 + 1.2.3: Query overlay UX polish [L2]

```text
Prompt (L2):

Polish query overlay:
- keyboard focus
- up/down to navigate results
- enter to select and focus item on canvas
- hide-results-in-view toggle has clear visual state
```

### 3: Nodes, Widgets and Connections

#### 3.2.8: Context Requirement Node
#### 3.2.9: Actual Context Node

##### Task 3.2.8-1 / 3.2.9-1: Scenario evaluation + grey-out logic [L4]

```text
Prompt (L4):

Implement scenario evaluation per FEATURES.md §3.2.8–3.2.9.

Requirements:
- ActualContext represents current conditions.
- ContextRequirement nodes connected to `conditional` port represent scenarios.
- If a scenario does not match ActualContext, grey it out (dim + disable interactions).

Define matching:
- focusLevel: ActualContext.focusLevel >= ContextRequirement.focusLevel
- contiguousMinutesAvailable >= contiguousMinutesNeeded
- for each resourceTag in requirement: must match actualContext.resourceTags

Implementation shape:
- class ScenarioEvaluator { bool matches(ActualContext actual, ContextRequirement required); }
- CanvasItemState has `bool disabledByScenario`
- Recompute when ActualContext updates.
```

### 6: Data and Auth

#### 6.3: API Usage Optimisation

##### Task 6.3-2: Add lightweight profiling to cache + Firestore calls (console only) [L3]

```text
Prompt (L3):

Add optional performance metrics to telemetry:
- Firestore read latency per operation
- cache hit/miss counts
Output stays console JSON (Appendix G).
```

### 5: Design and Styling

#### 5.3: Responsive Design

##### Task 5.3-2: Responsiveness polish across Hyperpanel + overlays [L2]

```text
Prompt (L2):

Implement responsiveness polish (desktop-only):
- Query overlay collapses to icon when width < breakpoint.
- Crosshair side panel uses min/max widths and becomes overlay drawer on small desktop widths.
- Tab bar uses horizontal scroll when too many tabs.
```

---

# Tests (mapped to coded features)

## v0.0.1

### 6.2 Data Storage Platform

- Test: Firestore emulator CRUD integration for each LH2Object type [L3]
```text
Prompt: Add integration tests using Firestore emulator that validate create/get/update/delete for ProjectGroup, Project, Deliverable, Task, Session, ContextRequirement, Event, ActualContext.
```

### 7.2 Performing Operations + 7.3 Telemetry

- Test: Telemetry JSON format correctness [L3]
```text
Prompt: Add unit tests that validate Telemetry.error() outputs JSON including ts, message, operationId, errorCode, payload, location.
```

## v0.1.0

### 1.1 Tabbed Views

- Test: tab create/rename/close + persistence [L3]
```text
Prompt: Add widget/integration tests ensuring tab creation (flow/calendar), in-place rename, and deletion persist correctly in the workspace Firestore schema.
```

### 2.1 Flow Canvas + 2.5 Selection Tools + 4.2 Shortcuts

- Test: CanvasController JSON round-trip + transforms [L4]
```text
Prompt: Add tests for CanvasController: worldToScreen/screenToWorld inversion, panBy/zoomAt behavior, and JSON serialization round-trip.
```

- Test: Cmd+Shift multi-select and Cmd+M marquee selection [L4]
```text
Prompt: Add integration tests for selection behavior: Cmd+Shift toggles selection; Cmd+M enters marquee mode; selection rectangle selects items.
```

### 1.2 Query Box

- Test: Query results update on Enter + hide-results-in-view toggle [L3]
```text
Prompt: Add widget tests verifying query results do not change while typing, but update on Enter; and hide-results-in-view filters based on active canvas visibleObjectIds.
```

## v0.2.0

### 2.2 Calendar Canvas

- Test: Sticky markers remain pinned while scrolling [L4]
```text
Prompt: Add widget tests verifying sticky time/date markers remain fixed at top during vertical scroll, while horizontal scroll updates dates.
```

- Test: Time interval scaling threshold rules [L4]
```text
Prompt: Add unit tests for ruleIntervalMinutes adjustment logic when minutesPerPixel changes; ensure correct doubling/halving and 24h switch behavior.
```

- Test: Snap-to-grid enforcement and modifier behavior [L4]
```text
Prompt: Add tests verifying snap applies only to Deliverable/Session/ContextRequirement/Event; Cmd toggles snap; snapped endpoint causes auto-snap on the other endpoint; Cmd disables snap in auto-snap mode.
```

## v0.3.0

### 1.2 Query Syntax

- Test: Parser produces AST and evaluation returns expected results [L4]
```text
Prompt: Add unit tests for query parsing and evaluation across sample LH2 objects with filters (type/status/text/date).
```

### 3.2.8–3.2.9 Context scenarios

- Test: Scenario mismatch greys out nodes [L4]
```text
Prompt: Add tests for ScenarioEvaluator.matches and that canvas item rendering is dimmed/disabled when mismatch.
```

---
