import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/prefs/prefs_repository.dart';
import '../../l10n/app_localizations.dart';
import '../journey/providers.dart';
import '../paywall/onboarding_paywall_funnel.dart';
import '../settings/notification_prefs.dart';
import 'onboarding_copy.dart';
import 'onboarding_widgets.dart';
import 'steps/bombshell_step.dart';
import 'steps/final_reflection_step.dart';
import 'steps/first_spark_step.dart';
import 'steps/loading_step.dart';
import 'steps/motivation_chart.dart';
import 'steps/notifications_education_screen.dart';
import 'steps/plan_summary_step.dart';
import 'steps/snapshot_step.dart';
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
  String? _commitment;
  // Notifications step: amount (per day) + the daily window, seeded from saved
  // prefs in initState so they match what the user already has.
  int _notifPerDay = 3;
  int _notifWindowStart = 9 * 60;
  int _notifWindowEnd = 22 * 60;
  int _page = 0;

  // Age ranges are numeric tokens, locale-independent — not localized.
  static const _ageRanges = ['14–24', '25–34', '35–44', '45–54', '55+'];
  static const _dietIds = ['vegan', 'mostly', 'cutting_down', 'curious'];
  static const _whyIds = ['ups_downs', 'fading', 'starting', 'strong'];
  static const _motivationIds = ['animals', 'planet', 'health', 'curious'];

  String _dietLabel(AppLocalizations l, String id) => switch (id) {
        'vegan' => l.onboardingDietVegan,
        'mostly' => l.onboardingDietMostly,
        'cutting_down' => l.onboardingDietCuttingDown,
        _ => l.onboardingDietCurious,
      };

  String _whyLabel(AppLocalizations l, String id) => switch (id) {
        'ups_downs' => l.onboardingWhyUpsDowns,
        'fading' => l.onboardingWhyFading,
        'starting' => l.onboardingWhyStarting,
        _ => l.onboardingWhyStrong,
      };

  String _motivationLabel(AppLocalizations l, String id) => switch (id) {
        'animals' => l.onboardingMotivationAnimals,
        'planet' => l.onboardingMotivationPlanet,
        'health' => l.onboardingMotivationHealth,
        _ => l.onboardingMotivationCurious,
      };

  bool get _showJourneyStep =>
      _dietStatus == 'vegan' || _dietStatus == 'mostly';

  @override
  void initState() {
    super.initState();
    // Seed the notifications step from saved prefs (defaults land near 09:00–22:00).
    final s = ref.read(notifSettingsProvider);
    _notifPerDay = s.perDay;
    _notifWindowStart = s.windowStartMin;
    _notifWindowEnd = s.windowEndMin;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _next() {
    // Drop keyboard focus so a text field (e.g. the name step) doesn't leave
    // the keyboard hanging over the next step. Central handler → covers all steps.
    FocusScope.of(context).unfocus();
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
    await prefs.setCommitmentLevel(_commitment);
    if (_motivation != null) await prefs.setMotivationPick(_motivation!);

    if (_showJourneyStep && _veganSince != null) {
      await journey.setVeganSince(_veganSince!);
    } else if (!_showJourneyStep) {
      await journey.setCurious();
    }

    // The notifications step (S26) already requested permission and saved
    // enabled / perDay / window, so _finish no longer touches them (avoids a
    // second permission prompt).

    // Mark done BEFORE the paywall funnel — closing a paywall must never drop
    // the user back into onboarding, even after a crash.
    await prefs.setOnboardingDone(true);
    if (!mounted) return;
    await runOnboardingPaywallFunnel(ref);
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
    // S19 — day-1 streak + review prompt. Needs to know when it's visible, so
    // it's added with an explicit index/active flag.
    final streakIndex = steps.length;
    steps.add(StreakStep(active: _page == streakIndex, onContinue: _next));
    // S21 — fake-loading transition, auto-advances when its bar fills.
    final loadingIndex = steps.length;
    steps.add(LoadingStep(active: _page == loadingIndex, onDone: _next));
    steps.add(PlanSummaryStep(
      name: _nameController.text.trim(),
      onContinue: _next,
    )); // S22
    steps.add(_commitmentStep(theme)); // S23
    steps.add(_commitmentResponse(theme)); // S24
    steps.add(SnapshotStep(
      whyRelationship: _whyRelationship,
      dipsPerWeek: _dips,
      commitmentLevel: _commitment,
      firstGoal: _goals.isEmpty ? null : _goals.first,
      onContinue: _next,
    )); // S25
    steps.add(_notificationsStep(theme)); // S26 (reframed)
    steps.add(_socialProofStep(theme)); // S27 → finish
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

  /// Headline that bolds the [emphasis] substring inside [full]. The full
  /// sentence lives in one ARB key so translators can reorder it; the emphasis
  /// word is its own key and is highlighted wherever it lands.
  Widget _boldHeadline(ThemeData theme, String full, String emphasis) {
    final boldStyle = TextStyle(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w700,
    );
    final i = full.indexOf(emphasis);
    final spans = <TextSpan>[];
    if (i < 0) {
      spans.add(TextSpan(text: full));
    } else {
      if (i > 0) spans.add(TextSpan(text: full.substring(0, i)));
      spans.add(TextSpan(text: emphasis, style: boldStyle));
      final rest = full.substring(i + emphasis.length);
      if (rest.isNotEmpty) spans.add(TextSpan(text: rest));
    }
    return Text.rich(
      TextSpan(children: spans),
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

  Widget _welcome(ThemeData theme) {
    final l = AppLocalizations.of(context);
    return TapStep(
      onContinue: _next,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.eco, size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          // Brand name — intentionally not localized.
          Text('VeganKit', style: theme.textTheme.displayLarge),
          const SizedBox(height: 12),
          _body(theme, l.onboardingWelcomeTagline),
        ],
      ),
    );
  }

  Widget _problem(ThemeData theme) {
    final l = AppLocalizations.of(context);
    return TapStep(
      onContinue: _next,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _boldHeadline(
              theme, l.onboardingProblemHeadline, l.onboardingProblemEmphasis),
          const SizedBox(height: 20),
          _body(theme, l.onboardingProblemBody),
        ],
      ),
    );
  }

  Widget _solution(ThemeData theme) {
    final l = AppLocalizations.of(context);
    return TapStep(
      onContinue: _next,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _boldHeadline(theme, l.onboardingSolutionHeadline,
              l.onboardingSolutionEmphasis),
          const SizedBox(height: 20),
          _body(theme, l.onboardingSolutionBody),
        ],
      ),
    );
  }

  Widget _name(ThemeData theme) {
    final l = AppLocalizations.of(context);
    return InputStep(
      onContinue: _next,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow(theme, l.onboardingNameEyebrow),
          Text(l.onboardingNameTitle, style: theme.textTheme.displaySmall),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: l.onboardingNameHint,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _next(),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _age(ThemeData theme) => InputStep(
        onContinue: _next,
        enabled: _ageRange != null,
        child: _singleSelectList(
          theme,
          title: AppLocalizations.of(context).onboardingAgeTitle,
          options: [for (final r in _ageRanges) (r, r)],
          selected: _ageRange,
          onPick: (id) => setState(() => _ageRange = id),
        ),
      );

  Widget _diet(ThemeData theme) {
    final l = AppLocalizations.of(context);
    return InputStep(
      onContinue: _next,
      enabled: _dietStatus != null,
      child: _singleSelectList(
        theme,
        title: l.onboardingDietTitle,
        options: [for (final id in _dietIds) (id, _dietLabel(l, id))],
        selected: _dietStatus,
        onPick: (id) => setState(() => _dietStatus = id),
      ),
    );
  }

  Widget _bridge(ThemeData theme) {
    final l = AppLocalizations.of(context);
    return TapStep(
      onContinue: _next,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l.onboardingBridgeIntro,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge),
          const SizedBox(height: 20),
          _boldHeadline(theme, l.onboardingBridgeHeadline1,
              l.onboardingBridgeHeadline1Emphasis),
          const SizedBox(height: 20),
          _boldHeadline(theme, l.onboardingBridgeHeadline2,
              l.onboardingBridgeHeadline2Emphasis),
        ],
      ),
    );
  }

  Widget _goalsStep(ThemeData theme) {
    final l = AppLocalizations.of(context);
    return InputStep(
      onContinue: _next,
      enabled: _goals.isNotEmpty,
      child: _multiSelectList(
        theme,
        title: l.onboardingGoalsTitle,
        subtitle: l.onboardingChooseUpTo3,
        options: [for (final id in goalIds) (id, goalLabel(l, id))],
        selected: _goals,
      ),
    );
  }

  Widget _goalsReflection(ThemeData theme) {
    final l = AppLocalizations.of(context);
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
                  goalReflection(l, id),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(children: [
              TextSpan(
                text: l.onboardingGoalsReflectionHeadline,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          _body(theme, l.onboardingGoalsReflectionBody),
        ],
      ),
    );
  }

  Widget _dipsStep(ThemeData theme) {
    final l = AppLocalizations.of(context);
    return InputStep(
      onContinue: _next,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l.onboardingDipsTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          Text(
            '$_dips',
            style: theme.textTheme.displayLarge
                ?.copyWith(color: theme.colorScheme.primary),
          ),
          Text(l.onboardingDipsUnit(_dips), style: theme.textTheme.bodyMedium),
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
  }

  Widget _obstaclesStep(ThemeData theme) {
    final l = AppLocalizations.of(context);
    return InputStep(
      onContinue: _next,
      enabled: _obstacles.isNotEmpty,
      child: _multiSelectList(
        theme,
        title: l.onboardingObstaclesTitle,
        subtitle: l.onboardingChooseUpTo3,
        options: [for (final id in obstacleIds) (id, obstacleLabel(l, id))],
        selected: _obstacles,
      ),
    );
  }

  Widget _whyStep(ThemeData theme) {
    final l = AppLocalizations.of(context);
    return InputStep(
      onContinue: _next,
      enabled: _whyRelationship != null,
      child: _singleSelectList(
        theme,
        title: l.onboardingWhyTitle,
        options: [for (final id in _whyIds) (id, _whyLabel(l, id))],
        selected: _whyRelationship,
        onPick: (id) => setState(() => _whyRelationship = id),
      ),
    );
  }

  Widget _journeyStep(ThemeData theme) {
    final l = AppLocalizations.of(context);
    return InputStep(
      onContinue: _next,
      enabled: _veganSince != null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.onboardingJourneyTitle,
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
                    ? l.onboardingJourneyPickDate
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
              label: Text(l.onboardingJourneyToday),
            ),
          ),
        ],
      ),
    );
  }

  Widget _motivationStep(ThemeData theme) {
    final l = AppLocalizations.of(context);
    return InputStep(
      onContinue: _next,
      enabled: _motivation != null,
      child: ListView(
        children: [
          const SizedBox(height: 8),
          _eyebrow(theme, l.onboardingMotivationEyebrow),
          Text(l.onboardingMotivationTitle,
              style: theme.textTheme.displaySmall),
          const SizedBox(height: 20),
          for (final id in _motivationIds)
            ChoiceCard(
              label: _motivationLabel(l, id),
              selected: _motivation == id,
              onTap: () => setState(() => _motivation = id),
            ),
        ],
      ),
    );
  }

  Widget _chartStep(ThemeData theme) {
    final l = AppLocalizations.of(context);
    return InputStep(
      onContinue: _next,
      child: ListView(
        children: [
          const SizedBox(height: 8),
          Text(
            l.onboardingChartTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          const MotivationChart(),
          const SizedBox(height: 20),
          _body(theme, l.onboardingChartBody),
        ],
      ),
    );
  }

  String _fmtTime(int minutes) =>
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60).format(context);

  /// Time picker for the notification window, mirroring the settings screen's
  /// keep-in-order, ≥2-hour-window guard. Updates local step state only; the
  /// values are persisted when the user taps "allow & save".
  Future<void> _pickNotifWindow({required bool isStart}) async {
    final current = isStart ? _notifWindowStart : _notifWindowEnd;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    var start = isStart ? minutes : _notifWindowStart;
    var end = isStart ? _notifWindowEnd : minutes;
    if (end - start < 120) {
      if (isStart) {
        end = (start + 120).clamp(0, 24 * 60 - 1);
      } else {
        start = (end - 120).clamp(0, end);
      }
    }
    setState(() {
      _notifWindowStart = start;
      _notifWindowEnd = end;
    });
  }

  /// "Allow & save": request the OS permission, persist the chosen settings,
  /// then advance. On denial, show the soft-wall education screen first and
  /// advance once the user resolves it (enabled in settings or continued
  /// without). Unsupported platforms return granted = true and just proceed.
  Future<void> _allowAndSaveNotifications() async {
    final granted = await NotificationService.instance.requestPermission();
    final notifier = ref.read(notifSettingsProvider.notifier);
    await notifier.setEnabled(true);
    await notifier.setPerDay(_notifPerDay);
    await notifier.setWindow(_notifWindowStart, _notifWindowEnd);
    if (!mounted) return;
    if (granted) {
      _next();
    } else {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => const NotificationsEducationScreen(),
        ),
      );
      if (mounted) _next();
    }
  }

  Widget _notificationsStep(ThemeData theme) {
    final l = AppLocalizations.of(context);
    return InputStep(
      onContinue: _allowAndSaveNotifications,
      cta: l.onboardingNotifAllowSave,
      child: ListView(
        children: [
          const SizedBox(height: 8),
          Text(l.onboardingNotifTitle, style: theme.textTheme.displaySmall),
          const SizedBox(height: 8),
          _body(theme, l.onboardingNotifBody),
          const SizedBox(height: 20),
          _NotifPreviewCard(),
          const SizedBox(height: 24),
          // Amount: −/+ stepper, clamped 1–10.
          Row(
            children: [
              Expanded(
                child: Text(l.onboardingNotifAmount,
                    style: theme.textTheme.titleMedium),
              ),
              IconButton.filledTonal(
                onPressed: _notifPerDay > 1
                    ? () => setState(() => _notifPerDay--)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  l.notificationsPerDayCount(_notifPerDay),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton.filledTonal(
                onPressed: _notifPerDay < 10
                    ? () => setState(() => _notifPerDay++)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Start / until time rows.
          Row(
            children: [
              Expanded(
                child: Text(l.onboardingNotifStart,
                    style: theme.textTheme.titleMedium),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickNotifWindow(isStart: true),
                icon: const Icon(Icons.wb_sunny_outlined, size: 18),
                label: Text(_fmtTime(_notifWindowStart)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(l.onboardingNotifUntil,
                    style: theme.textTheme.titleMedium),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickNotifWindow(isStart: false),
                icon: const Icon(Icons.nights_stay_outlined, size: 18),
                label: Text(_fmtTime(_notifWindowEnd)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _commitmentStep(ThemeData theme) {
    final l = AppLocalizations.of(context);
    return InputStep(
      onContinue: _next,
      enabled: _commitment != null,
      child: _singleSelectList(
        theme,
        title: l.onboardingCommitmentTitle,
        options: [for (final id in commitmentIds) (id, commitmentLabel(l, id))],
        selected: _commitment,
        onPick: (id) => setState(() => _commitment = id),
      ),
    );
  }

  Widget _commitmentResponse(ThemeData theme) {
    final l = AppLocalizations.of(context);
    final copy = commitmentResponse(l, _commitment);
    return ColoredBox(
      color: theme.colorScheme.primaryContainer,
      child: InputStep(
        onContinue: _next,
        cta: l.onboardingCommitmentResponseCta,
        child: Center(
          child: Text(
            copy,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall
                ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
          ),
        ),
      ),
    );
  }

  Widget _socialProofStep(ThemeData theme) {
    final l = AppLocalizations.of(context);
    return InputStep(
      onContinue: _next,
      cta: l.onboardingSocialCta,
      child: ListView(
        children: [
          const SizedBox(height: 8),
          Text(l.onboardingSocialTitle, style: theme.textTheme.displaySmall),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in [
                l.onboardingSocialChip1,
                l.onboardingSocialChip2,
                l.onboardingSocialChip3,
              ])
                Chip(
                  label: Text(c),
                  backgroundColor: theme.colorScheme.primaryContainer,
                  side: BorderSide.none,
                ),
            ],
          ),
          const SizedBox(height: 20),
          _body(theme, l.onboardingSocialBody),
        ],
      ),
    );
  }

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

/// A static, decorative notification preview on the notifications step — shows
/// the user what a daily quote nudge looks like. Purely illustrative.
class _NotifPreviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.format_quote,
              size: 20,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.onboardingNotifPreviewSender,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      l.onboardingNotifNow,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  l.onboardingNotifPreviewSample,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
