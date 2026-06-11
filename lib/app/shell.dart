import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Adaptive navigation shell: bottom NavigationBar on phones,
/// NavigationRail on wide layouts (>= 840dp, Phase 11 polish).
class VeggieShell extends StatelessWidget {
  const VeggieShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    (icon: Icons.spa_outlined, selectedIcon: Icons.spa, label: 'Today'),
    (
      icon: Icons.task_alt_outlined,
      selectedIcon: Icons.task_alt,
      label: 'Habits'
    ),
    (
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
      label: 'Explore'
    ),
    (
      icon: Icons.favorite_outline,
      selectedIcon: Icons.favorite,
      label: 'Journey'
    ),
  ];

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      label: Text(d.label),
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

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
