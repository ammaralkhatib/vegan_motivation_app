import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vegan_motivation_app/core/db/database.dart';
import 'package:vegan_motivation_app/core/purchases/premium_gate.dart';
import 'package:vegan_motivation_app/core/purchases/purchase_providers.dart';
import 'package:vegan_motivation_app/core/theme/app_theme.dart';
import 'package:vegan_motivation_app/l10n/app_localizations.dart';
import 'package:vegan_motivation_app/data/content_importer.dart';
import 'package:vegan_motivation_app/features/explore/explore_screen.dart';
import 'package:vegan_motivation_app/features/paywall/paywall_data.dart';
import 'package:vegan_motivation_app/features/paywall/paywall_screen.dart';

import 'helpers.dart';
import 'support/fake_purchase_service.dart';
import 'support/paywall_fixtures.dart';

/// Two free categories + one premium one, each with a quote.
Future<AppDatabase> seededDb() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await ContentImporter(db).import(
    jsonString: json.encode({
      'version': 1,
      'categories': [
        {'id': 'why_vegan', 'name': 'Why Vegan', 'emoji': '🌍', 'sortOrder': 0},
        {'id': 'facts', 'name': 'Facts', 'emoji': '📊', 'sortOrder': 1},
        {'id': 'quick_tips', 'name': 'Quick Tips', 'emoji': '💡', 'sortOrder': 2},
      ],
      'quotes': [
        {'id': 1, 'category': 'why_vegan', 'text': 'Free why-vegan quote'},
        {'id': 2, 'category': 'facts', 'text': 'Free facts quote'},
        {'id': 3, 'category': 'quick_tips', 'text': 'Premium tip quote'},
      ],
    }),
    lastImportedVersion: 0,
  );
  return db;
}

Widget exploreApp(AppDatabase db, {required bool premium}) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      purchaseServiceProvider
          .overrideWithValue(FakePurchaseService(initialPremium: premium)),
    ],
    child: MaterialApp(
      theme: VeggieTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ExploreScreen(),
    ),
  );
}

void main() {
  group('unlockedCategoryIdsProvider', () {
    test('free user gets only the two free categories', () {
      final container = ProviderContainer(overrides: [
        purchaseServiceProvider
            .overrideWithValue(FakePurchaseService(initialPremium: false)),
      ]);
      addTearDown(container.dispose);

      expect(container.read(unlockedCategoryIdsProvider), freeCategoryIds);
      expect(container.read(unlockedCategoryIdsProvider).length, 2);
    });

    test('premium user gets all six categories', () {
      final container = ProviderContainer(overrides: [
        purchaseServiceProvider
            .overrideWithValue(FakePurchaseService(initialPremium: true)),
      ]);
      addTearDown(container.dispose);

      expect(container.read(unlockedCategoryIdsProvider), allCategoryIds);
      expect(container.read(unlockedCategoryIdsProvider).length, 6);
    });

    test('flipping premium at runtime expands the unlocked set live', () async {
      final fake = FakePurchaseService(initialPremium: false);
      final container = ProviderContainer(overrides: [
        purchaseServiceProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);
      container.listen(unlockedCategoryIdsProvider, (_, _) {});

      expect(container.read(unlockedCategoryIdsProvider).length, 2);

      fake.emitPremium(true);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(unlockedCategoryIdsProvider), allCategoryIds);
    });
  });

  group('feed mix query gating', () {
    test('free user: mix excludes premium categories', () async {
      final db = await seededDb();
      addTearDown(db.close);

      final quotes =
          await db.quoteDao.getQuotesInMix(unlockedCategoryIds: freeCategoryIds);
      final cats = quotes.map((q) => q.categoryId).toSet();

      expect(cats, {'why_vegan', 'facts'});
      expect(cats.contains('quick_tips'), isFalse);
    });

    test('premium user: mix includes everything', () async {
      final db = await seededDb();
      addTearDown(db.close);

      final quotes =
          await db.quoteDao.getQuotesInMix(unlockedCategoryIds: allCategoryIds);
      expect(quotes.map((q) => q.categoryId).toSet(),
          {'why_vegan', 'facts', 'quick_tips'});
    });

    test('no filter argument leaves the mix unfiltered (back-compat)', () async {
      final db = await seededDb();
      addTearDown(db.close);

      final quotes = await db.quoteDao.getQuotesInMix();
      expect(quotes.length, 3);
    });
  });

  group('Explore screen', () {
    testWidgets('free user: premium category shows a lock and opens the paywall',
        (tester) async {
      final db = await seededDb();
      addTearDown(db.close);

      final router = GoRouter(
        initialLocation: '/explore',
        routes: [
          GoRoute(
            path: '/explore',
            builder: (context, state) => const ExploreScreen(),
          ),
          GoRoute(
            path: '/explore/category/:id',
            builder: (context, state) =>
                const Scaffold(body: Text('CATEGORY DETAIL')),
          ),
          GoRoute(
            path: '/paywall/:variant',
            builder: (context, state) => PaywallScreen(
              variant: PaywallVariant.fromName(state.pathParameters['variant']),
            ),
          ),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          purchaseServiceProvider.overrideWithValue(FakePurchaseService(
            initialPremium: false,
            offerings: {
              'default': testOffering(
                'default',
                package: testPackage(
                  product:
                      testStoreProduct(priceString: r'$24.99', price: 24.99),
                ),
              ),
              'onboarding': testOffering('onboarding'),
            },
          )),
        ],
        child: MaterialApp.router(
          theme: VeggieTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ));
      await tester.pumpAndSettle();

      // Two free categories show a Switch; the premium one shows a lock.
      expect(find.byType(Switch), findsNWidgets(2));
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);

      // Tapping the locked card opens the 50%-off paywall, not the detail.
      await tester.tap(find.text('Quick Tips'));
      await tester.pumpAndSettle();
      expect(find.text('CATEGORY DETAIL'), findsNothing);
      expect(find.text('50% OFF'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Unlock VeganKit Premium'),
        findsOneWidget,
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await unmountAndFlush(tester);
    });

    testWidgets('premium user: every category is unlocked (no locks)',
        (tester) async {
      final db = await seededDb();
      addTearDown(db.close);

      await tester.pumpWidget(exploreApp(db, premium: true));
      await tester.pumpAndSettle();

      expect(find.byType(Switch), findsNWidgets(3));
      expect(find.byIcon(Icons.lock_outline), findsNothing);

      await unmountAndFlush(tester);
    });
  });
}
