/// Generic in-memory cache for LH2 objects.
///
/// Supports optional TTL per entry, manual invalidation, and a bypass flag.
library;

import 'dart:async';

/// A single cache entry wrapping a value with an optional expiry time.
class _CacheEntry<T> {
  final T value;
  final DateTime? expiresAt;

  _CacheEntry(this.value, {Duration? ttl})
      : expiresAt = ttl != null ? DateTime.now().add(ttl) : null;

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

/// Type-safe in-memory cache for objects of type [T], keyed by [String] id.
///
/// Usage:
/// ```dart
/// final cache = GenericCache<Project>((id) => db.getObject<Project>(id));
/// final project = await cache.get('proj-123');
/// ```
class GenericCache<T> {
  final Map<String, _CacheEntry<T>> _registry = {};
  final FutureOr<T> Function(String id) _fetcher;

  /// Default TTL applied to every entry unless overridden per-call.
  final Duration? defaultTtl;

  bool _hasInitAll = false;

  GenericCache(this._fetcher, {this.defaultTtl});

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Returns the cached value for [id], fetching and caching it if absent or
  /// expired.
  ///
  /// Pass [bypassCache] to force a fresh fetch regardless of cache state.
  /// Pass [ttl] to override [defaultTtl] for this specific entry.
  Future<T> get(
    String id, {
    bool bypassCache = false,
    Duration? ttl,
  }) async {
    final entry = _registry[id];
    if (!bypassCache && entry != null && !entry.isExpired) {
      return entry.value;
    }
    final value = await _fetcher(id);
    _registry[id] = _CacheEntry(value, ttl: ttl ?? defaultTtl);
    return value;
  }

  /// Returns the cached value synchronously if present and not expired,
  /// otherwise returns `null`.
  T? peek(String id) {
    final entry = _registry[id];
    if (entry == null || entry.isExpired) return null;
    return entry.value;
  }

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Stores [value] directly in the cache under [id].
  void put(String id, T value, {Duration? ttl}) {
    _registry[id] = _CacheEntry(value, ttl: ttl ?? defaultTtl);
  }

  // ---------------------------------------------------------------------------
  // Invalidation
  // ---------------------------------------------------------------------------

  /// Removes the entry for [id] from the cache.
  void invalidate(String id) => _registry.remove(id);

  /// Clears all entries from the cache.
  void invalidateAll() {
    _registry.clear();
    _hasInitAll = false;
  }

  // ---------------------------------------------------------------------------
  // Bulk init
  // ---------------------------------------------------------------------------

  /// Pre-populates the cache from a map of id → value pairs.
  ///
  /// Typically called with the result of a Firestore collection fetch.
  /// Pass [force] to re-initialise even if [initAll] was already called.
  void initFromMap(Map<String, T> items, {bool force = false}) {
    if (_hasInitAll && !force) return;
    for (final entry in items.entries) {
      _registry[entry.key] =
          _CacheEntry(entry.value, ttl: defaultTtl);
    }
    _hasInitAll = true;
  }

  /// Whether [initAll] / [initFromMap] has been called at least once.
  bool get isInitialised => _hasInitAll;

  /// Number of entries currently in the cache (including potentially expired
  /// ones that have not yet been evicted).
  int get length => _registry.length;
}
