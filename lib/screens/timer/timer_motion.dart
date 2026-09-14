// timer_motion.dart
// Shared animation tokens and custom-painter components for the G-Timer screen.
// Reuses the same duration constants as game_animations.dart for consistency.

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';


// ---------------------------------------------------------------------------
// MOTION DURATION CONSTANTS  (mirrors GameAnimations constants)
// ---------------------------------------------------------------------------

class TimerMotion {
  TimerMotion._();

  /// Micro interactions â€” button press, digit flicker.
  static const micro = Duration(milliseconds: 120);

  /// Standard transitions â€” ring fill, state tint changes.
  static const standard = Duration(milliseconds: 240);

  /// Major events â€” completion overlay.
  static const major = Duration(milliseconds: 420);

  /// Completion overlay auto-dismiss window.
  static const completionWindow = Duration(milliseconds: 3200);
}

// ---------------------------------------------------------------------------
// TIMER RING PAINTER
// ---------------------------------------------------------------------------

/// Smooth continuous countdown ring that reads [fractionRemaining] directly.
/// Draws a rounded-cap arc on a background track.
/// No dependency on `percent_indicator` package.
class TimerRingPainter extends CustomPainter {
  final double fractionRemaining; // 1.0 = full, 0.0 = empty
  final Color trackColor;
  final Color ringColor;
  final double strokeWidth;
  final bool isLastTenSeconds;

  const TimerRingPainter({
    required this.fractionRemaining,
    required this.ringColor,
    this.trackColor = const Color(0xFFE5E5EA),
    this.strokeWidth = 10.0,
    this.isLastTenSeconds = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (fractionRemaining <= 0) return;

    // Active arc â€” starts at 12 o'clock (âˆ’Ï€/2), sweeps clockwise
    final sweepAngle = fractionRemaining * 2 * math.pi;
    final rect =
        Rect.fromCircle(center: center, radius: radius);

    // Pulse the ring slightly in the last 10s
    final effectiveColor = isLastTenSeconds
        ? ringColor
        : ringColor;

    canvas.drawArc(
      rect,
      -math.pi / 2, // start at top
      sweepAngle,
      false,
      Paint()
        ..color = effectiveColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(TimerRingPainter old) =>
      old.fractionRemaining != fractionRemaining ||
      old.ringColor != ringColor ||
      old.isLastTenSeconds != isLastTenSeconds;
}

// ---------------------------------------------------------------------------
// LAST SECONDS PULSE RING
// ---------------------------------------------------------------------------

/// Subtle pulsing ring overlay drawn when < 10s remain.
class LastSecondsWidget extends StatefulWidget {
  final Color color;
  final double size;
  final Widget child;

  const LastSecondsWidget({
    super.key,
    required this.color,
    required this.size,
    required this.child,
  });

  @override
  State<LastSecondsWidget> createState() => _LastSecondsWidgetState();
}

class _LastSecondsWidgetState extends State<LastSecondsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _opacity = Tween<double>(begin: 0.0, end: 0.22).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
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
      builder: (_, child) => Stack(
        alignment: Alignment.center,
        children: [
          // Pulse ring
          Transform.scale(
            scale: _scale.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withValues(alpha: _opacity.value),
                  width: 3,
                ),
              ),
            ),
          ),
          // Inner content
          child!,
        ],
      ),
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// COMPLETION OVERLAY
// ---------------------------------------------------------------------------

/// Elegant completion overlay â€” scale + fade in, auto-dismisses.
class CompletionOverlay extends StatelessWidget {
  final VoidCallback onDismiss;
  final Color accentColor;

  const CompletionOverlay({
    super.key,
    required this.onDismiss,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 48),
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.28),
                  blurRadius: 48,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated emoji
                const Text('âœ…', style: TextStyle(fontSize: 52))
                    .animate()
                    .scale(
                      begin: const Offset(0.4, 0.4),
                      end: const Offset(1.0, 1.0),
                      duration: TimerMotion.major,
                      curve: Curves.elasticOut,
                    ),
                const SizedBox(height: 20),
                Text(
                  'Time\'s Up!',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1C1C1E),
                  ),
                )
                    .animate(delay: 120.ms)
                    .fadeIn(duration: TimerMotion.standard)
                    .slideY(begin: 0.2, end: 0),
                const SizedBox(height: 8),
                Text(
                  'Well done â€” session complete.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF8E8E93),
                    fontWeight: FontWeight.w500,
                  ),
                )
                    .animate(delay: 200.ms)
                    .fadeIn(duration: TimerMotion.standard),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: onDismiss,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.36),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
                    .animate(delay: 280.ms)
                    .fadeIn(duration: TimerMotion.standard)
                    .slideY(begin: 0.3, end: 0),
              ],
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(duration: TimerMotion.standard)
          .scale(
            begin: const Offset(0.96, 0.96),
            end: const Offset(1.0, 1.0),
            duration: TimerMotion.standard,
            curve: Curves.easeOut,
          ),
    );
  }
}

// ---------------------------------------------------------------------------
// ANIMATED PRESS BUTTON (reused from GameAnimations style)
// ---------------------------------------------------------------------------

/// Scale press animation for timer control buttons (Start, Pause, Reset).
class TimerPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressScale;

  const TimerPressButton({
    super.key,
    required this.child,
    this.onTap,
    this.pressScale = 0.93,
  });

  @override
  State<TimerPressButton> createState() => _TimerPressButtonState();
}

class _TimerPressButtonState extends State<TimerPressButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: TimerMotion.micro,
      reverseDuration: TimerMotion.micro,
    );
    _scale = Tween<double>(begin: 1.0, end: widget.pressScale).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ===========================================================================
// INFINITY FLOW ANIMATION
// ===========================================================================

// ---------------------------------------------------------------------------
// STARFIELD BACKGROUND
// Replicates the exact same three blob layout as splash_screen.dart so the
// timer animation feels visually continuous with the rest of the app.
// ---------------------------------------------------------------------------

class StarfieldBackground extends StatelessWidget {
  final Color primaryColor;
  const StarfieldBackground({super.key, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      return Stack(
        children: [
          // Dark base
          Container(color: const Color(0xFF1C1C1E)),
          // Top-right warm blob (matches splash top-right blob)
          Positioned(
            top: -h * 0.08,
            right: -w * 0.14,
            child: Container(
              width: w * 0.62,
              height: w * 0.62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: 0.13),
              ),
            ),
          ),
          // Bottom-left cool blob (matches splash bottom-left blob)
          Positioned(
            bottom: h * 0.20,
            left: -w * 0.12,
            child: Container(
              width: w * 0.44,
              height: w * 0.44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFBDB0F5).withValues(alpha: 0.09),
              ),
            ),
          ),
          // Small bottom-right accent blob
          Positioned(
            bottom: h * 0.08,
            right: w * 0.08,
            child: Container(
              width: w * 0.18,
              height: w * 0.18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: 0.06),
              ),
            ),
          ),
        ],
      );
    });
  }
}

// ---------------------------------------------------------------------------
// INFINITY FLOW PAINTER
// Draws a neon figure-8 (âˆž) with:
//   â€¢ A faint static base path (always visible)
//   â€¢ A traveling bright segment via dashOffset on PathMetrics
//   â€¢ A soft MaskFilter bloom / glow
//   â€¢ Two floating text labels inside the left and right loops
//   â€¢ A pulsing center flare at the crossing point
// ---------------------------------------------------------------------------

class InfinityFlowPainter extends CustomPainter {
  final double flowValue;   // 0.0 â†’ 1.0, drives the dashOffset loop
  final double flareValue;  // 0.0 â†’ 1.0, drives center-flare pulse
  final double surgeValue;  // 0.0 â†’ 1.0, widens stroke on completion
  final Color warmColor;
  final Color coolColor;
  final Color glowColor;
  final String leftLabel;
  final String rightLabel;

  const InfinityFlowPainter({
    required this.flowValue,
    required this.flareValue,
    required this.surgeValue,
    required this.warmColor,
    required this.coolColor,
    required this.glowColor,
    required this.leftLabel,
    required this.rightLabel,
  });

  // Build the figure-8 path sized to a bounding rect.
  // The path crosses at the center and makes two equal loops.
  static Path _buildPath(Rect bounds) {
    final cx = bounds.center.dx;
    final cy = bounds.center.dy;
    final rx = bounds.width * 0.36;   // horizontal loop radius
    final ry = bounds.height * 0.38;  // vertical loop radius

    final path = Path();
    // Start at the center crossing point
    path.moveTo(cx, cy);
    // Left loop â€” sweeps through left half then back to center
    path.cubicTo(
      cx - rx * 0.1, cy - ry,   // cp1
      cx - rx * 2.0, cy - ry,   // cp2
      cx - rx * 2.0, cy,         // end-left
    );
    path.cubicTo(
      cx - rx * 2.0, cy + ry,   // cp1
      cx - rx * 0.1, cy + ry,   // cp2
      cx, cy,                    // back to center
    );
    // Right loop
    path.cubicTo(
      cx + rx * 0.1, cy - ry,   // cp1
      cx + rx * 2.0, cy - ry,   // cp2
      cx + rx * 2.0, cy,         // end-right
    );
    path.cubicTo(
      cx + rx * 2.0, cy + ry,   // cp1
      cx + rx * 0.1, cy + ry,   // cp2
      cx, cy,                    // back to center
    );
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = _buildPath(rect);

    // â”€â”€ Compute exact path length for a perfectly seamless loop â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final metrics = path.computeMetrics().toList();
    final totalLen = metrics.fold(0.0, (sum, m) => sum + m.length);
    if (totalLen <= 0) return;

    final segmentLen  = totalLen * 0.15; // lit segment = 15% of path
    final dashOffset  = flowValue * totalLen; // travels forward 0 â†’ full
    final strokeBase  = 3.5 + surgeValue * 4.5; // 3.5 â†’ 8.0 on surge

    // â”€â”€ Gradient shader spanning the full bounding box â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final gradShader = ui.Gradient.linear(
      Offset(rect.left, rect.center.dy),
      Offset(rect.right, rect.center.dy),
      [warmColor, glowColor, coolColor],
      [0.0, 0.50, 1.0],
    );

    // â”€â”€ 1. Faint static base path â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeBase * 0.7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // â”€â”€ 2. Traveling glow segment using PathMetrics â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    // We extract only the lit 15% segment from wherever dashOffset places it
    // and draw that sub-path with the gradient shader.
    final segPath = Path();
    double remaining = segmentLen;
    double start     = dashOffset % totalLen;
    bool started     = false;

    for (final metric in metrics) {
      if (remaining <= 0) break;
      final metricLen = metric.length;

      // How far into this contour does our segment start?
      final double localStart = start;
      if (localStart >= metricLen) {
        start -= metricLen;
        continue;
      }
      start = 0;

      final localEnd = math.min(localStart + remaining, metricLen);
      final extracted = metric.extractPath(localStart, localEnd);
      if (!started) {
        segPath.addPath(extracted, Offset.zero);
        started = true;
      } else {
        segPath.addPath(extracted, Offset.zero);
      }
      remaining -= (localEnd - localStart);

      // Wrap: if the segment crosses the path end, restart from 0
      if (remaining > 0 && localEnd >= metricLen) {
        start = 0;
      }
    }

    // Handle wrap-around if segment crosses end â†’ beginning
    if (remaining > 0) {
      double r2 = remaining;
      for (final metric in metrics) {
        if (r2 <= 0) break;
        final localEnd = math.min(r2, metric.length);
        segPath.addPath(metric.extractPath(0, localEnd), Offset.zero);
        r2 -= localEnd;
      }
    }

    // Outer bloom (blur)
    final blurSigma = 4.0 + surgeValue * 8.0;
    canvas.drawPath(
      segPath,
      Paint()
        ..shader = gradShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeBase * 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma),
    );

    // Core bright line
    canvas.drawPath(
      segPath,
      Paint()
        ..shader = gradShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeBase
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // â”€â”€ 3. Center flare â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final cx = size.width / 2;
    final cy = size.height / 2;
    final flareRadius = 14.0 + flareValue * 8.0;
    final flareOpacity = 0.55 + flareValue * 0.45;

    canvas.drawCircle(
      Offset(cx, cy),
      flareRadius,
      Paint()
        ..color = glowColor.withValues(alpha: flareOpacity * 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      flareRadius * 0.4,
      Paint()..color = glowColor.withValues(alpha: flareOpacity),
    );

    // â”€â”€ 4. Left & right loop labels â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final leftX  = size.width * 0.24;
    final rightX = size.width * 0.76;
    _drawLabel(canvas, leftLabel,  Offset(leftX,  cy), warmColor);
    _drawLabel(canvas, rightLabel, Offset(rightX, cy), coolColor);
  }

  void _drawLabel(Canvas canvas, String text, Offset center, Color color) {
    final pb = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        maxLines: 1,
      ),
    )
      ..pushStyle(ui.TextStyle(
        color: Colors.white.withValues(alpha: 0.90),
        fontSize: 13,
        fontWeight: ui.FontWeight.w700,
        letterSpacing: 0.5,
      ))
      ..addText(text);

    final para = pb.build()
      ..layout(const ui.ParagraphConstraints(width: 80));

    canvas.drawParagraph(
      para,
      Offset(center.dx - 40, center.dy - para.height / 2),
    );
  }

  @override
  bool shouldRepaint(InfinityFlowPainter old) =>
      old.flowValue  != flowValue  ||
      old.flareValue != flareValue ||
      old.surgeValue != surgeValue ||
      old.warmColor  != warmColor  ||
      old.coolColor  != coolColor  ||
      old.leftLabel  != leftLabel  ||
      old.rightLabel != rightLabel;
}

// ---------------------------------------------------------------------------
// INFINITY FLOW WIDGET
// Stateful shell that manages four AnimationControllers and feeds them into
// InfinityFlowPainter + StarfieldBackground.
// ---------------------------------------------------------------------------

enum InfinityMode { classic, interval, workout }

class InfinityFlowWidget extends StatefulWidget {
  /// 1.0 = full, 0.0 = done.
  final double progress;
  final String leftLabel;
  final String rightLabel;
  final Color warmColor;
  final Color coolColor;
  final InfinityMode mode;
  final VoidCallback? onComplete;

  const InfinityFlowWidget({
    super.key,
    required this.progress,
    required this.leftLabel,
    required this.rightLabel,
    required this.warmColor,
    required this.coolColor,
    this.mode = InfinityMode.classic,
    this.onComplete,
  });

  @override
  State<InfinityFlowWidget> createState() => _InfinityFlowWidgetState();
}

class _InfinityFlowWidgetState extends State<InfinityFlowWidget>
    with TickerProviderStateMixin {
  // â”€â”€ Flow: endless 3s linear dash travel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  late final AnimationController _flowCtrl;
  // â”€â”€ Flare: 1.8s ease-in-out center pulse â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  late final AnimationController _flareCtrl;
  // â”€â”€ Entry: one-shot scale 0.85 â†’ 1.0 on first build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryScale;
  // â”€â”€ Surge + fade on completion â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  late final AnimationController _surgeCtrl;
  late final Animation<double> _surgeAnim;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  bool _completionFired = false;

  @override
  void initState() {
    super.initState();

    _flowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _flareCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _entryScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut),
    );
    _entryCtrl.forward();

    _surgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _surgeAnim = CurvedAnimation(parent: _surgeCtrl, curve: Curves.easeOut);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
  }

  @override
  void didUpdateWidget(InfinityFlowWidget old) {
    super.didUpdateWidget(old);
    // Fire completion surge when progress hits 0 for the first time
    if (!_completionFired &&
        widget.progress <= 0.0 &&
        widget.mode != InfinityMode.interval) {
      _completionFired = true;
      _surgeCtrl.forward().then((_) {
        if (mounted) {
          _fadeCtrl.forward().then((_) {
            widget.onComplete?.call();
          });
        }
      });
    }
    // Reset if the widget is reused (e.g., timer reset)
    if (widget.progress > 0.0 && _completionFired) {
      _completionFired = false;
      _surgeCtrl.reset();
      _fadeCtrl.reset();
    }
  }

  @override
  void dispose() {
    _flowCtrl.dispose();
    _flareCtrl.dispose();
    _entryCtrl.dispose();
    _surgeCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _flowCtrl,
        _flareCtrl,
        _entryCtrl,
        _surgeCtrl,
        _fadeCtrl,
      ]),
      builder: (context, _) {
        // Smoothly interpolate warm/cool colors via TweenAnimationBuilder
        // handled by parent (no controller needed here â€” props carry the value)
        return Opacity(
          opacity: (1.0 - _fadeAnim.value).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: _entryScale.value,
            child: CustomPaint(
              painter: InfinityFlowPainter(
                flowValue:  _flowCtrl.value,
                flareValue: _flareCtrl.value,
                surgeValue: _surgeAnim.value,
                warmColor:  widget.warmColor,
                coolColor:  widget.coolColor,
                glowColor:  Colors.white,
                leftLabel:  widget.leftLabel,
                rightLabel: widget.rightLabel,
              ),
              // The widget fills whatever space it's given
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }
}




// ---------------------------------------------------------------------------
// THUNDER HALO WIDGET — Semi-circle halo + aggressive sky lightning
// ---------------------------------------------------------------------------
// Layout: bottom-anchored semi-circle arc (180 degrees, lower half hidden).
// Lightning: fractal recursive branching bolts — NOT tesla coil spirals.
// Each bolt grows from the halo edge outward, splits into 2-3 branches,
// each branch splits again — exactly like cloud-to-ground lightning.
// Bolt lifetime: 80-140ms. New bolt spawned every 60-120ms.
// Low-time mode (<10s): bolt spawn rate doubles, halo pulses red.

class ThunderHaloWidget extends StatefulWidget {
  final double progress;        // 1.0 = full, 0.0 = empty
  final String timeText;
  final String pctText;
  final Color accentColor;
  final VoidCallback? onComplete;

  const ThunderHaloWidget({
    super.key,
    required this.progress,
    required this.timeText,
    required this.pctText,
    required this.accentColor,
    this.onComplete,
  });

  @override
  State<ThunderHaloWidget> createState() => _ThunderHaloWidgetState();
}

class _ThunderHaloWidgetState extends State<ThunderHaloWidget>
    with TickerProviderStateMixin {
  late AnimationController _loopCtrl;  // drives everything
  late AnimationController _pulseCtrl; // low-time halo pulse

  final List<_SkyBolt> _bolts = [];
  final _rng = math.Random();

  // Timers for bolt scheduling
  int _frameCount = 0;
  int _nextSpawnFrame = 0;

  @override
  void initState() {
    super.initState();
    _loopCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 16))
      ..addListener(_onTick)
      ..repeat();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
  }

  void _onTick() {
    _frameCount++;
    // Remove expired bolts
    _bolts.removeWhere((b) => b.isExpired);

    // Spawn new bolt at scheduled frame
    if (_frameCount >= _nextSpawnFrame) {
      final isLowTime = widget.progress < 0.15;
      final intervalMin = isLowTime ? 3 : 6;
      final intervalMax = isLowTime ? 6 : 12;
      _nextSpawnFrame = _frameCount + intervalMin + _rng.nextInt(intervalMax - intervalMin);
      _spawnBolt();
    }
  }

  void _spawnBolt() {
    // Pick a random angle on the halo arc (semi-circle top — 210° to 330° = bottom cut out)
    // Full circle bolts look better for aggressiveness, bias towards top
    final angle = _rng.nextDouble() * 2 * math.pi;
    _bolts.add(_SkyBolt.generate(_rng, angle));
  }

  @override
  void dispose() {
    _loopCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLowTime  = widget.progress < 0.15;
    final haloColor  = isLowTime ? const Color(0xFFFF2222) : widget.accentColor;

    return AnimatedBuilder(
      animation: Listenable.merge([_loopCtrl, _pulseCtrl]),
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // ── Full-screen bolt painter ───────────────────────────────
            Positioned.fill(
              child: CustomPaint(
                painter: _SkyLightningPainter(
                  bolts:      _bolts,
                  accentColor: haloColor,
                ),
              ),
            ),

            // ── Semi-circle halo ───────────────────────────────────────
            Positioned.fill(
              child: CustomPaint(
                painter: _SemiHaloPainter(
                  progress:    widget.progress,
                  accentColor: haloColor,
                  pulse:       isLowTime ? _pulseCtrl.value : 0.0,
                ),
              ),
            ),

            // ── Centre text ────────────────────────────────────────────
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.timeText,
                  style: GoogleFonts.poppins(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                    shadows: [
                      Shadow(color: haloColor.withAlpha(140), blurRadius: 24),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                    color: haloColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: haloColor.withAlpha(80)),
                  ),
                  child: Text(
                    widget.pctText,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: haloColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEMI-CIRCLE HALO PAINTER
// Draws a progress arc (top semi-circle) with multi-layer glow.
// ─────────────────────────────────────────────────────────────────────────────

class _SemiHaloPainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final double pulse; // 0-1 for low-time pulsing

  const _SemiHaloPainter({
    required this.progress,
    required this.accentColor,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width  / 2;
    final cy = size.height / 2;
    final r  = math.min(cx, cy) * 0.86;

    const startAngle = -math.pi;       // left (9 o'clock)
    const sweepFull  = math.pi;        // top half only (180°)
    final sweep      = sweepFull * progress;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Outer glow (wide, soft)
    canvas.drawArc(rect, startAngle, sweepFull, false, Paint()
      ..color = accentColor.withAlpha((25 + (20 * pulse)).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28 + 8 * pulse
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));

    // Track
    canvas.drawArc(rect, startAngle, sweepFull, false, Paint()
      ..color = Colors.white.withAlpha(12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round);

    if (sweep > 0) {
      // Mid glow
      canvas.drawArc(rect, startAngle, sweep, false, Paint()
        ..color = accentColor.withAlpha(60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

      // Core arc
      canvas.drawArc(rect, startAngle, sweep, false, Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round);

      // Bright leading dot
      if (sweep > 0.02) {
        final tipAngle = startAngle + sweep;
        final tx = cx + r * math.cos(tipAngle);
        final ty = cy + r * math.sin(tipAngle);
        canvas.drawCircle(Offset(tx, ty), 7 + 3 * pulse,
          Paint()..color = Colors.white.withAlpha(230)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
        canvas.drawCircle(Offset(tx, ty), 4,
          Paint()..color = accentColor);
      }
    }

    // Trailing dot at start
    final sx = cx + r * math.cos(startAngle);
    final sy = cy + r * math.sin(startAngle);
    canvas.drawCircle(Offset(sx, sy), 4,
      Paint()..color = accentColor.withAlpha(100));
  }

  @override
  bool shouldRepaint(_SemiHaloPainter old) =>
      old.progress != progress || old.accentColor != accentColor || old.pulse != pulse;
}

// ─────────────────────────────────────────────────────────────────────────────
// SKY BOLT — fractal recursive branching lightning
// ─────────────────────────────────────────────────────────────────────────────

class _SkyBolt {
  final List<_BranchSegment> segments;
  int age = 0;
  final int lifetime; // frames

  _SkyBolt({required this.segments, required this.lifetime});

  bool get isExpired => age > lifetime;
  double get alpha   => (1.0 - age / lifetime).clamp(0.0, 1.0);

  void tick() => age++;

  factory _SkyBolt.generate(math.Random rng, double originAngle) {
    final segments = <_BranchSegment>[];
    // Start near a random point on the halo edge, going outward
    // halo radius ~0.32 of widget half-size, represented in unit coords
    const cx = 0.5; const cy = 0.5;
    const r  = 0.28; // halo radius in unit coords
    final sx = cx + r * math.cos(originAngle);
    final sy = cy + r * math.sin(originAngle);

    // Recursive branching — depth controls how many splits
    _buildBranch(rng, segments, sx, sy, originAngle, 0.14, 0, 3);

    final life = 5 + rng.nextInt(6); // 5-10 frames (~80-160ms at 60fps)
    return _SkyBolt(segments: segments, lifetime: life);
  }

  static void _buildBranch(
    math.Random rng,
    List<_BranchSegment> out,
    double x, double y,
    double angle,
    double length,
    int depth,
    int maxDepth,
  ) {
    if (depth > maxDepth || length < 0.015) return;

    // Jagged segments along this branch
    final steps = 3 + rng.nextInt(3);
    var cx = x; var cy = y;
    var curAngle = angle;
    final segLen = length / steps;

    for (int i = 0; i < steps; i++) {
      curAngle += (rng.nextDouble() - 0.5) * 0.9; // aggressive jitter
      final nx = cx + segLen * math.cos(curAngle);
      final ny = cy + segLen * math.sin(curAngle);
      out.add(_BranchSegment(x1: cx, y1: cy, x2: nx, y2: ny,
          isTrunk: depth == 0, isTip: (i == steps - 1 && depth == maxDepth)));
      cx = nx; cy = ny;
    }

    // Spawn 1-2 child branches from random midpoint
    final numChildren = depth < maxDepth - 1 ? 1 + rng.nextInt(2) : 1;
    for (int c = 0; c < numChildren; c++) {
      final branchAngle = curAngle + (rng.nextDouble() - 0.5) * 1.4;
      final branchLen   = length * (0.45 + rng.nextDouble() * 0.3);
      _buildBranch(rng, out, cx, cy, branchAngle, branchLen, depth + 1, maxDepth);
    }
  }
}

class _BranchSegment {
  final double x1, y1, x2, y2;
  final bool isTrunk;
  final bool isTip;
  const _BranchSegment({
    required this.x1, required this.y1,
    required this.x2, required this.y2,
    required this.isTrunk,
    required this.isTip,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SKY LIGHTNING PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _SkyLightningPainter extends CustomPainter {
  final List<_SkyBolt> bolts;
  final Color accentColor;

  const _SkyLightningPainter({
    required this.bolts,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;

    for (final bolt in bolts) {
      bolt.tick();
      if (bolt.segments.isEmpty) continue;
      final a = bolt.alpha;
      if (a <= 0) continue;

      for (final seg in bolt.segments) {
        final p1 = Offset(seg.x1 * w, seg.y1 * h);
        final p2 = Offset(seg.x2 * w, seg.y2 * h);

        // Glow layer
        canvas.drawLine(p1, p2, Paint()
          ..color = accentColor.withAlpha((40 * a).round())
          ..strokeWidth = seg.isTrunk ? 10 : 5
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

        // Core white bolt
        canvas.drawLine(p1, p2, Paint()
          ..color = Colors.white.withAlpha((180 * a).round())
          ..strokeWidth = seg.isTrunk ? 2.0 : 1.2
          ..strokeCap = StrokeCap.round);

        // Tip spark
        if (seg.isTip) {
          canvas.drawCircle(p2, 4 * a, Paint()
            ..color = Colors.white.withAlpha((220 * a).round())
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
        }
      }
    }
  }


  @override
  bool shouldRepaint(_SkyLightningPainter _) => true;
}

// ---------------------------------------------------------------------------
// THUNDER BALL DECAGON WIDGET
// Ball bounces randomly inside a DECAGON (10 sides) made of lightning edges.
// A thunder web of cross-vertex lightning threads fills the interior.
// On wall impact: explosive spark bursts. Tap anywhere = scale up 1 sec.
// Center: timer text glows in the active app accent color.
// ---------------------------------------------------------------------------

class ThunderBallHexWidget extends StatefulWidget {
  final Color accentColor;
  final Color secondaryColor;
  final String timeText;
  final String phaseLabel;

  const ThunderBallHexWidget({
    super.key,
    required this.accentColor,
    required this.secondaryColor,
    required this.timeText,
    required this.phaseLabel,
  });

  @override
  State<ThunderBallHexWidget> createState() => _ThunderBallHexState();
}

class _ThunderBallHexState extends State<ThunderBallHexWidget>
    with TickerProviderStateMixin {
  late AnimationController _physCtrl;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  final _rng = math.Random();

  // Ball state (unit coords 0-1, center=0.5,0.5)
  Offset _pos = const Offset(0.5, 0.5);
  Offset _vel = Offset.zero;
  bool _physInited = false;

  final List<_ImpactSpark> _sparks = [];
  List<List<Offset>> _decaEdgeSegs = [];  // decagon edges (jagged lightning)
  int _edgeRebuildFrame = 0;
  int _frameIdx = 0;

  static const int    _sides = 10;   // DECAGON — 10 sides
  static const double _decaR = 0.40; // radius in unit coords

  /// Returns the 10 equally-spaced corners of the decagon in unit coords.
  static List<Offset> _unitDecaCorners() {
    return List.generate(_sides, (i) {
      final angle = -math.pi / 2 + i * 2 * math.pi / _sides;
      return Offset(0.5 + _decaR * math.cos(angle),
                    0.5 + _decaR * math.sin(angle));
    });
  }

  @override
  void initState() {
    super.initState();
    _physCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8),
    )
      ..addListener(_tick)
      ..repeat();

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      reverseDuration: const Duration(milliseconds: 500),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut),
    );
  }

  void _initPhysics() {
    if (_physInited) return;
    _physInited = true;
    final angle = _rng.nextDouble() * 2 * math.pi;
    const speed = 0.0038;
    _vel = Offset(math.cos(angle) * speed, math.sin(angle) * speed);
    _rebuildDecaEdgeSegs();
  }

  void _tick() {
    _frameIdx++;
    if (_frameIdx - _edgeRebuildFrame >= 3) {
      _edgeRebuildFrame = _frameIdx;
      _rebuildDecaEdgeSegs();
    }

    var nx = _pos.dx + _vel.dx;
    var ny = _pos.dy + _vel.dy;
    var vx = _vel.dx;
    var vy = _vel.dy;

    final corners = _unitDecaCorners();
    for (int i = 0; i < _sides; i++) {
      final a = corners[i];
      final b = corners[(i + 1) % _sides];
      final ex = b.dx - a.dx;
      final ey = b.dy - a.dy;
      final len = math.sqrt(ex * ex + ey * ey);
      final inx = -ey / len;
      final iny =  ex / len;
      final dist = (nx - a.dx) * inx + (ny - a.dy) * iny;
      if (dist < 0.038) {
        final dot = vx * inx + vy * iny;
        vx -= 2 * dot * inx;
        vy -= 2 * dot * iny;
        nx += inx * (0.038 - dist);
        ny += iny * (0.038 - dist);
        _spawnSparks(Offset(nx, ny), Offset(inx, iny));
        break;
      }
    }

    _pos = Offset(nx, ny);
    _vel = Offset(vx, vy);
    _sparks.removeWhere((s) => s.isDead);
    for (final s in _sparks) { s.advance(); }
  }

  void _spawnSparks(Offset pos, Offset normal) {
    final count = 9 + _rng.nextInt(10);
    for (int i = 0; i < count; i++) {
      final angle = math.atan2(normal.dy, normal.dx) +
          (_rng.nextDouble() - 0.5) * math.pi * 1.5;
      final speed = 0.003 + _rng.nextDouble() * 0.009;
      _sparks.add(_ImpactSpark(
        pos: pos,
        vel: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
        life: 10 + _rng.nextInt(14),
      ));
    }
  }

  void _rebuildDecaEdgeSegs() {
    final corners = _unitDecaCorners();
    _decaEdgeSegs = List.generate(_sides, (i) =>
        _jaggedEdge(corners[i], corners[(i + 1) % _sides]));
  }

  List<Offset> _jaggedEdge(Offset a, Offset b) {
    final pts = <Offset>[a];
    const steps = 8;
    final ex = b.dx - a.dx;
    final ey = b.dy - a.dy;
    final len = math.sqrt(ex * ex + ey * ey);
    final px = -ey / len;
    final py =  ex / len;
    for (int i = 1; i < steps; i++) {
      final t = i / steps;
      final jitter = (_rng.nextDouble() - 0.5) * 0.048;
      pts.add(Offset(
        a.dx + ex * t + px * jitter,
        a.dy + ey * t + py * jitter,
      ));
    }
    pts.add(b);
    return pts;
  }

  @override
  void dispose() {
    _physCtrl.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _initPhysics();
    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp:   (_) => _scaleCtrl.reverse(),
      onTapCancel: () => _scaleCtrl.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_physCtrl, _scaleCtrl]),
        builder: (context, _) => Transform.scale(
          scale: _scaleAnim.value,
          child: CustomPaint(
            painter: _ThunderBallPainter(
              pos:          _pos,
              sparks:       List.from(_sparks),
              decaEdgeSegs: _decaEdgeSegs,
              accent:       widget.accentColor,
              secondary:    widget.secondaryColor,
              timeText:     widget.timeText,
              phaseLabel:   widget.phaseLabel,
              frameIdx:     _frameIdx,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

// ── Impact spark ─────────────────────────────────────────────────────────────
class _ImpactSpark {
  Offset pos;
  Offset vel;
  int life;
  final int maxLife;
  _ImpactSpark({required this.pos, required this.vel, required this.life})
      : maxLife = life;
  bool get isDead => life <= 0;
  double get alpha => (life / maxLife).clamp(0.0, 1.0);
  void advance() {
    pos = pos + vel;
    vel = vel * 0.86;
    life--;
  }
}

// ── Thunder Ball Painter (Decagon + Thunder Web) ──────────────────────────────
class _ThunderBallPainter extends CustomPainter {
  final Offset pos;
  final List<_ImpactSpark> sparks;
  final List<List<Offset>> decaEdgeSegs;  // renamed from hexEdgeSegs
  final Color accent;
  final Color secondary;
  final String timeText;
  final String phaseLabel;
  final int frameIdx;

  static const int    _sides = 10;
  static const double _decaR = 0.40;

  _ThunderBallPainter({
    required this.pos,
    required this.sparks,
    required this.decaEdgeSegs,
    required this.accent,
    required this.secondary,
    required this.timeText,
    required this.phaseLabel,
    required this.frameIdx,
  });

  Offset _d(Offset n, Size s) => Offset(n.dx * s.width, n.dy * s.height);

  /// Pixel position of decagon vertex [i] for a given canvas size.
  Offset _vertex(int i, Size size) {
    final angle = -math.pi / 2 + i * 2 * math.pi / _sides;
    return _d(Offset(0.5 + _decaR * math.cos(angle),
                     0.5 + _decaR * math.sin(angle)), size);
  }

  /// Draw a single jagged lightning segment between two pixel points.
  void _drawWebThread(Canvas canvas, Offset a, Offset b,
      math.Random rng, double alphaFactor) {
    const steps = 7;
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    final px = -dy / len;
    final py =  dx / len;

    final pts = <Offset>[a];
    for (int i = 1; i < steps; i++) {
      final t = i / steps;
      final jitter = (rng.nextDouble() - 0.5) * len * 0.11;
      pts.add(Offset(a.dx + dx * t + px * jitter,
                     a.dy + dy * t + py * jitter));
    }
    pts.add(b);

    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) { path.lineTo(pts[i].dx, pts[i].dy); }

    // Outer bloom
    canvas.drawPath(path, Paint()
      ..color = accent.withAlpha((22 * alphaFactor).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    // Colored core
    canvas.drawPath(path, Paint()
      ..color = accent.withAlpha((90 * alphaFactor).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round);
    // White highlight
    canvas.drawPath(path, Paint()
      ..color = Colors.white.withAlpha((60 * alphaFactor).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);

    // ── 1. Decagon outer glow (ambient halo) ─────────────────────────────────
    final decaPath = Path();
    for (int i = 0; i < _sides; i++) {
      final v = _vertex(i, size);
      if (i == 0) decaPath.moveTo(v.dx, v.dy);
      else decaPath.lineTo(v.dx, v.dy);
    }
    decaPath.close();
    canvas.drawPath(decaPath, Paint()
      ..color = accent.withAlpha(14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 32
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));

    // ── 2. Decagon lightning edges (jagged) ──────────────────────────────────
    for (final seg in decaEdgeSegs) {
      if (seg.length < 2) continue;
      final pts = seg.map((p) => _d(p, size)).toList();
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (int i = 1; i < pts.length; i++) { path.lineTo(pts[i].dx, pts[i].dy); }

      // Outer bloom
      canvas.drawPath(path, Paint()
        ..color = accent.withAlpha(30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
      // Mid glow
      canvas.drawPath(path, Paint()
        ..color = accent.withAlpha(90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      // White core
      canvas.drawPath(path, Paint()
        ..color = Colors.white.withAlpha(210)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round);
    }

    // ── 3. Vertex spark nodes ────────────────────────────────────────────────
    for (int i = 0; i < _sides; i++) {
      final v = _vertex(i, size);
      canvas.drawCircle(v, 8, Paint()
        ..color = accent.withAlpha(55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
      canvas.drawCircle(v, 2.5, Paint()..color = Colors.white.withAlpha(220));
    }

    // ── 4. THUNDER WEB — cross-vertex lightning threads ───────────────────────
    // Seeded RNG: each frame group picks a fixed set of vertex pairs.
    // We use multiple seed steps so the web visibly flickers.
    final rngW = math.Random(frameIdx ~/ 4);
    const numWebThreads = 8;  // number of internal web connections
    for (int t = 0; t < numWebThreads; t++) {
      final iA = rngW.nextInt(_sides);
      // Skip adjacent vertices (those are the edges already drawn)
      int iB = rngW.nextInt(_sides - 3) + iA + 2;
      iB = iB % _sides;
      if (iB == iA) continue;

      final vA = _vertex(iA, size);
      final vB = _vertex(iB, size);
      final threadRng = math.Random(frameIdx ~/ 4 + t * 7);
      // Alternating alpha so threads breathe / flicker at different rates
      final alphaFactor = 0.35 + 0.65 * (math.sin(frameIdx * 0.08 + t * 1.2) * 0.5 + 0.5);
      _drawWebThread(canvas, vA, vB, threadRng, alphaFactor);
    }

    // Hub spokes — 5 threads from center to random vertices (star pattern)
    final rngS = math.Random(frameIdx ~/ 6);
    for (int s = 0; s < 5; s++) {
      final vi = rngS.nextInt(_sides);
      final v  = _vertex(vi, size);
      final spokeRng  = math.Random(frameIdx ~/ 6 + s * 13);
      final spokeAlpha = 0.20 + 0.40 * (math.sin(frameIdx * 0.06 + s * 2.1) * 0.5 + 0.5);
      _drawWebThread(canvas, center, v, spokeRng, spokeAlpha);
    }

    // ── 5. Random ambient sparks inside (flicker with seeded rng) ────────────
    final rngA = math.Random(frameIdx ~/ 3);
    for (int i = 0; i < 8; i++) {
      final sx = 0.18 + rngA.nextDouble() * 0.64;
      final sy = 0.20 + rngA.nextDouble() * 0.60;
      final sp = _d(Offset(sx, sy), size);
      final a = 0.3 + rngA.nextDouble() * 0.7;
      canvas.drawCircle(sp, 1.5 + rngA.nextDouble() * 2.5, Paint()
        ..color = accent.withAlpha((a * 110).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawCircle(sp, 0.8, Paint()
        ..color = Colors.white.withAlpha((a * 150).round()));
    }

    // ── 6. Impact sparks (wall smash bursts) ─────────────────────────────────
    for (final spark in sparks) {
      final sp = _d(spark.pos, size);
      final a = spark.alpha;
      canvas.drawCircle(sp, 9 * a, Paint()
        ..color = accent.withAlpha((a * 90).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
      canvas.drawCircle(sp, 3.5 * a, Paint()
        ..color = Colors.white.withAlpha((a * 230).round()));
      if (spark.vel.distance > 0.0001) {
        final tail = sp - Offset(
          spark.vel.dx * size.width  * 7,
          spark.vel.dy * size.height * 7,
        );
        canvas.drawLine(tail, sp, Paint()
          ..color = accent.withAlpha((a * 170).round())
          ..strokeWidth = 2.0 * a
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5 * a));
        canvas.drawLine(tail, sp, Paint()
          ..color = Colors.white.withAlpha((a * 140).round())
          ..strokeWidth = 0.9 * a
          ..strokeCap = StrokeCap.round);
      }
    }

    // ── 7. Ball with radiating mini-lightning ─────────────────────────────────
    final ballPos = _d(pos, size);
    const ballR = 12.0;

    canvas.drawCircle(ballPos, ballR * 3.0, Paint()
      ..color = accent.withAlpha(35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22));
    canvas.drawCircle(ballPos, ballR * 1.7, Paint()
      ..color = accent.withAlpha(95)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
    canvas.drawCircle(ballPos, ballR, Paint()
      ..shader = ui.Gradient.radial(
        ballPos - const Offset(3, 3), ballR * 0.65,
        [Colors.white, accent, secondary],
        [0.0, 0.5, 1.0],
      ));

    // Mini lightning bolts from ball
    final rngB = math.Random(frameIdx ~/ 2);
    final numBolts = 3 + rngB.nextInt(4);
    for (int i = 0; i < numBolts; i++) {
      final boltAngle = rngB.nextDouble() * 2 * math.pi;
      final boltLen = 18.0 + rngB.nextDouble() * 30.0;
      _miniLightning(canvas, ballPos, boltAngle, boltLen, rngB);
    }

    // ── 8. Centre text — timer glows in accent color ──────────────────────────
    _drawCentreText(canvas, size, center);
  }

  void _miniLightning(Canvas canvas, Offset origin, double angle,
      double length, math.Random rng) {
    var x = origin.dx;
    var y = origin.dy;
    var cur = angle;
    const steps = 5;
    final seg = length / steps;
    var prev = origin;
    for (int i = 0; i < steps; i++) {
      cur += (rng.nextDouble() - 0.5) * 1.2;
      x += math.cos(cur) * seg;
      y += math.sin(cur) * seg;
      final next = Offset(x, y);
      canvas.drawLine(prev, next, Paint()
        ..color = accent.withAlpha(55)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawLine(prev, next, Paint()
        ..color = Colors.white.withAlpha(170)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round);
      prev = next;
    }
  }

  void _drawCentreText(Canvas canvas, Size size, Offset center) {
    // Multi-layer accent glow behind the timer — the key visual upgrade.
    // Outermost diffuse halo
    canvas.drawCircle(center, 90, Paint()
      ..color = accent.withAlpha(14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40));
    // Mid bloom
    canvas.drawCircle(center, 60, Paint()
      ..color = accent.withAlpha(25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24));
    // Inner core glow
    canvas.drawCircle(center, 40, Paint()
      ..color = accent.withAlpha(38)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
    // Tight center pulse
    final pulseAlpha = (35 + 20 * math.sin(frameIdx * 0.12)).round();
    canvas.drawCircle(center, 28, Paint()
      ..color = accent.withAlpha(pulseAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Time text — white with strong accent shadow + glow
    final tp = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.center, maxLines: 1))
      ..pushStyle(ui.TextStyle(
        color: Colors.white,
        fontSize: 46,
        fontWeight: ui.FontWeight.w900,
        letterSpacing: -1.0,
        shadows: [
          ui.Shadow(color: accent,                blurRadius: 32),
          ui.Shadow(color: accent.withAlpha(180), blurRadius: 16),
          ui.Shadow(color: Colors.white.withAlpha(80), blurRadius: 4),
        ],
      ))
      ..addText(timeText);
    final tPara = tp.build()
      ..layout(ui.ParagraphConstraints(width: size.width * 0.72));
    canvas.drawParagraph(
        tPara, Offset(center.dx - tPara.longestLine / 2, center.dy - tPara.height - 4));

    // Phase label — accent color with glow
    final lp = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.center, maxLines: 1))
      ..pushStyle(ui.TextStyle(
        color: accent,
        fontSize: 13,
        fontWeight: ui.FontWeight.w700,
        letterSpacing: 2.5,
        shadows: [
          ui.Shadow(color: accent.withAlpha(200), blurRadius: 12),
        ],
      ))
      ..addText(phaseLabel);
    final lPara = lp.build()
      ..layout(ui.ParagraphConstraints(width: size.width * 0.5));
    canvas.drawParagraph(
        lPara, Offset(center.dx - lPara.longestLine / 2, center.dy + 8));
  }

  @override
  bool shouldRepaint(_ThunderBallPainter old) => true;
}
