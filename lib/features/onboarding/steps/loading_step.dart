import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../onboarding_widgets.dart';

/// S21 — a fake-loading transition that builds anticipation. When it becomes
/// [active], a percentage counts to 100% over ~3.5 s and three checklist lines
/// appear in sequence, then it auto-advances. Under reduced motion it skips
/// straight through.
class LoadingStep extends StatefulWidget {
  const LoadingStep({
    super.key,
    required this.active,
    required this.onDone,
  });

  final bool active;
  final VoidCallback onDone;

  @override
  State<LoadingStep> createState() => _LoadingStepState();
}

class _LoadingStepState extends State<LoadingStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3500),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    });

  bool _started = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  @override
  void didUpdateWidget(LoadingStep old) {
    super.didUpdateWidget(old);
    if (!old.active && widget.active) _start();
  }

  void _start() {
    if (_started || !mounted) return;
    _started = true;
    if (reduceMotion(context)) {
      // Skip straight through, but after this frame (never navigate mid-build).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onDone();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final lines = [
      l.onboardingLoadingLine1,
      l.onboardingLoadingLine2,
      l.onboardingLoadingLine3,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final percent = (t * 100).round();
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 168,
                height: 168,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: t == 0 ? null : t,
                      strokeWidth: 10,
                    ),
                    Text('$percent%', style: theme.textTheme.headlineMedium),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              for (var i = 0; i < lines.length; i++)
                AnimatedOpacity(
                  opacity: t >= (i + 1) / (lines.length + 1) ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            lines[i],
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                l.onboardingLoadingFooter,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          );
        },
      ),
    );
  }
}
