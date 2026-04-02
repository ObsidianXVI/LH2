import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_app/domain/notifiers/workspace_controller.dart';
import 'package:lh2_stub/lh2_stub.dart' as lh2;

// Web-specific imports for disabling context menu
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditionally import web implementation
import 'context_menu_web.dart'
    if (dart.library.html) 'context_menu_web_impl.dart';

import 'app/providers.dart';
import 'data/workspace_repository.dart';

import 'app/theme.dart';
import 'ui/theme/tokens.dart';
import 'app/responsive.dart';
import 'app/hyperpanel_scaffold.dart';
import 'ui/flow_canvas/flow_canvas_view.dart';
import 'ui/flow_canvas/canvas_provider.dart';

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
      theme: LH2Theme.materialTheme,
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing LH2...'),
          ],
        ),
      ),
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

    // Trigger initial workspace load using current user UID
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final wsId = await ref.read(workspaceIdProvider.future);
      await ref.read(workspaceControllerProvider.notifier).loadWorkspace(wsId);
    });

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

    return HyperpanelScaffold(
      child: Column(
        children: [
          // Top bar
          Container(
            height: 48,
            color: LH2Colors.panel,
            padding: EdgeInsets.symmetric(horizontal: LH2Theme.spacing(2)),
            child: Row(
              children: [
                Text(
                  'LH2',
                  style: LH2Theme.nodeTitle.copyWith(
                    fontSize: 18,
                    color: LH2Colors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Lighthouse Hyperpanel',
                  style: LH2Theme.tabLabel.copyWith(
                    color: LH2Colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Main content area - show FlowCanvasView when active tab exists
          Expanded(
            child: Container(
              color: LH2Colors.background,
              child: Consumer(
                builder: (context, ref, child) {
                  final canvasController = ref.watch(activeCanvasControllerProvider);
                  
                  if (canvasController == null) {
                    // No active tab or not a flow canvas - show placeholder
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'LH2 App Loaded Successfully',
                            style: LH2Theme.nodeTitle.copyWith(fontSize: 20),
                          ),
                          SizedBox(height: LH2Theme.spacing(2)),
                          Text(
                            'Imported ${_objects.length} LH2 objects from lh2_stub',
                            style: LH2Theme.body,
                          ),
                          SizedBox(height: LH2Theme.spacing(3)),
                          // Demo: Show object types
                          ..._objects.map((obj) => Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: LH2Theme.spacing(0.5)),
                                child: Text(
                                  '- ${obj.runtimeType}: ${obj.toJson()['name']}',
                                  style: LH2Theme.body.copyWith(fontSize: 12),
                                ),
                              )),
                          SizedBox(height: LH2Theme.spacing(4)),
                          Text(
                            'Create a Flow Canvas tab to get started',
                            style: LH2Theme.body.copyWith(
                              color: LH2Colors.accentBlue,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          SizedBox(height: LH2Theme.spacing(2)),
                          // Responsive demo
                          if (LH2Breakpoints.isSmallDesktop(context))
                            Padding(
                              padding: EdgeInsets.all(LH2Theme.spacing(2)),
                              child: Card(
                                color: LH2Colors.panel,
                                child: Padding(
                                  padding: EdgeInsets.all(LH2Theme.spacing(2)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Small Desktop Demo',
                                          style: LH2Theme.tabLabel),
                                      Text(
                                        'Query overlay: ${context.queryOverlayWidth.toStringAsFixed(0)}px',
                                        style: LH2Theme.body,
                                      ),
                                      Text(
                                        'Canvas min: ${context.canvasMinSize.width}x${context.canvasMinSize.height}px',
                                        style: LH2Theme.body,
                                      ),
                                      SizedBox(
                                        width: context.crosshairPanelWidth,
                                        child: Card(
                                          color: LH2Colors.selectionBlue
                                              .withValues(alpha: 0.1),
                                          child: Padding(
                                            padding:
                                                EdgeInsets.all(LH2Theme.spacing(1)),
                                            child: Text('Mock Crosshair Panel',
                                                style: LH2Theme.body),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // DI status indicator
                          _DiStatusWidget(api: api, workspaceRepo: workspaceRepo),
                        ],
                      ),
                    );
                  }
                  
                  // Show the Flow Canvas
                  return FlowCanvasView(controller: canvasController);
                },
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
      padding: EdgeInsets.all(LH2Theme.spacing(1.5)),
      decoration: BoxDecoration(
        border: Border.all(color: LH2Colors.border.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(LH2Theme.spacing(1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DI Graph — provider instances',
            style: LH2Theme.tabLabel.copyWith(fontSize: 12),
          ),
          SizedBox(height: LH2Theme.spacing(1)),
          Text(
            '✓ LH2API: ${api.runtimeType}',
            style: LH2Theme.body.copyWith(fontSize: 12),
          ),
          Text(
            '✓ WorkspaceRepository: ${workspaceRepo.runtimeType}',
            style: LH2Theme.body.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
