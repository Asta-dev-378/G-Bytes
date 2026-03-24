import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/interval_timer_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/music_provider.dart';

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
  late AnimationController _burstCtrl; // for bubble burst on phase change
  late Animation<double> _pulseAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _burstAnim;

  IntervalPhase? _lastPhase;
  bool _bursting = false;

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

    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseAnim = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _glowAnim = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _burstAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _burstCtrl, curve: Curves.easeOut));

    // Set up workout completion callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timerProvider = context.read<IntervalTimerProvider>();
      timerProvider.onWorkoutComplete = _handleWorkoutComplete;
    });
  }

  void _handleWorkoutComplete() {
    final gameProvider = context.read<GameProvider>();
    gameProvider.completeWorkout();

    // Auto-navigate back after a short delay for visual feedback
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _glowCtrl.dispose();
    _burstCtrl.dispose();
    super.dispose();
  }

  void _triggerBurst() {
    _bursting = true;
    _burstCtrl.forward(from: 0).then((_) {
      if (mounted) setState(() => _bursting = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<IntervalTimerProvider>();
    final settings = context.watch<SettingsProvider>();

    // Sync sound setting
    timer.soundEnabled = settings.soundEffectsEnabled;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWork = timer.phase == IntervalPhase.work;
    final orange = settings.appSeedColor; // uses selected theme color
    final restColor = isDark
        ? const Color(0xFF00E5FF)
        : const Color(0xFF00BCD4);
    final activeColor = isWork ? orange : restColor;

    // Detect phase change → trigger burst animation
    if (_lastPhase != null && _lastPhase != timer.phase) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _triggerBurst());
    }
    _lastPhase = timer.phase;

    // Circular progress
    final totalSeconds = isWork ? timer.workSeconds : timer.restSeconds;
    final progress = totalSeconds > 0
        ? timer.remainingSeconds / totalSeconds
        : 0.0;

    final animationType = settings.timerAnimation;

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
              'G-TIMER',
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
      body: Stack(
        children: [
          // ── Main timer content ──────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _pulseCtrl,
                        _rotateCtrl,
                        _glowCtrl,
                        _burstCtrl,
                      ]),
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // ── Background animation based on selected type ──
                            if (animationType == TimerAnimationType.jellyfish)
                              _buildJellyfishAnimation(timer, activeColor)
                            else if (animationType ==
                                TimerAnimationType.bubbleBurst)
                              _buildBubbleBurstAnimation(timer, activeColor)
                            else
                              _buildStarDustAnimation(timer, activeColor),

                            // ── Progress ring (shared) ──
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

                            // ── Burst overlay on phase change ──
                            if (_bursting) _buildBurstOverlay(activeColor),

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
                                        color: activeColor.withValues(
                                          alpha: 0.9,
                                        ),
                                        blurRadius: 24,
                                      ),
                                      Shadow(
                                        color: activeColor.withValues(
                                          alpha: 0.5,
                                        ),
                                        blurRadius: 60,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeInOut,
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
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 400),
                                    child: Text(
                                      isWork ? 'WORK' : 'REST',
                                      key: ValueKey(isWork),
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: activeColor,
                                        letterSpacing: 2.5,
                                      ),
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
        ],
      ),
    );
  }

  // ── JELLYFISH Animation ──────────────────────────────────────────
  Widget _buildJellyfishAnimation(
    IntervalTimerProvider timer,
    Color activeColor,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer rotating tentacles
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
        // Outer soft glow rings
        ...List.generate(4, (i) {
          final ringScale = _pulseAnim.value + i * 0.08;
          final opacity = (_glowAnim.value * (0.25 - i * 0.05)).clamp(0.0, 1.0);
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
                    color: activeColor.withValues(alpha: opacity * 0.6),
                    blurRadius: 20 + i * 8.0,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          );
        }),
        // Inner glowing core
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
                  color: activeColor.withValues(alpha: _glowAnim.value * 0.6),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: activeColor.withValues(alpha: _glowAnim.value * 0.3),
                  blurRadius: 80,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── BUBBLE BURST Animation ───────────────────────────────────────
  Widget _buildBubbleBurstAnimation(
    IntervalTimerProvider timer,
    Color activeColor,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Animated bubble rings expanding outward
        ...List.generate(5, (i) {
          final offset = i / 5.0;
          final t = (_rotateCtrl.value + offset) % 1.0;
          final scale = 0.3 + t * 1.5;
          final opacity = (1.0 - t).clamp(0.0, 1.0) * 0.5;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: activeColor.withValues(alpha: opacity),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withValues(alpha: opacity * 0.4),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
          );
        }),
        // Floating bubble particles
        CustomPaint(
          painter: _BubblePainter(
            progress: _rotateCtrl.value,
            glowOpacity: _glowAnim.value,
            color: activeColor,
            isActive: timer.isRunning,
          ),
          size: const Size(320, 320),
        ),
        // Pulsing core
        Transform.scale(
          scale: _pulseAnim.value,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  activeColor.withValues(alpha: 0.5),
                  activeColor.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: _glowAnim.value * 0.7),
                  blurRadius: 50,
                  spreadRadius: 15,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── STAR DUST Animation ──────────────────────────────────────────
  Widget _buildStarDustAnimation(
    IntervalTimerProvider timer,
    Color activeColor,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          painter: _StarDustPainter(
            progress: _rotateCtrl.value,
            glowOpacity: _glowAnim.value,
            color: activeColor,
            isActive: timer.isRunning,
          ),
          size: const Size(340, 340),
        ),
        // Dual rotating arcs
        Transform.rotate(
          angle: _rotateCtrl.value * 2 * pi,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: activeColor.withValues(alpha: _glowAnim.value * 0.3),
                width: 1,
              ),
            ),
          ),
        ),
        Transform.rotate(
          angle: -_rotateCtrl.value * 2 * pi * 0.7,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: activeColor.withValues(alpha: _glowAnim.value * 0.2),
                width: 1,
              ),
            ),
          ),
        ),
        // Core glow
        Transform.scale(
          scale: _pulseAnim.value,
          child: Container(
            width: 155,
            height: 155,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  activeColor.withValues(alpha: 0.4),
                  activeColor.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: _glowAnim.value * 0.55),
                  blurRadius: 45,
                  spreadRadius: 12,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Phase change burst overlay ──────────────────────────────────
  Widget _buildBurstOverlay(Color activeColor) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _BurstPainter(progress: _burstAnim.value, color: activeColor),
        size: const Size(380, 380),
      ),
    );
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// ── Phase Chip ──────────────────────────────────────────────────────
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

// ── Control Button ──────────────────────────────────────────────────
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

    // Glow shadow
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
      const startR = 100.0;
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

    // Scattered glow dots
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

// ── Bubble Painter ──────────────────────────────────────────────────
class _BubblePainter extends CustomPainter {
  final double progress;
  final double glowOpacity;
  final Color color;
  final bool isActive;

  _BubblePainter({
    required this.progress,
    required this.glowOpacity,
    required this.color,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rng = Random(99);
    const bubbleCount = 18;

    for (int i = 0; i < bubbleCount; i++) {
      final seed = rng.nextDouble();
      final baseAngle = (i / bubbleCount) * 2 * pi + seed * 0.5;
      final t = (progress + i / bubbleCount) % 1.0;
      final r = 80 + seed * 70;
      final wobble = isActive ? sin(progress * pi * 2 + i * 1.3) * 10 : 0;
      final x = center.dx + cos(baseAngle) * (r + wobble);
      final y = center.dy + sin(baseAngle) * (r + wobble);
      final bubbleR = 3 + seed * 8;
      final opacity = glowOpacity * (0.1 + (1.0 - t) * 0.4);

      // Draw bubble
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(x, y), bubbleR, paint);

      // Inner bubble shine
      final shinePaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.5)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(x - bubbleR * 0.25, y - bubbleR * 0.25),
        bubbleR * 0.25,
        shinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) =>
      old.progress != progress ||
      old.glowOpacity != glowOpacity ||
      old.isActive != isActive ||
      old.color != color;
}

// ── Star Dust Painter ───────────────────────────────────────────────
class _StarDustPainter extends CustomPainter {
  final double progress;
  final double glowOpacity;
  final Color color;
  final bool isActive;

  _StarDustPainter({
    required this.progress,
    required this.glowOpacity,
    required this.color,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rng = Random(77);
    const starCount = 60;

    for (int i = 0; i < starCount; i++) {
      final seed = rng.nextDouble();
      final baseAngle = rng.nextDouble() * 2 * pi;
      final baseR = 60 + rng.nextDouble() * 110;
      final twinkle = isActive ? sin(progress * pi * 4 + i * 0.8) : 0;
      final r = baseR + twinkle * 8;
      final x = center.dx + cos(baseAngle + progress * 0.5) * r;
      final y = center.dy + sin(baseAngle + progress * 0.5) * r;
      final starSize = 0.5 + seed * 3.0;
      final opacity =
          glowOpacity * (0.2 + seed * 0.5 + twinkle * 0.15).clamp(0.0, 0.85);

      // Draw star glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: opacity * 0.4)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, starSize * 2);
      canvas.drawCircle(Offset(x, y), starSize * 2, glowPaint);

      // Draw star core
      final starPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), starSize, starPaint);
    }

    // Draw shooting star trails
    for (int i = 0; i < 4; i++) {
      final trailProgress = (progress + i * 0.25) % 1.0;
      final angle = (i / 4) * 2 * pi + progress * pi;
      final startR = 50.0;
      final endR = 140.0;
      final sx =
          center.dx + cos(angle) * (startR + trailProgress * (endR - startR));
      final sy =
          center.dy + sin(angle) * (startR + trailProgress * (endR - startR));
      final ex = sx + cos(angle) * 20;
      final ey = sy + sin(angle) * 20;
      final trailOpacity = (glowOpacity * (1.0 - trailProgress) * 0.7).clamp(
        0.0,
        0.7,
      );
      if (!isActive) continue;
      final trailPaint = Paint()
        ..color = color.withValues(alpha: trailOpacity)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawLine(Offset(sx, sy), Offset(ex, ey), trailPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarDustPainter old) =>
      old.progress != progress ||
      old.glowOpacity != glowOpacity ||
      old.isActive != isActive ||
      old.color != color;
}

// ── Burst Painter (phase transition effect) ─────────────────────────
class _BurstPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0
  final Color color;

  _BurstPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const numRays = 16;

    for (int i = 0; i < numRays; i++) {
      final angle = (i / numRays) * 2 * pi;
      final innerR = 80.0 + progress * 60;
      final outerR = innerR + 20 + progress * 100;
      final opacity = (1.0 - progress).clamp(0.0, 1.0) * 0.8;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawLine(
        Offset(
          center.dx + cos(angle) * innerR,
          center.dy + sin(angle) * innerR,
        ),
        Offset(
          center.dx + cos(angle) * outerR,
          center.dy + sin(angle) * outerR,
        ),
        paint,
      );
    }

    // Expanding burst ring
    final ringPaint = Paint()
      ..color = color.withValues(alpha: (1.0 - progress).clamp(0.0, 0.6))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, 80 + progress * 150, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) =>
      old.progress != progress || old.color != color;
}

// ══════════════════════════════════════════════════════════════════════
// Dynamic Island Music Control
// Floating pill at top-right of the timer screen. Tap to expand/collapse.
// ══════════════════════════════════════════════════════════════════════

class _DynamicIslandMusicControl extends StatefulWidget {
  const _DynamicIslandMusicControl();

  @override
  State<_DynamicIslandMusicControl> createState() =>
      _DynamicIslandMusicControlState();
}

class _DynamicIslandMusicControlState extends State<_DynamicIslandMusicControl>
    with TickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _expandCtrl;
  late Animation<double> _expandAnim;
  late List<AnimationController> _barCtrls;
  late List<Animation<double>> _barAnims;

  static const _barColors = [
    Color(0xFFFF4081),
    Color(0xFFFF8C00),
    Color(0xFFFFD600),
    Color(0xFF00E5FF),
    Color(0xFF7C4DFF),
  ];

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _expandAnim = CurvedAnimation(
      parent: _expandCtrl,
      curve: Curves.easeInOutCubic,
    );

    _barCtrls = List.generate(5, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 320 + i * 80),
      );
    });
    _barAnims = List.generate(5, (i) {
      return Tween<double>(
        begin: 0.12,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _barCtrls[i], curve: Curves.easeInOut));
    });
  }

  void _syncBars(bool playing) {
    for (int i = 0; i < _barCtrls.length; i++) {
      if (playing) {
        if (!_barCtrls[i].isAnimating) _barCtrls[i].repeat(reverse: true);
      } else {
        _barCtrls[i].stop();
      }
    }
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _expandCtrl.forward();
    } else {
      _expandCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    for (final c in _barCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    final isPlaying = music.isPlaying;
    final trackTitle = music.current?.title ?? 'No track';
    final trackColor = Color(music.colorValue);

    _syncBars(isPlaying);

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _expandAnim,
        builder: (context2, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeInOutCubic,
            width: _expanded ? 230 : 48,
            height: _expanded ? 72 : 48,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(_expanded ? 24 : 50),
              border: Border.all(
                color: trackColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: trackColor.withValues(alpha: 0.3 * _expandAnim.value),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_expanded ? 24 : 50),
              child: _expanded
                  ? _buildExpanded(music, trackTitle, trackColor, isPlaying)
                  : _buildCollapsed(isPlaying, trackColor),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCollapsed(bool isPlaying, Color trackColor) {
    return AnimatedBuilder(
      animation: Listenable.merge(_barCtrls),
      builder: (context2, child) {
        if (!isPlaying) {
          return Center(
            child: Icon(Icons.music_note_rounded, color: trackColor, size: 22),
          );
        }
        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(5, (i) {
              final h = 6.0 + _barAnims[i].value * 14;
              return Container(
                width: 3,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: _barColors[i],
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildExpanded(
    MusicProvider music,
    String title,
    Color trackColor,
    bool isPlaying,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Mini animated bars
          AnimatedBuilder(
            animation: Listenable.merge(_barCtrls),
            builder: (context2, child) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(5, (i) {
                  final h = isPlaying ? 4.0 + _barAnims[i].value * 14 : 4.0;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 3,
                    height: h,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: _barColors[i],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 8),

          // Track title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  'Now Playing',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Playback controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IslandBtn(
                icon: Icons.skip_previous_rounded,
                color: trackColor,
                size: 16,
                onTap: music.previous,
              ),
              const SizedBox(width: 2),
              _IslandBtn(
                icon: isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: trackColor,
                size: 20,
                onTap: music.togglePlay,
                filled: true,
              ),
              const SizedBox(width: 2),
              _IslandBtn(
                icon: Icons.skip_next_rounded,
                color: trackColor,
                size: 16,
                onTap: music.next,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IslandBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;
  final bool filled;

  const _IslandBtn({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size + 10,
        height: size + 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? color.withValues(alpha: 0.2) : Colors.transparent,
        ),
        child: Center(
          child: Icon(icon, color: color, size: size),
        ),
      ),
    );
  }
}
