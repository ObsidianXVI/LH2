library;

import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

/// Canvas port specification.
class CanvasPortSpec {
  final String portId;
  final String direction; // 'in' | 'out'
  final String portType; // e.g. 'logic' | 'data' | 'dependency'

  const CanvasPortSpec({
    required this.portId,
    required this.direction,
    required this.portType,
  });

  factory CanvasPortSpec.fromJson(Map<String, Object?> json) {
    return CanvasPortSpec(
      portId: json['portId'] as String,
      direction: json['direction'] as String,
      portType: json['portType'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'portId': portId,
      'direction': direction,
      'portType': portType,
    };
  }
}

/// Canvas kind for workspace tabs.
sealed class CanvasKind {
  const CanvasKind();

  factory CanvasKind.fromJson(String value) {
    return switch (value) {
      'flow' => const FlowCanvasKind(),
      'calendar' => const CalendarCanvasKind(),
      _ => throw ArgumentError('Unknown canvas kind: $value'),
    };
  }

  String toJson() => switch (this) {
        FlowCanvasKind() => 'flow',
        CalendarCanvasKind() => 'calendar',
      };
}

class FlowCanvasKind extends CanvasKind {
  const FlowCanvasKind();
}

class CalendarCanvasKind extends CanvasKind {
  const CalendarCanvasKind();
}

/// Canvas viewport containing pan, zoom, and viewport size information.
class CanvasViewport {
  final Offset pan;
  final double zoom;
  final Size viewportSizePx;

  const CanvasViewport({
    required this.pan,
    required this.zoom,
    required this.viewportSizePx,
  });

  factory CanvasViewport.fromJson(Map<String, Object?> json) {
    return CanvasViewport(
      pan: Offset(
        ((json['panX'] as num?)?.toDouble() ?? 0.0),
        ((json['panY'] as num?)?.toDouble() ?? 0.0),
      ),
      zoom: ((json['zoom'] as num?)?.toDouble() ?? 1.0),
      viewportSizePx: Size(
        ((json['viewportWidthPx'] as num?)?.toDouble() ?? 800.0),
        ((json['viewportHeightPx'] as num?)?.toDouble() ?? 600.0),
      ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'panX': pan.dx,
      'panY': pan.dy,
      'zoom': zoom,
      'viewportWidthPx': viewportSizePx.width,
      'viewportHeightPx': viewportSizePx.height,
    };
  }

  CanvasViewport copyWith({
    Offset? pan,
    double? zoom,
    Size? viewportSizePx,
  }) {
    return CanvasViewport(
      pan: pan ?? this.pan,
      zoom: zoom ?? this.zoom,
      viewportSizePx: viewportSizePx ?? this.viewportSizePx,
    );
  }
}

/// Canvas item representing a node or widget on the canvas.
class CanvasItem {
  final String itemId;
  final String itemType; // 'node' | 'widget'
  final Rect worldRect;
  final String? objectId; // Firestore doc id (for nodes)
  final String? objectType; // for nodes
  final Map<String, dynamic>? config;
  final CanvasItemSnapState snap;
  final bool disabledByScenario;

  const CanvasItem({
    required this.itemId,
    required this.itemType,
    required this.worldRect,
    this.objectId,
    this.objectType,
    this.config,
    this.snap = const CanvasItemSnapState(),
    this.disabledByScenario = false,
  });

  factory CanvasItem.fromJson(String itemId, Map<String, Object?> json) {
    final worldRectJson = json['worldRect'] as Map<String, Object?>? ??
        {
          'x': json['x'],
          'y': json['y'],
          'w': json['w'],
          'h': json['h'],
        };

    return CanvasItem(
      itemId: itemId,
      itemType: json['itemType'] as String,
      worldRect: Rect.fromLTWH(
        (worldRectJson['x'] as num).toDouble(),
        (worldRectJson['y'] as num).toDouble(),
        (worldRectJson['w'] as num).toDouble(),
        (worldRectJson['h'] as num).toDouble(),
      ),
      objectId: json['objectId'] as String?,
      objectType: json['objectType'] as String?,
      config: json['config'] as Map<String, dynamic>?,
      snap: json['snap'] != null
          ? CanvasItemSnapState.fromJson(json['snap'] as Map<String, Object?>)
          : const CanvasItemSnapState(),
      disabledByScenario: json['disabledByScenario'] as bool? ?? false,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'itemType': itemType,
      'worldRect': {
        'x': worldRect.left,
        'y': worldRect.top,
        'w': worldRect.width,
        'h': worldRect.height,
      },
      if (objectId != null) 'objectId': objectId,
      if (objectType != null) 'objectType': objectType,
      if (config != null) 'config': config,
      'snap': snap.toJson(),
      'disabledByScenario': disabledByScenario,
    };
  }
}

class CanvasItemSnapState {
  final bool startSnapped;
  final bool endSnapped;

  const CanvasItemSnapState({
    this.startSnapped = false,
    this.endSnapped = false,
  });

  factory CanvasItemSnapState.fromJson(Map<String, Object?> json) {
    return CanvasItemSnapState(
      startSnapped: json['startSnapped'] as bool? ?? false,
      endSnapped: json['endSnapped'] as bool? ?? false,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'startSnapped': startSnapped,
      'endSnapped': endSnapped,
    };
  }
}

/// Canvas link representing connections between items.
class CanvasLink {
  final String linkId;
  final String fromItemId;
  final String fromPortId;
  final String toItemId;
  final String toPortId;
  final String relationType; // e.g. outboundDependency|labelledArrow|...

  const CanvasLink({
    required this.linkId,
    required this.fromItemId,
    required this.fromPortId,
    required this.toItemId,
    required this.toPortId,
    required this.relationType,
  });

  factory CanvasLink.fromJson(String linkId, Map<String, Object?> json) {
    return CanvasLink(
      linkId: linkId,
      fromItemId: json['fromItemId'] as String,
      fromPortId: json['fromPortId'] as String,
      toItemId: json['toItemId'] as String,
      toPortId: json['toPortId'] as String,
      relationType: json['relationType'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'fromItemId': fromItemId,
      'fromPortId': fromPortId,
      'toItemId': toItemId,
      'toPortId': toPortId,
      'relationType': relationType,
    };
  }
}

/// Abstract base class for canvas controllers.
abstract class CanvasController extends ChangeNotifier {
  CanvasController() {
    _items = {};
    _links = {};
    _selection = {};
  }

  CanvasKind get kind;
  CanvasViewport get viewport;
  Map<String, CanvasItem> get items;
  Map<String, CanvasLink> get links;
  Set<String> get selection;

  /// Active link creation state
  String? _pendingFromItemId;
  String? _pendingFromPortId;
  Offset? _pendingPointerScreen;
  String? get pendingFromItemId => _pendingFromItemId;
  String? get pendingFromPortId => _pendingFromPortId;
  Offset? get pendingPointerScreen => _pendingPointerScreen;

  void startLinking(String itemId, String portId) {
    _pendingFromItemId = itemId;
    _pendingFromPortId = portId;

    // Compute an initial pointer screen position anchored at the from-port so
    // the pending link is visible immediately (no cursor move required).
    final item = _items[itemId];
    if (item != null) {
      final worldPort = (portId.contains('out'))
          ? Offset(item.worldRect.right,
              item.worldRect.top + item.worldRect.height / 2)
          : Offset(item.worldRect.left,
              item.worldRect.top + item.worldRect.height / 2);

      // Offset the initial pointer slightly so a short preview of the link
      // is immediately visible to the user without having to move the mouse.
      final anchorScreen = worldToScreen(worldPort);
      final offsetDir = portId.contains('out') ? Offset(40, 0) : Offset(-40, 0);
      _pendingPointerScreen = anchorScreen + offsetDir;
    } else {
      _pendingPointerScreen = null;
    }

    // Debug
    // ignore: avoid_print
    print(
        '[CanvasController] startLinking: $itemId.$portId pendingScreen=$_pendingPointerScreen');
    notifyListeners();
  }

  void cancelLinking() {
    _pendingFromItemId = null;
    _pendingFromPortId = null;
    _pendingPointerScreen = null;
    // ignore: avoid_print
    print('[CanvasController] cancelLinking');
    notifyListeners();
  }

  /// Update the current pointer position (screen coords) while linking.
  ///
  /// This enables the link overlay to render a "pending" link following the
  /// cursor.
  void updatePendingPointerScreen(Offset screenPos) {
    if (_pendingFromItemId == null) return;
    _pendingPointerScreen = screenPos;
    // ignore: avoid_print
    // print('[CanvasController] updatePendingPointerScreen: $screenPos');
    notifyListeners();
  }

  /// Check if a target item is a valid connection target
  bool isValidLinkTarget(String targetItemId) {
    if (_pendingFromItemId == null || _pendingFromPortId == null) return false;
    if (_pendingFromItemId == targetItemId) return false;

    // Default impl: any node is a valid target.
    // FlowCanvasView will do richer port compatibility checks based on
    // NodeTemplate.renderSpec ports.
    final targetItem = _items[targetItemId];
    return targetItem != null && targetItem.itemType == 'node';
  }

  /// Convert world coordinates to screen coordinates
  Offset worldToScreen(Offset world) {
    return (world - viewport.pan) * viewport.zoom +
        Offset(viewport.viewportSizePx.width / 2,
            viewport.viewportSizePx.height / 2);
  }

  /// Convert screen coordinates to world coordinates
  Offset screenToWorld(Offset screen) {
    return (screen -
                Offset(viewport.viewportSizePx.width / 2,
                    viewport.viewportSizePx.height / 2)) /
            viewport.zoom +
        viewport.pan;
  }

  /// Get the world rectangle of the current viewport
  Rect get viewportWorldRect {
    final halfWidth = viewport.viewportSizePx.width / (2 * viewport.zoom);
    final halfHeight = viewport.viewportSizePx.height / (2 * viewport.zoom);
    return Rect.fromCenter(
      center: viewport.pan,
      width: halfWidth * 2,
      height: halfHeight * 2,
    );
  }

  /// Update viewport size (in screen pixels).
  ///
  /// This is critical for correct screen<->world coordinate conversions.
  void setViewportSize(Size viewportSizePx) {
    if (viewport.viewportSizePx == viewportSizePx) return;
    _updateViewport(viewport.copyWith(viewportSizePx: viewportSizePx));
  }

  /// Directly set the viewport to preserve state across recreations
  void setViewport(CanvasViewport newViewport) {
    _updateViewport(newViewport);
  }

  /// Pan the viewport by a delta in screen coordinates
  void panBy(Offset deltaScreen) {
    final deltaWorld = deltaScreen / viewport.zoom;
    _updateViewport(viewport.copyWith(pan: viewport.pan + deltaWorld));
  }

  /// Zoom the viewport at a focal point in screen coordinates
  void zoomAt({required Offset focalScreen, required double scaleDelta}) {
    final focalWorld = screenToWorld(focalScreen);

    // --- Synchronized clamping (viewport zoom <-> node pixel size) ---
    // We clamp zoom based on current node world sizes so that:
    // - Zooming in stops exactly when nodes reach the max allowed *pixel* size
    // - Zooming out stops exactly when nodes reach the min allowed *pixel* size
    // This keeps node bounds and port positions aligned, because nodes scale
    // with zoom (see BaseNodeWidget).
    const minNodeWidthPx = 120.0;
    const minNodeHeightPx = 60.0;
    // Allow deeper zoom-in, while still preventing runaway scaling.
    const maxNodeWidthPx = 200000.0;
    const maxNodeHeightPx = 200000.0;

    // If there are no nodes yet, fall back to a conservative clamp.
    final nodeItems = _items.values.where((i) => i.itemType == 'node');
    final oldZoom = viewport.zoom;
    double proposedZoom = (oldZoom * scaleDelta).clamp(0.01, 1000.0);

    if (nodeItems.isNotEmpty) {
      // For min zoom (zooming out): smallest world size hits min pixel size first.
      double minZoom = 0.0;
      for (final item in nodeItems) {
        final w = item.worldRect.width;
        final h = item.worldRect.height;
        if (w > 0) minZoom = Math.max(minZoom, minNodeWidthPx / w);
        if (h > 0) minZoom = Math.max(minZoom, minNodeHeightPx / h);
      }

      // For max zoom (zooming in): largest world size hits max pixel size first.
      double maxZoom = double.infinity;
      for (final item in nodeItems) {
        final w = item.worldRect.width;
        final h = item.worldRect.height;
        if (w > 0) maxZoom = Math.min(maxZoom, maxNodeWidthPx / w);
        if (h > 0) maxZoom = Math.min(maxZoom, maxNodeHeightPx / h);
      }

      // Guard against pathological values.
      if (maxZoom.isFinite) {
        // Ensure minZoom doesn't exceed maxZoom.
        if (minZoom > maxZoom) {
          // If they overlap, pin both to the closest feasible value.
          minZoom = maxZoom;
        }
        proposedZoom = proposedZoom.clamp(minZoom, maxZoom);
      } else {
        proposedZoom = proposedZoom.clamp(minZoom, 1000.0);
      }
    }

    final newZoom = proposedZoom;
    if (newZoom == oldZoom) return;

    // Calculate new pan to keep the focal point stationary
    final newPan = focalWorld -
        (focalScreen -
                Offset(viewport.viewportSizePx.width / 2,
                    viewport.viewportSizePx.height / 2)) /
            newZoom;

    _updateViewport(viewport.copyWith(pan: newPan, zoom: newZoom));
  }

  /// Set the selection set
  void setSelection(Set<String> itemIds) {
    _selection = Set<String>.from(itemIds);
    notifyListeners();
  }

  /// Toggle selection of an item
  void toggleSelection(String itemId) {
    if (_selection.contains(itemId)) {
      _selection.remove(itemId);
    } else {
      _selection.add(itemId);
    }
    notifyListeners();
  }

  /// Get visible object IDs (basic implementation)
  Set<String> get visibleObjectIds => computeVisibleObjectIds();

  /// Compute visible object IDs based on viewport
  Set<String> computeVisibleObjectIds() {
    final visibleIds = <String>{};
    final viewportRect = viewportWorldRect;

    for (final entry in items.entries) {
      if (viewportRect.overlaps(entry.value.worldRect)) {
        visibleIds.add(entry.key);
      }
    }

    return visibleIds;
  }

  /// Add an item to the canvas
  void addItem(CanvasItem item) {
    _items[item.itemId] = item;
    notifyListeners();
  }

  /// Update an item's rectangle
  void updateItemRect(String itemId, Rect newWorldRect,
      {CanvasItemSnapState? snap}) {
    final item = _items[itemId];
    if (item != null) {
      _items[itemId] = CanvasItem(
        itemId: item.itemId,
        itemType: item.itemType,
        worldRect: newWorldRect,
        objectId: item.objectId,
        objectType: item.objectType,
        config: item.config,
        snap: snap ?? item.snap,
        disabledByScenario: item.disabledByScenario,
      );
      notifyListeners();
    }
  }

  /// Update an item's config (for text editing, etc.)
  void updateItemConfig(String itemId, Map<String, dynamic> newConfig) {
    final item = _items[itemId];
    if (item == null) return;
    _items[itemId] = CanvasItem(
      itemId: item.itemId,
      itemType: item.itemType,
      worldRect: item.worldRect,
      objectId: item.objectId,
      objectType: item.objectType,
      config: newConfig,
      snap: item.snap,
      disabledByScenario: item.disabledByScenario,
    );
    notifyListeners();
  }

  /// Remove an item from the canvas
  void removeItem(String itemId) {
    _items.remove(itemId);
    _selection.remove(itemId);
    notifyListeners();
  }

  /// Add a link to the canvas
  void addLink(CanvasLink link) {
    _links[link.linkId] = link;
    // ignore: avoid_print
    print(
        '[CanvasController] addLink: ${link.linkId} ${link.fromItemId}->${link.toItemId}');
    notifyListeners();
  }

  /// Remove a link from the canvas
  void removeLink(String linkId) {
    _links.remove(linkId);
    // ignore: avoid_print
    print('[CanvasController] removeLink: $linkId');
    notifyListeners();
  }

  /// Convert to JSON for persistence
  Map<String, Object?> toJson();

  /// Create from JSON
  factory CanvasController.fromJson(Map<String, Object?> json) {
    final kind = CanvasKind.fromJson(json['kind'] as String);

    return switch (kind) {
      FlowCanvasKind() => FlowCanvasController.fromJson(json),
      CalendarCanvasKind() => CalendarCanvasController.fromJson(json),
    };
  }

  // Protected members for internal use
  late CanvasViewport _viewport;
  late Map<String, CanvasItem> _items;
  late Map<String, CanvasLink> _links;
  late Set<String> _selection;

  void _updateViewport(CanvasViewport newViewport) {
    _viewport = newViewport;
    notifyListeners();
  }

  void _initializeFromJson(Map<String, Object?> json) {
    _viewport =
        CanvasViewport.fromJson(json['viewport'] as Map<String, Object?>);

    _items = {};
    final itemsJson =
        json['items'] as Map<dynamic, dynamic>? ?? <String, Object?>{};
    for (final entry in itemsJson.entries) {
      final key = entry.key as String;
      final value = entry.value as Map<dynamic, dynamic>;
      _items[key] = CanvasItem.fromJson(key, value.cast<String, Object?>());
    }

    _links = {};
    final linksJson =
        json['links'] as Map<dynamic, dynamic>? ?? <String, Object?>{};
    for (final entry in linksJson.entries) {
      final key = entry.key as String;
      final value = entry.value as Map<dynamic, dynamic>;
      _links[key] = CanvasLink.fromJson(key, value.cast<String, Object?>());
    }

    _selection = Set<String>.from(json['selection'] as List? ?? <String>[]);
  }
}

/// Flow canvas controller with grid support.
class FlowCanvasController extends CanvasController {
  final double gridSizePx;

  FlowCanvasController({
    required CanvasViewport viewport,
    Map<String, CanvasItem>? items,
    Map<String, CanvasLink>? links,
    Set<String>? selection,
    this.gridSizePx = 24.0,
  }) {
    _viewport = viewport;
    _items = Map<String, CanvasItem>.from(items ?? {});
    _links = Map<String, CanvasLink>.from(links ?? {});
    _selection = Set<String>.from(selection ?? {});
  }

  factory FlowCanvasController.fromJson(Map<String, Object?> json) {
    return FlowCanvasController(
      viewport:
          CanvasViewport.fromJson(json['viewport'] as Map<String, Object?>),
      items: {}, // Will be populated by _initializeFromJson
      links: {}, // Will be populated by _initializeFromJson
      selection: {}, // Will be populated by _initializeFromJson
      gridSizePx: (json['gridSizePx'] as num?)?.toDouble() ?? 24.0,
    ).._initializeFromJson(json);
  }

  @override
  CanvasKind get kind => const FlowCanvasKind();

  @override
  CanvasViewport get viewport => _viewport;

  @override
  Map<String, CanvasItem> get items => Map.unmodifiable(_items);

  @override
  Map<String, CanvasLink> get links => Map.unmodifiable(_links);

  @override
  Set<String> get selection => Set.unmodifiable(_selection);

  @override
  Map<String, Object?> toJson() {
    return {
      'kind': kind.toJson(),
      'viewport': viewport.toJson(),
      'gridSizePx': gridSizePx,
      'items': _items.map((key, value) => MapEntry(key, value.toJson())),
      'links': _links.map((key, value) => MapEntry(key, value.toJson())),
      'selection': _selection.toList(),
    };
  }

  /// Snap a world coordinate to the grid
  Offset snapToGrid(Offset worldPos) {
    // Keep snapping aligned with the rendered grid.
    // GridBackgroundPainter now treats gridSizePx as a world-unit spacing,
    // so snapping should use the same spacing.
    final gridWorldSize = gridSizePx;
    return Offset(
      (worldPos.dx / gridWorldSize).round() * gridWorldSize,
      (worldPos.dy / gridWorldSize).round() * gridWorldSize,
    );
  }
}

/// Calendar canvas controller with time-based scaling and snapping.
class CalendarCanvasController extends CanvasController {
  DateTime anchorStartSgt;
  double minutesPerPixel;
  int ruleIntervalMinutes;

  /// The discrete time steps the UI can use for rule rendering.
  ///
  /// This is intentionally an explicit ladder (instead of always doubling)
  /// so we can include human-friendly steps like 12h.
  static const List<int> allowedRuleIntervalsMinutes = <int>[
    60, // 1h
    120, // 2h
    240, // 4h
    480, // 8h
    720, // 12h
    960, // 16h
    1440, // 1d
    2880, // 2d
    4320, // 3d
    5760, // 4d
    10080, // 1w
  ];

  static const int minRuleIntervalMinutes = 60;
  static const int maxRuleIntervalMinutes = 10080;

  /// Target label density at the most zoomed-out view.
  ///
  /// When you hit [maxRuleIntervalMinutes], we clamp [minutesPerPixel] so that
  /// roughly this many intervals are visible across the viewport.
  static const double maxZoomOutTargetIntervalsVisible = 12.0;

  /// Fixed number of interval columns visible across the viewport.
  static const double fixedIntervalsVisible = 12.0;

  // Cmd+scroll tuning: accumulate wheel deltas and only step the interval rung
  // once the user has scrolled past this threshold.
  static const double cmdScrollStepThresholdPx = 200.0;
  double _cmdScrollAccumPx = 0.0;

  double _maxMinutesPerPixelForInterval({required int intervalMinutes}) {
    final viewportWidthPx = viewport.viewportSizePx.width;
    if (viewportWidthPx <= 0) return double.infinity;

    // viewport world width in minutes = viewportWidthPx / zoom * minutesPerPixel
    // intervals visible = worldWidth / interval
    // => minutesPerPixelMax = intervalsVisible * interval * zoom / viewportWidthPx
    // With fixed columns, minutesPerPixel is *always* ruleIntervalMinutes / columnWidthPx.
    // columnWidthPx = viewportWidthPx / fixedIntervalsVisible.
    // => minutesPerPixel = intervalMinutes / (viewportWidthPx / fixedIntervalsVisible)
    return (fixedIntervalsVisible * intervalMinutes) / viewportWidthPx;
  }

  void _enforceMaxIntervalsVisibleConstraint() {
    // With fixed columns, minutesPerPixel is derived and not free.
    minutesPerPixel = _maxMinutesPerPixelForInterval(
      intervalMinutes: ruleIntervalMinutes,
    );
  }

  CalendarCanvasController({
    required CanvasViewport viewport,
    Map<String, CanvasItem>? items,
    Map<String, CanvasLink>? links,
    Set<String>? selection,
    DateTime? anchorStartSgt,
    this.minutesPerPixel = 1.0,
    this.ruleIntervalMinutes = 60,
  }) : anchorStartSgt = anchorStartSgt ?? _defaultAnchorStart() {
    _viewport = viewport;
    _items = Map<String, CanvasItem>.from(items ?? {});
    _links = Map<String, CanvasLink>.from(links ?? {});
    _selection = Set<String>.from(selection ?? {});

    _enforceMaxIntervalsVisibleConstraint();
  }

  static DateTime _defaultAnchorStart() {
    final singapore = tz.getLocation('Asia/Singapore');
    final nowSgt = tz.TZDateTime.now(singapore);
    // Start of the week (Monday)
    return nowSgt.subtract(Duration(days: nowSgt.weekday - 1)).subtract(
        Duration(
            hours: nowSgt.hour,
            minutes: nowSgt.minute,
            seconds: nowSgt.second,
            milliseconds: nowSgt.millisecond,
            microseconds: nowSgt.microsecond));
  }

  factory CalendarCanvasController.fromJson(Map<String, Object?> json) {
    final controller = CalendarCanvasController(
      viewport:
          CanvasViewport.fromJson(json['viewport'] as Map<String, Object?>),
      anchorStartSgt: json['anchorStartSgt'] != null
          ? DateTime.parse(json['anchorStartSgt'] as String)
          : null,
      minutesPerPixel: (json['minutesPerPixel'] as num?)?.toDouble() ?? 1.0,
      ruleIntervalMinutes: (json['ruleIntervalMinutes'] as num?)?.toInt() ?? 60,
    ).._initializeFromJson(json);

    // Re-check constraints after JSON init.
    controller._enforceMaxIntervalsVisibleConstraint();
    return controller;
  }

  @override
  CanvasKind get kind => const CalendarCanvasKind();

  @override
  CanvasViewport get viewport => _viewport;

  @override
  Map<String, CanvasItem> get items => Map.unmodifiable(_items);

  @override
  Map<String, CanvasLink> get links => Map.unmodifiable(_links);

  @override
  Set<String> get selection => Set.unmodifiable(_selection);

  @override
  Map<String, Object?> toJson() {
    return {
      'kind': kind.toJson(),
      'viewport': viewport.toJson(),
      'anchorStartSgt': anchorStartSgt.toIso8601String(),
      'minutesPerPixel': minutesPerPixel,
      'ruleIntervalMinutes': ruleIntervalMinutes,
      'items': _items.map((key, value) => MapEntry(key, value.toJson())),
      'links': _links.map((key, value) => MapEntry(key, value.toJson())),
      'selection': _selection.toList(),
    };
  }

  void updateScaling(double newMinutesPerPixel, int newRuleInterval) {
    minutesPerPixel = newMinutesPerPixel;
    ruleIntervalMinutes = newRuleInterval;
    notifyListeners();
  }

  void handleCmdScroll(double deltaY) {
    int nextRuleInterval = ruleIntervalMinutes;

    // Hysteresis thresholds to avoid flicker.
    // Within these thresholds, we keep the same rule interval and only
    // minutesPerPixel changes => rules squeeze/expand smoothly in real time.
    const double minPx = 40.0;
    const double maxPx = 420.0;
    const double hysteresisFactor = 1.1;

    // With fixed columns, pixel spacing is always viewportWidth / fixedIntervalsVisible.
    final double columnWidthPx =
        viewport.viewportSizePx.width / fixedIntervalsVisible;
    double pixelSpacing = columnWidthPx;

    int idx = allowedRuleIntervalsMinutes.indexOf(nextRuleInterval);
    if (idx == -1) {
      // If persisted state contains an unexpected interval, snap it.
      idx = 0;
      nextRuleInterval = allowedRuleIntervalsMinutes[idx];
    }

    // Keep the column width within a comfortable pixel range by stepping the
    // interval size (time per column). This changes the *time* represented,
    // not the column width.
    if (pixelSpacing < minPx / hysteresisFactor) {
      // Columns too narrow => step interval up.
      if (idx < allowedRuleIntervalsMinutes.length - 1) {
        idx++;
        nextRuleInterval = allowedRuleIntervalsMinutes[idx];
      } else {
        nextRuleInterval = maxRuleIntervalMinutes;
      }
      // Reset scroll accumulator when we auto-correct.
      _cmdScrollAccumPx = 0.0;
    } else if (pixelSpacing > maxPx * hysteresisFactor) {
      // Columns too wide => step interval down.
      if (idx > 0) {
        idx--;
        nextRuleInterval = allowedRuleIntervalsMinutes[idx];
      } else {
        nextRuleInterval = minRuleIntervalMinutes;
      }
      _cmdScrollAccumPx = 0.0;
    } else {
      // Within thresholds: accumulate Cmd+scroll and step interval only when
      // exceeding a threshold to reduce sensitivity.
      _cmdScrollAccumPx += deltaY;

      while (_cmdScrollAccumPx.abs() >= cmdScrollStepThresholdPx) {
        final dir = _cmdScrollAccumPx.sign; // + => zoom out, - => zoom in
        if (dir > 0 && idx < allowedRuleIntervalsMinutes.length - 1) {
          idx++;
          nextRuleInterval = allowedRuleIntervalsMinutes[idx];
        } else if (dir < 0 && idx > 0) {
          idx--;
          nextRuleInterval = allowedRuleIntervalsMinutes[idx];
        }

        _cmdScrollAccumPx -= dir * cmdScrollStepThresholdPx;
      }
    }

    // No additional zoom-out enforcement needed: fixedIntervalsVisible means
    // we always render 12 columns, and zoom extent is represented solely by
    // stepping ruleIntervalMinutes up to 1w.

    // Hard clamp the rule interval.
    if (nextRuleInterval < minRuleIntervalMinutes) {
      nextRuleInterval = minRuleIntervalMinutes;
    }
    if (nextRuleInterval > maxRuleIntervalMinutes) {
      nextRuleInterval = maxRuleIntervalMinutes;
    }

    // (note) We clamp the max zoom-out extent for every interval above.

    ruleIntervalMinutes = nextRuleInterval;
    _enforceMaxIntervalsVisibleConstraint();
    notifyListeners();
  }

  @override
  Offset worldToScreen(Offset world) {
    return Offset(
      (world.dx - viewport.pan.dx) / minutesPerPixel +
          viewport.viewportSizePx.width / 2,
      (world.dy - viewport.pan.dy) * viewport.zoom +
          viewport.viewportSizePx.height / 2,
    );
  }

  @override
  Offset screenToWorld(Offset screen) {
    return Offset(
      (screen.dx - viewport.viewportSizePx.width / 2) * minutesPerPixel +
          viewport.pan.dx,
      (screen.dy - viewport.viewportSizePx.height / 2) / viewport.zoom +
          viewport.pan.dy,
    );
  }

  @override
  Rect get viewportWorldRect {
    final halfWidth = viewport.viewportSizePx.width * minutesPerPixel / 2;
    final halfHeight = viewport.viewportSizePx.height / (2 * viewport.zoom);
    return Rect.fromCenter(
      center: viewport.pan,
      width: halfWidth * 2,
      height: halfHeight * 2,
    );
  }

  @override
  void panBy(Offset deltaScreen) {
    // Calendar X-axis is time (minutes). Convert pixel delta to minutes using
    // current minutesPerPixel so panning feels consistent across scales.
    //
    // Y-axis keeps the normal canvas behavior (world units scale with zoom)
    // because nodes/items still use the shared world coordinate system.
    final deltaWorld = Offset(
      deltaScreen.dx * minutesPerPixel,
      deltaScreen.dy / viewport.zoom,
    );
    _updateViewport(viewport.copyWith(pan: viewport.pan + deltaWorld));
  }

  double snapWorldX(double worldX) {
    // Snap increment is 15 minutes.
    const snapIncrement = 15.0;
    return (worldX / snapIncrement).round() * snapIncrement;
  }

  /// Applies a drag delta to a [CanvasItem] and returns the updated rect + snap
  /// metadata, following FEATURES.md §2.2.4 and Appendix D.
  ///
  /// Rules:
  /// - Default is freehand (no snap).
  /// - Holding Cmd enables snap *unless* the item is already in auto-snap mode.
  /// - Auto-snap mode activates once either end has been snapped at least once.
  ///   In this mode, snapping is ON by default and holding Cmd DISABLES snap.
  /// - Snap-to-grid applies to nodes only, and only for snappable types
  ///   (see [shouldSnap]).
  ({Rect rect, CanvasItemSnapState snap}) applyMoveWithSnapping({
    required CanvasItem item,
    required Offset deltaWorld,
    required bool isCmdPressed,
  }) {
    final Rect proposedRect = item.worldRect.shift(deltaWorld);

    // Widgets never snap.
    if (!shouldSnap(item)) {
      return (rect: proposedRect, snap: item.snap);
    }

    final bool inAutoSnapMode = item.snap.startSnapped || item.snap.endSnapped;
    final bool shouldSnapNow = inAutoSnapMode ? !isCmdPressed : isCmdPressed;

    if (!shouldSnapNow) {
      // Freehand move: do not change snap metadata.
      return (rect: proposedRect, snap: item.snap);
    }

    // For node movement, we keep duration constant but align the start/end to
    // the 15-minute ladder.
    final double snappedLeft = snapWorldX(proposedRect.left);
    final double snappedRight = snapWorldX(proposedRect.right);
    final Rect snappedRect = Rect.fromLTRB(
      snappedLeft,
      proposedRect.top,
      snappedRight,
      proposedRect.bottom,
    );

    // Mark both ends as having been snapped at least once.
    // (Future resizing could set these individually.)
    return (
      rect: snappedRect,
      snap: const CanvasItemSnapState(startSnapped: true, endSnapped: true),
    );
  }

  /// Applies a resize delta to either the start or end of a [CanvasItem],
  /// following time-based snapping rules.
  ({Rect rect, CanvasItemSnapState snap}) applyResizeWithSnapping({
    required CanvasItem item,
    required double deltaWorldX,
    required bool isStart,
    required bool isCmdPressed,
  }) {
    double newLeft = item.worldRect.left;
    double newRight = item.worldRect.right;

    if (isStart) {
      newLeft += deltaWorldX;
      // Prevent negative width (min 1 minute)
      if (newLeft > newRight - 1.0) newLeft = newRight - 1.0;
    } else {
      newRight += deltaWorldX;
      // Prevent negative width (min 1 minute)
      if (newRight < newLeft + 1.0) newRight = newLeft + 1.0;
    }

    final Rect proposedRect = Rect.fromLTRB(
      newLeft,
      item.worldRect.top,
      newRight,
      item.worldRect.bottom,
    );

    // Widgets never snap.
    if (!shouldSnap(item)) {
      return (rect: proposedRect, snap: item.snap);
    }

    final bool inAutoSnapMode = item.snap.startSnapped || item.snap.endSnapped;
    final bool shouldSnapNow = inAutoSnapMode ? !isCmdPressed : isCmdPressed;

    if (!shouldSnapNow) {
      // Freehand resize: keep existing snap state for the other end,
      // but the edge being dragged is definitely not "snapped" anymore
      // in terms of the grid (though we preserve the bit if it was already snapped).
      return (rect: proposedRect, snap: item.snap);
    }

    double snappedLeft = newLeft;
    double snappedRight = newRight;
    bool newStartSnapped = item.snap.startSnapped;
    bool newEndSnapped = item.snap.endSnapped;

    if (isStart) {
      snappedLeft = snapWorldX(newLeft);
      newStartSnapped = true;
    } else {
      snappedRight = snapWorldX(newRight);
      newEndSnapped = true;
    }

    // Final safety check to prevent negative width after snapping
    if (snappedLeft >= snappedRight) {
      if (isStart) {
        snappedLeft = snappedRight - 15.0; // Snap to previous 15m step
      } else {
        snappedRight = snappedLeft + 15.0; // Snap to next 15m step
      }
    }

    final Rect snappedRect = Rect.fromLTRB(
      snappedLeft,
      item.worldRect.top,
      snappedRight,
      item.worldRect.bottom,
    );

    return (
      rect: snappedRect,
      snap: CanvasItemSnapState(
        startSnapped: newStartSnapped,
        endSnapped: newEndSnapped,
      ),
    );
  }

  /// Returns true if moving/adding a *root-level* deliverable to [proposedRect]
  /// would overlap any existing canvas item.
  bool rootDeliverableWouldOverlap({
    required Rect proposedRect,
    String? ignoreItemId,
  }) {
    for (final other in _items.values) {
      if (ignoreItemId != null && other.itemId == ignoreItemId) continue;
      if (other.worldRect.overlaps(proposedRect)) return true;
    }
    return false;
  }

  bool shouldSnap(CanvasItem item) {
    if (item.itemType != 'node') return false;
    final type = item.objectType;
    return type == 'deliverable' ||
        type == 'session' ||
        type == 'contextRequirement' ||
        type == 'event';
  }
}

/// Provider for creating canvas controllers from JSON data
final canvasControllerProvider =
    Provider.family<CanvasController, Map<String, Object?>>((ref, json) {
  return CanvasController.fromJson(json);
});
