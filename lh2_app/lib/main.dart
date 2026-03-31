import 'package:flutter/material.dart';
import 'package:lh2_stub/lh2_stub.dart' as lh2;

// Web-specific imports for disabling context menu
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditionally import web implementation
import 'context_menu_web.dart'
    if (dart.library.html) 'context_menu_web_impl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable browser context menu on web platform
  if (kIsWeb) {
    disableBrowserContextMenu();
  }

  runApp(const LH2App());
}

/// Root widget of the LH2 Lighthouse Hyperpanel application.
class LH2App extends StatelessWidget {
  const LH2App({super.key});

  @override
  Widget build(BuildContext context) {
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
      home: const LH2HomePage(),
    );
  }
}

/// Home page with minimal shell structure.
class LH2HomePage extends StatefulWidget {
  const LH2HomePage({super.key});

  @override
  State<LH2HomePage> createState() => _LH2HomePageState();
}

class _LH2HomePageState extends State<LH2HomePage> {
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
