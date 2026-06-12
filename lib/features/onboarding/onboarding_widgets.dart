import 'dart:async';

import 'package:flutter/material.dart';

/// Shared building blocks for the story onboarding flow.

/// True when the platform asks for reduced motion — animations collapse to
/// their end state (matches the AnimatedCritter precedent).
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Slim rounded progress bar shown at the top of every step after the first.
class OnboardingProgressBar extends StatelessWidget {
  const OnboardingProgressBar({super.key, required this.value});

  /// 0–1 completion.
  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          minHeight: 6,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
        ),
      ),
    );
  }
}

/// A whole-screen tap target with a subtle "tap to continue →" hint.
class TapStep extends StatelessWidget {
  const TapStep({super.key, required this.onContinue, required this.child});

  final VoidCallback onContinue;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onContinue,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(child: child),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'tap to continue →',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A step with a CTA button, disabled until [enabled].
class InputStep extends StatelessWidget {
  const InputStep({
    super.key,
    required this.onContinue,
    required this.child,
    this.enabled = true,
    this.cta = 'continue',
  });

  final VoidCallback onContinue;
  final Widget child;
  final bool enabled;
  final String cta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: child),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: enabled ? onContinue : null,
            child: Text(cta),
          ),
        ],
      ),
    );
  }
}

/// A selectable option card (single- or multi-select).
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: selected ? theme.colorScheme.primaryContainer : null,
      child: ListTile(
        title: Text(label),
        trailing: selected
            ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

/// Fades + slides its child in after [delay]. Shows immediately under reduced
/// motion.
class FadeInLine extends StatefulWidget {
  const FadeInLine({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  State<FadeInLine> createState() => _FadeInLineState();
}

class _FadeInLineState extends State<FadeInLine> {
  bool _show = false;
  bool _scheduled = false;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    if (reduceMotion(context)) {
      _show = true;
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) setState(() => _show = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    return AnimatedSlide(
      offset: _show ? Offset.zero : const Offset(0, 0.12),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: _show ? 1 : 0,
        duration: const Duration(milliseconds: 450),
        child: widget.child,
      ),
    );
  }
}

/// Compact number formatting for the big impact figures (adapted from
/// `impact_estimates.dart`).
String compactNumber(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 10000) return '${(v / 1000).toStringAsFixed(0)}k';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return v.round().toString();
}

/// A number that counts up from zero to [value] (instant under reduced motion).
/// Returned as an inline [WidgetSpan] for use inside rich sentences.
class CountUpNumber extends StatelessWidget {
  const CountUpNumber({super.key, required this.value, this.style});

  final double value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: reduceMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(compactNumber(v), style: style),
    );
  }
}
