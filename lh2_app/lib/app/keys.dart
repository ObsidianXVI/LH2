/// Flutter Key strategy for LH2 to minimize unnecessary rebuilds.
///
/// ## Guidelines
///
/// Use Keys to help Flutter's element tree identify widgets uniquely:
///
/// - **ValueKey(String)**: For list items or stable identities (e.g., objectId, itemId).
///   - Use when the key is a simple stable string like Firestore doc ID.
///   - Example: `ValueKey('project/${project.id}')`.
///
/// - **ObjectKey(Object)**: For instances where == is reliable (immutable models).
///   - Use for LH2Object instances if they override ==/hashCode properly.
///   - Avoid if model recreated frequently.
///
/// - **GlobalKey**: For stateful widgets needing preserved state across rebuilds (e.g., controllers, forms).
///   - Rare; prefer ValueKey + Riverpod for most cases.
///   - Reuse across builds.
///
/// - **UniqueKey()**: Last resort for one-off uniqueness.
///
/// Always key lists (ListView.builder itemBuilder) and conditional widgets (if/else).
///
/// ## Helpers
///
/// CanvasItem keys (future CanvasItem.id):
///
import 'package:flutter/foundation.dart';

Key canvasItemKey(String itemId) => ValueKey('canvasItem/$itemId');

/// Node key combining template + object.
Key nodeKey(String templateId, String? objectId) =>
    ValueKey('node/$templateId${objectId ?? ''}');

/// Example usage in node list builder:
///
/// ```dart
/// ListView.builder(
///   key: ValueKey('nodesList-${canvas.kind}'),
///   itemCount: items.length,
///   itemBuilder: (context, index) {
///     final item = items[index];
///     return NodeWidget(
///       key: canvasItemKey(item.id),
///       item: item,
///     );
///   },
/// )
/// ```
