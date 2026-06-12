import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/prefs/prefs_repository.dart';
import '../features/explore/category_detail_screen.dart';
import '../features/explore/explore_screen.dart';
import '../features/explore/favorites_screen.dart';
import '../features/habits/habit_edit_screen.dart';
import '../features/habits/habits_screen.dart';
import '../features/journey/journey_screen.dart';
import '../features/onboarding/onboarding_flow.dart';
import '../features/paywall/paywall_data.dart';
import '../features/paywall/paywall_screen.dart';
import '../features/quotes/feed_screen.dart';
import '../features/quotes/quote_detail_screen.dart';
import '../features/settings/notification_settings_screen.dart';
import '../features/settings/settings_screen.dart';
import 'shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final prefs = ref.watch(prefsProvider);

  return GoRouter(
    initialLocation: '/today',
    redirect: (context, state) {
      final inOnboarding = state.matchedLocation == '/onboarding';
      if (!prefs.onboardingDone && !inOnboarding) return '/onboarding';
      if (prefs.onboardingDone && inOnboarding) return '/today';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingFlow(),
      ),
      GoRoute(
        path: '/quote/:id',
        builder: (context, state) => QuoteDetailScreen(
          quoteId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/paywall/:variant',
        builder: (context, state) => PaywallScreen(
          variant: PaywallVariant.fromName(state.pathParameters['variant']),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            VeggieShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/today',
              builder: (context, state) => const FeedScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/habits',
              builder: (context, state) => const HabitsScreen(),
              routes: [
                GoRoute(
                  path: 'edit/:id',
                  builder: (context, state) => HabitEditScreen(
                    habitId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/explore',
              builder: (context, state) => const ExploreScreen(),
              routes: [
                GoRoute(
                  path: 'category/:id',
                  builder: (context, state) => CategoryDetailScreen(
                    categoryId: state.pathParameters['id']!,
                  ),
                ),
                GoRoute(
                  path: 'favorites',
                  builder: (context, state) => const FavoritesScreen(),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/journey',
              builder: (context, state) => const JourneyScreen(),
              routes: [
                GoRoute(
                  path: 'settings',
                  builder: (context, state) => const SettingsScreen(),
                  routes: [
                    GoRoute(
                      path: 'notifications',
                      builder: (context, state) =>
                          const NotificationSettingsScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});
