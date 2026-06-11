import 'package:flutter/material.dart';

import '../../core/utils/date_utils.dart';

/// Seven dots for the trailing week (oldest → today).
class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.completedDays,
    required this.today,
  });

  final Set<int> completedDays;
  final int today;

  static const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var offset = 6; offset >= 0; offset--)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _weekdayLetters[
                      (dateFromEpochDay(today - offset).weekday - 1) % 7],
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completedDays.contains(today - offset)
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                    border: offset == 0
                        ? Border.all(color: scheme.primary, width: 1.5)
                        : null,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
