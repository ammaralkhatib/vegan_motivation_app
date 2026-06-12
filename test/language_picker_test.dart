import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vegan_motivation_app/core/db/database.dart';
import 'package:vegan_motivation_app/core/locale/locale_provider.dart';
import 'package:vegan_motivation_app/core/prefs/prefs_repository.dart';
import 'package:vegan_motivation_app/core/purchases/purchase_providers.dart';
import 'package:vegan_motivation_app/core/theme/app_theme.dart';
import 'package:vegan_motivation_app/features/settings/settings_screen.dart';
import 'package:vegan_motivation_app/l10n/app_localizations.dart';

import 'support/fake_purchase_service.dart';

/// Mirrors the real app: the language override drives `MaterialApp.locale`, so
/// changing the setting rebuilds the whole tree in the new language.
class _App extends ConsumerWidget {
  const _App();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      theme: VeggieTheme.light(),
      locale: ref.watch(appLocaleProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SettingsScreen(),
    );
  }
}

Future<PrefsRepository> _prefs([Map<String, Object> seed = const {}]) async {
  SharedPreferences.setMockInitialValues(seed);
  return PrefsRepository(await SharedPreferences.getInstance());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('language override pref round-trips (null clears it)', () async {
    final prefs = await _prefs();
    expect(prefs.languageOverride, isNull);
    await prefs.setLanguageOverride('de');
    expect(prefs.languageOverride, 'de');
    await prefs.setLanguageOverride(null);
    expect(prefs.languageOverride, isNull);
  });

  test('resolveLanguageCode prefers the override over the system locale', () {
    expect(resolveLanguageCode('de'), 'de');
    expect(resolveLanguageCode(null),
        ui.PlatformDispatcher.instance.locale.languageCode);
  });

  test('appLocaleProvider follows the override; null = system', () async {
    final prefs = await _prefs({'languageOverride': 'fr'});
    final container = ProviderContainer(
      overrides: [prefsProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    expect(container.read(appLocaleProvider), const Locale('fr'));
    await container.read(languageOverrideProvider.notifier).set(null);
    expect(container.read(appLocaleProvider), isNull);
  });

  testWidgets('picking Deutsch switches the visible UI text', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final prefs = await _prefs();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        prefsProvider.overrideWithValue(prefs),
        purchaseServiceProvider
            .overrideWithValue(FakePurchaseService(initialPremium: true)),
      ],
      child: const _App(),
    ));
    await tester.pumpAndSettle();

    // Starts in English (no override set).
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();

    // Whole app flipped to German, and the choice persisted.
    expect(find.text('Einstellungen'), findsWidgets);
    expect(prefs.languageOverride, 'de');
  });
}
