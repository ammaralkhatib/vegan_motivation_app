import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/backgrounds/background_providers.dart';
import '../../core/db/database.dart';
import '../../core/prefs/prefs_repository.dart';
import '../../core/purchases/purchase_providers.dart';
import '../../core/purchases/restore_flow.dart';
import '../../data/content_importer.dart';
import '../../l10n/app_localizations.dart';
import '../paywall/paywall_data.dart';
import '../paywall/paywall_screen.dart';
import 'package:flutter/services.dart' show rootBundle;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _resetAllData(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final first = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsResetTitle),
        content: Text(l10n.settingsResetBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.settingsResetCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.settingsResetConfirm),
          ),
        ],
      ),
    );
    if (first != true || !context.mounted) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsResetConfirmTitle),
        content: Text(l10n.settingsResetConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.settingsResetKeep),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.settingsResetEraseAll),
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

  Future<void> _restorePurchases(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await performRestore(ref.read(purchaseServiceProvider));
    messenger.showSnackBar(SnackBar(content: Text(restoreMessage(result))));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          // Hidden once the user is premium — nothing left to sell / restore.
          if (!isPremium) ...[
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.workspace_premium_outlined),
                    title: Text(l10n.settingsPremiumTitle),
                    subtitle: Text(l10n.settingsPremiumSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        showPaywall(context, PaywallVariant.defaultOffer),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.restore),
                    title: Text(l10n.settingsRestorePurchases),
                    onTap: () => _restorePurchases(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          // Photo backgrounds: a live switch for premium; for free users a
          // dimmed, off switch whose row opens the 50%-off paywall.
          Card(
            child: isPremium
                ? SwitchListTile(
                    secondary: const Icon(Icons.image_outlined),
                    title: Text(l10n.settingsPhotoBackgrounds),
                    subtitle:
                        Text(l10n.settingsPhotoBackgroundsSubtitlePremium),
                    value: ref.watch(photoBackgroundsProvider),
                    onChanged: (v) =>
                        ref.read(photoBackgroundsProvider.notifier).set(v),
                  )
                : ListTile(
                    leading: const Icon(Icons.image_outlined),
                    title: Text(l10n.settingsPhotoBackgrounds),
                    subtitle: Text(l10n.settingsPhotoBackgroundsSubtitleFree),
                    trailing: const Switch(value: false, onChanged: null),
                    onTap: () =>
                        showPaywall(context, PaywallVariant.defaultOffer),
                  ),
          ),
          const SizedBox(height: 24),
          Text(l10n.settingsAppearance,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(l10n.settingsThemeLight),
                icon: const Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l10n.settingsThemeAuto),
                icon: const Icon(Icons.brightness_auto_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(l10n.settingsThemeDark),
                icon: const Icon(Icons.dark_mode_outlined),
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
                  title: Text(l10n.settingsDailyNotifications),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/notifications'),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.grid_view_outlined),
                  title: Text(l10n.settingsContentMix),
                  subtitle: Text(l10n.settingsContentMixSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/explore'),
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
                  title: Text(l10n.settingsAbout),
                  subtitle: Text(l10n.settingsAboutSubtitle),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Veggie',
                    applicationLegalese: l10n.settingsAboutLegalese,
                  ),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    l10n.settingsResetAllData,
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
