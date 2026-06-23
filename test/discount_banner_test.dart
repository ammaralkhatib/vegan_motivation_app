import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vegan_motivation_app/core/prefs/prefs_repository.dart';
import 'package:vegan_motivation_app/core/purchases/purchase_providers.dart';
import 'package:vegan_motivation_app/core/theme/app_theme.dart';
import 'package:vegan_motivation_app/features/paywall/discount_banner.dart';
import 'package:vegan_motivation_app/features/paywall/paywall_data.dart';
import 'package:vegan_motivation_app/features/paywall/paywall_screen.dart';
import 'package:vegan_motivation_app/features/streak/open_streak.dart';
import 'package:vegan_motivation_app/l10n/app_localizations.dart';

import 'support/fake_purchase_service.dart';

/// Streak result that keeps the streak banner hidden (so the discount banner
/// owns the top-center slot and is free to show).
const _noStreak = OpenStreakResult(
  count: 0,
  openedDays: <int>{},
  today: 0,
  showBanner: false,
  savedDays: <int>[],
);

/// Streak result where the streak banner IS showing — the discount banner must
/// yield to it (Req 4).
const _streakShowing = OpenStreakResult(
  count: 1,
  openedDays: <int>{0},
  today: 0,
  showBanner: true,
  savedDays: <int>[0],
);

Future<PrefsRepository> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return PrefsRepository(await SharedPreferences.getInstance());
}

Widget _app(
  PrefsRepository prefs,
  FakePurchaseService fake, {
  OpenStreakResult streak = _noStreak,
}) =>
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        purchaseServiceProvider.overrideWithValue(fake),
        appOpenStreakProvider.overrideWithValue(streak),
      ],
      child: MaterialApp(
        theme: VeggieTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: DiscountBanner()),
      ),
    );

void main() {
  testWidgets('shows for an eligible free user and persists the flag once',
      (tester) async {
    final prefs = await _prefs({'onboardingDone': true});
    final fake = FakePurchaseService(initialPremium: false);
    await tester.pumpWidget(_app(prefs, fake));
    await tester.pump(); // run the post-frame persist

    expect(find.text('See offer'), findsOneWidget);
    expect(prefs.discountOfferShown, isTrue);
  });

  testWidgets('hidden for premium users (flag untouched)', (tester) async {
    final prefs = await _prefs({'onboardingDone': true});
    final fake = FakePurchaseService(initialPremium: true);
    await tester.pumpWidget(_app(prefs, fake));
    await tester.pump();

    expect(find.text('See offer'), findsNothing);
    expect(prefs.discountOfferShown, isFalse);
  });

  testWidgets('hidden once the discount flag is already set', (tester) async {
    final prefs =
        await _prefs({'onboardingDone': true, 'discountOfferShown': true});
    final fake = FakePurchaseService(initialPremium: false);
    await tester.pumpWidget(_app(prefs, fake));
    await tester.pump();

    expect(find.text('See offer'), findsNothing);
  });

  testWidgets('hidden until onboarding is done (flag untouched)',
      (tester) async {
    final prefs = await _prefs({}); // onboardingDone == false
    final fake = FakePurchaseService(initialPremium: false);
    await tester.pumpWidget(_app(prefs, fake));
    await tester.pump();

    expect(find.text('See offer'), findsNothing);
    expect(prefs.discountOfferShown, isFalse);
  });

  testWidgets('yields while the streak banner is showing (flag untouched)',
      (tester) async {
    final prefs = await _prefs({'onboardingDone': true});
    final fake = FakePurchaseService(initialPremium: false);
    await tester.pumpWidget(_app(prefs, fake, streak: _streakShowing));
    await tester.pump();

    expect(find.text('See offer'), findsNothing);
    expect(prefs.discountOfferShown, isFalse);
  });

  testWidgets('dismiss hides the banner and leaves the flag set',
      (tester) async {
    final prefs = await _prefs({'onboardingDone': true});
    final fake = FakePurchaseService(initialPremium: false);
    await tester.pumpWidget(_app(prefs, fake));
    await tester.pump();

    expect(find.text('See offer'), findsOneWidget);
    await tester.tap(find.byTooltip('Dismiss offer'));
    await tester.pumpAndSettle();

    expect(find.text('See offer'), findsNothing);
    expect(prefs.discountOfferShown, isTrue);
  });

  testWidgets('tapping the CTA opens the discount paywall, then the banner is gone',
      (tester) async {
    final prefs = await _prefs({'onboardingDone': true});
    final fake = FakePurchaseService(initialPremium: false);

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (c, s) => const Scaffold(body: DiscountBanner()),
        ),
        GoRoute(
          path: '/paywall/:variant',
          builder: (c, s) => PaywallScreen(
            variant: PaywallVariant.fromName(s.pathParameters['variant']),
          ),
        ),
      ],
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        purchaseServiceProvider.overrideWithValue(fake),
        appOpenStreakProvider.overrideWithValue(_noStreak),
      ],
      child: MaterialApp.router(
        theme: VeggieTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pump();

    await tester.tap(find.text('See offer'));
    await tester.pumpAndSettle();

    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(prefs.discountOfferShown, isTrue);
  });
}
