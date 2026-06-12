import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The six farm companions. Each owns three pixel-aligned frames:
/// `base` (eyes open), `blink` (eyes closed), `happy` (^ ^ eyes + open smile).
enum Critter {
  cow,
  pig,
  sheep,
  chicken,
  duck,
  goat;

  String get base => 'assets/critters/${name}_base.png';
  String get blink => 'assets/critters/${name}_blink.png';
  String get happy => 'assets/critters/${name}_happy.png';

  /// Deterministic content-category → companion mapping. Unknown ids fall
  /// back to the cow so every card always has a friend.
  static Critter forCategory(String? categoryId) {
    switch (categoryId) {
      case 'why_vegan':
        return Critter.cow;
      case 'quick_tips':
        return Critter.chicken;
      case 'youre_awesome':
        return Critter.pig;
      case 'facts':
        return Critter.duck;
      case 'staying_strong':
        return Critter.goat;
      case 'milestones':
        return Critter.sheep;
      default:
        return Critter.cow;
    }
  }
}

/// A small kawaii farm animal head that gently breathes (scales) and blinks,
/// and does a happy wiggle when tapped. Pure `AnimationController`/`Ticker` —
/// no packages.
///
/// All three frames stay mounted (opacity swap) so frame changes never
/// flicker. With [animate] false — or when the platform requests reduced
/// motion via `MediaQuery.disableAnimations` — it renders the static base
/// frame, which is also the path the widget tests exercise.
class AnimatedCritter extends StatefulWidget {
  const AnimatedCritter({
    super.key,
    required this.critter,
    this.size = 96,
    this.animate = true,
    this.onTap,
  });

  final Critter critter;
  final double size;
  final bool animate;

  /// Optional extra callback fired on tap (the happy wiggle plays regardless).
  final VoidCallback? onTap;

  @override
  State<AnimatedCritter> createState() => _AnimatedCritterState();
}

/// The frame currently on top of the stack.
enum _Frame { base, blink, happy }

class _AnimatedCritterState extends State<AnimatedCritter>
    with TickerProviderStateMixin {
  // Drives the continuous breathing scale (one full sine period per cycle).
  late final AnimationController _breathe;
  // Drives the decaying tap wiggle (rotation + slight scale up) once per tap.
  late final AnimationController _tap;

  final math.Random _rnd = math.Random();
  Timer? _blinkOnTimer;
  Timer? _blinkOffTimer;

  bool _animating = false;
  bool _blinking = false;
  bool _happy = false;
  bool _precached = false;

  static const _breathePeriod = Duration(milliseconds: 2800);
  static const _blinkDuration = Duration(milliseconds: 160);
  static const _tapDuration = Duration(milliseconds: 1200);

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(vsync: this, duration: _breathePeriod);
    _tap = AnimationController(vsync: this, duration: _tapDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _happy = false);
        }
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      precacheImage(AssetImage(widget.critter.base), context);
      precacheImage(AssetImage(widget.critter.blink), context);
      precacheImage(AssetImage(widget.critter.happy), context);
    }
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _setAnimating(widget.animate && !reduceMotion);
  }

  @override
  void didUpdateWidget(AnimatedCritter old) {
    super.didUpdateWidget(old);
    // PageView recycles elements, so the same state can adopt a new critter.
    if (old.critter != widget.critter) {
      precacheImage(AssetImage(widget.critter.base), context);
      precacheImage(AssetImage(widget.critter.blink), context);
      precacheImage(AssetImage(widget.critter.happy), context);
    }
    if (old.animate != widget.animate) {
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      _setAnimating(widget.animate && !reduceMotion);
    }
  }

  void _setAnimating(bool on) {
    if (on == _animating) return;
    _animating = on;
    if (on) {
      _breathe.repeat();
      _scheduleBlink();
    } else {
      _breathe.stop();
      _cancelBlink();
      if (_blinking || _happy) {
        setState(() {
          _blinking = false;
          _happy = false;
        });
      }
    }
  }

  void _scheduleBlink() {
    // Random rest between blinks: 2.2 s – 4.8 s.
    final restMs = 2200 + _rnd.nextInt(2600);
    _blinkOnTimer = Timer(Duration(milliseconds: restMs), () {
      if (!mounted) return;
      setState(() => _blinking = true);
      _blinkOffTimer = Timer(_blinkDuration, () {
        if (!mounted) return;
        setState(() => _blinking = false);
        _scheduleBlink();
      });
    });
  }

  void _cancelBlink() {
    _blinkOnTimer?.cancel();
    _blinkOffTimer?.cancel();
    _blinkOnTimer = null;
    _blinkOffTimer = null;
  }

  void _handleTap() {
    widget.onTap?.call();
    if (!_animating) return;
    setState(() => _happy = true);
    _tap.forward(from: 0);
  }

  @override
  void dispose() {
    _cancelBlink();
    _breathe.dispose();
    _tap.dispose();
    super.dispose();
  }

  _Frame get _frame {
    if (_happy) return _Frame.happy;
    if (_blinking) return _Frame.blink;
    return _Frame.base;
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final stack = SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _frameImage(_Frame.base, widget.critter.base),
          _frameImage(_Frame.blink, widget.critter.blink),
          _frameImage(_Frame.happy, widget.critter.happy),
        ],
      ),
    );

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breathe, _tap]),
        child: stack,
        builder: (context, child) {
          // Breathing: a gentle in-place scale over one full sine period.
          // Stays put — no vertical movement.
          final breathScale =
              _animating ? 1 + 0.04 * math.sin(_breathe.value * 2 * math.pi) : 1.0;

          // Tap wiggle: a decaying oscillation in rotation + a gentle scale bump.
          double angle = 0;
          double tapScale = 1;
          if (_happy) {
            final t = _tap.value;
            final decay = 1 - t;
            angle = math.sin(t * math.pi * 6) * decay * (8 * math.pi / 180);
            tapScale = 1 + 0.05 * math.sin(t * math.pi);
          }

          return Transform.rotate(
            angle: angle,
            child: Transform.scale(scale: breathScale * tapScale, child: child),
          );
        },
      ),
    );
  }

  Widget _frameImage(_Frame frame, String asset) {
    return Opacity(
      key: ValueKey('critter_frame_${frame.name}'),
      opacity: _frame == frame ? 1 : 0,
      child: Image.asset(asset, width: widget.size, height: widget.size),
    );
  }
}
