import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../l10n/app_localizations.dart';
import 'providers.dart';

/// GitHub-style intensity grid for the current month: how many habits were
/// completed each day, on the sage→forest ramp.
class MonthHeatmap extends ConsumerWidget {
  const MonthHeatmap({super.key, required this.habitCount});

  final int habitCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final ramp = theme.extension<VeggieAccents>()!.heatmapRamp;
    final completions = ref.watch(monthCompletionsProvider).valueOrNull ?? {};

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = DateTime(now.year, now.month, 1).weekday; // 1 = Mon
    final today = todayEpochDay();

    Color cellColor(int dayOfMonth) {
      final day = epochDay(DateTime(now.year, now.month, dayOfMonth));
      if (day > today) return Colors.transparent;
      final count = completions[day] ?? 0;
      if (count == 0 || habitCount == 0) return ramp[0];
      final fraction = count / habitCount;
      if (fraction >= 1) return ramp[4];
      if (fraction >= 0.66) return ramp[3];
      if (fraction >= 0.33) return ramp[2];
      return ramp[1];
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  DateFormat('MMMM').format(now),
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                Text(l.habitsHeatmapLess, style: theme.textTheme.labelSmall),
                const SizedBox(width: 6),
                for (final color in ramp) ...[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 3),
                ],
                const SizedBox(width: 3),
                Text(l.habitsHeatmapMore, style: theme.textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                const columns = 7;
                const gap = 5.0;
                final cell =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                final leadingBlanks = firstWeekday - 1;
                final totalCells = leadingBlanks + daysInMonth;
                final rows = (totalCells / columns).ceil();

                return Column(
                  children: [
                    for (var r = 0; r < rows; r++) ...[
                      Row(
                        children: [
                          for (var c = 0; c < columns; c++) ...[
                            Builder(builder: (context) {
                              final index = r * columns + c;
                              final dayOfMonth = index - leadingBlanks + 1;
                              final valid = dayOfMonth >= 1 &&
                                  dayOfMonth <= daysInMonth;
                              return Container(
                                width: cell,
                                height: cell * 0.72,
                                decoration: BoxDecoration(
                                  color: valid
                                      ? cellColor(dayOfMonth)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                alignment: Alignment.center,
                                child: valid
                                    ? Text(
                                        '$dayOfMonth',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          fontSize: 9,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      )
                                    : null,
                              );
                            }),
                            if (c < columns - 1) const SizedBox(width: gap),
                          ],
                        ],
                      ),
                      if (r < rows - 1) const SizedBox(height: gap),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
