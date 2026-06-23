import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/paywall/discount_banner.dart';
import '../features/quotes/feed_screen.dart';
import '../features/streak/streak_banner.dart';
import '../l10n/app_localizations.dart';

/// The app's base screen: the full-screen quote feed with four floating,
/// semi-transparent round buttons in the corners. Each button pushes its
/// screen on top (so closing always lands back here on the feed). There is no
/// bottom bar or navigation rail any more — corner buttons are used at every
/// width.
class VeggieShell extends StatelessWidget {
  const VeggieShell({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        children: [
          const FeedScreen(),
          SafeArea(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: _CornerButton(
                    icon: Icons.person_outline,
                    label: l.shellTabJourney,
                    onTap: () => context.push('/journey'),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: _CornerButton(
                    icon: Icons.settings_outlined,
                    label: l.settingsTitle,
                    onTap: () => context.push('/settings'),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: _CornerButton(
                    icon: Icons.task_alt_outlined,
                    label: l.shellTabHabits,
                    onTap: () => context.push('/habits'),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: _CornerButton(
                    icon: Icons.grid_view_outlined,
                    label: l.shellTabExplore,
                    onTap: () => context.push('/explore'),
                  ),
                ),
              ],
            ),
          ),
          // Top streak banner — paints above the feed and corner buttons. It
          // manages its own show/hide, so mounting it unconditionally is fine.
          const Align(
            alignment: Alignment.topCenter,
            child: StreakBanner(),
          ),
          // Opt-in 80%-off discount banner, same top-center slot. It yields
          // whenever the streak banner is showing (see DiscountBanner), so the
          // two never overlap; mounting it unconditionally is fine.
          const Align(
            alignment: Alignment.topCenter,
            child: DiscountBanner(),
          ),
        ],
      ),
    );
  }
}

/// A single circular corner button: translucent [surface] disc with the icon
/// in [onSurface] — the same see-through look the old Today bar had.
class _CornerButton extends StatelessWidget {
  const _CornerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Material(
        color: scheme.surface.withValues(alpha: 0.7),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon),
          color: scheme.onSurface,
          tooltip: label,
          // ≥ 48dp tap target.
          iconSize: 24,
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
          ),
        ),
      ),
    );
  }
}
