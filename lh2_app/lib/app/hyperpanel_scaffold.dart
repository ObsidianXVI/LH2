import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_app/domain/operations/core.dart';
import 'package:flutter/services.dart';
import 'responsive.dart';

import 'providers.dart';
import 'theme.dart';
import '../ui/theme/tokens.dart';
import '../domain/notifiers/workspace_controller.dart' as ws;
import '../domain/notifiers/canvas_controller_impl.dart';
import '../ui/query_overlay.dart';

/// Hyperpanel Scaffold with hover-reveal tab bar (FEATURES.md §1.1.1).
class HyperpanelScaffold extends ConsumerWidget {
  final Widget child;
  const HyperpanelScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceState = ref.watch(ws.workspaceControllerProvider);
    final isSmall = LH2Breakpoints.isSmallDesktop(context);
    final activeTabId = workspaceState.activeTabId;
    final tabs =
        workspaceState.tabs.map((t) => (t.tabId, t.tab.title)).toList();
    final hovered = ref.watch(ws.tabBarHoveredProvider);

    void showCreateTabMenu() {
      final RenderBox? overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox?;
      if (overlay == null) return;

      final position = RelativeRect.fromLTRB(
        100, // left position near the tab bar
        40, // below the tab bar
        overlay.size.width - 100,
        overlay.size.height,
      );

      showMenu<String>(
        context: context,
        position: position,
        items: [
          const PopupMenuItem(
            value: 'flow',
            child: Row(
              children: [
                Text('⧉', style: TextStyle(fontSize: 16)), // Unicode flow icon
                SizedBox(width: 8),
                Text('Flow Canvas'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'calendar',
            child: Row(
              children: [
                Text('◫',
                    style: TextStyle(fontSize: 16)), // Unicode calendar icon
                SizedBox(width: 8),
                Text('Calendar Canvas'),
              ],
            ),
          ),
        ],
      ).then((kind) async {
        if (kind != null) {
          final controller = ref.read(ws.workspaceControllerProvider.notifier);

          // Now create the tab
          try {
            await controller.createTab(
              kind == 'flow' ? ws.CanvasKind.flow : ws.CanvasKind.calendar,
            );
          } on LH2OpError catch (e) {
            if (context.mounted) {
              String msg = e.toString();
              if (e is LH2OpError) msg = e.message;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to create tab: $msg'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        }
      });
    }

    return Scaffold(
      body: Column(
        children: [
          /// Hover-reveal tab bar (fixed height, no content shift).
          MouseRegion(
            onEnter: (_) =>
                ref.read(ws.tabBarHoveredProvider.notifier).state = true,
            onExit: (_) =>
                ref.read(ws.tabBarHoveredProvider.notifier).state = false,
            child: Container(
              height: 40.0,
              color: LH2Colors.panel,
              child: DocumentTabBar(
                tabs: tabs.map((t) => TabMeta(id: t.$1, title: t.$2)).toList(),
                activeTabId: activeTabId,
                hovered: hovered,
                onSelect: (id) => ref
                    .read(ws.workspaceControllerProvider.notifier)
                    .setActiveTab(id),
                onCreateTab: showCreateTabMenu,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: isSmall ? 60.0 : context.queryOverlayWidth,
                  child: isSmall
                      ? Container(
                          color: LH2Colors.panel,
                          child: Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: () {
                                  // In a real app, this could open a drawer or expand the overlay
                                },
                              ),
                            ],
                          ),
                        )
                      : const QueryOverlay(),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab bar widget (VS Code-like hover reveal).
/// When not hovered: only active tab visible.
/// When hovered: all tabs visible plus "+" button for creating new tabs.
class DocumentTabBar extends StatelessWidget {
  final List<TabMeta> tabs;
  final String? activeTabId;
  final bool hovered;
  final void Function(String) onSelect;
  final VoidCallback onCreateTab;
  const DocumentTabBar({
    super.key,
    required this.tabs,
    this.activeTabId,
    required this.hovered,
    required this.onSelect,
    required this.onCreateTab,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in tabs)
            Opacity(
              opacity: hovered || tab.id == activeTabId ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !hovered && tab.id != activeTabId,
                child: TabButton(
                  tab: tab,
                  isActive: tab.id == activeTabId,
                  onTap: tab.id == activeTabId
                      ? () {} // No-op for active tab
                      : () => onSelect(tab.id),
                ),
              ),
            ),
          // "+" button to create new tab (visible when hovered)
          if (hovered)
            InkWell(
              onTap: onCreateTab,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Text(
                  '+',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Demo tab meta.
class TabMeta {
  final String id;
  final String title;
  const TabMeta({required this.id, required this.title});
}

class TabButton extends ConsumerStatefulWidget {
  final TabMeta tab;
  final bool isActive;
  final VoidCallback onTap;
  const TabButton({
    super.key,
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  ConsumerState<TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends ConsumerState<TabButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: LH2Theme.spacing(2),
            vertical: LH2Theme.spacing(1),
          ),
          decoration: BoxDecoration(
            color: widget.isActive
                ? LH2Colors.selectionBlue.withOpacity(0.2)
                : null,
            borderRadius: BorderRadius.circular(LH2Theme.spacing(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              EditableTabLabel(tab: widget.tab, isActive: widget.isActive),
              if (_hovered)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    ref
                        .read(ws.workspaceControllerProvider.notifier)
                        .deleteTab(widget.tab.id);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditableTabLabel extends ConsumerStatefulWidget {
  final TabMeta tab;
  final bool isActive;
  const EditableTabLabel({
    super.key,
    required this.tab,
    required this.isActive,
  });

  @override
  ConsumerState<EditableTabLabel> createState() => _EditableTabLabelState();
}

class _EditableTabLabelState extends ConsumerState<EditableTabLabel> {
  bool _editing = false;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _editing) {
      _commit();
    }
  }

  void _startEditing() {
    setState(() {
      _editing = true;
    });
    _controller.text = widget.tab.title;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _commit() {
    final newTitle = _controller.text.trim();
    if (newTitle.isNotEmpty && newTitle != widget.tab.title) {
      ref
          .read(ws.workspaceControllerProvider.notifier)
          .renameTab(widget.tab.id, newTitle);
    }
    setState(() {
      _editing = false;
    });
  }

  void _cancel() {
    setState(() {
      _editing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_editing) {
      return GestureDetector(
        onDoubleTap: _startEditing,
        child: Text(
          widget.tab.title,
          style: LH2Theme.tabLabel.copyWith(
            color: LH2Colors.textPrimary,
            fontWeight: widget.isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    }

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.escape): const DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (intent) => _cancel(),
          ),
        },
        child: SizedBox(
          width:
              120, // Give TextField a fixed width during edit to avoid layout issues
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            style: LH2Theme.tabLabel.copyWith(
              color: LH2Colors.textPrimary,
              fontWeight: widget.isActive ? FontWeight.bold : FontWeight.normal,
              backgroundColor: Colors.transparent,
            ),
            decoration: const InputDecoration(
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 1.0),
              ),
              contentPadding: EdgeInsets.zero,
              isDense: true,
              isCollapsed: true,
            ),
            onSubmitted: (_) => _commit(),
            textInputAction: TextInputAction.done,
          ),
        ),
      ),
    );
  }
}
