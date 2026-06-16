import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/date_utils.dart';

/// Seven dots for the trailing week (oldest → today).
class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.completedDays,
    required this.today,
    this.alignment = MainAxisAlignment.start,
    this.dotSize = 10,
    this.showCheck = false,
    this.animateChecks = false,
  });

  final Set<int> completedDays;
  final int today;

  /// How the seven dots are laid out across the row. Defaults to [start]
  /// (the habits-screen layout). The streak banner passes [spaceEvenly] to
  /// spread the dots across a full-width pill.
  final MainAxisAlignment alignment;

  /// Dot diameter. Defaults to the small habit-tile size.
  final double dotSize;

  /// When true, a completed day shows a check icon inside the dot instead of a
  /// plain fill. Off by default so the habit tiles keep their plain dots.
  final bool showCheck;

  /// When true (and [showCheck]), the check icons scale + fade in, staggered
  /// left→right. Ignored under reduced motion.
  final bool animateChecks;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Narrow weekday initial in the ambient locale (English: M T W T F S S).
    final weekdayLetter = DateFormat('EEEEE');
    // When the dots are spread evenly, the row itself supplies the gaps, so
    // the per-dot right padding is dropped to avoid a double gap on the right.
    final dotPadding = alignment == MainAxisAlignment.spaceEvenly
        ? EdgeInsets.zero
        : const EdgeInsets.only(right: 10);
    final labelSize = (dotSize * 0.65).clamp(10.0, 13.0);
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Row(
      mainAxisAlignment: alignment,
      children: [
        for (var offset = 6; offset >= 0; offset--)
          Padding(
            padding: dotPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  weekdayLetter.format(dateFromEpochDay(today - offset)),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: labelSize,
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: dotSize,
                  height: dotSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completedDays.contains(today - offset)
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                    border: offset == 0
                        ? Border.all(color: scheme.primary, width: 1.5)
                        : null,
                  ),
                  child: (showCheck && completedDays.contains(today - offset))
                      ? _AnimatedCheck(
                          size: dotSize * 0.72,
                          color: scheme.onPrimary,
                          animate: animateChecks && !reduceMotion,
                          // Stagger left→right: leftmost (offset 6) first.
                          delay: Duration(milliseconds: 90 * (6 - offset)),
                        )
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A check icon that scales + fades in after [delay] (a small pop). Renders
/// instantly when [animate] is false.
class _AnimatedCheck extends StatefulWidget {
  const _AnimatedCheck({
    required this.size,
    required this.color,
    required this.animate,
    required this.delay,
  });

  final double size;
  final Color color;
  final bool animate;
  final Duration delay;

  @override
  State<_AnimatedCheck> createState() => _AnimatedCheckState();
}

class _AnimatedCheckState extends State<_AnimatedCheck> {
  bool _show = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!widget.animate) {
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
    final icon = Icon(Icons.check, size: widget.size, color: widget.color);
    if (!widget.animate) return icon;
    return AnimatedScale(
      scale: _show ? 1 : 0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: _show ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        child: icon,
      ),
    );
  }
}
