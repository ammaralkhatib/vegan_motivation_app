import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vegan_motivation_app/core/backgrounds/background_manifest.dart';
import 'package:vegan_motivation_app/core/backgrounds/background_providers.dart';
import 'package:vegan_motivation_app/core/db/database.dart';
import 'package:vegan_motivation_app/core/prefs/prefs_repository.dart';
import 'package:vegan_motivation_app/core/purchases/purchase_providers.dart';
import 'package:vegan_motivation_app/core/theme/app_theme.dart';
import 'package:vegan_motivation_app/data/content_importer.dart';
import 'package:vegan_motivation_app/features/onboarding/onboarding_flow.dart';
import 'package:vegan_motivation_app/features/onboarding/onboarding_widgets.dart';
import 'package:vegan_motivation_app/features/onboarding/review_prompter.dart';
import 'package:vegan_motivation_app/features/paywall/paywall_data.dart';
import 'package:vegan_motivation_app/features/paywall/paywall_screen.dart';
import 'package:vegan_motivation_app/l10n/app_localizations.dart';

import 'helpers.dart';
import 'support/fake_purchase_service.dart';

class FakeReviewPrompter implements ReviewPrompter {
  int calls = 0;
  @override
  Future<void> requestReview() async => calls++;
}

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

typedef Harness = ({
  Widget widget,
  PrefsRepository prefs,
  FakeReviewPrompter reviewer,
});

Future<Harness> harness() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = PrefsRepository(await SharedPreferences.getInstance());

  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await ContentImporter(db).import(
    jsonString: json.encode({
      'version': 1,
      'categories': [
        {'id': 'why_vegan', 'name': 'Why Vegan', 'emoji': '🌍', 'sortOrder': 0},
      ],
      'quotes': [
        {'id': 1, 'category': 'why_vegan', 'text': 'A kinder plate'},
      ],
    }),
    lastImportedVersion: 0,
  );
  addTearDown(db.close);

  final reviewer = FakeReviewPrompter();
  final widget = ProviderScope(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(db),
      // Premium → the end-of-onboarding funnel skips straight to /today.
      purchaseServiceProvider
          .overrideWithValue(FakePurchaseService(initialPremium: true)),
      reviewPrompterProvider.overrideWithValue(reviewer),
      // Keep the spark card on its gradient — deterministic, no asset loads.
      backgroundManifestValueProvider
          .overrideWithValue(BackgroundManifest.empty),
    ],
    child: MaterialApp.router(
      theme: VeggieTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router(),
    ),
  );
  return (widget: widget, prefs: prefs, reviewer: reviewer);
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

  /// Drives S1–S13 (the shared front of the flow) for the given diet card.
  Future<void> driveToWhyStep({required int dietIndex}) async {
    await tapScreen(); // S1 welcome
    await tapScreen(); // S2 problem
    await tapScreen(); // S3 solution

    await enterText(find.byType(TextField).hitTestable(), 'Sam'); // S4 name
    await pump();
    await tapContinue();

    await pickFirstChoice(); // S5 age
    await tapContinue();

    await pickChoiceAt(dietIndex); // S6 diet
    await tapContinue();

    await tapScreen(); // S7 bombshell
    await tapScreen(); // S8 bridge

    await pickFirstChoice(); // S9 goals
    await tapContinue();

    await tapScreen(); // S10 goals reflection

    await tapContinue(); // S11 dips

    await pickFirstChoice(); // S12 obstacles
    await tapContinue();

    await pickFirstChoice(); // S13 why
    await tapContinue();
  }

  /// From the streak step (S19) through the conclusion to `_finish`. Selects
  /// the first commitment option ("extreme").
  Future<void> driveConclusionToFinish() async {
    await tapContinue(); // S19 streak → S21 loading (auto) → S22 plan
    await tapContinue('begin my journey'); // S22 → S23 commitment
    await pickFirstChoice(); // commitment → "extreme"
    await tapContinue(); // S23 → S24 response
    await tapContinue('done ✓'); // S24 → S25 snapshot
    await tapContinue(); // S25 → S26 notifications
    // S26: "allow & save" → permission is denied in tests (the plugin isn't
    // initialized), so the education soft-wall appears; escape it to continue.
    await tapContinue('allow & save');
    await tap(find.text('continue without notifications'));
    await pumpAndSettle();
    await tapContinue('join VeganKit 🌱'); // S27 → finish
  }
}

void main() {
  testWidgets(
      'full flow (vegan) reaches today, fires the review once, persists answers',
      (tester) async {
    disableCritterAnimations(tester);
    final h = await harness();
    await tester.pumpWidget(h.widget);
    await tester.pumpAndSettle();

    await tester.driveToWhyStep(dietIndex: 0); // diet → "i'm vegan"

    // S14 journey (shown for vegan) — pick "today".
    await tester.tap(find.text('today').hitTestable());
    await tester.pumpAndSettle();
    await tester.tapContinue();

    await tester.tapScreen(); // S15 final reflection

    await tester.pickFirstChoice(); // S16 motivation → animals
    await tester.tapContinue();

    await tester.tapContinue(); // S17 chart → S18 first spark

    // S18 first spark shows a real quote from the why_vegan category. Let the
    // DB-backed providers resolve before asserting.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.text('A kinder plate'), findsOneWidget);
    await tester.tapContinue(); // S18 → S19 streak

    // The review fires ~1.2 s after the streak lands.
    expect(h.reviewer.calls, 0);
    await tester.pump(const Duration(milliseconds: 1300));
    expect(h.reviewer.calls, 1);
    expect(h.prefs.reviewPromptShown, isTrue);

    await tester.driveConclusionToFinish();

    expect(find.text('TODAY HOME'), findsOneWidget);

    expect(h.prefs.onboardingDone, isTrue);
    expect(h.prefs.userName, 'Sam');
    expect(h.prefs.dietStatus, 'vegan');
    expect(h.prefs.goalsPick, isNotEmpty);
    expect(h.prefs.motivationPick, isNotNull);
    expect(h.prefs.veganSince, isNotNull);
    expect(h.prefs.commitmentLevel, 'extreme');

    await unmountAndFlush(tester);
  });

  testWidgets('the review prompt never fires twice (flag already set)',
      (tester) async {
    final h = await harness();
    await h.prefs.setReviewPromptShown(true); // already shown on a prior run
    disableCritterAnimations(tester);
    await tester.pumpWidget(h.widget);
    await tester.pumpAndSettle();

    await tester.driveToWhyStep(dietIndex: 3); // "just curious" → no S14

    await tester.tapScreen(); // S15 final reflection
    await tester.pickFirstChoice(); // S16 motivation
    await tester.tapContinue();
    await tester.tapContinue(); // S17 chart → S18 spark
    await tester.tapContinue(); // S18 → S19 streak

    await tester.pump(const Duration(milliseconds: 1300));
    expect(h.reviewer.calls, 0); // guarded by the persisted flag

    await tester.driveConclusionToFinish();
    expect(find.text('TODAY HOME'), findsOneWidget);

    await unmountAndFlush(tester);
  });

  testWidgets('journey-date step is skipped for "just curious"',
      (tester) async {
    disableCritterAnimations(tester);
    final h = await harness();
    await tester.pumpWidget(h.widget);
    await tester.pumpAndSettle();

    await tester.driveToWhyStep(dietIndex: 3); // "just curious"

    // Next is S15, not the journey-date step.
    expect(find.text('when did your journey start?'), findsNothing);
    expect(
      find.textContaining('VeganKit was made for exactly this moment'),
      findsOneWidget,
    );

    await unmountAndFlush(tester);
  });
}
