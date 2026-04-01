
import 'dart:async';

import 'package:test/test.dart';
import 'package:lh2_app/data/cache.dart';

void main() {
  late GenericCache<String> cache;
  late List<String> fetchCalls;

  setUp(() {
    fetchCalls = [];
    cache = GenericCache<String>(
      (id) async {
        fetchCalls.add(id);
        await Future.delayed(Duration(milliseconds: 1)); // simulate async
        return 'value-$id';
      },
      defaultTtl: Duration(seconds: 5),
    );
  });

  group('GenericCache', () {
    test('cache hit (no bypass)', () async {
      final v1 = await cache.get('key1');
      final v2 = await cache.get('key1');
      expect(v2, v1);
      expect(fetchCalls, ['key1']); // fetched once
    });

    test('cache miss -> fetch and store', () async {
      final v = await cache.get('miss');
      expect(v, 'value-miss');
      expect(fetchCalls, ['miss']);
    });

    test('bypassCache forces fresh fetch', () async {
      await cache.get('key');
      fetchCalls.clear();
      await cache.get('key', bypassCache: true);
      expect(fetchCalls, ['key']); // fetched again
    });

    test('TTL expiry evicts entry', () async {
      final ttlCache = GenericCache<String>(
        (id) async {
          fetchCalls.add(id);
          return 'fresh-$id';
        },
        defaultTtl: Duration(milliseconds: 10),
      );
      await ttlCache.get('exp');
      await Future.delayed(Duration(milliseconds: 20));
      await ttlCache.get('exp'); // should refetch
      expect(fetchCalls.length, 2);
    });

    test('per-call TTL override', () async {
      await cache.get('short', ttl: Duration(milliseconds: 1));
      await Future.delayed(Duration(milliseconds: 5));
      await cache.get('short'); // refetch short, but default still cached if had
      expect(fetchCalls, ['short', 'short']);
    });

    test('put stores directly', () async {
      cache.put('direct', 'manual-value');
      final v = await cache.get('direct');
      expect(v, 'manual-value');
      expect(fetchCalls, isEmpty); // no fetch
    });

    test('invalidate(id) removes single entry', () async {
      await cache.get('to-inv');
      cache.invalidate('to-inv');
      await cache.get('to-inv');
      expect(fetchCalls.length, 2); // fetched twice
    });

    test('invalidateAll clears everything', () async {
      await cache.get('a');
      await cache.get('b');
      cache.invalidateAll();
      await cache.get('a');
      expect(fetchCalls.length, 3); // original 2 + 1 refetch
    });

    test('initFromMap populates bulk', () async {
      cache.initFromMap({'k1': 'v1', 'k2': 'v2'});
      expect(await cache.get('k1'), 'v1');
      expect(await cache.get('k2'), 'v2');
      expect(fetchCalls, []); // no fetches
    });

    test('initFromMap force re-inits', () async {
      cache.initFromMap({'k': 'old'});
      cache.initFromMap({'k': 'new'}, force: true);
      expect(cache.peek('k'), 'new');
    });

    test('peek returns null if expired/missing', () async {
      expect(cache.peek('missing'), isNull);
      await cache.get('exp', ttl: Duration(milliseconds: 1));
      await Future.delayed(Duration(milliseconds: 2));
      expect(cache.peek('exp'), isNull);
    });
  });
}