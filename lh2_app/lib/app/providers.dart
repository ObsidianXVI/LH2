/// LH2 Composition Root — Riverpod provider graph.
///
/// Layering:
///   UI  →  domain (LH2API, operations)  →  data (FirestoreDBInterface, repos)
///
/// All app-level singletons are defined here so that the dependency graph is
/// visible in one place.  Widgets should read providers via `ref.watch` /
/// `ref.read`; they must never instantiate Firebase or repository objects
/// directly.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:lh2_app/options.dart';
import 'package:lh2_stub/lh2_stub.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../domain/models/current_user.dart';

import '../data/cache.dart';
import '../data/firestore_db_interface.dart';
import '../data/workspace_repository.dart';

// ============================================================================
// 1. Firebase core
// ============================================================================

/// Initialises [FirebaseApp] once.  All downstream providers depend on this.
///
/// Usage (in main.dart):
/// ```dart
/// await ProviderContainer().read(firebaseAppProvider.future);
/// ```
final firebaseAppProvider = FutureProvider<FirebaseApp>((ref) async {
  return Firebase.initializeApp(options: webOptions);
});

final firebaseEmulatorProvider = FutureProvider<void>((ref) async {
  await ref.read(firebaseAppProvider.future);
  if (kDebugMode) {
    try {
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8081);
      FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    } catch (e) {
      // ignore if already initialized
    }
  }
});

// ============================================================================
// 2. Firebase service singletons
// ============================================================================

/// [FirebaseFirestore] instance.
///
/// Throws if [firebaseAppProvider] has not yet resolved.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  ref.watch(firebaseEmulatorProvider);
  // Ensure Firebase is initialised before accessing Firestore.
  ref.watch(firebaseAppProvider).maybeWhen(
        data: (_) => null,
        orElse: () => throw StateError(
          'FirebaseApp is not yet initialised. '
          'Await firebaseAppProvider before reading firestoreProvider.',
        ),
      );
  return FirebaseFirestore.instance;
});

/// [FirebaseAuth] instance.
///
/// Auth flows are stubbed for now (Task 6.1-1 will add sign-in logic).
final authProvider = Provider<FirebaseAuth>((ref) {
  ref.watch(firebaseEmulatorProvider);
  ref.watch(firebaseAppProvider).maybeWhen(
        data: (_) => null,
        orElse: () => throw StateError(
          'FirebaseApp is not yet initialised. '
          'Await firebaseAppProvider before reading authProvider.',
        ),
      );
  return FirebaseAuth.instance;
});

final currentUserProvider =
    FutureProvider.autoDispose<CurrentUser>((ref) async {
  final auth = ref.read(authProvider);
  User? user = auth.currentUser;
  if (user == null) {
    final result = await auth.signInAnonymously();
    user = result.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'anonymous-signin-failed',
        message: 'Anonymous sign-in failed',
      );
    }
  }
  return CurrentUser(user.uid);
});

// ============================================================================
// 3. Data layer
// ============================================================================

/// [FirestoreDBInterface] — the single gateway to all domain Firestore reads
/// and writes.
final dbProvider = Provider<FirestoreDBInterface>((ref) {
  final db = ref.watch(firestoreProvider);
  return FirestoreDBInterface(db);
});

/// [WorkspaceRepository] — reads/writes workspace state (tabs, node templates,
/// canvas controller JSON) to Firestore.
final workspaceRepoProvider = Provider<WorkspaceRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  return WorkspaceRepository(db);
});

// ============================================================================
// 4. Domain / application layer
// ============================================================================

/// [LH2API] — the top-level API object used by all operations.
///
/// Depends on [dbProvider] so that the correct [DatabaseInterface] is injected.
final lh2ApiProvider = Provider<LH2API>((ref) {
  final db = ref.watch(dbProvider);
  return LH2API(databaseInterface: db);
});

// ============================================================================
// 5. Per-type in-memory caches
// ============================================================================
//
// Each cache is a [GenericCache<T>] that fetches from Firestore on miss.
// A default TTL of 5 minutes is applied; callers can override per-call.
//
// Naming convention: <objectType>CacheProvider

const _defaultCacheTtl = Duration(minutes: 5);

/// Cache for [ProjectGroup] objects.
final projectGroupCacheProvider = Provider<GenericCache<ProjectGroup>>((ref) {
  final db = ref.watch(dbProvider);
  return GenericCache<ProjectGroup>(
    (id) => db.getObject<ProjectGroup>(id),
    defaultTtl: _defaultCacheTtl,
  );
});

/// Cache for [Project] objects.
final projectCacheProvider = Provider<GenericCache<Project>>((ref) {
  final db = ref.watch(dbProvider);
  return GenericCache<Project>(
    (id) => db.getObject<Project>(id),
    defaultTtl: _defaultCacheTtl,
  );
});

/// Cache for [Deliverable] objects.
final deliverableCacheProvider = Provider<GenericCache<Deliverable>>((ref) {
  final db = ref.watch(dbProvider);
  return GenericCache<Deliverable>(
    (id) => db.getObject<Deliverable>(id),
    defaultTtl: _defaultCacheTtl,
  );
});

/// Cache for [Task] objects.
final taskCacheProvider = Provider<GenericCache<Task>>((ref) {
  final db = ref.watch(dbProvider);
  return GenericCache<Task>(
    (id) => db.getObject<Task>(id),
    defaultTtl: _defaultCacheTtl,
  );
});

/// Cache for [Session] objects.
final sessionCacheProvider = Provider<GenericCache<Session>>((ref) {
  final db = ref.watch(dbProvider);
  return GenericCache<Session>(
    (id) => db.getObject<Session>(id),
    defaultTtl: _defaultCacheTtl,
  );
});

/// Cache for [ContextRequirement] objects.
final contextRequirementCacheProvider =
    Provider<GenericCache<ContextRequirement>>((ref) {
  final db = ref.watch(dbProvider);
  return GenericCache<ContextRequirement>(
    (id) => db.getObject<ContextRequirement>(id),
    defaultTtl: _defaultCacheTtl,
  );
});

/// Cache for [Event] objects.
final eventCacheProvider = Provider<GenericCache<Event>>((ref) {
  final db = ref.watch(dbProvider);
  return GenericCache<Event>(
    (id) => db.getObject<Event>(id),
    defaultTtl: _defaultCacheTtl,
  );
});

/// Cache for [ActualContext] objects.
final actualContextCacheProvider = Provider<GenericCache<ActualContext>>((ref) {
  final db = ref.watch(dbProvider);
  return GenericCache<ActualContext>(
    (id) => db.getObject<ActualContext>(id),
    defaultTtl: _defaultCacheTtl,
  );
});

/// Demo tab list for tab bar (Task 1.1.1).
typedef TabInfo = (String id, String title);
final tabListProvider = Provider<List<TabInfo>>((ref) => const [
      ('flow1', 'Flow 1'),
      ('calendar1', 'Calendar 1'),
    ]);

/// Tab bar hover state.
final tabBarHoveredProvider = StateProvider<bool>((ref) => false);

/// Workspace ID derived from current user UID.
final workspaceIdProvider = FutureProvider<String>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  return user.uid;
});

/// General object provider that fetches an object by its type and ID.
final objectProvider = FutureProvider.family<LH2Object?, (ObjectType, String)>((ref, params) async {
  final (type, id) = params;
  switch (type) {
    case ObjectType.project:
      return ref.watch(projectCacheProvider).get(id);
    case ObjectType.task:
      return ref.watch(taskCacheProvider).get(id);
    case ObjectType.deliverable:
      return ref.watch(deliverableCacheProvider).get(id);
    case ObjectType.session:
      return ref.watch(sessionCacheProvider).get(id);
    case ObjectType.event:
      return ref.watch(eventCacheProvider).get(id);
    case ObjectType.contextRequirement:
      return ref.watch(contextRequirementCacheProvider).get(id);
    case ObjectType.actualContext:
      return ref.watch(actualContextCacheProvider).get(id);
    case ObjectType.projectGroup:
      return ref.watch(projectGroupCacheProvider).get(id);
  }
});
