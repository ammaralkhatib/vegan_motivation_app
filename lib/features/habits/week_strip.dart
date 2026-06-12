import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Narrow weekday initial in the ambient locale (English: M T W T F S S).
    final weekdayLetter = DateFormat('EEEEE');
    return Row(
      children: [
        for (var offset = 6; offset >= 0; offset--)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  weekdayLetter.format(dateFromEpochDay(today - offset)),
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
