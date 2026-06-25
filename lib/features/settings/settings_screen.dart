import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/backgrounds/background_providers.dart';
import '../../core/db/database.dart';
import '../../core/locale/locale_provider.dart';
import '../../core/notifications/notification_coordinator.dart';
import '../../core/prefs/prefs_repository.dart';
import '../../core/purchases/premium_gate.dart';
import '../../core/purchases/purchase_providers.dart';
import '../../core/purchases/purchase_service.dart';
import '../../core/purchases/restore_flow.dart';
import '../../core/widgetkit/home_widget_service.dart';
import '../../data/content_importer.dart';
import '../../l10n/app_localizations.dart';
import '../paywall/paywall_data.dart';
import '../paywall/paywall_presenter.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Endonyms — a language's own name for itself. Kept literal and **never**
/// translated (a French speaker scans for "Français", not "French"), so these
/// are intentionally hardcoded here rather than routed through ARB. null in the
/// picker means "follow the device language" and uses a localized label.
const _languageEndonyms = <String, String>{
  'en': 'English',
  'de': 'Deutsch',
  'fr': 'Français',
  'es': 'Español',
};

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
    final jsonString = await rootBundle.loadString(
      'assets/content/quotes_v1.json',
    );
    final version = await ContentImporter(
      db,
    ).import(jsonString: jsonString, lastImportedVersion: 0);
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

  /// The row subtitle: the current language, localized "System default" when
  /// following the device, else the literal endonym.
  String _languageLabel(AppLocalizations l10n, String? override) =>
      override == null
      ? l10n.settingsLanguageSystemDefault
      : (_languageEndonyms[override] ?? override);

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final current = ref.read(languageOverrideProvider);
    // (code, label) pairs; a null code is "System default".
    final options = <(String?, String)>[
      (null, l10n.settingsLanguageSystemDefault),
      for (final e in _languageEndonyms.entries) (e.key, e.value),
    ];

    // Records distinguish a real pick (any code, including null) from a dismiss
    // (sheet returns null), since "System default" is itself a null code.
    final picked = await showModalBottomSheet<({String? code})>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.settingsLanguage,
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
              ),
              for (final (code, label) in options)
                ListTile(
                  title: Text(label),
                  trailing: code == current ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.pop(sheetContext, (code: code)),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (picked == null || picked.code == current) return;
    await ref.read(languageOverrideProvider.notifier).set(picked.code);

    // Flip the background paths promptly (the UI + quote text flip on rebuild
    // via the appLocaleProvider). Reuse the existing reschedule + widget push.
    await ref.read(notificationCoordinatorProvider).reschedule(force: true);
    await HomeWidgetService.pushQueue(
      ref.read(databaseProvider),
      unlockedCategoryIds: ref.read(unlockedCategoryIdsProvider),
      languageOverride: picked.code,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final languageOverride = ref.watch(languageOverrideProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/today'),
        ),
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          // Free users get the upsell + restore card; premium users get the
          // subscription card in its place.
          if (!isPremium) ...[
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.workspace_premium_outlined),
                    title: Text(l10n.settingsPremiumTitle),
                    subtitle: Text(l10n.settingsPremiumSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => ref
                        .read(paywallPresenterProvider)
                        .present(PaywallVariant.defaultOffer),
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
          ] else ...[
            const _SubscriptionCard(),
            const SizedBox(height: 24),
          ],
          // Photo backgrounds: a live switch for premium; for free users a
          // dimmed, off switch whose row opens the 50%-off paywall.
          Card(
            child: isPremium
                ? SwitchListTile(
                    secondary: const Icon(Icons.image_outlined),
                    title: Text(l10n.settingsPhotoBackgrounds),
                    subtitle: Text(
                      l10n.settingsPhotoBackgroundsSubtitlePremium,
                    ),
                    value: ref.watch(photoBackgroundsProvider),
                    onChanged: (v) =>
                        ref.read(photoBackgroundsProvider.notifier).set(v),
                  )
                : ListTile(
                    leading: const Icon(Icons.image_outlined),
                    title: Text(l10n.settingsPhotoBackgrounds),
                    subtitle: Text(l10n.settingsPhotoBackgroundsSubtitleFree),
                    trailing: const Switch(value: false, onChanged: null),
                    onTap: () => ref
                        .read(paywallPresenterProvider)
                        .present(PaywallVariant.defaultOffer),
                  ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.settingsAppearance,
            style: Theme.of(context).textTheme.titleMedium,
          ),
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
            child: ListTile(
              leading: const Icon(Icons.language_outlined),
              title: Text(l10n.settingsLanguage),
              subtitle: Text(_languageLabel(l10n, languageOverride)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickLanguage(context, ref),
            ),
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
                    applicationName: 'Stay Vegan',
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
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

/// Shown only for premium users: subscription status (Active + renewal/expiry
/// date when available) and a button that opens the store's subscription page.
/// Degrades to just "Active" when details can't be loaded (offline / no SDK).
class _SubscriptionCard extends ConsumerWidget {
  const _SubscriptionCard();

  /// Status line, derived from the loaded details. Anything other than a real
  /// expiry date (loading, error, null, no expiry) shows plain "Active".
  String _statusLine(
    AppLocalizations l10n,
    AsyncValue<SubscriptionDetails?> async,
  ) {
    final details = async.valueOrNull;
    final expiry = details?.expirationDate;
    if (details != null && expiry != null) {
      final formatted = DateFormat.yMMMMd(l10n.localeName).format(expiry);
      return details.willRenew
          ? l10n.settingsSubscriptionRenewsOn(formatted)
          : l10n.settingsSubscriptionExpiresOn(formatted);
    }
    return l10n.settingsSubscriptionStatusActive;
  }

  /// The store's subscription page, by platform.
  String _defaultStoreUrl() => switch (defaultTargetPlatform) {
    TargetPlatform.android =>
      'https://play.google.com/store/account/subscriptions',
    _ => 'https://apps.apple.com/account/subscriptions', // iOS + macOS
  };

  Future<void> _manageSubscription(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final details = ref.read(subscriptionDetailsProvider).valueOrNull;
    final uri = Uri.parse(details?.managementUrl ?? _defaultStoreUrl());
    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!launched) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsManageSubscriptionError)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final details = ref.watch(subscriptionDetailsProvider);

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: Text(l10n.settingsSubscriptionTitle),
            subtitle: Text(_statusLine(l10n, details)),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: Text(l10n.settingsManageSubscription),
            onTap: () => _manageSubscription(context, ref),
          ),
        ],
      ),
    );
  }
}
