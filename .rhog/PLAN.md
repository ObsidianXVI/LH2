Project Plan for LH2 (Lighthouse Hyperpanel)

---

# Releases

- v0.0.1: Foundations & Architecture Baseline
- v0.1.0: Hyperpanel Shell + Flow Canvas MVP
- v0.2.0: Calendar Canvas & Advanced Interactions
- v0.3.0: Querying, Context Scenarios, and UX Polish

---

# Global Decisions / Constraints (from Q/A + FEATURES.md)

- Platform: Flutter (Dart) Web, desktop-first.
- Backend: Firebase Auth + Firestore.
  - Local dev uses Firebase emulators.
  - Firebase project id: `lh2-db`.
  - Firebase config stored in `secrets/.env` (not committed).
- Firestore domain data uses **root collections** (see `.rhog/boilerplate/db_interface.dart`).
- Workspace persistence (tab configs + node templates + canvas state) is stored in Firestore in a **separate root collection** (schema defined by us; see Appendix A).
- Calendar Canvas defaults:
  - Default view: **full week**.
  - Timestamps displayed in **SGT (UTC+8)**.
- Query Box results update timing: **results update once `Enter` is hit** (FEATURES.md §1.2.1). (Not live-typing for now.)
- State management / DI: Riverpod.
- Interaction constraints:
  - Browser context menu disabled in app.
  - Operations must be encapsulated with operation IDs; telemetry logs JSON to console (FEATURES.md §7.2–7.3).
  - Optimisations: in-memory caching (`GenericCache`), Keys to reduce rebuilds (FEATURES.md §6.3).

---

# “Deep Spec” Appendices

These appendices define concrete data shapes and APIs that tasks below must follow.

- **Appendix A**: Workspace Firestore data model (collection/doc schema, versioning, listeners)
- **Appendix B**: CanvasController API + JSON shape (Flow + Calendar specialisations)
- **Appendix C**: Calendar Canvas rendering model (layers, time↔pixel mapping, scaling thresholds, sticky markers)
- **Appendix D**: Snap-to-grid & temporal mapping algorithm (Cmd-modifier rules, snappable types)
- **Appendix E**: Keyboard shortcuts engine outline (key chord parsing, registry, dispatch)
- **Appendix F**: Responsiveness strategy (desktop breakpoints + layout constraints)
- **Appendix G**: Operations + telemetry conventions (IDs, error model, JSON payload)

---

# Features In Each Release (coded to `.rhog/FEATURES.md`)

## v0.0.1: Foundations & Architecture Baseline

### 7: Overall Architecture

#### 7.1: App (Client) Stubs

##### Task 7.1-1: Scaffold Flutter web app + wire `lh2_stub` + disable browser context menu [L2]

*DONE*

- Deliverable:
  - Flutter web app skeleton that boots into `LH2App`.
  - Imports/uses `lh2_stub` types and `LH2API` (from `lh2_stub/lib/api/*`).
  - Disables browser context menu on right-click.
- Prompt:
```text
Prompt (L2):

Goal: Create the LH2 Flutter Web app skeleton.

Requirements:
1) Create a Flutter web app (desktop-first) that boots into a root widget `LH2App`.
2) Add local path dependency on `lh2_stub/` and import `lh2_stub` types (`LH2Object`, `Project`, etc.) and `LH2API`.
3) Disable the browser context menu for right-click on web (so the app can use right-click menus).
4) Add a minimal routing/shell structure but keep everything in a single view for now.

Output:
- File changes for the Flutter app.
- Notes on how right-click context menu is disabled on Flutter Web.
```

##### Task 7.1-2: Riverpod DI composition root [L4]

*DONE*

- Deliverable:
  - Riverpod provider graph for app singletons: `FirebaseApp`, `FirebaseFirestore`, `FirebaseAuth` (even if auth flow is stubbed), `FirestoreDBInterface`, `LH2API`, caches, workspace repository.
  - Clear layering: UI → application/services → data.
- Prompt:
```text
Prompt (L4):

Implement the LH2 dependency injection and layering using Riverpod.

Constraints:
- Flutter Web.
- Keep layering clear:
  - data/: FirestoreDBInterface, repositories
  - domain/: operations, models (lh2_stub types), controller state
  - ui/: widgets

Implement providers (names are required):
- firebaseAppProvider: FutureProvider<FirebaseApp>
- firestoreProvider: Provider<FirebaseFirestore>
- authProvider: Provider<FirebaseAuth>
- dbProvider: Provider<FirestoreDBInterface>
- lh2ApiProvider: Provider<LH2API>
- workspaceRepoProvider: Provider<WorkspaceRepository>
- caches: Provider<GenericCache<T>> for each LH2Object type (or a typed wrapper)

Include:
- A single file that acts as the composition root (e.g. lib/app/providers.dart).
- Example usage from UI to read LH2API and workspace repo.
```

#### 7.2: Performing Operations

##### Task 7.2-1: Operation framework (IDs, error model, throw vs recover) [L4]

*DONE*

- Deliverable:
  - A lightweight operations layer used by UI; UI should not directly call Firestore.
  - Operation IDs follow `api.<area>.<action>` (aligned with `lh2_stub` `APIOperation` style).
  - Standard result and standard error codes.
- Prompt:
```text
Prompt (L4):

Design and implement an LH2 operation framework (client-side only for now).

Requirements:
- All business logic and data mutations must be encapsulated as operations (FEATURES.md §7.2).
- Each operation must have:
  - operationId: String (format: api.<area>.<action>)
  - input payload object (JSON-encodable)
  - typed output
  - LH2OpError with errorCode, message, isFatal, cause

Implement these Dart types (names required):
- class LH2OpError implements Exception { String operationId; String errorCode; String message; Map<String,Object?> payload; String? location; Object? cause; bool isFatal; }
- class LH2OpResult<T> { T? value; LH2OpError? error; bool get ok; }
- abstract class LH2Operation<In, Out> { String get operationId; Future<LH2OpResult<Out>> run(In input); }

Implement helper:
- Future<T> runOrThrow<T>(LH2Operation<In,T> op, In input) which throws if fatal.

Also implement initial concrete operations used later:
- api.workspace.load
- api.workspace.save
- api.canvas.addItem
- api.canvas.updateViewport
- api.objects.get
- api.objects.update

Do not implement UI yet, but provide example usage from a Riverpod notifier.
```

#### 7.3: Logging and Observability

##### Task 7.3-1: Telemetry logger (console JSON) [L3]

*DONE*

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

### 6: Data and Auth

#### 6.1: Authentication Platform

##### Task 6.1-1: Minimal auth bootstrap (no auth flows) [L3]

*DONE*


- Deliverable:
  - A “current user” concept used for workspace ownership, without building UI auth flows.
  - Supports emulator.
- Prompt:
```text
Prompt (L3):

Implement a minimal auth bootstrap for LH2 without UI auth flows.

Requirements:
- App can run without user interaction to sign in.
- For local dev, use one of:
  - Anonymous sign-in, OR
  - Hardcoded UID in secrets/.env

Implement:
- class CurrentUser { String uid; }
- currentUserProvider: FutureProvider<CurrentUser>

This UID will be stored on workspace documents (Appendix A), but domain collections remain root collections.
```

#### 6.2: Data Storage Platform

##### Task 6.2-1: Firebase init + emulator wiring [L2]

*DONE*

```text
Prompt (L2):

Wire Firebase Core/Auth/Firestore for Flutter Web.

Requirements:
- Firebase project id: lh2-db
- Config stored in secrets/.env (do not commit)
- Use Firestore + Auth emulators in debug builds.

Provide:
- Initialization code (main.dart)
- Emulator host/port config
- Simple smoke check that can read a known collection.
```

##### Task 6.2-2: Implement FirestoreDBInterface using `.rhog/boilerplate/db_interface.dart` root collections [L3]

*DONE*

```text
Prompt (L3):

Implement FirestoreDBInterface CRUD exactly following `.rhog/boilerplate/db_interface.dart`.

Requirements:
- Root collections only:
  - projectGroups, projects, deliverables, tasks, sessions, contextRequirements, events, actualContexts
- Use create via set() on auto-id doc.
- Use updateObject via update().
- JSON conversion uses lh2_stub/lib/types.dart toJson/fromJson.

Add:
- Unit tests for JSON round-trip of each LH2Object.
- Integration tests using Firestore emulator for create/get/update/delete for each LH2Object.
```

##### Task 6.2-3: Workspace persistence repository (Firestore) [L4]

*DONE*

- Deliverable:
  - WorkspaceRepository that reads/writes workspace state using the schema in Appendix A.
  - Snapshot listeners for workspace and active tab state.
- Prompt:
```text
Prompt (L4):

Implement the Firestore-backed WorkspaceRepository for LH2.

Use the exact schema specified in Appendix A (workspaces root collection + subcollections).

Implement these APIs (names required):
- class WorkspaceRepository {
    Stream<WorkspaceMeta> watchWorkspaceMeta(String workspaceId);
    Future<WorkspaceMeta> getWorkspaceMeta(String workspaceId);
    Future<void> upsertWorkspaceMeta(String workspaceId, WorkspaceMeta meta);

    Stream<WorkspaceTab> watchTab(String workspaceId, String tabId);
    Future<WorkspaceTab> getTab(String workspaceId, String tabId);
    Future<String> createTab(String workspaceId, WorkspaceTabDraft draft);
    Future<void> updateTab(String workspaceId, String tabId, WorkspaceTabPatch patch);
    Future<void> deleteTab(String workspaceId, String tabId);

    Stream<List<NodeTemplate>> watchNodeTemplates(String workspaceId, ObjectType type);
    Future<void> upsertNodeTemplate(String workspaceId, NodeTemplate template);
  }

Also:
- Add schemaVersion fields + a migration hook (no migrations needed yet; just scaffolding).
- Implement debounced save for high-frequency writes (viewport pan/zoom).
```

#### 6.3: API Usage Optimisation

##### 6.3.1: Native In-App Caching

##### Task 6.3.1-1: Improve `GenericCache` to be type-safe + TTL + invalidation [L3]

*DONE*

```text
Prompt (L3):

Refactor/extend `.rhog/skills/caching.dart` GenericCache to support:
- Type-safe caching of Firestore-loaded models (LH2Object subtypes).
- Optional TTL per entry.
- Manual invalidation (invalidate(id), invalidateAll())
- initAll should correctly store T, not QueryDocumentSnapshot.

Provide:
- Updated GenericCache<T> implementation.
- Unit tests for cache hit/miss, TTL expiry, and invalidate().
```

##### 6.3.2: Use of Keys to Reduce Widget Rebuilds

##### Task 6.3.2-1: Key strategy guidelines + utility helpers [L2]

*DONE*

```text
Prompt (L2):

Add a small set of guidelines and utility helpers for using Keys in LH2 to reduce rebuilds.

Include:
- When to use ValueKey(objectId), ObjectKey(model), and GlobalKey.
- A helper like `Key canvasItemKey(CanvasItem item)`.
- Example usage in a node list builder.
```

### 5: Design and Styling

#### 5.1: Design Philosophy and Branding

##### Task 5.1-1: Theme baseline + Menlo everywhere [L2]

*DONE*

```text
Prompt (L2):

Create the LH2 baseline theme:
- Use Menlo font family globally.
- Provide a `LH2Theme` wrapper with:
  - colors (placeholder values for now)
  - spacing scale (8px base)
  - text styles for tab labels, node titles, body

Implement:
- ThemeData extension or InheritedWidget
- Ensure all Text uses Menlo via defaultTextStyle/theme
```

#### 5.2: Figma Designs

##### Task 5.2-1: Extract color tokens from Figma (manual first, automate later) [L2]

*DONE*

```text
Prompt (L2):

Create a design token file `lib/ui/theme/tokens.dart`.

For now:
- Manually add a placeholder palette matching the Figma intent.
- Structure tokens so we can later replace values with exact Figma tokens.

Define:
- LH2Colors { background, panel, border, textPrimary, textSecondary, accentBlue, selectionBlue, dangerRed, ... }
```

#### 5.3: Responsive Design

##### Task 5.3-1: Implement desktop responsiveness utilities (Appendix F) [L2]

*DONE*

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

#### 5.4: Adaptive Design

- No implementation in current releases; ensure architecture doesn’t prevent future read-only mobile.

---

## v0.1.0: Hyperpanel Shell + Flow Canvas MVP

### 1: Interface Layout

#### 1.1: Tabbed Views

##### 1.1.1: Tab Bar

###### Task 1.1.1-1: Tab bar UI (hidden-on-hover, active label always visible) [L2]

*DONE*

```text
Prompt (L2):

Implement the LH2 tab bar UI per FEATURES.md §1.1.1.

Requirements:
- Tab bar is usually hidden: only the active tab’s name is visible.
- When mouse enters the tab bar area, reveal full tab strip (like VS Code).
- Clicking a tab activates it.

Implement widgets:
- HyperpanelScaffold
- DocumentTabBar (name required)
  - inputs: List<TabMeta>, activeTabId, onSelect(tabId)
  - hover reveal animation (e.g. AnimatedContainer height)

State:
- Use Riverpod: activeTabIdProvider, tabListProvider.
```

##### 1.1.2: Tab Creation

###### Task 1.1.2-1: Create tab via right-click menu (Flow vs Calendar) [L2]

*DONE*

```text
Prompt (L2):

Implement tab creation per FEATURES.md §1.1.2.

Requirements:
- "Create new tab" triggers a context menu asking: Flow Canvas or Calendar Canvas.
- On selection, create a tab persisted to Firestore workspace (Appendix A):
  - kind = flow|calendar
  - default title (e.g. "Flow 1", "Calendar 1")
  - default controller state (Appendix B)

Implement:
- WorkspaceController (Riverpod Notifier) with method `createTab(CanvasKind kind)`
- Use WorkspaceRepository.createTab()
```

##### 1.1.3: Tab Renaming

###### Task 1.1.3-1: In-place rename (double click, save on Enter) [L2]

*DONE*

```text
Prompt (L2):

Implement tab rename per FEATURES.md §1.1.3.

Requirements:
- Double click tab label -> becomes TextField.
- Enter commits rename and persists to Firestore.
- Esc cancels.

Implement:
- EditableTabLabel widget
- WorkspaceController.renameTab(tabId, newTitle)
```

##### 1.1.4: Tab Closing/Deletion

###### Task 1.1.4-1: Close tab (hover X, delete state) [L2]

*DONE*

```text
Prompt (L2):

Implement tab closing per FEATURES.md §1.1.4.

Requirements:
- Hover tab -> show "x".
- Clicking "x" deletes that tab and discards its configuration/state data.
- Persist deletion in Firestore (WorkspaceRepository.deleteTab).

Edge cases:
- If active tab deleted, switch to nearest neighbor in tab order.
```

#### 1.2: Query Box

##### 1.2.1: Query Box Overlay

###### Task 1.2.1-1: Query overlay layout + “Enter to run” behavior [L2]

*DONE*

```text
Prompt (L2):

Implement the Query Box overlay per FEATURES.md §1.2.1.

Requirements:
- Left overlay contains:
  - TextField for query input
  - results list area
- Results update only when Enter is pressed (onSubmitted), not on every keystroke.

Implement:
- QueryOverlay widget
  - state: queryText, results
  - onSubmitted -> QueryController.runQuery(queryText)

Wire:
- Use Riverpod QueryController.
```

##### 1.2.2: Query Syntax

###### Task 1.2.2-1: Accept-any-text placeholder parser (no grammar yet) [L3]

*DONE*

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

##### 1.2.3: Query Filters

###### Task 1.2.3-1: “Hide results in view” toggle [L4]

*DONE*

```text
Prompt (L4):

Implement query filtering per FEATURES.md §1.2.3.

Requirement:
- Toggle "Hide results in view" hides query results whose objects are already present in the current viewport.

Define required APIs:
- In CanvasController (Appendix B):
  - Set<String> get visibleObjectIds; // ids of objects currently rendered on canvas
  - Rect get viewportWorldRect;

Implementation shape:
- QueryController stores `hideResultsInView` bool.
- When computing results, if toggle enabled:
  - filter out any result whose objectId ∈ activeCanvasController.visibleObjectIds.

Add tests:
- Unit test for filter logic.
```

### 3: Nodes, Widgets and Connections

### 2: Canvases

#### 2.1: Flow Canvas

##### 2.1.1: CanvasController

###### Task 2.1.1-1: Implement CanvasController base + FlowCanvasController (Appendix B) [L4]

*DONE*

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

###### Task 2.1-2: Flow Canvas rendering + interaction (grid, pan/zoom, item drag) [L4]

*DONE*

```text
Prompt (L4):

Implement Flow Canvas per FEATURES.md §2.1.

Requirements:
- Infinite scroll canvas with grid background.
- Pan/zoom interactions:
  - drag to pan
  - Cmd/Ctrl + scroll to zoom
  - plain scroll pans (or vertical scroll pans)
- Render items (nodes/widgets) with positions stored in FlowCanvasController.

Implementation guidance:
- Prefer using `vs_node_view` if feasible.
- Wrap canvas in Listener to capture pointer + scroll signals.
- Maintain a single source of truth for viewport in FlowCanvasController.

Expose these UI components:
- FlowCanvasView(widget) { FlowCanvasController controller; }
- GridBackgroundPainter
```

#### 2.3: Right-Click Menu

##### 2.3.1: Adding Nodes

###### Task 2.3.1-1: Context menu with "Add Node" → type → template [L4]

*DONE*

```text
Prompt (L4):

Implement the canvas right-click menu per FEATURES.md §2.3.1.

Requirements:
- Right-click on canvas opens context menu.
- Hover "Add Node" -> shows node types.
- Hover node type -> shows templates for that type.
- Clicking template:
  - creates a CanvasItem referencing a domain object OR a new draft object
  - opens Information Popup in "Adding Information" mode (FEATURES §2.4.2)

Data model:
- NodeTemplate stored in workspace (Appendix A).
- CanvasItem created via operation `api.canvas.addItem`.

UI:
- Use OverlayEntry for menus.
- Ensure browser context menu is suppressed.
```

#### 2.4: Information Popup

##### 2.4.1: Viewing Information

###### Task 2.4.1-1: Info popup view/edit with Save/Cancel and Enter/Esc [L4]

*DONE*

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

##### 2.4.2: Adding Information

###### Task 2.4.2-1: Auto-open popup after adding a node/widget [L2]

*DONE*

```text
Prompt (L2):

Implement FEATURES.md §2.4.2.

Requirements:
- When a node/widget is added, immediately open Info Popup in "add" mode.
- Enter saves.
- Cancel removes the newly-added item from the canvas.
```

##### 2.4.3: Crosshair Mode

###### Task 2.4.3-1: Information overlay on hover and Crosshair overlay side panel [L4]

*DONE*

```text
Prompt (L4):

Implement Information overlay (same as Info popup when new node is added) whenver a node is hovered over.

Implement Crosshair Mode per FEATURES.md §2.4.3.

Requirements:
- Clicking crosshair icon on Info Popup activates Crosshair Mode.
- A fixed-size side overlay appears on the right.
- The overlay shows info fields for whatever item the cursor is hovering.
- While in crosshair mode:
  - clicking/hovering does NOT open popups
  - if user is creating a link, show starting node + link data in the side panel

Implementation shape:
- CrosshairModeController with:
  - enabled bool
  - hoveredItemId
  - linkDraft (optional)

- Hook into canvas hover events:
  - onPointerHover -> hit-test item -> set hoveredItemId
```

#### 2.5: Selection Tools

##### 2.5.1: Cmd-Shift-Select

###### Task 2.5.1-1: Multi-select with Cmd+Shift click + blue outline [L4]

*DONE*

```text
Prompt (L4):

Implement Cmd-Shift-Select per FEATURES.md §2.5.1.

Requirements:
- Normal click selects a single node.
- Cmd+Shift + click toggles node in multi-selection set.
- Selected items have a blue outline.
- Right-click menus disable actions that cannot apply to all selected items (greyed out but visible).

Implementation shape:
- CanvasController.selection: Set<String> itemIds
- Selection policy:
  - click without modifiers => selection = {id}
  - Cmd+Shift click => toggle membership

Menu integration:
- Context menu builder receives selection set and computes enabled/disabled actions.
```

##### 2.5.2: Marquee Select

###### Task 2.5.2-1: Cmd+M marquee mode [L4]

*DONE*

```text
Prompt (L4):

Implement marquee selection per FEATURES.md §2.5.2.

Requirements:
- Press Cmd+M to enter marquee mode.
- First pointer down defines start world point.
- Drag defines translucent selection rectangle.
- All nodes/widgets inside rectangle become selected and get border matching marquee border color.

Implementation shape:
- Shortcuts engine dispatches `Cmd+M` -> enterMarqueeMode()
- MarqueeSelectionController stores:
  - enabled
  - startWorld
  - currentWorld

- During drag, compute selection:
  - for each item with worldBounds intersects marqueeRect => include
```

### 3: Nodes, Widgets and Connections

#### 3.1: Pre-Defined Widget Library

##### 3.1.1: Text Widget

###### Task 3.1.1-1: Text widget rendering + editing [L2]

*DONE*

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

###### Task 3.1.1-2: Connection model + rendering + persistence (Flow Canvas) [L4]

*DONE*

```text
Prompt (L4):

Implement the connections system referenced in FEATURES.md §3.1.1.

Requirements:
- Connections are created by clicking an out-port (green/red circles) then clicking a destination node.
- While adding a connection:
  - nodes that are not valid destinations (port type mismatch) are greyed out.
- Connections are persisted per-tab in the WorkspaceTab document (Appendix A).

Data model (required):
- class CanvasPortSpec { String portId; String direction; String portType; }
- class CanvasLink {
    String linkId;
    String fromItemId;
    String fromPortId;
    String toItemId;
    String toPortId;
    String relationType; // e.g. outboundDependency|labelledArrow|...
  }

Workspace schema changes:
- Add `links` map to `workspaces/{workspaceId}/tabs/{tabId}`:
  links: { "<linkId>": { fromItemId, fromPortId, toItemId, toPortId, relationType } }

Rendering:
- Draw links as a separate overlay layer (CustomPainter) above items.
- Link endpoints should track the connected item worldRect + port positions.

Operations:
- api.canvas.addLink
- api.canvas.deleteLink

Validation:
- NodeTemplate.renderSpec.ports declares each port’s `portType`.
- A connection is valid only if from.portType is compatible with to.portType.

Add tests:
- Unit tests for port compatibility + link serialization.
```

##### 3.1.2: Query Board Widget

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

#### 3.2: Pre-Defined Node Library

##### 3.2.1: Node Templates

###### Task 3.2.1-1: Node template schema + registry + renderer [L4]

```text
Prompt (L4):

Implement node templates per FEATURES.md §3.2.1.

Requirements:
- Node templates customize:
  - which fields of the LH2Object are shown
  - styling (colors, sizes)
  - port layout
- Templates are stored in Firestore workspace (Appendix A).

Define:
- class NodeTemplate { String id; ObjectType objectType; String name; int schemaVersion; Map<String,Object?> renderSpec; }
- renderSpec minimum fields:
  - header: { showTitle: bool }
  - bodyFields: List<String> // e.g. ["name", "taskStatus"]
  - ports: { in: [...], out: [...] }
  - size: { width, height }
  - style: { backgroundColor, borderColor, textColor }

Renderer:
- NodeRendererRegistry: Map<ObjectType, Widget Function(LH2Object, NodeTemplate, CanvasItemState)>
```

##### 3.2.2–3.2.9: Node widgets (initial set) [L2]

```text
Prompt (L2):

Implement baseline node widgets for these LH2Object types:
- ProjectGroup (3.2.2 is a meta-node; see below)
- Project (3.2.3)
- Deliverable (3.2.4)
- Task (3.2.5)
- Session (3.2.6)
- Event (3.2.7)
- ContextRequirement (3.2.8)
- ActualContext (3.2.9)

Constraints:
- Project Group Node (3.2.2) is NOT directly addable; it is used as a grouping/color concept for Project nodes.
- Keep visual styling simple for v0.1.0; Calendar-specific styling happens in v0.2.0.
```

### 4: Keyboard Input

#### 4.1: Keystroke Behaviour Modifiers

##### Task 4.1-1: Modifier state tracker (Cmd/Ctrl/Shift/Alt) [L3]

```text
Prompt (L3):

Implement a global modifier key state tracker.

Requirements:
- Track whether Cmd (Meta), Ctrl, Shift, Alt are currently pressed.
- Expose via Riverpod so canvases can check modifier state during pointer gestures.

Implement:
- ModifierState { bool cmd; bool ctrl; bool shift; bool alt; }
- modifierStateProvider
- A widget near the root (e.g. LH2App) that listens to RawKeyboard events and updates state.

Use cases:
- Cmd+scroll zoom / calendar scaling
- Cmd+Shift multi-select
- Cmd toggles snap-to-grid in calendar
```

#### 4.2: Keyboard Shortcuts

##### Task 4.2-1: Shortcuts engine (Appendix E) [L4]

```text
Prompt (L4):

Implement a rudimentary keyboard shortcuts engine for LH2 (FEATURES.md §4.2) per Appendix E.

Requirements:
- Map keystroke sequences to operations.
- Must route shortcuts to the active canvas/tab.

Implement these types (names required):
- class KeyChord { Set<LogicalKeyboardKey> modifiers; LogicalKeyboardKey key; }
- class KeySequence { List<KeyChord> chords; }
- typedef ShortcutHandler = Future<void> Function(ShortcutContext ctx);
- class ShortcutRegistry { void register(KeySequence seq, ShortcutHandler handler); }
- class ShortcutsEngine { void handleKeyEvent(KeyEvent e); }

Required bindings:
- Cmd+M => enter marquee mode
- Esc => cancel popup / exit modes

Integration:
- Use Focus at root; engine receives events and dispatches.
```

---

## v0.2.0: Calendar Canvas & Advanced Interactions

### 2: Canvases

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

## v0.3.0: Querying, Context Scenarios, and UX Polish

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

# Appendix A — Workspace Firestore Data Model

Goal: Persist tab configs, node templates, and canvas state in Firestore (root-level; not under /users).

## Collections

### `workspaces` (root collection)

Document id: `workspaceId` (string). For now, can equal `CurrentUser.uid`.

`workspaces/{workspaceId}` fields:

```json
{
  "schemaVersion": 1,
  "ownerUid": "<uid>",
  "createdAt": <serverTimestamp>,
  "updatedAt": <serverTimestamp>,
  "activeTabId": "<tabId>",
  "tabOrder": ["<tabId>", "<tabId>"]
}
```

Subcollections:

#### `workspaces/{workspaceId}/tabs/{tabId}`

```json
{
  "schemaVersion": 1,
  "kind": "flow" | "calendar",
  "title": "Flow 1",
  "createdAt": <serverTimestamp>,
  "updatedAt": <serverTimestamp>,
  "controller": { /* CanvasController JSON (Appendix B) */ },
  "links": {
    "<linkId>": {
      "fromItemId": "<itemId>",
      "fromPortId": "<portId>",
      "toItemId": "<itemId>",
      "toPortId": "<portId>",
      "relationType": "outboundDependency" | "labelledArrow" | "booleanDecisionPoint" | "multiDecisionPoint"
    }
  },
  "items": {
    "<itemId>": {
      "schemaVersion": 1,
      "itemId": "<itemId>",
      "itemType": "node" | "widget",
      "objectType": "task" | "event" | ...,
      "objectId": "<firestoreDocId>" | null,
      "templateId": "<templateId>" | null,
      "worldRect": {"x":0,"y":0,"w":300,"h":120},
      "snap": {"startSnapped": false, "endSnapped": false},
      "widgetConfig": { /* for widgets only */ }
    }
  }
}
```

Notes:
- `items` starts as a map for simplicity. If it grows too large, migrate to `items` subcollection.
- `controller` is the authoritative viewport state.

#### `workspaces/{workspaceId}/nodeTemplates/{templateId}`

```json
{
  "schemaVersion": 1,
  "objectType": "task",
  "name": "Compact Task",
  "renderSpec": { /* see 3.2.1 */ }
}
```

## Listener strategy

- On app start:
  - watch `workspaces/{workspaceId}` meta doc.
  - watch active tab doc.
  - watch nodeTemplates for types used by active tab.
- Writes:
  - Debounce high-frequency viewport updates (pan/zoom) to ~250ms.
  - For drag operations, write at drag end (plus optional debounced intermediate for safety).

## Versioning/migrations

- Each document has `schemaVersion`.
- WorkspaceRepository must:
  - read schemaVersion
  - if unsupported, surface a fatal LH2OpError with telemetry.

---

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

# Appendix C — Calendar Canvas Rendering Model

## Coordinate system

- X axis: **time (timeline)** horizontally.
  - World X is measured in *pixels* and maps to SGT datetime using `minutesPerPixel`.
  - Horizontal scrolling moves forward/backward in time.
- Y axis: **free-layout stacking axis** (no intrinsic meaning).
  - Vertical scrolling pans through rows/lanes of nodes.

### Mapping functions

- `DateTime<SGT> -> worldX`:
  - minutesSinceAnchor = dt.difference(anchorStartSgt).inMinutes
  - worldX = minutesSinceAnchor / minutesPerPixel

- `worldX -> DateTime<SGT>`:
  - minutesSinceAnchor = (worldX * minutesPerPixel).round()
  - dt = anchorStartSgt.add(Duration(minutes: minutesSinceAnchor))

- `Duration -> widthPx`:
  - widthPx = duration.inMinutes / minutesPerPixel

- Calendar items typically map:
  - **start datetime** ← `worldRect.left`
  - **end datetime**   ← `worldRect.right`
  - `worldRect.top/bottom` are purely layout/stacking.

## Layers (Stack)

1) **Timescale overlay** (CustomPainter)
   - Draw **vertical rules** at every `ruleIntervalMinutes`.
   - Draw **stronger day-boundary rules** every 1440 minutes.
2) **Item layer**
   - Render nodes positioned by CanvasItem.worldRect.
3) **Sticky markers overlay**
   - Positioned at top; renders date/time labels based on current horizontal pan.
   - Time markers align to rule lines; date markers align to day-boundary lines.

## Full week default

- On create, `anchorStartSgt = startOfWeek(SGT now)`.
- Initial `minutesPerPixel` should be chosen so that **7 days** (10080 minutes) roughly fits the initial viewport width.
  - Example: `minutesPerPixel = 10080 / viewportWidthPx`.
- Horizontal pan changes which week portion is visible.

---

# Appendix D — Snap-to-grid & Temporal Mapping

## Snapping increment

- 15 minutes.

## Snap decision

Let `cmdHeld` be current modifier state.

If (startSnapped || endSnapped):
- default snap = true
- but Cmd **disables** snapping

Else:
- default snap = cmdHeld

## When snapping

- Compute proposed start/end datetime from item world rect.
- Calendar nodes must support resizing by **dragging start/end handles**:
  - dragging left handle adjusts start datetime
  - dragging right handle adjusts end datetime
- Snap/auto-snap rules apply per-handle (startSnapped/endSnapped).
- Snap each datetime to nearest 15-minute boundary.
- Persist snapped timestamps to domain objects on drag end via operations:
  - api.objects.update (Session/Event/Deliverable/ContextRequirement as applicable)

---

# Appendix E — Keyboard Shortcuts Engine

## Goals

- Central registry for shortcuts.
- Route to active canvas/tab.
- Support both single-chord and multi-chord sequences.

## Dispatch

- ShortcutsEngine listens to KeyEvents from a root Focus.
- Maintains an in-progress sequence buffer with a timeout (e.g. 800ms).
- Matches registered sequences.
- On match, calls handler with ShortcutContext:
  - activeTabId
  - activeCanvasController
  - workspaceController
  - infoPopupController

---

# Appendix F — Responsiveness Strategy (desktop-only)

## Breakpoints (suggested)

- Small desktop: < 1100px
- Standard desktop: 1100–1600px
- Large desktop: > 1600px

## Layout constraints

- Query overlay width:
  - clamp between 280px and 420px
  - if small desktop, allow collapse to icon (v0.3.0 polish)

- Tab bar:
  - height 40px collapsed, 64px expanded

- Crosshair side panel:
  - width clamp 320–480px

---

# Appendix G — Operations + Telemetry Conventions

## Operation IDs

- Format: `api.<area>.<action>`
- Examples:
  - api.workspace.load
  - api.workspace.save
  - api.canvas.addItem
  - api.canvas.updateViewport

## Telemetry JSON schema

```json
{
  "ts": 0,
  "level": "error",
  "message": "...",
  "operationId": "api.canvas.addItem",
  "errorCode": "CANVAS_ITEM_INVALID",
  "payload": {"itemId": "..."},
  "location": "lib/...:Class.method"
}
```
