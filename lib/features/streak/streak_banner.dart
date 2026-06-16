import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../habits/week_strip.dart';
import 'open_streak.dart';

/// A top pill that slides in once per calendar day to celebrate the app-open
/// streak, holds for a few seconds, then slides away and collapses to nothing.
class StreakBanner extends ConsumerStatefulWidget {
  const StreakBanner({super.key});

  @override
  ConsumerState<StreakBanner> createState() => _StreakBannerState();
}

class _StreakBannerState extends ConsumerState<StreakBanner>
    with SingleTickerProviderStateMixin {
  static const _slide = Duration(milliseconds: 350);
  static const _hold = Duration(seconds: 3);

  /// Short beat before the banner slides in, so it lands just after the screen
  /// settles instead of competing with the app's first paint.
  static const _enterDelay = Duration(milliseconds: 600);

  late final OpenStreakResult _result;
  late final AnimationController _controller;
  late final Animation<Offset> _offset;
  late final Animation<double> _fade;

  /// Fires after the entrance delay to start the slide-in (then the hold timer).
  Timer? _showTimer;

  /// Fires after slide-in + hold to start the slide-out. Cancelable so it never
  /// outlives the widget (e.g. in tests, or if the user leaves the screen).
  Timer? _holdTimer;

  /// Once the in/hold/out cycle finishes we collapse the banner to nothing.
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _result = ref.read(appOpenStreakProvider);
    _controller = AnimationController(vsync: this, duration: _slide);
    _offset = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    if (_result.showBanner) {
      // Wait a beat, then slide in and arm the slide-out (delay excluded, so
      // the visible hold is unchanged).
      _showTimer = Timer(_enterDelay, () {
        if (!mounted) return;
        _controller.forward();
        _holdTimer = Timer(_slide + _hold, _slideOut);
      });
    } else {
      _done = true;
    }
  }

  void _slideOut() {
    if (!mounted) return;
    _controller.reverse().then(
      (_) {
        if (mounted) setState(() => _done = true);
      },
      // Controller disposed mid-reverse (user left the screen) — ignore.
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _holdTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done || !_result.showBanner) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: SlideTransition(
          position: _offset,
          child: FadeTransition(
            opacity: _fade,
            child: Semantics(
              label: l.streakBannerLabel(_result.count),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: scheme.inverseSurface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StreakBadge(count: _result.count),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Theme(
                        // WeekStrip reads the ambient colorScheme; give it an
                        // inverse scheme so its dots read on the dark pill.
                        data: Theme.of(context).copyWith(
                          colorScheme: scheme.copyWith(
                            onSurfaceVariant: scheme.onInverseSurface,
                            surfaceContainerHighest:
                                scheme.onInverseSurface.withValues(alpha: 0.25),
                          ),
                        ),
                        child: WeekStrip(
                          completedDays: _result.openedDays,
                          today: _result.today,
                          alignment: MainAxisAlignment.spaceEvenly,
                          dotSize: 17,
                          showCheck: true,
                          animateChecks: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular badge showing the streak number, like the reference screenshot.
class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.primary,
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
