class GenericCache<T> {
  final Map<String, T> registry = {};
  final FutureOr<T> Function(String id) operation;
  bool _hasInitAll = false;

  GenericCache(this.operation);

  Future<void> initAll({
    CollectionReference? collection,
    Query? query,
    bool force = false,
  }) async {
    if (_hasInitAll) {
      if (!force) return;
    } else {
      final res = collection != null
          ? (await collection.get()).docs
          : (await query!.get()).docs;
      for (final item in res) {
        registry[item.id] = item as T;
      }
      _hasInitAll = true;
    }
  }

  Future<T> get(String id, {bool bypassCache = false}) async {
    if (bypassCache || !registry.containsKey(id)) {
      return registry[id] = await operation(id);
    } else {
      return registry[id]!;
    }
  }
}
