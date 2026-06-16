import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/notification_prefs.dart';

/// Soft wall shown only when the user denies the OS notification permission on
/// the onboarding notifications step. It explains the value of the daily nudges
/// but NEVER traps the user — "continue without notifications" always escapes.
/// Pushed with `Navigator.push` and pops itself; the caller advances the flow
/// once it returns.
class NotificationsEducationScreen extends ConsumerWidget {
  const NotificationsEducationScreen({super.key});

  Future<void> _turnOn(BuildContext context, WidgetRef ref) async {
    final granted = await NotificationService.instance.requestPermission();
    if (!context.mounted) return;
    if (granted) {
      await ref.read(notifSettingsProvider.notifier).setEnabled(true);
      if (context.mounted) Navigator.of(context).pop();
      return;
    }
    // Still denied → best-effort open the OS settings so the user can flip it;
    // the screen stays open so they can come back and continue either way.
    final messenger = ScaffoldMessenger.of(context);
    final hint = AppLocalizations.of(context).onboardingNotifEduSettingsHint;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS exposes an app-settings deep link.
      try {
        if (await launchUrl(Uri.parse('app-settings:'))) return;
      } catch (_) {
        // fall through to the hint
      }
    }
    // Android (and any failure): no reliable settings deep link without adding
    // a package, so guide the user to system settings instead.
    messenger.showSnackBar(SnackBar(content: Text(hint)));
  }

  Future<void> _continueWithout(BuildContext context, WidgetRef ref) async {
    await ref.read(notifSettingsProvider.notifier).setEnabled(false);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_active_outlined,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l.onboardingNotifEduTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l.onboardingNotifEduBody,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              FilledButton(
                onPressed: () => _turnOn(context, ref),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
                child: Text(l.onboardingNotifEduTurnOn),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _continueWithout(context, ref),
                child: Text(l.onboardingNotifEduContinue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
