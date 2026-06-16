import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vegan_motivation_app/features/onboarding/steps/snapshot_step.dart';
import 'package:vegan_motivation_app/l10n/app_localizations.dart';

/// Regression guard for the "blank snapshot step" bug: `_ValueCard` once became
/// a Column with an `Expanded` child, which throws a RenderFlex layout assertion
/// inside the unbounded-height `ListView` and renders blank in a release build.
/// It has regressed at least once before (commit 2615c14). This test pumps the
/// step and fails if any card subtree throws during layout.
Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('SnapshotStep renders all four cards without a layout exception',
      (tester) async {
    await tester.pumpWidget(_host(SnapshotStep(
      whyRelationship: 'strong',
      dipsPerWeek: 3,
      commitmentLevel: 'extreme',
      // A real goal id so the strengths value card holds a long-ish string —
      // the worst case that previously overflowed / threw.
      firstGoal: 'social_strength',
      onContinue: () {},
    )));
    await tester.pumpAndSettle();

    // A RenderFlex assertion in a card subtree would surface here.
    expect(tester.takeException(), isNull);
    // Two bar cards + two value cards must all lay out (they'd be missing if a
    // card threw and its subtree failed to render).
    expect(find.byType(Card), findsNWidgets(4));
  });
}
