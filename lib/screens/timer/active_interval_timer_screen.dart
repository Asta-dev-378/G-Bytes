import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/interval_timer_provider.dart';

class ActiveIntervalTimerScreen extends StatefulWidget {
  const ActiveIntervalTimerScreen({super.key});

  @override
  State<ActiveIntervalTimerScreen> createState() =>
      _ActiveIntervalTimerScreenState();
}

class _ActiveIntervalTimerScreenState extends State<ActiveIntervalTimerScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _rotateCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _glowAnim = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<IntervalTimerProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWork = timer.phase == IntervalPhase.work;
    final orange = isDark ? Colors.orangeAccent : const Color(0xFFFF8C00);
    final restColor = isDark
        ? const Color(0xFF00E5FF)
        : const Color(0xFF00BCD4);
    final activeColor = isWork ? orange : restColor;

    // Circular progress
    final totalSeconds = isWork ? timer.workSeconds : timer.restSeconds;
    final progress = totalSeconds > 0
        ? timer.remainingSeconds / totalSeconds
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () {
            timer.stopWorkout();
            Navigator.pop(context);
          },
        ),
        title: Column(
          children: [
            Text(
              'INTERVAL TIMER',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Colors.white54,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'Round ${timer.currentRound}/${timer.totalRounds}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: activeColor,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _pulseCtrl,
                    _rotateCtrl,
                    _glowCtrl,
                  ]),
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // ── Outermost glow tentacles (jellyfish trailing effect) ──
                        Transform.rotate(
                          angle: _rotateCtrl.value * 2 * pi,
                          child: CustomPaint(
                            painter: _JellyfishTentaclePainter(
                              progress: _rotateCtrl.value,
                              glowOpacity: _glowAnim.value,
                              color: activeColor,
                              isActive: timer.isRunning,
                            ),
                            size: const Size(310, 310),
                          ),
                        ),

                        // ── Outer soft glow rings ──
                        ...List.generate(4, (i) {
                          final delay = i * 0.15;
                          final ringScale =
                              _pulseAnim.value + i * 0.08 + delay * 0.02;
                          final opacity = (_glowAnim.value * (0.25 - i * 0.05))
                              .clamp(0.0, 1.0);
                          return Transform.scale(
                            scale: ringScale,
                            child: Container(
                              width: 220 + i * 28.0,
                              height: 220 + i * 28.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: activeColor.withValues(alpha: opacity),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: activeColor.withValues(
                                      alpha: opacity * 0.6,
                                    ),
                                    blurRadius: 20 + i * 8.0,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        // ── Progress ring ──
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: CustomPaint(
                            painter: _ProgressRingPainter(
                              progress: progress.toDouble(),
                              color: activeColor,
                              glowOpacity: _glowAnim.value,
                            ),
                          ),
                        ),

                        // ── Inner jellyfish bell (the solid glowing core) ──
                        Transform.scale(
                          scale: _pulseAnim.value,
                          child: Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  activeColor.withValues(alpha: 0.45),
                                  activeColor.withValues(alpha: 0.15),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.6, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: activeColor.withValues(
                                    alpha: _glowAnim.value * 0.6,
                                  ),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                                BoxShadow(
                                  color: activeColor.withValues(
                                    alpha: _glowAnim.value * 0.3,
                                  ),
                                  blurRadius: 80,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ── Timer text ──
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(timer.remainingSeconds),
                              style: GoogleFonts.russoOne(
                                fontSize: 62,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 3,
                                shadows: [
                                  Shadow(
                                    color: activeColor.withValues(alpha: 0.9),
                                    blurRadius: 24,
                                  ),
                                  Shadow(
                                    color: activeColor.withValues(alpha: 0.5),
                                    blurRadius: 60,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: activeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: activeColor.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                isWork ? 'WORK' : 'REST',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: activeColor,
                                  letterSpacing: 2.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Phase info strip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _PhaseChip(
                    label: 'Work',
                    value: '${timer.workSeconds}s',
                    isActive: isWork,
                    color: orange,
                  ),
                  Container(width: 1, height: 30, color: Colors.white24),
                  _PhaseChip(
                    label: 'Rest',
                    value: '${timer.restSeconds}s',
                    isActive: !isWork,
                    color: restColor,
                  ),
                  Container(width: 1, height: 30, color: Colors.white24),
                  _PhaseChip(
                    label: 'Round',
                    value: '${timer.currentRound}/${timer.totalRounds}',
                    isActive: false,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Controls Bottom
            Padding(
              padding: const EdgeInsets.only(bottom: 44),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ControlButton(
                    icon: timer.isRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    label: timer.isRunning ? 'Pause' : 'Resume',
                    onTap: timer.pauseResume,
                    isSecondary: true,
                    activeColor: orange,
                  ),
                  _ControlButton(
                    icon: Icons.stop_rounded,
                    label: 'Stop',
                    onTap: () {
                      timer.stopWorkout();
                      Navigator.pop(context);
                    },
                    isPrimary: true,
                    activeColor: orange,
                  ),
                  _ControlButton(
                    icon: Icons.refresh_rounded,
                    label: 'Restart',
                    onTap: () {
                      timer.stopWorkout();
                      timer.startWorkout();
                    },
                    isSecondary: true,
                    activeColor: orange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _PhaseChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isActive;
  final Color color;

  const _PhaseChip({
    required this.label,
    required this.value,
    required this.isActive,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.white38,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isActive ? color : Colors.white60,
          ),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isSecondary;
  final Color activeColor;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.activeColor,
    this.isPrimary = false,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPrimary
        ? activeColor
        : Colors.white.withValues(alpha: 0.08);
    final iconColor = isPrimary ? Colors.white : Colors.white70;
    final size = isPrimary ? 76.0 : 60.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isPrimary ? Colors.transparent : Colors.white24,
                width: 1,
              ),
              boxShadow: [
                if (isPrimary)
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.5),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: isPrimary ? 30 : 24),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: isPrimary ? activeColor : Colors.white38,
          ),
        ),
      ],
    );
  }
}

// ── Progress Ring Painter ─────────────────────────────────────────────
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double glowOpacity;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.glowOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Glow shadow for progress arc
    final glowPaint = Paint()
      ..color = color.withValues(alpha: glowOpacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final sweep = 2 * pi * progress;
    const start = -pi / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      glowPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress ||
      old.glowOpacity != glowOpacity ||
      old.color != color;
}

// ── Jellyfish Tentacle Painter ──────────────────────────────────────
class _JellyfishTentaclePainter extends CustomPainter {
  final double progress;
  final double glowOpacity;
  final Color color;
  final bool isActive;

  _JellyfishTentaclePainter({
    required this.progress,
    required this.glowOpacity,
    required this.color,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rng = Random(42);
    const numTentacles = 14;

    for (int i = 0; i < numTentacles; i++) {
      final baseAngle = (i / numTentacles) * 2 * pi;
      final waveOffset = isActive ? sin(progress * 2 * pi + i * 0.7) * 15 : 0;
      final len = 55.0 + rng.nextDouble() * 35 + waveOffset;
      final startR = 100.0;
      final endR = startR + len;

      final opacity = glowOpacity * (0.15 + rng.nextDouble() * 0.2);

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..strokeWidth = 1.5 + rng.nextDouble() * 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          3 + rng.nextDouble() * 4,
        );

      // Wavy tentacle using a cubic bezier
      final angle1 =
          baseAngle + (isActive ? sin(progress * pi * 3 + i) * 0.2 : 0);
      final cp1x = center.dx + cos(angle1 + 0.15) * (startR + len * 0.3);
      final cp1y = center.dy + sin(angle1 + 0.15) * (startR + len * 0.3);
      final cp2x = center.dx + cos(angle1 - 0.15) * (startR + len * 0.65);
      final cp2y = center.dy + sin(angle1 - 0.15) * (startR + len * 0.65);

      final path = Path()
        ..moveTo(
          center.dx + cos(baseAngle) * startR,
          center.dy + sin(baseAngle) * startR,
        )
        ..cubicTo(
          cp1x,
          cp1y,
          cp2x,
          cp2y,
          center.dx + cos(angle1) * endR,
          center.dy + sin(angle1) * endR,
        );

      canvas.drawPath(path, paint);
    }

    // Scattered glow dots around the outer ring
    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 40; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final r = 90 + rng.nextDouble() * 70;
      if (isActive) {
        final drift = sin(progress * pi * 2 + i) * 6;
        final x = center.dx + cos(angle) * (r + drift);
        final y = center.dy + sin(angle) * (r + drift);
        dotPaint.color = color.withValues(
          alpha: glowOpacity * (rng.nextDouble() * 0.35 + 0.05),
        );
        canvas.drawCircle(Offset(x, y), 1 + rng.nextDouble() * 2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _JellyfishTentaclePainter old) =>
      old.progress != progress ||
      old.glowOpacity != glowOpacity ||
      old.isActive != isActive ||
      old.color != color;
}
