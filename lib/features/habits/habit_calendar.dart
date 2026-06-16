import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/utils/date_utils.dart';
import 'cell_text_color.dart';

/// Whether a calendar day can be toggled: today and past only, never the
/// future. Pure so it can be unit-tested without a widget tree.
bool isToggleable(int day, int today) => day <= today;

/// A single-month, binary (done / not-done) calendar for one habit — unlike the
/// multi-habit intensity [MonthHeatmap]. The parent owns the visible [month]
/// and performs the toggle; this widget is stateless.
class HabitCalendar extends StatelessWidget {
  const HabitCalendar({
    super.key,
    required this.completedDays,
    required this.month,
    required this.today,
    this.onToggleDay,
  });

  /// All completion epoch-days for the habit (membership is checked per cell).
  final Set<int> completedDays;

  /// Any date inside the month to render (only year+month are used).
  final DateTime month;

  /// Today's epoch-day; cells after it are locked.
  final int today;

  /// Called with the cell's epoch-day when a non-future cell is tapped.
  final void Function(int epochDay)? onToggleDay;

  // 2024-01-01 was a Monday → offset 0..6 maps to Mon..Sun, matching the
  // heatmap's `firstWeekday` (1 = Mon) ordering.
  static DateTime _headerDate(int column) =>
      DateTime(2024, 1, 1).add(Duration(days: column));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final weekdayLetter = DateFormat('EEEEE');

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday; // 1 = Mon
    final leadingBlanks = firstWeekday - 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 7;
        const gap = 5.0;
        final cellW = (constraints.maxWidth - gap * (columns - 1)) / columns;
        final cellH = cellW * 0.72;
        final totalCells = leadingBlanks + daysInMonth;
        final rows = (totalCells / columns).ceil();

        return Column(
          children: [
            // Weekday header (Mon→Sun), localized single letters.
            Row(
              children: [
                for (var c = 0; c < columns; c++) ...[
                  SizedBox(
                    width: cellW,
                    child: Text(
                      weekdayLetter.format(_headerDate(c)),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (c < columns - 1) const SizedBox(width: gap),
                ],
              ],
            ),
            const SizedBox(height: 6),
            for (var r = 0; r < rows; r++) ...[
              Row(
                children: [
                  for (var c = 0; c < columns; c++) ...[
                    Builder(builder: (context) {
                      final index = r * columns + c;
                      final dayOfMonth = index - leadingBlanks + 1;
                      final valid =
                          dayOfMonth >= 1 && dayOfMonth <= daysInMonth;
                      if (!valid) {
                        return SizedBox(width: cellW, height: cellH);
                      }
                      return _dayCell(context, dayOfMonth, cellW, cellH);
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
    );
  }

  Widget _dayCell(
    BuildContext context,
    int dayOfMonth,
    double w,
    double h,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final epoch = epochDay(DateTime(month.year, month.month, dayOfMonth));
    final isFuture = epoch > today;
    final isToday = epoch == today;
    final completed = completedDays.contains(epoch);

    final bg = isFuture
        ? Colors.transparent
        : completed
            ? scheme.primary
            : scheme.surfaceContainerHighest;

    final cell = Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border:
            isToday ? Border.all(color: scheme.primary, width: 1.5) : null,
      ),
      alignment: Alignment.center,
      // Future cells draw no number.
      child: isFuture
          ? null
          : Text(
              '$dayOfMonth',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: cellTextColor(bg, scheme),
              ),
            ),
    );

    if (isFuture || onToggleDay == null) return cell;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onToggleDay!(epoch);
      },
      child: cell,
    );
  }
}
