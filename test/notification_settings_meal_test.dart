import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vegan_motivation_app/core/prefs/prefs_repository.dart';
import 'package:vegan_motivation_app/core/theme/app_theme.dart';
import 'package:vegan_motivation_app/features/settings/notification_settings_screen.dart';
import 'package:vegan_motivation_app/l10n/app_localizations.dart';

Future<Widget> screen() async {
  // Notifications already on, so the mode selector is visible.
  SharedPreferences.setMockInitialValues({'notifEnabled': true});
  final prefs = PrefsRepository(await SharedPreferences.getInstance());
  return ProviderScope(
    overrides: [prefsProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      theme: VeggieTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const NotificationSettingsScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('switching to meals mode reveals the three meal cards',
      (tester) async {
    await tester.pumpWidget(await screen());
    await tester.pumpAndSettle();

    // Spread mode by default — no meal cards yet.
    expect(find.text('Breakfast'), findsNothing);
    expect(find.text('How many per day'), findsOneWidget);

    await tester.tap(find.text('Around meals'));
    await tester.pumpAndSettle();

    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Dinner'), findsOneWidget);
    expect(find.text('How many per day'), findsNothing);
  });

  testWidgets('toggling a meal off hides its controls', (tester) async {
    await tester.pumpWidget(await screen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Around meals'));
    await tester.pumpAndSettle();

    // All three meals on → three count selectors.
    expect(find.byType(SegmentedButton<int>), findsNWidgets(3));

    // Switches: [master, breakfast, lunch, dinner] — turn breakfast off.
    await tester.tap(find.byType(Switch).at(1));
    await tester.pumpAndSettle();

    expect(find.byType(SegmentedButton<int>), findsNWidgets(2));
  });
}
