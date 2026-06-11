import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/prefs/prefs_repository.dart';
import '../features/explore/explore_screen.dart';
import '../features/habits/habits_screen.dart';
import '../features/journey/journey_screen.dart';
import '../features/quotes/feed_screen.dart';
import 'shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final prefs = ref.watch(prefsProvider);

  return GoRouter(
    initialLocation: '/today',
    redirect: (context, state) {
      // Onboarding gate wired fully in Phase 7; flag exists from day one.
      final inOnboarding = state.matchedLocation == '/onboarding';
      if (!prefs.onboardingDone && !inOnboarding) {
        // Until the onboarding flow exists, let everything through.
        return null;
      }
      return null;
    },
    routes: [
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
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/explore',
              builder: (context, state) => const ExploreScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/journey',
              builder: (context, state) => const JourneyScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});
