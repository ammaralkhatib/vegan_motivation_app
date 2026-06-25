import 'package:flutter/material.dart';

import '../../core/db/database.dart';
import '../../core/theme/palette.dart';

enum ShareCardStyle { cream, forest, coral }

/// Fixed-ratio (4:5) styled quote card, captured at 3x for sharing.
/// Designed at 360×450 logical → 1080×1350 px output.
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.quote, required this.style});

  final Quote quote;
  final ShareCardStyle style;

  static const designSize = Size(360, 450);

  ({Color bg, Color ink, Color accent}) get _colors => switch (style) {
        ShareCardStyle.cream => (
            bg: VeggiePalette.cream,
            ink: VeggiePalette.inkLight,
            accent: VeggiePalette.forest,
          ),
        ShareCardStyle.forest => (
            bg: VeggiePalette.forest,
            ink: const Color(0xFFF3F7F0),
            accent: VeggiePalette.mint,
          ),
        ShareCardStyle.coral => (
            bg: const Color(0xFFF8D8CC),
            ink: const Color(0xFF4A2A1E),
            accent: const Color(0xFFB35F44),
          ),
      };

  @override
  Widget build(BuildContext context) {
    final c = _colors;
    final isLong = quote.body.length > 140;

    return SizedBox.fromSize(
      size: designSize,
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.bg),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.eco, size: 28, color: c.accent),
              const Spacer(),
              Text(
                quote.body,
                maxLines: 10,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: isLong ? 19 : 24,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                ),
              ),
              if (quote.author != null) ...[
                const SizedBox(height: 12),
                Text(
                  '— ${quote.author}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: c.ink.withValues(alpha: 0.7),
                  ),
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 3,
                    decoration: BoxDecoration(
                      color: c.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Stay Vegan',
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
