import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';

/// Adaptive navigation shell: bottom NavigationBar on phones,
/// NavigationRail on wide layouts (>= 840dp, Phase 11 polish).
class VeggieShell extends StatelessWidget {
  const VeggieShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // Icons/ids stay const; the visible label is resolved per build with context.
  static const _destinations = [
    (id: 'today', icon: Icons.spa_outlined, selectedIcon: Icons.spa),
    (id: 'habits', icon: Icons.task_alt_outlined, selectedIcon: Icons.task_alt),
    (
      id: 'explore',
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded
    ),
    (
      id: 'journey',
      icon: Icons.favorite_outline,
      selectedIcon: Icons.favorite
    ),
  ];

  String _label(AppLocalizations l, String id) => switch (id) {
        'today' => l.shellTabToday,
        'habits' => l.shellTabHabits,
        'explore' => l.shellTabExplore,
        _ => l.shellTabJourney,
      };

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 840;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _goBranch,
                labelType: NavigationRailLabelType.all,
                groupAlignment: -0.8,
                backgroundColor: Theme.of(context).colorScheme.surface,
                destinations: [
                  for (final d in _destinations)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(_label(l, d.id)),
                    ),
                ],
              ),
            ),
            const VerticalDivider(),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    // Today (index 0) gets a full-screen feed behind a see-through bar; other
    // tabs keep the solid bar and a non-extended body (unchanged).
    final onToday = navigationShell.currentIndex == 0;
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: onToday,
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        backgroundColor:
            onToday ? theme.colorScheme.surface.withValues(alpha: 0.7) : null,
        surfaceTintColor: onToday ? Colors.transparent : null,
        elevation: onToday ? 0 : null,
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: _label(l, d.id),
            ),
        ],
      ),
    );
  }
}
