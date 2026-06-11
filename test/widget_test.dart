import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vegan_motivation_app/app/app.dart';
import 'package:vegan_motivation_app/core/prefs/prefs_repository.dart';

void main() {
  testWidgets('app shell renders with four tabs', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PrefsRepository(await SharedPreferences.getInstance());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [prefsProvider.overrideWithValue(prefs)],
        child: const VeggieApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Habits'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Journey'), findsOneWidget);
  });
}
