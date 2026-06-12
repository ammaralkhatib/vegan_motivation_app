import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/prefs/prefs_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../onboarding_widgets.dart';
import '../review_prompter.dart';

/// S19 — the day-1 streak celebration. When this step becomes [active] it fires
/// a short confetti burst and, ~1.2 s later (the emotional peak), requests the
/// OS review prompt exactly once ever. Confetti is suppressed under reduced
/// motion.
class StreakStep extends ConsumerStatefulWidget {
  const StreakStep({
    super.key,
    required this.active,
    required this.onContinue,
  });

  final bool active;
  final VoidCallback onContinue;

  @override
  ConsumerState<StreakStep> createState() => _StreakStepState();
}

class _StreakStepState extends ConsumerState<StreakStep> {
  final _confetti =
      ConfettiController(duration: const Duration(milliseconds: 1200));
  Timer? _reviewTimer;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onPeak());
    }
  }

  @override
  void didUpdateWidget(StreakStep old) {
    super.didUpdateWidget(old);
    if (!old.active && widget.active) _onPeak();
  }

  void _onPeak() {
    if (_triggered || !mounted) return;
    _triggered = true;
    if (!reduceMotion(context)) _confetti.play();
    // Fire the review at the peak, a beat after the celebration lands.
    _reviewTimer = Timer(const Duration(milliseconds: 1200), _requestReview);
  }

  Future<void> _requestReview() async {
    if (!mounted) return;
    final prefs = ref.read(prefsProvider);
    if (prefs.reviewPromptShown) return;
    // Set before requesting so it can never fire twice, even on a crash.
    await prefs.setReviewPromptShown(true);
    await ref.read(reviewPrompterProvider).requestReview();
  }

  @override
  void dispose() {
    _reviewTimer?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return InputStep(
      onContinue: widget.onContinue,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🌱', style: theme.textTheme.displayLarge),
                const SizedBox(height: 8),
                Text(
                  l.onboardingStreakDay1,
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.onboardingStreakTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  l.onboardingStreakBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 22,
              maxBlastForce: 18,
              minBlastForce: 6,
              gravity: 0.25,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
                theme.colorScheme.tertiary,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
