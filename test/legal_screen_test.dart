import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vegan_motivation_app/core/theme/app_theme.dart';
import 'package:vegan_motivation_app/features/legal/legal_content.dart';
import 'package:vegan_motivation_app/features/legal/legal_screen.dart';
import 'package:vegan_motivation_app/l10n/app_localizations.dart';

/// The privacy LegalScreen, with its title resolved from localizations.
class _PrivacyScreen extends StatelessWidget {
  const _PrivacyScreen();

  @override
  Widget build(BuildContext context) => LegalScreen(
        title: AppLocalizations.of(context).legalPrivacyTitle,
        sections: privacyPolicySections,
      );
}

/// The terms LegalScreen, with its title resolved from localizations.
class _TermsScreen extends StatelessWidget {
  const _TermsScreen();

  @override
  Widget build(BuildContext context) => LegalScreen(
        title: AppLocalizations.of(context).legalTermsTitle,
        sections: termsOfUseSections,
      );
}

Widget host(Widget child) => MaterialApp(
      theme: VeggieTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  testWidgets('privacy LegalScreen shows its title and last-updated stamp',
      (tester) async {
    await tester.pumpWidget(host(const _PrivacyScreen()));

    expect(find.byType(LegalScreen), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget); // app bar title
    expect(find.text(legalLastUpdated), findsOneWidget);
  });

  testWidgets('terms LegalScreen shows its title', (tester) async {
    await tester.pumpWidget(host(const _TermsScreen()));

    expect(find.byType(LegalScreen), findsOneWidget);
    expect(find.text('Terms of Use'), findsOneWidget); // app bar title
  });

  testWidgets('LegalScreen has a working back button', (tester) async {
    await tester.pumpWidget(host(Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const _TermsScreen()),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    )));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(LegalScreen), findsOneWidget);

    // Back button returns to the launcher.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });
}
