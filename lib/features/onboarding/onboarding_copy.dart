/// Onboarding option ids (stable, persisted) and their localized copy.
///
/// Ids are the contract with prefs and downstream logic — they never change.
/// All user-visible text is resolved through [AppLocalizations] here, so the
/// data layer stays string-free (UI-strings-only l10n, CLAUDE.md §1).
library;

import '../../l10n/app_localizations.dart';

/// S9 goal ids, in display order.
const goalIds = [
  'daily_motivation',
  'habits',
  'social_strength',
  'reconnect_why',
  'less_alone',
];

/// S12 obstacle ids, in display order.
const obstacleIds = [
  'cravings',
  'social_pressure',
  'fading_motivation',
  'alone',
  'busyness',
];

/// S23 commitment ids, in display order.
const commitmentIds = ['extreme', 'very', 'somewhat', 'little', 'trying'];

/// S25 — how full the commitment bar reads, per level (0–1).
const commitmentBarFill = {
  'extreme': 1.0,
  'very': 0.8,
  'somewhat': 0.6,
  'little': 0.4,
  'trying': 0.2,
};

/// S9 — goal choice label.
String goalLabel(AppLocalizations l, String id) => switch (id) {
      'daily_motivation' => l.onboardingGoalDailyMotivation,
      'habits' => l.onboardingGoalHabits,
      'social_strength' => l.onboardingGoalSocialStrength,
      'reconnect_why' => l.onboardingGoalReconnectWhy,
      _ => l.onboardingGoalLessAlone,
    };

/// S10 — what each picked goal promises back to the user.
String goalReflection(AppLocalizations l, String id) => switch (id) {
      'daily_motivation' => l.onboardingGoalReflectionDailyMotivation,
      'habits' => l.onboardingGoalReflectionHabits,
      'social_strength' => l.onboardingGoalReflectionSocialStrength,
      'reconnect_why' => l.onboardingGoalReflectionReconnectWhy,
      'less_alone' => l.onboardingGoalReflectionLessAlone,
      _ => '',
    };

/// S15 / S25 — first goal in plain words ("you want ...").
String goalPlainWords(AppLocalizations l, String id) => switch (id) {
      'daily_motivation' => l.onboardingGoalPlainDailyMotivation,
      'habits' => l.onboardingGoalPlainHabits,
      'social_strength' => l.onboardingGoalPlainSocialStrength,
      'reconnect_why' => l.onboardingGoalPlainReconnectWhy,
      'less_alone' => l.onboardingGoalPlainLessAlone,
      _ => l.onboardingReflectionGoalFallback,
    };

/// S12 — obstacle choice label.
String obstacleLabel(AppLocalizations l, String id) => switch (id) {
      'cravings' => l.onboardingObstacleCravings,
      'social_pressure' => l.onboardingObstacleSocialPressure,
      'fading_motivation' => l.onboardingObstacleFadingMotivation,
      'alone' => l.onboardingObstacleAlone,
      _ => l.onboardingObstacleBusyness,
    };

/// S15 — first obstacle in plain words ("but ... keeps getting in the way").
String obstaclePlainWords(AppLocalizations l, String id) => switch (id) {
      'cravings' => l.onboardingObstaclePlainCravings,
      'social_pressure' => l.onboardingObstaclePlainSocialPressure,
      'fading_motivation' => l.onboardingObstaclePlainFadingMotivation,
      'alone' => l.onboardingObstaclePlainAlone,
      _ => l.onboardingObstaclePlainBusyness,
    };

/// S23 — commitment choice label.
String commitmentLabel(AppLocalizations l, String id) => switch (id) {
      'extreme' => l.onboardingCommitmentExtreme,
      'very' => l.onboardingCommitmentVery,
      'somewhat' => l.onboardingCommitmentSomewhat,
      'little' => l.onboardingCommitmentLittle,
      _ => l.onboardingCommitmentTrying,
    };

/// S24 — response copy tailored to the commitment answer. Falls back to a
/// generic line when nothing was picked.
String commitmentResponse(AppLocalizations l, String? id) => switch (id) {
      'extreme' => l.onboardingCommitmentResponseExtreme,
      'very' => l.onboardingCommitmentResponseVery,
      'somewhat' => l.onboardingCommitmentResponseSomewhat,
      'little' => l.onboardingCommitmentResponseLittle,
      'trying' => l.onboardingCommitmentResponseTrying,
      _ => l.onboardingCommitmentFallback,
    };
