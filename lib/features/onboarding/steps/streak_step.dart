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

class _StreakStepState extends ConsumerState<StreakStep>
    with SingleTickerProviderStateMixin {
  final _confetti =
      ConfettiController(duration: const Duration(milliseconds: 1200));
  // Drives the staggered scale-up "pop" of the seven day cells.
  late final AnimationController _cellAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
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
    // Under reduced motion the cells render at full size (animate: false in
    // build), so there's nothing to forward and no confetti to play.
    if (!reduceMotion(context)) {
      _confetti.play();
      _cellAnim.forward();
    }
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
    _cellAnim.dispose();
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
                const SizedBox(height: 24),
                // First-week strip: day 1 achieved, days 2–7 upcoming. Wrapped
                // in FittedBox so the seven cells scale down instead of
                // overflowing on narrow screens.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      for (var day = 1; day <= 7; day++) ...[
                        if (day > 1) const SizedBox(width: 8),
                        _DayCell(
                          day: day,
                          done: day == 1,
                          index: day - 1,
                          total: 7,
                          animation: _cellAnim,
                          animate: !reduceMotion(context),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Align(
            // Emitter just right of center, on the top edge. NOT a corner:
            // prompt 005 put it at topRight, but the explosive burst then fired
            // off-screen into the corner and was invisible. This keeps the spray
            // on-screen while staying slightly right of dead-center.
            alignment: const Alignment(0.3, -1),
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

/// One cell in the first-week strip. [done] day 1 is filled with a check; the
/// upcoming days 2–7 are muted outlined circles showing their number.
///
/// When [animate] is true the cell pops in via a staggered scale from
/// [animation] (each cell's window is offset by its [index]); the achieved day-1
/// cell uses a springier [Curves.elasticOut] for a bigger pop than the gentler
/// [Curves.easeOutBack] of days 2–7. When [animate] is false (reduced motion)
/// it renders at full size instantly.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.done,
    required this.index,
    required this.total,
    required this.animation,
    required this.animate,
  });

  final int day;
  final bool done;
  final int index;
  final int total;
  final Animation<double> animation;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final cell = _circle(context);
    if (!animate) return cell;

    // Staggered window inside the parent timeline: each cell starts a beat after
    // the previous (left → right) and animates over half the total duration.
    const window = 0.5;
    final start = (1 - window) * index / (total - 1);
    final curve = done ? Curves.elasticOut : Curves.easeOutBack;

    return AnimatedBuilder(
      animation: animation,
      child: cell,
      builder: (context, child) {
        final raw = Interval(start, start + window).transform(animation.value);
        return Opacity(
          opacity: raw.clamp(0.0, 1.0),
          child: Transform.scale(scale: curve.transform(raw), child: child),
        );
      },
    );
  }

  Widget _circle(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        border:
            done ? null : Border.all(color: theme.colorScheme.outlineVariant),
      ),
      alignment: Alignment.center,
      child: done
          ? Icon(Icons.check, size: 20, color: theme.colorScheme.onPrimary)
          : Text(
              '$day',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
    );
  }
}
