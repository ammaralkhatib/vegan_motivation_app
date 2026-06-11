import 'package:flutter/material.dart';

import '../../data/impact_estimates.dart';

/// One animated impact stat: counts up from zero on first build.
class ImpactCounter extends StatelessWidget {
  const ImpactCounter({super.key, required this.stat, required this.days});

  final ImpactStat stat;
  final int days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = stat.perDay * days;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(stat.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: target),
                    duration: const Duration(milliseconds: 1100),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => Text(
                      stat.format(value),
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 28,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Text(stat.label, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
