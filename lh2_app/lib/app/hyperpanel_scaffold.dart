import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'theme.dart';
import '../ui/theme/tokens.dart';

/// Hyperpanel Scaffold with hover-reveal tab bar (FEATURES.md §1.1.1).
class HyperpanelScaffold extends ConsumerWidget {
  final Widget child;
  const HyperpanelScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTabId = ref.watch(activeTabIdProvider);
    final tabs = ref.watch(tabListProvider);
    final hovered = ref.watch(tabBarHoveredProvider);

    return Scaffold(
      body: Column(
        children: [
          /// Hover-reveal tab bar (fixed height, no content shift).
          MouseRegion(
            onEnter: (_) => ref.read(tabBarHoveredProvider.notifier).state = true,
            onExit: (_) => ref.read(tabBarHoveredProvider.notifier).state = false,
            child: Container(
              height: 40.0,
              color: LH2Colors.panel,
              child: DocumentTabBar(
                tabs: tabs.map((t) => TabMeta(id: t.$1, title: t.$2)).toList(),
                activeTabId: activeTabId,
                hovered: hovered,
                onSelect: (id) => ref.read(activeTabIdProvider.notifier).state = id,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Tab bar widget (VS Code-like hover reveal).
/// When not hovered: only active tab visible (centered).
/// When hovered: all tabs visible in a row.
class DocumentTabBar extends StatelessWidget {
  final List<TabMeta> tabs;
  final String? activeTabId;
  final bool hovered;
  final void Function(String) onSelect;
  const DocumentTabBar({
    super.key,
    required this.tabs,
    this.activeTabId,
    required this.hovered,
    required this.onSelect,
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

/// Tab button.
class TabButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: LH2Theme.spacing(2),
          vertical: LH2Theme.spacing(1),
        ),
        decoration: BoxDecoration(
          color: isActive ? LH2Colors.selectionBlue.withOpacity(0.2) : null,
          borderRadius: BorderRadius.circular(LH2Theme.spacing(0.5)),
        ),
        child: TabLabel(tab: tab, isActive: isActive),
      ),
    );
  }
}

/// Tab label.
class TabLabel extends StatelessWidget {
  final TabMeta tab;
  final bool isActive;
  const TabLabel({
    super.key,
    required this.tab,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      tab.title,
      style: LH2Theme.tabLabel.copyWith(
        color: LH2Colors.textPrimary,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}