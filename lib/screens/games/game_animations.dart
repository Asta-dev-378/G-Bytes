// game_animations.dart
// Shared micro-interaction animation library for all G-Bytes brain games.
// Every animation moment has a standardized implementation here — game screens
// simply call these widgets instead of rolling their own.
//
// Motion Tiers:
//   Micro   : 80–180ms   (button press/release, small state flips)
//   Standard: 150–300ms  (state changes, feedback)
//   Major   : 300–600ms  (level complete, new record, completion)

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MOTION TOKENS
// ─────────────────────────────────────────────────────────────────────────────

class _MT {
  static const micro = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 220);
  static const major = Duration(milliseconds: 450);
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. ANIMATED PRESS BUTTON
//    Scale: idle 1.0 → pressed 0.94 → released 1.04 → settle 1.0
//    Provides the "tactile" feel for every tappable button.
// ─────────────────────────────────────────────────────────────────────────────

class AnimatedPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool disabled;

  const AnimatedPressButton({
    super.key,
    required this.child,
    this.onTap,
    this.disabled = false,
  });

  @override
  State<AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<AnimatedPressButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _MT.micro);
    _scale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.94)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 0.94, end: 1.04)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 35),
      TweenSequenceItem(
          tween: Tween(begin: 1.04, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 25),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _animate() async {
    if (widget.disabled) return;
    HapticFeedback.lightImpact();
    await _ctrl.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _animate,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. CORRECT ANSWER FLASH
//    Wraps a widget, flashes green glow + scale bounce on trigger.
// ─────────────────────────────────────────────────────────────────────────────

class CorrectAnswerFlash extends StatefulWidget {
  final Widget child;
  final bool triggered;

  const CorrectAnswerFlash({
    super.key,
    required this.child,
    required this.triggered,
  });

  @override
  State<CorrectAnswerFlash> createState() => _CorrectAnswerFlashState();
}

class _CorrectAnswerFlashState extends State<CorrectAnswerFlash>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _MT.standard);
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _glow = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(CorrectAnswerFlash old) {
    super.didUpdateWidget(old);
    if (widget.triggered && !old.triggered) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF20BC68).withValues(alpha: _glow.value * 0.55),
                  blurRadius: 28 * _glow.value,
                  spreadRadius: 4 * _glow.value,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. WRONG ANSWER SHAKE
//    Horizontal shake + red tint on wrong answers.
// ─────────────────────────────────────────────────────────────────────────────

class WrongAnswerShake extends StatefulWidget {
  final Widget child;
  final bool triggered;

  const WrongAnswerShake({
    super.key,
    required this.child,
    required this.triggered,
  });

  @override
  State<WrongAnswerShake> createState() => _WrongAnswerShakeState();
}

class _WrongAnswerShakeState extends State<WrongAnswerShake>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _offsetX;
  late Animation<double> _tint;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    // x offset: 0 → -8 → +8 → -5 → +5 → 0
    _offsetX = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -5.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: 0.0), weight: 20),
    ]).animate(_ctrl);
    _tint = Tween<double>(begin: 0.0, end: 0.35).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5)));
  }

  @override
  void didUpdateWidget(WrongAnswerShake old) {
    super.didUpdateWidget(old);
    if (widget.triggered && !old.triggered) {
      HapticFeedback.mediumImpact();
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        return Transform.translate(
          offset: Offset(_offsetX.value, 0),
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.red.withValues(alpha: _tint.value),
              BlendMode.srcATop,
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. ANIMATED SCORE COUNTER
//    Smoothly counts from old value to new value with a roll-up effect.
// ─────────────────────────────────────────────────────────────────────────────

class AnimatedScoreCounter extends StatefulWidget {
  final int score;
  final TextStyle? style;

  const AnimatedScoreCounter({
    super.key,
    required this.score,
    this.style,
  });

  @override
  State<AnimatedScoreCounter> createState() => _AnimatedScoreCounterState();
}

class _AnimatedScoreCounterState extends State<AnimatedScoreCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<int> _value;
  int _from = 0;

  @override
  void initState() {
    super.initState();
    _from = widget.score;
    _ctrl = AnimationController(vsync: this, duration: _MT.standard);
    _value = IntTween(begin: widget.score, end: widget.score).animate(_ctrl);
  }

  @override
  void didUpdateWidget(AnimatedScoreCounter old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) {
      _from = old.score;
      _ctrl.reset();
      _value = IntTween(begin: _from, end: widget.score)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _value,
      builder: (_, _) {
        return Text(
          '${_value.value}',
          style: widget.style ??
              GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1C1C1E),
              ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. FLOATING POINTS TEXT
//    "+10" floats upward and fades. Show it on top of a Stack.
// ─────────────────────────────────────────────────────────────────────────────

class FloatingPointsOverlay extends StatefulWidget {
  final String text;
  final bool triggered;
  final Color color;

  const FloatingPointsOverlay({
    super.key,
    required this.text,
    required this.triggered,
    this.color = const Color(0xFF20BC68),
  });

  @override
  State<FloatingPointsOverlay> createState() => _FloatingPointsOverlayState();
}

class _FloatingPointsOverlayState extends State<FloatingPointsOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _y;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _MT.major);
    _y = Tween<double>(begin: 0.0, end: -60.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 35),
    ]).animate(_ctrl);
  }

  @override
  void didUpdateWidget(FloatingPointsOverlay old) {
    super.didUpdateWidget(old);
    if (widget.triggered && !old.triggered) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          return Transform.translate(
            offset: Offset(0, _y.value),
            child: Opacity(
              opacity: _opacity.value,
              child: Text(
                widget.text,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: widget.color,
                  shadows: [
                    Shadow(
                      color: widget.color.withValues(alpha: 0.45),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. PARTICLE BURST
//    Radial particles — used for correct answers, combos, completions.
// ─────────────────────────────────────────────────────────────────────────────

class ParticleBurst extends StatefulWidget {
  final bool triggered;
  final Color color;
  final int particleCount;
  final double radius;

  const ParticleBurst({
    super.key,
    required this.triggered,
    this.color = const Color(0xFF20BC68),
    this.particleCount = 10,
    this.radius = 60,
  });

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Particle> _particles;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _MT.major);
    _particles = _buildParticles();
  }

  List<_Particle> _buildParticles() {
    return List.generate(widget.particleCount, (i) {
      final angle = (i / widget.particleCount) * 2 * math.pi +
          _rng.nextDouble() * 0.4;
      return _Particle(
        angle: angle,
        radius: widget.radius * (0.6 + _rng.nextDouble() * 0.4),
        size: 4 + _rng.nextDouble() * 5,
        color: widget.color.withValues(
            alpha: 0.7 + _rng.nextDouble() * 0.3),
      );
    });
  }

  @override
  void didUpdateWidget(ParticleBurst old) {
    super.didUpdateWidget(old);
    if (widget.triggered && !old.triggered) {
      _particles = _buildParticles();
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          return CustomPaint(
            painter: _ParticlePainter(
              particles: _particles,
              progress: _ctrl.value,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double radius;
  final double size;
  final Color color;
  const _Particle(
      {required this.angle,
      required this.radius,
      required this.size,
      required this.color});
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress; // 0..1

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Ease out the spread
    final spread = Curves.easeOut.transform(progress);
    // Opacity: fade in quickly, then fade out
    final opacity = progress < 0.3
        ? progress / 0.3
        : (1 - (progress - 0.3) / 0.7).clamp(0.0, 1.0);

    for (final p in particles) {
      final x = cx + math.cos(p.angle) * p.radius * spread;
      final y = cy + math.sin(p.angle) * p.radius * spread;
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity * p.color.a)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), p.size * (1 - progress * 0.4), paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. LEVEL COMPLETE OVERLAY
//    Major moment: covers the screen briefly with a celebration.
// ─────────────────────────────────────────────────────────────────────────────

class LevelCompleteOverlay extends StatefulWidget {
  final bool triggered;
  final String message;
  final VoidCallback onDone;

  const LevelCompleteOverlay({
    super.key,
    required this.triggered,
    this.message = 'Level Complete! 🎉',
    required this.onDone,
  });

  @override
  State<LevelCompleteOverlay> createState() => _LevelCompleteOverlayState();
}

class _LevelCompleteOverlayState extends State<LevelCompleteOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _MT.major);
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.1), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_ctrl);

    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void didUpdateWidget(LevelCompleteOverlay old) {
    super.didUpdateWidget(old);
    if (widget.triggered && !old.triggered && !_shown) {
      _shown = true;
      HapticFeedback.heavyImpact();
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.triggered) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          return Opacity(
            opacity: _opacity.value,
            child: Container(
              color: const Color(0xFF1C1C1E).withValues(alpha: 0.55),
              child: Center(
                child: Transform.scale(
                  scale: _scale.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36, vertical: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC6E05B),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC6E05B).withValues(alpha: 0.55),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      widget.message,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1C1C1E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 8. STREAK COMBO BADGE
//    Grows and glows as the combo/streak increases.
// ─────────────────────────────────────────────────────────────────────────────

class StreakComboBadge extends StatefulWidget {
  final int streak;

  const StreakComboBadge({super.key, required this.streak});

  @override
  State<StreakComboBadge> createState() => _StreakComboBadgeState();
}

class _StreakComboBadgeState extends State<StreakComboBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _MT.micro);
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(StreakComboBadge old) {
    super.didUpdateWidget(old);
    if (widget.streak > old.streak) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _color {
    if (widget.streak >= 10) return const Color(0xFFFF6B35);
    if (widget.streak >= 5) return const Color(0xFFF0C040);
    return const Color(0xFFC6E05B);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.streak < 2) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _color.withValues(alpha: 0.55),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department_rounded,
                size: 14, color: Color(0xFF1C1C1E)),
            const SizedBox(width: 4),
            Text(
              '${widget.streak}×',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1C1C1E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 9. PULSE RING
//    Subtle pulsing ring — used for timer last-seconds warning, active state.
// ─────────────────────────────────────────────────────────────────────────────

class PulseRing extends StatefulWidget {
  final bool active;
  final Color color;
  final double size;

  const PulseRing({
    super.key,
    required this.active,
    this.color = const Color(0xFFFF6B35),
    this.size = 180,
  });

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _scale = Tween<double>(begin: 0.85, end: 1.15)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.0), weight: 100),
    ]).animate(_ctrl);
    if (widget.active) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(PulseRing old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _ctrl.repeat();
    } else if (!widget.active && old.active) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          return Center(
            child: Opacity(
              opacity: _opacity.value,
              child: Transform.scale(
                scale: _scale.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color,
                      width: 3,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 10. SCREEN ENTER TRANSITION
//    Wraps a widget to animate in when first shown.
// ─────────────────────────────────────────────────────────────────────────────

class ScreenEnterTransition extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const ScreenEnterTransition({
    super.key,
    required this.child,
    this.delayMs = 0,
  });

  @override
  State<ScreenEnterTransition> createState() => _ScreenEnterTransitionState();
}

class _ScreenEnterTransitionState extends State<ScreenEnterTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _MT.standard);
    _opacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
