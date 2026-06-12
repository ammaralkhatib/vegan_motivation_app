import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/prefs/prefs_repository.dart';
import '../journey/providers.dart';
import '../paywall/onboarding_paywall_funnel.dart';
import '../settings/notification_prefs.dart';
import 'onboarding_copy.dart';
import 'onboarding_widgets.dart';
import 'steps/bombshell_step.dart';
import 'steps/final_reflection_step.dart';
import 'steps/first_spark_step.dart';
import 'steps/motivation_chart.dart';
import 'steps/streak_step.dart';

/// Story-driven first-run flow: problem → solution → questions → personalized
/// impact → self-persuasion → chart → notifications → paywall funnel → /today.
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final _pageController = PageController();
  final _nameController = TextEditingController();

  String? _ageRange;
  String? _dietStatus;
  final Set<String> _goals = {};
  int _dips = 3;
  final Set<String> _obstacles = {};
  String? _whyRelationship;
  DateTime? _veganSince;
  String? _motivation;
  bool _wantsNotifications = true;
  double _perDay = 3;
  int _page = 0;

  static const _ageRanges = ['14–24', '25–34', '35–44', '45–54', '55+'];
  static const _dietOptions = [
    ('vegan', '🌱 i\'m vegan'),
    ('mostly', '🥦 mostly plant-based'),
    ('cutting_down', '🍃 cutting down'),
    ('curious', '👀 just curious'),
  ];
  static const _whyOptions = [
    ('ups_downs', '📈 it has its ups and downs'),
    ('fading', '🍂 fading a bit lately'),
    ('starting', '🌱 just starting or rebuilding'),
    ('strong', '💪 strong and steady'),
  ];
  static const _motivationOptions = [
    ('animals', '🐮  For the animals'),
    ('planet', '🌍  For the planet'),
    ('health', '💪  For my health'),
    ('curious', '✨  Just exploring'),
  ];

  bool get _showJourneyStep =>
      _dietStatus == 'vegan' || _dietStatus == 'mostly';

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _next() {
    final steps = _buildSteps(Theme.of(context));
    if (_page < steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _toggleMax3(Set<String> set, String id) {
    setState(() {
      if (set.contains(id)) {
        set.remove(id);
      } else if (set.length < 3) {
        set.add(id);
      }
    });
  }

  Future<void> _finish() async {
    final prefs = ref.read(prefsProvider);
    final journey = ref.read(journeyProvider.notifier);

    await journey.setUserName(_nameController.text.trim());
    await prefs.setAgeRange(_ageRange);
    await prefs.setDietStatus(_dietStatus);
    await prefs.setGoalsPick(_goals.toList());
    await prefs.setMotivationDipsPerWeek(_dips);
    await prefs.setObstacles(_obstacles.toList());
    await prefs.setWhyRelationship(_whyRelationship);
    if (_motivation != null) await prefs.setMotivationPick(_motivation!);

    if (_showJourneyStep && _veganSince != null) {
      await journey.setVeganSince(_veganSince!);
    } else if (!_showJourneyStep) {
      await journey.setCurious();
    }

    if (_wantsNotifications) {
      await NotificationService.instance.requestPermission();
    }
    final notif = ref.read(notifSettingsProvider.notifier);
    await notif.setEnabled(_wantsNotifications);
    await notif.setPerDay(_perDay.round());

    // Mark done BEFORE the paywall funnel — closing a paywall must never drop
    // the user back into onboarding, even after a crash.
    await prefs.setOnboardingDone(true);
    if (!mounted) return;
    await runOnboardingPaywallFunnel(context, ref);
    if (mounted) context.go('/today');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = _buildSteps(theme);
    final progress = steps.length <= 1 ? 0.0 : _page / (steps.length - 1);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar hidden on the very first step.
            SizedBox(
              height: 14,
              child: _page == 0
                  ? null
                  : OnboardingProgressBar(value: progress),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _page = page),
                children: steps,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step list ------------------------------------------------------------

  List<Widget> _buildSteps(ThemeData theme) {
    final steps = <Widget>[
      _welcome(theme), // S1
      _problem(theme), // S2
      _solution(theme), // S3
      _name(theme), // S4
      _age(theme), // S5
      _diet(theme), // S6
      BombshellStep(
        name: _nameController.text.trim(),
        dietStatus: _dietStatus,
        ageRange: _ageRange,
        onContinue: _next,
      ), // S7
      _bridge(theme), // S8
      _goalsStep(theme), // S9
      _goalsReflection(theme), // S10
      _dipsStep(theme), // S11
      _obstaclesStep(theme), // S12
      _whyStep(theme), // S13
      if (_showJourneyStep) _journeyStep(theme), // S14 (conditional)
      FinalReflectionStep(
        goals: _goals.toList(),
        obstacles: _obstacles.toList(),
        dipsPerWeek: _dips,
        onContinue: _next,
      ), // S15
      _motivationStep(theme), // S16
      _chartStep(theme), // S17
      FirstSparkStep(
        name: _nameController.text.trim(),
        motivationPick: _motivation,
        onContinue: _next,
      ), // S18 — first spark (a live quote)
    ];
    // S19 — day-1 streak + review prompt. Always second-to-last, so its index
    // is stable regardless of the conditional journey step; that lets the step
    // know exactly when it becomes visible.
    final streakIndex = steps.length;
    steps.add(StreakStep(active: _page == streakIndex, onContinue: _next));
    steps.add(_notificationsStep(theme)); // tail (temporary)
    return steps;
  }

  // --- Reusable bits --------------------------------------------------------

  Widget _eyebrow(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: theme.textTheme.labelLarge
              ?.copyWith(color: theme.colorScheme.primary),
        ),
      );

  /// Headline with one bolded, primary-colored word/phrase.
  Widget _boldHeadline(ThemeData theme, List<(String, bool)> parts) {
    return Text.rich(
      TextSpan(
        children: [
          for (final (text, isBold) in parts)
            TextSpan(
              text: text,
              style: isBold
                  ? TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    )
                  : null,
            ),
        ],
      ),
      textAlign: TextAlign.center,
      style: theme.textTheme.headlineMedium,
    );
  }

  Widget _body(ThemeData theme, String text) => Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyLarge
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );

  // --- Steps ----------------------------------------------------------------

  Widget _welcome(ThemeData theme) => TapStep(
        onContinue: _next,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text('Veggie', style: theme.textTheme.displayLarge),
            const SizedBox(height: 12),
            _body(theme, 'your daily dose of vegan motivation'),
          ],
        ),
      );

  Widget _problem(ThemeData theme) => TapStep(
        onContinue: _next,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _boldHeadline(theme, const [
              ('ever feel your ', false),
              ('motivation', true),
              (' fade, even when your reasons haven\'t?', false),
            ]),
            const SizedBox(height: 20),
            _body(
              theme,
              'you\'re not alone. cravings, social pressure, and busy days '
              'quietly pull people away from the path they chose.',
            ),
          ],
        ),
      );

  Widget _solution(ThemeData theme) => TapStep(
        onContinue: _next,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _boldHeadline(theme, const [
              ('veggie keeps your ', false),
              ('why', true),
              (' in front of you', false),
            ]),
            const SizedBox(height: 20),
            _body(
              theme,
              'it\'s simple — every day, a small spark of motivation, made '
              'for you.',
            ),
          ],
        ),
      );

  Widget _name(ThemeData theme) => InputStep(
        onContinue: _next,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _eyebrow(theme, 'first things first'),
            Text('what should we call you?',
                style: theme.textTheme.displaySmall),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'your name',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _next(),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      );

  Widget _age(ThemeData theme) => InputStep(
        onContinue: _next,
        enabled: _ageRange != null,
        child: _singleSelectList(
          theme,
          title: 'how old are you?',
          options: [for (final r in _ageRanges) (r, r)],
          selected: _ageRange,
          onPick: (id) => setState(() => _ageRange = id),
        ),
      );

  Widget _diet(ThemeData theme) => InputStep(
        onContinue: _next,
        enabled: _dietStatus != null,
        child: _singleSelectList(
          theme,
          title: 'where are you on the path right now?',
          options: _dietOptions,
          selected: _dietStatus,
          onPick: (id) => setState(() => _dietStatus = id),
        ),
      );

  Widget _bridge(ThemeData theme) => TapStep(
        onContinue: _next,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('it doesn\'t have to be this way',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            _boldHeadline(theme, const [
              ('do you have just ', false),
              ('2 minutes', true),
              (' a day?', false),
            ]),
            const SizedBox(height: 20),
            _boldHeadline(theme, const [
              ('let\'s build a plan for ', false),
              ('you', true),
            ]),
          ],
        ),
      );

  Widget _goalsStep(ThemeData theme) => InputStep(
        onContinue: _next,
        enabled: _goals.isNotEmpty,
        child: _multiSelectList(
          theme,
          title: 'what do you want from veggie?',
          subtitle: 'choose up to 3',
          options: goalOptions,
          selected: _goals,
        ),
      );

  Widget _goalsReflection(ThemeData theme) {
    final picked = _goals.toList();
    return TapStep(
      onContinue: _next,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final id in picked)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  goalReflections[id] ?? '',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(children: [
              TextSpan(
                text: 'you\'re in the right place',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          _body(
            theme,
            'every journey here starts with the same goals — veggie was built '
            'for exactly this.',
          ),
        ],
      ),
    );
  }

  Widget _dipsStep(ThemeData theme) => InputStep(
        onContinue: _next,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'be honest — how many days a week does your motivation dip?',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Text(
              '$_dips',
              style: theme.textTheme.displayLarge
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
            Text('${_dips == 1 ? 'day' : 'days'} a week',
                style: theme.textTheme.bodyMedium),
            Slider(
              value: _dips.toDouble(),
              min: 0,
              max: 7,
              divisions: 7,
              label: '$_dips',
              onChanged: (v) => setState(() => _dips = v.round()),
            ),
          ],
        ),
      );

  Widget _obstaclesStep(ThemeData theme) => InputStep(
        onContinue: _next,
        enabled: _obstacles.isNotEmpty,
        child: _multiSelectList(
          theme,
          title: 'what gets in the way most?',
          subtitle: 'choose up to 3',
          options: obstacleOptions,
          selected: _obstacles,
        ),
      );

  Widget _whyStep(ThemeData theme) => InputStep(
        onContinue: _next,
        enabled: _whyRelationship != null,
        child: _singleSelectList(
          theme,
          title: 'and how\'s your connection to your why right now?',
          options: _whyOptions,
          selected: _whyRelationship,
          onPick: (id) => setState(() => _whyRelationship = id),
        ),
      );

  Widget _journeyStep(ThemeData theme) => InputStep(
        onContinue: _next,
        enabled: _veganSince != null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('when did your journey start?',
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
                      ? 'pick a date'
                      : DateFormat('MMM d, y').format(_veganSince!),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _veganSince ?? DateTime.now(),
                    firstDate: DateTime(1970),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _veganSince = picked);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _veganSince = DateTime.now()),
                icon: const Icon(Icons.today),
                label: const Text('today'),
              ),
            ),
          ],
        ),
      );

  Widget _motivationStep(ThemeData theme) => InputStep(
        onContinue: _next,
        enabled: _motivation != null,
        child: ListView(
          children: [
            const SizedBox(height: 8),
            _eyebrow(theme, 'last one — to make the quotes feel right for you'),
            Text('what moves you most?', style: theme.textTheme.displaySmall),
            const SizedBox(height: 20),
            for (final (id, label) in _motivationOptions)
              ChoiceCard(
                label: label,
                selected: _motivation == id,
                onTap: () => setState(() => _motivation = id),
              ),
          ],
        ),
      );

  Widget _chartStep(ThemeData theme) => InputStep(
        onContinue: _next,
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Text(
              'your motivation, with and without a daily spark',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            const MotivationChart(),
            const SizedBox(height: 20),
            _body(
              theme,
              'small daily reminders beat willpower. that\'s the whole idea.',
            ),
          ],
        ),
      );

  Widget _notificationsStep(ThemeData theme) => InputStep(
        onContinue: _next,
        cta: 'start my journey',
        child: ListView(
          children: [
            const SizedBox(height: 12),
            Text('daily nudges?', style: theme.textTheme.displaySmall),
            const SizedBox(height: 8),
            _body(
              theme,
              'short bursts of motivation, delivered to your phone (and watch).',
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _wantsNotifications,
              onChanged: (v) => setState(() => _wantsNotifications = v),
              title: const Text('send me motivation'),
              contentPadding: EdgeInsets.zero,
            ),
            if (_wantsNotifications)
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
        ),
      );

  // --- Selection helpers ----------------------------------------------------

  Widget _singleSelectList(
    ThemeData theme, {
    required String title,
    required List<(String, String)> options,
    required String? selected,
    required void Function(String id) onPick,
  }) {
    return ListView(
      children: [
        const SizedBox(height: 8),
        Text(title, style: theme.textTheme.displaySmall),
        const SizedBox(height: 20),
        for (final (id, label) in options)
          ChoiceCard(
            label: label,
            selected: selected == id,
            onTap: () => onPick(id),
          ),
      ],
    );
  }

  Widget _multiSelectList(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required List<(String, String)> options,
    required Set<String> selected,
  }) {
    return ListView(
      children: [
        const SizedBox(height: 8),
        Text(title, style: theme.textTheme.displaySmall),
        const SizedBox(height: 4),
        Text(subtitle,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        for (final (id, label) in options)
          ChoiceCard(
            label: label,
            selected: selected.contains(id),
            onTap: () => _toggleMax3(selected, id),
          ),
      ],
    );
  }
}
