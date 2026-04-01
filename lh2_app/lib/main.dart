import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_stub/lh2_stub.dart' as lh2;

// Web-specific imports for disabling context menu
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditionally import web implementation
import 'context_menu_web.dart'
    if (dart.library.html) 'context_menu_web_impl.dart';

import 'app/providers.dart';
import 'data/workspace_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable browser context menu on web platform
  if (kIsWeb) {
    disableBrowserContextMenu();
  }

  // Wrap the entire app in a ProviderScope so all Riverpod providers are
  // available throughout the widget tree.
  runApp(
    const ProviderScope(
      child: LH2App(),
    ),
  );
}

/// Root widget of the LH2 Lighthouse Hyperpanel application.
class LH2App extends ConsumerWidget {
  const LH2App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch Firebase + emulator initialisation.  While loading, show a splash; on error,
    // show a simple error screen.
    final firebaseAsync = ref.watch(firebaseEmulatorProvider);

    return MaterialApp(
      title: 'LH2 Lighthouse Hyperpanel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: firebaseAsync.when(
        loading: () => const _SplashScreen(),
        error: (err, _) => _ErrorScreen(error: err),
        data: (_) => const LH2HomePage(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Splash / error screens
// ---------------------------------------------------------------------------

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final Object error;
  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Failed to initialise Firebase:\n$error',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home page
// ---------------------------------------------------------------------------

/// Home page with minimal shell structure.
class LH2HomePage extends ConsumerStatefulWidget {
  const LH2HomePage({super.key});

  @override
  ConsumerState<LH2HomePage> createState() => _LH2HomePageState();
}

class _LH2HomePageState extends ConsumerState<LH2HomePage> {
  // Demo: Store some LH2 objects to verify imports work
  final List<lh2.LH2Object> _objects = [];

  @override
  void initState() {
    super.initState();

    // Initialize with some demo objects to verify lh2_stub imports work
    _objects.addAll([
      const lh2.Project(
        name: 'Demo Project',
        deliverablesIds: [],
        nonDeliverableTasksIds: [],
      ),
      const lh2.Task(
        name: 'Demo Task',
        sessionsIds: [],
        taskStatus: lh2.TaskStatus.draft,
        outboundDependenciesIds: [],
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // Example: read LH2API and WorkspaceRepository from the provider graph.
    // These are not used in the UI yet — they demonstrate correct DI wiring.
    final api = ref.watch(lh2ApiProvider);
    final workspaceRepo = ref.watch(workspaceRepoProvider);

    return Scaffold(
      body: Column(
        children: [
          // Top bar
          Container(
            height: 48,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'LH2',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  'Lighthouse Hyperpanel',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Main content area
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'LH2 App Loaded Successfully',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Imported ${_objects.length} LH2 objects from lh2_stub',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    // Demo: Show object types
                    ..._objects.map((obj) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '- ${obj.runtimeType}: ${obj.toJson()['name']}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        )),
                    const SizedBox(height: 32),
                    Text(
                      'Right-click context menu is disabled on web',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // DI status indicator
                    _DiStatusWidget(api: api, workspaceRepo: workspaceRepo),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DI status widget — example of reading providers from UI
// ---------------------------------------------------------------------------

/// Demonstrates reading [LH2API] and [WorkspaceRepository] from the Riverpod
/// provider graph.  This widget is for development verification only.
class _DiStatusWidget extends StatelessWidget {
  final lh2.LH2API api;
  final WorkspaceRepository workspaceRepo;

  const _DiStatusWidget({
    required this.api,
    required this.workspaceRepo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DI Graph — provider instances',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '✓ LH2API: ${api.runtimeType}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            '✓ WorkspaceRepository: ${workspaceRepo.runtimeType}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
