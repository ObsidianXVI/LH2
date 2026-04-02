library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  const CanvasItem({
    required this.itemId,
    required this.itemType,
    required this.worldRect,
    this.objectId,
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
    };
  }
}

/// Canvas link representing connections between items.
class CanvasLink {
  final String linkId;
  final String fromItemId;
  final String toItemId;
  final String? linkType;

  const CanvasLink({
    required this.linkId,
    required this.fromItemId,
    required this.toItemId,
    this.linkType,
  });

  factory CanvasLink.fromJson(String linkId, Map<String, Object?> json) {
    return CanvasLink(
      linkId: linkId,
      fromItemId: json['fromItemId'] as String,
      toItemId: json['toItemId'] as String,
      linkType: json['linkType'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'fromItemId': fromItemId,
      'toItemId': toItemId,
      if (linkType != null) 'linkType': linkType,
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

  /// Convert world coordinates to screen coordinates
  Offset worldToScreen(Offset world) {
    return (world - viewport.pan) * viewport.zoom + 
           Offset(viewport.viewportSizePx.width / 2, viewport.viewportSizePx.height / 2);
  }

  /// Convert screen coordinates to world coordinates
  Offset screenToWorld(Offset screen) {
    return (screen - Offset(viewport.viewportSizePx.width / 2, viewport.viewportSizePx.height / 2)) / viewport.zoom + 
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

  /// Pan the viewport by a delta in screen coordinates
  void panBy(Offset deltaScreen) {
    final deltaWorld = deltaScreen / viewport.zoom;
    _updateViewport(viewport.copyWith(pan: viewport.pan - deltaWorld));
  }

  /// Zoom the viewport at a focal point in screen coordinates
  void zoomAt({required Offset focalScreen, required double scaleDelta}) {
    final focalWorld = screenToWorld(focalScreen);
    final newZoom = (viewport.zoom * scaleDelta).clamp(0.1, 10.0);
    
    // Calculate new pan to keep the focal point stationary
    final newPan = focalWorld - (focalScreen - Offset(viewport.viewportSizePx.width / 2, viewport.viewportSizePx.height / 2)) / newZoom;
    
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
  void updateItemRect(String itemId, Rect newWorldRect) {
    final item = _items[itemId];
    if (item != null) {
      _items[itemId] = CanvasItem(
        itemId: item.itemId,
        itemType: item.itemType,
        worldRect: newWorldRect,
        objectId: item.objectId,
      );
      notifyListeners();
    }
  }

  /// Remove an item from the canvas
  void removeItem(String itemId) {
    _items.remove(itemId);
    _selection.remove(itemId);
    notifyListeners();
  }

  /// Convert to JSON for persistence
  Map<String, Object?> toJson();

  /// Create from JSON
  factory CanvasController.fromJson(Map<String, Object?> json) {
    final kind = CanvasKind.fromJson(json['kind'] as String);
    
    return switch (kind) {
      FlowCanvasKind() => FlowCanvasController.fromJson(json),
      CalendarCanvasKind() => throw UnimplementedError('CalendarCanvasController not implemented yet'),
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
    _viewport = CanvasViewport.fromJson(json['viewport'] as Map<String, Object?>);
    
    _items = {};
    final itemsJson = json['items'] as Map<dynamic, dynamic>? ?? <String, Object?>{};
    for (final entry in itemsJson.entries) {
      final key = entry.key as String;
      final value = entry.value as Map<dynamic, dynamic>;
      _items[key] = CanvasItem.fromJson(key, value.cast<String, Object?>());
    }
    
    _links = {};
    final linksJson = json['links'] as Map<dynamic, dynamic>? ?? <String, Object?>{};
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
      viewport: CanvasViewport.fromJson(json['viewport'] as Map<String, Object?>),
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
    final gridWorldSize = gridSizePx / viewport.zoom;
    return Offset(
      (worldPos.dx / gridWorldSize).round() * gridWorldSize,
      (worldPos.dy / gridWorldSize).round() * gridWorldSize,
    );
  }
}

/// Provider for creating canvas controllers from JSON data
final canvasControllerProvider = Provider.family<CanvasController, Map<String, Object?>>((ref, json) {
  return CanvasController.fromJson(json);
});