import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../core/prefs/prefs_repository.dart';
import '../../core/purchases/purchase_providers.dart';
import '../../data/content_importer.dart';
import '../paywall/paywall_data.dart';
import '../paywall/paywall_screen.dart';
import 'package:flutter/services.dart' show rootBundle;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _resetAllData(BuildContext context, WidgetRef ref) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset everything?'),
        content: const Text(
          'Favorites, habits, streaks, and settings will all be erased. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (first != true || !context.mounted) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Absolutely sure?'),
        content: const Text('Last chance — everything will be gone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep my data'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, erase it all'),
          ),
        ],
      ),
    );
    if (second != true || !context.mounted) return;

    final db = ref.read(databaseProvider);
    final prefs = ref.read(prefsProvider);
    await db.transaction(() async {
      await db.delete(db.habitCompletions).go();
      await db.delete(db.habits).go();
      await db.delete(db.quotes).go();
      await db.delete(db.categories).go();
    });
    await prefs.clear();
    final jsonString =
        await rootBundle.loadString('assets/content/quotes_v1.json');
    final version = await ContentImporter(db)
        .import(jsonString: jsonString, lastImportedVersion: 0);
    if (version != null) await prefs.setContentVersion(version);

    // Rebuild all prefs-derived state, then back to onboarding.
    ref.invalidate(themeModeProvider);
    if (context.mounted) context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          // Hidden once the user is premium — nothing left to sell.
          if (!isPremium) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: const Text('Veggie Premium'),
                subtitle:
                    const Text('Unlock all categories & the full library'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    showPaywall(context, PaywallVariant.defaultOffer),
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('Auto'),
                icon: Icon(Icons.brightness_auto_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (selection) =>
                ref.read(themeModeProvider.notifier).set(selection.first),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Daily notifications'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/journey/settings/notifications'),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.grid_view_outlined),
                  title: const Text('Content mix'),
                  subtitle: const Text('Choose which categories you see'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/explore'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About Veggie'),
                  subtitle: const Text('Open-source licenses & font credits'),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Veggie',
                    applicationLegalese:
                        'Daily vegan motivation.\nFonts: Fraunces & Inter (SIL OFL 1.1).',
                  ),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Reset all data',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  onTap: () => _resetAllData(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
