import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vegan_motivation_app/core/prefs/prefs_repository.dart';
import 'package:vegan_motivation_app/core/purchases/purchase_providers.dart';
import 'package:vegan_motivation_app/core/theme/app_theme.dart';
import 'package:vegan_motivation_app/features/onboarding/onboarding_flow.dart';
import 'package:vegan_motivation_app/features/onboarding/onboarding_widgets.dart';
import 'package:vegan_motivation_app/features/paywall/paywall_data.dart';
import 'package:vegan_motivation_app/features/paywall/paywall_screen.dart';

import 'helpers.dart';
import 'support/fake_purchase_service.dart';

GoRouter _router() => GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingFlow()),
        GoRoute(
          path: '/paywall/:variant',
          builder: (c, s) => PaywallScreen(
            variant: PaywallVariant.fromName(s.pathParameters['variant']),
          ),
        ),
        GoRoute(
          path: '/today',
          builder: (_, _) => const Scaffold(body: Text('TODAY HOME')),
        ),
      ],
    );

Future<(Widget, PrefsRepository)> harness() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = PrefsRepository(await SharedPreferences.getInstance());
  final widget = ProviderScope(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      // Premium → the end-of-onboarding funnel skips straight to /today.
      purchaseServiceProvider
          .overrideWithValue(FakePurchaseService(initialPremium: true)),
    ],
    child: MaterialApp.router(
      theme: VeggieTheme.light(),
      routerConfig: _router(),
    ),
  );
  return (widget, prefs);
}

extension _Drive on WidgetTester {
  Future<void> tapScreen() async {
    await tapAt(getCenter(find.byType(PageView)));
    await pumpAndSettle();
  }

  Future<void> tapContinue([String label = 'continue']) async {
    await tap(find.widgetWithText(FilledButton, label).hitTestable());
    await pumpAndSettle();
  }

  Future<void> pickFirstChoice() async {
    await tap(find.byType(ChoiceCard).hitTestable().first);
    await pumpAndSettle();
  }

  Future<void> pickChoiceAt(int index) async {
    await tap(find.byType(ChoiceCard).hitTestable().at(index));
    await pumpAndSettle();
  }
}

void main() {
  testWidgets('full flow (vegan) persists every answer and reaches today',
      (tester) async {
    disableCritterAnimations(tester);
    final (widget, prefs) = await harness();
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    await tester.tapScreen(); // S1 welcome
    await tester.tapScreen(); // S2 problem
    await tester.tapScreen(); // S3 solution

    await tester.enterText(find.byType(TextField).hitTestable(), 'Sam'); // S4
    await tester.pump();
    await tester.tapContinue();

    await tester.pickFirstChoice(); // S5 age
    await tester.tapContinue();

    await tester.pickChoiceAt(0); // S6 diet → "i'm vegan"
    await tester.tapContinue();

    await tester.tapScreen(); // S7 bombshell
    await tester.tapScreen(); // S8 bridge

    await tester.pickFirstChoice(); // S9 goals
    await tester.tapContinue();

    await tester.tapScreen(); // S10 goals reflection

    await tester.tapContinue(); // S11 dips (always enabled)

    await tester.pickFirstChoice(); // S12 obstacles
    await tester.tapContinue();

    await tester.pickFirstChoice(); // S13 why
    await tester.tapContinue();

    // S14 journey (shown for vegan) — pick "today".
    await tester.tap(find.text('today').hitTestable());
    await tester.pumpAndSettle();
    await tester.tapContinue();

    await tester.tapScreen(); // S15 final reflection

    await tester.pickFirstChoice(); // S16 motivation
    await tester.tapContinue();

    await tester.tapContinue(); // S17 chart

    await tester.tapContinue('start my journey'); // S18 notifications → finish

    expect(find.text('TODAY HOME'), findsOneWidget);

    expect(prefs.onboardingDone, isTrue);
    expect(prefs.userName, 'Sam');
    expect(prefs.ageRange, isNotNull);
    expect(prefs.dietStatus, 'vegan');
    expect(prefs.goalsPick, isNotEmpty);
    expect(prefs.motivationDipsPerWeek, 3);
    expect(prefs.obstacles, isNotEmpty);
    expect(prefs.whyRelationship, isNotNull);
    expect(prefs.motivationPick, isNotNull);
    // Vegan path recorded a start date, not curious mode.
    expect(prefs.veganSince, isNotNull);
    expect(prefs.curiousMode, isFalse);
  });

  testWidgets('journey-date step is skipped for "just curious"',
      (tester) async {
    disableCritterAnimations(tester);
    final (widget, _) = await harness();
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    await tester.tapScreen(); // S1
    await tester.tapScreen(); // S2
    await tester.tapScreen(); // S3

    await tester.enterText(find.byType(TextField).hitTestable(), 'Sam'); // S4
    await tester.pump();
    await tester.tapContinue();

    await tester.pickFirstChoice(); // S5 age
    await tester.tapContinue();

    await tester.pickChoiceAt(3); // S6 diet → "just curious"
    await tester.tapContinue();

    await tester.tapScreen(); // S7 bombshell (negative framing)
    await tester.tapScreen(); // S8 bridge

    await tester.pickFirstChoice(); // S9 goals
    await tester.tapContinue();

    await tester.tapScreen(); // S10 goals reflection

    await tester.tapContinue(); // S11 dips

    await tester.pickFirstChoice(); // S12 obstacles
    await tester.tapContinue();

    await tester.pickFirstChoice(); // S13 why
    await tester.tapContinue();

    // Next is S15, not the journey-date step.
    expect(find.text('when did your journey start?'), findsNothing);
    expect(
      find.textContaining('veggie was made for exactly this moment'),
      findsOneWidget,
    );
  });
}
