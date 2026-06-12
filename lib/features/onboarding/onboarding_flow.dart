import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/prefs/prefs_repository.dart';
import '../journey/providers.dart';
import '../paywall/onboarding_paywall_funnel.dart';
import '../settings/notification_prefs.dart';

/// Warm 5-step first-run flow. Every step is skippable.
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  String? _motivation;
  DateTime? _veganSince;
  bool _curious = false;
  bool _wantsNotifications = true;
  double _perDay = 3;
  ThemeMode _themeMode = ThemeMode.system;
  int _page = 0;

  static const _pageCount = 5;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = ref.read(prefsProvider);
    final journey = ref.read(journeyProvider.notifier);

    await journey.setUserName(_nameController.text.trim());
    if (_motivation != null) await prefs.setMotivationPick(_motivation!);
    if (_veganSince != null) {
      await journey.setVeganSince(_veganSince!);
    } else if (_curious) {
      await journey.setCurious();
    }
    if (_wantsNotifications) {
      await NotificationService.instance.requestPermission();
    }
    final notif = ref.read(notifSettingsProvider.notifier);
    await notif.setEnabled(_wantsNotifications);
    await notif.setPerDay(_perDay.round());
    await ref.read(themeModeProvider.notifier).set(_themeMode);
    // Mark onboarding done BEFORE the paywall funnel — closing a paywall must
    // never dump the user back into onboarding, even after a crash.
    await prefs.setOnboardingDone(true);
    if (!mounted) return;

    await runOnboardingPaywallFunnel(context, ref);

    if (mounted) context.go('/today');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
              child: Row(
                children: [
                  // Progress dots
                  for (var i = 0; i < _pageCount; i++)
                    Container(
                      width: i == _page ? 22 : 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: i <= _page
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  const Spacer(),
                  if (_page > 0 && _page < _pageCount - 1)
                    TextButton(onPressed: _next, child: const Text('Skip')),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  _welcomeStep(theme),
                  _nameStep(theme),
                  _motivationStep(theme),
                  _journeyStep(theme),
                  _notificationsAndThemeStep(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step({
    required Widget child,
    required String cta,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: child),
          FilledButton(
            onPressed: enabled ? _next : null,
            child: Text(cta),
          ),
        ],
      ),
    );
  }

  Widget _welcomeStep(ThemeData theme) {
    return _step(
      cta: "Let's grow 🌱",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.eco, size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text('Veggie', style: theme.textTheme.displayLarge),
          const SizedBox(height: 12),
          Text(
            'Daily motivation, gentle habits,\nand a clear view of the good you do.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _nameStep(ThemeData theme) {
    return _step(
      cta: 'Continue',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What should we call you?', style: theme.textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Totally optional — it just makes things warmer.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Your name',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _next(),
          ),
        ],
      ),
    );
  }

  Widget _motivationStep(ThemeData theme) {
    const options = [
      ('animals', '🐮  For the animals'),
      ('planet', '🌍  For the planet'),
      ('health', '💪  For my health'),
      ('curious', '✨  Just exploring'),
    ];
    return _step(
      cta: 'Continue',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("What's your why?", style: theme.textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            "We'll keep it close on the hard days.",
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          for (final (key, label) in options) ...[
            Card(
              color: _motivation == key
                  ? theme.colorScheme.primaryContainer
                  : null,
              child: ListTile(
                title: Text(label),
                onTap: () => setState(() => _motivation = key),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _journeyStep(ThemeData theme) {
    return _step(
      cta: 'Continue',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where are you on the path?',
              style: theme.textTheme.displaySmall),
          const SizedBox(height: 24),
          Card(
            color: _veganSince != null
                ? theme.colorScheme.primaryContainer
                : null,
            child: ListTile(
              leading: const Text('🌱', style: TextStyle(fontSize: 24)),
              title: Text(
                _veganSince == null
                    ? "I'm vegan — set my start date"
                    : 'Vegan since ${DateFormat('MMM d, y').format(_veganSince!)}',
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _veganSince ?? DateTime.now(),
                  firstDate: DateTime(1970),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    _veganSince = picked;
                    _curious = false;
                  });
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            color: _curious ? theme.colorScheme.primaryContainer : null,
            child: ListTile(
              leading: const Text('👀', style: TextStyle(fontSize: 24)),
              title: const Text('Just curious for now'),
              onTap: () => setState(() {
                _curious = true;
                _veganSince = null;
              }),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationsAndThemeStep(ThemeData theme) {
    return _step(
      cta: 'Start my journey',
      child: ListView(
        children: [
          const SizedBox(height: 12),
          Text('Daily nudges?', style: theme.textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Short bursts of motivation, delivered to your phone (and watch).',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _wantsNotifications,
            onChanged: (v) => setState(() => _wantsNotifications = v),
            title: const Text('Send me motivation'),
            contentPadding: EdgeInsets.zero,
          ),
          if (_wantsNotifications) ...[
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _perDay,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '${_perDay.round()}× per day',
                    onChanged: (v) => setState(() => _perDay = v),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text('${_perDay.round()}× / day',
                      style: theme.textTheme.labelMedium),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Text('Pick your mood', style: theme.textTheme.displaySmall),
          const SizedBox(height: 16),
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
            selected: {_themeMode},
            onSelectionChanged: (selection) =>
                setState(() => _themeMode = selection.first),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
