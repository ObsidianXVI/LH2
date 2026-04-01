Task 6.3.1-1: Improve `GenericCache` to be type-safe + TTL + invalidation [L3]

---

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`). You have access to Flutter and Chrome devtools for debugging, inspection, loggin, profiling, etc.

Use `flutter run -d web-server --web-hostname localhost --web-port 8080` to run the web server initially.

You have access to the Chrome browser instance, so navigate to `localhost:8080` to access the app. Refresh to show the latest changes for future code changes.

DO NOT modify `system_prompt.md` or `PLAN.md`

Your job is to implement without breaking existing functionality, the specified task:

##### Task 6.3.1-1: Improve `GenericCache` to be type-safe + TTL + invalidation [L3]

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
