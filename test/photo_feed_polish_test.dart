import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vegan_motivation_app/core/prefs/prefs_repository.dart';
import 'package:vegan_motivation_app/core/purchases/purchase_providers.dart';
import 'package:vegan_motivation_app/core/theme/app_theme.dart';
import 'package:vegan_motivation_app/features/quotes/quote_card.dart';
import 'package:vegan_motivation_app/features/settings/settings_screen.dart';
import 'package:vegan_motivation_app/l10n/app_localizations.dart';

import 'support/fake_purchase_service.dart';

void main() {
  group('kenBurnsVariant', () {
    test('is deterministic and cycles every 8 ids', () {
      for (var id = 0; id < 8; id++) {
        expect(kenBurnsVariant(id), kenBurnsVariant(id)); // stable
        expect(kenBurnsVariant(id), kenBurnsVariant(id + 8)); // cycles by 8
      }
    });

    test('covers 8 distinct moves (zoom × 4 corners)', () {
      final moves = {for (var id = 0; id < 8; id++) kenBurnsVariant(id)};
      expect(moves.length, 8);
      // First four zoom in, last four zoom out.
      expect(kenBurnsVariant(0).zoomIn, isTrue);
      expect(kenBurnsVariant(4).zoomIn, isFalse);
    });
  });

  testWidgets('free user: Photo backgrounds row is a disabled off switch that '
      'opens the paywall', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PrefsRepository(await SharedPreferences.getInstance());

    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (_, _) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/paywall/:variant',
          builder: (_, _) =>
              const Scaffold(body: Text('PAYWALL OPENED')),
        ),
      ],
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        purchaseServiceProvider
            .overrideWithValue(FakePurchaseService(initialPremium: false)),
      ],
      child: MaterialApp.router(
        theme: VeggieTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();

    // The row is visible, and its switch is off + disabled (onChanged null).
    expect(find.text('Photo backgrounds'), findsOneWidget);
    final sw = tester.widget<Switch>(find.byType(Switch));
    expect(sw.value, isFalse);
    expect(sw.onChanged, isNull);

    // Tapping the row opens the default paywall.
    await tester.tap(find.text('Photo backgrounds'));
    await tester.pumpAndSettle();
    expect(find.text('PAYWALL OPENED'), findsOneWidget);
  });
}
