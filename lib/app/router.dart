import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/prefs/prefs_repository.dart';
import '../features/explore/category_detail_screen.dart';
import '../features/explore/explore_screen.dart';
import '../features/explore/favorites_screen.dart';
import '../features/habits/habit_detail_screen.dart';
import '../features/habits/habit_edit_screen.dart';
import '../features/habits/habits_screen.dart';
import '../features/journey/journey_screen.dart';
import '../features/legal/legal_content.dart';
import '../features/legal/legal_screen.dart';
import '../features/onboarding/onboarding_flow.dart';
import '../features/quotes/quote_detail_screen.dart';
import '../features/settings/notification_settings_screen.dart';
import '../features/settings/settings_screen.dart';
import '../l10n/app_localizations.dart';
import 'shell.dart';

/// A modal-sheet-style page: slides up from the bottom (ease-out, ~300ms).
/// Used for the four corner-button screens; their nested sub-routes keep the
/// default platform transition.
CustomTransitionPage<void> _sheetPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final prefs = ref.watch(prefsProvider);

  return GoRouter(
    initialLocation: '/today',
    redirect: (context, state) {
      final inOnboarding = state.matchedLocation == '/onboarding';
      // Force a not-yet-onboarded user into onboarding.
      if (!prefs.onboardingDone && !inOnboarding) return '/onboarding';
      // Deliberately NO auto-bounce off /onboarding once done: the end-of-
      // onboarding paywall funnel sets onboardingDone, then pushes paywalls on
      // top of /onboarding and pops back here between them. An auto-bounce to
      // /today would tear the funnel down mid-sequence. _finish() navigates to
      // /today explicitly once the funnel completes. Nothing else routes a
      // finished user to /onboarding (reset clears the flag first).
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
        path: '/legal/privacy',
        builder: (context, state) => LegalScreen(
          title: AppLocalizations.of(context).legalPrivacyTitle,
          sections: privacyPolicySections,
        ),
      ),
      GoRoute(
        path: '/legal/terms',
        builder: (context, state) => LegalScreen(
          title: AppLocalizations.of(context).legalTermsTitle,
          sections: termsOfUseSections,
        ),
      ),
      // The feed + corner buttons. The only base screen; the four screens
      // below push on top of it as bottom-up sheets.
      GoRoute(path: '/today', builder: (context, state) => const VeggieShell()),
      GoRoute(
        path: '/habits',
        pageBuilder: (context, state) =>
            _sheetPage(state, const HabitsScreen()),
        routes: [
          GoRoute(
            path: 'edit/:id',
            builder: (context, state) =>
                HabitEditScreen(habitId: state.pathParameters['id']!),
          ),
          // One-segment detail route (/habits/5). No conflict with the
          // two-segment edit route (/habits/edit/5).
          GoRoute(
            path: ':id',
            builder: (context, state) => HabitDetailScreen(
              habitId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/explore',
        pageBuilder: (context, state) =>
            _sheetPage(state, const ExploreScreen()),
        routes: [
          GoRoute(
            path: 'category/:id',
            builder: (context, state) =>
                CategoryDetailScreen(categoryId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'favorites',
            builder: (context, state) => const FavoritesScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/journey',
        pageBuilder: (context, state) =>
            _sheetPage(state, const JourneyScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            _sheetPage(state, const SettingsScreen()),
        routes: [
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationSettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
