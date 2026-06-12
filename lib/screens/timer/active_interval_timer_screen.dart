import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/interval_timer_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/game_provider.dart';


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
      duration: const Duration(seconds: 5),
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

    timer.soundEnabled = settings.soundEffectsEnabled;

    final isWork = timer.phase == IntervalPhase.work;
    final orange = settings.appSeedColor; 
    final restColor = const Color(0xFF00BCD4);
    final activeColor = isWork ? orange : restColor;

    if (_lastPhase != null && _lastPhase != timer.phase) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _triggerBurst());
    }
    _lastPhase = timer.phase;

    final totalSeconds = isWork ? timer.workSeconds : timer.restSeconds;
    final progress = totalSeconds > 0
        ? timer.remainingSeconds / totalSeconds
        : 0.0;

    // Pearl White background
    const bgColor = Color(0xFFFDFDFD);
    const textColor = Color(0xFF1A1A1A);
    const mutedTextColor = Color(0xFF757575);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: textColor),
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
                color: mutedTextColor,
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
          SafeArea(
            child: Column(
              children: [
                // Workout Items List
                if (timer.activeItems.length > 1)
                  Container(
                    height: 50,
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: timer.activeItems.length,
                      itemBuilder: (context, index) {
                        final item = timer.activeItems[index];
                        final isActiveItem = index == timer.currentItemIndex;
                        final isPast = index < timer.currentItemIndex;
                        return Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActiveItem 
                                ? activeColor.withValues(alpha:0.1) 
                                : (isPast ? Colors.grey.shade200 : Colors.transparent),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActiveItem 
                                  ? activeColor 
                                  : (isPast ? Colors.grey.shade300 : Colors.grey.shade300),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              item.name,
                              style: GoogleFonts.poppins(
                                fontWeight: isActiveItem ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 13,
                                color: isActiveItem 
                                    ? activeColor 
                                    : (isPast ? Colors.grey.shade500 : Colors.grey.shade600),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  const SizedBox(height: 16),
                  
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
                            _buildStarDustAnimation(timer, activeColor),

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

                            if (_bursting) _buildBurstOverlay(activeColor),

                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(timer.remainingSeconds),
                                  style: GoogleFonts.russoOne(
                                    fontSize: 62,
                                    fontWeight: FontWeight.bold,
                                    color: activeColor,
                                    letterSpacing: 3,
                                    shadows: [
                                      Shadow(
                                        color: activeColor.withValues(alpha: 0.2),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (timer.activeItems.length == 1)
                                  Text(
                                    timer.currentItemName,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: textColor,
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
                        lightTheme: true,
                      ),
                      Container(width: 1, height: 30, color: Colors.grey.shade300),
                      _PhaseChip(
                        label: 'Rest',
                        value: '${timer.restSeconds}s',
                        isActive: !isWork,
                        color: restColor,
                        lightTheme: true,
                      ),
                      Container(width: 1, height: 30, color: Colors.grey.shade300),
                      _PhaseChip(
                        label: 'Round',
                        value: '${timer.currentRound}/${timer.totalRounds}',
                        isActive: false,
                        color: mutedTextColor,
                        lightTheme: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

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
                        lightTheme: true,
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
                        lightTheme: true,
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
                        lightTheme: true,
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

  // ── STAR DUST Animation ──────────────────────────────────────────
  Widget _buildStarDustAnimation(
    IntervalTimerProvider timer,
    Color activeColor,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Floating star dust particles — always active
        CustomPaint(
          painter: _StarDustPainter(
            progress: _rotateCtrl.value,
            glowOpacity: _glowAnim.value,
            color: activeColor,
            isActive: true,
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
  final bool lightTheme;

  const _PhaseChip({
    required this.label,
    required this.value,
    required this.isActive,
    required this.color,
    this.lightTheme = false,
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
            color: lightTheme ? Colors.grey.shade500 : Colors.white38,
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
            color: isActive ? color : (lightTheme ? Colors.grey.shade700 : Colors.white60),
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
  final bool lightTheme;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.activeColor,
    this.isPrimary = false,
    this.isSecondary = false,
    this.lightTheme = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPrimary
        ? activeColor
        : (lightTheme ? Colors.grey.shade100 : Colors.white.withValues(alpha: 0.08));
    final iconColor = isPrimary ? Colors.white : (lightTheme ? Colors.grey.shade800 : Colors.white70);
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
                color: isPrimary ? Colors.transparent : (lightTheme ? Colors.grey.shade300 : Colors.white24),
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
            color: isPrimary ? activeColor : (lightTheme ? Colors.grey.shade500 : Colors.white38),
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
      ..color = Colors.grey.shade200 // Use light gray for pearl white background
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Glow shadow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: glowOpacity * 0.2) // Reduced alpha for light bg
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
    if (!isActive) return;

    final center = Offset(size.width / 2, size.height / 2);
    final baseColor = color; 

    // Helper for orbit trails (comets)
    void drawComet(
      double r,
      double baseAngle,
      double speed,
      double tailLength,
      double thickness,
      double opacityMod,
    ) {
      final currentAngle = baseAngle + (progress * 2 * pi * speed);
      final fraction = tailLength / (2 * pi);
      
      final startAngle = speed >= 0 ? currentAngle - tailLength : currentAngle;
      final sweepAngle = tailLength; 
      
      SweepGradient gradient;
      if (speed >= 0) {
        gradient = SweepGradient(
          colors: [
            baseColor.withValues(alpha: 0.0),
            baseColor.withValues(alpha: opacityMod * glowOpacity),
            baseColor.withValues(alpha: 0.0), // edge finish
          ],
          stops: [0.0, max(0.001, fraction - 0.02), fraction],
          transform: GradientRotation(startAngle),
        );
      } else {
        gradient = SweepGradient(
          colors: [
            baseColor.withValues(alpha: opacityMod * glowOpacity),
            baseColor.withValues(alpha: 0.0),
            baseColor.withValues(alpha: 0.0), // empty space
          ],
          stops: [0.0, fraction - 0.01, fraction],
          transform: GradientRotation(startAngle),
        );
      }
      
      final rect = Rect.fromCircle(center: center, radius: r);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round
        ..shader = gradient.createShader(rect);
        
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness * 2.5
        ..strokeCap = StrokeCap.round
        ..shader = gradient.createShader(rect)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, thickness * 2);

      canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      
      // Paint bright glowing head
      final tipX = center.dx + r * cos(currentAngle);
      final tipY = center.dy + r * sin(currentAngle);
      final headPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacityMod * glowOpacity)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      canvas.drawCircle(Offset(tipX, tipY), thickness * 0.9, headPaint);
    }

    // Helper for dashed and semi-circular static-moving arcs
    void drawOrbitingArc(
      double r,
      double baseAngle,
      double speed,
      double sweepAngle,
      double thickness,
      double opacityMod,
    ) {
      final currentAngle = baseAngle + (progress * 2 * pi * speed);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round
        ..color = baseColor.withValues(alpha: opacityMod * glowOpacity);
      
      final rect = Rect.fromCircle(center: center, radius: r);
      canvas.drawArc(rect, currentAngle, sweepAngle, false, paint);
      
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness * 2
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
        ..color = baseColor.withValues(alpha: opacityMod * 0.5 * glowOpacity);
      canvas.drawArc(rect, currentAngle, sweepAngle, false, glowPaint);
    }

    // 1. Sci-fi glowing comets (Speeds must be integers for seamless wrap)
    drawComet(120.0, 0.0, 1.0, pi, 3.5, 1.0);
    drawComet(130.0, pi, -1.0, pi * 0.8, 2.5, 0.8);
    drawComet(145.0, pi / 2, 1.0, pi * 1.2, 4.0, 0.6); // 0.5 -> 1.0

    // 2. Dash arcs
    drawOrbitingArc(115.0, 0, 1.0, pi * 0.4, 2.0, 0.5); // 0.2 -> 1.0
    drawOrbitingArc(115.0, pi, 1.0, pi * 0.4, 2.0, 0.5); // 0.2 -> 1.0
    
    drawOrbitingArc(124.0, pi / 2, -1.0, pi * 0.1, 4.0, 0.7); // -0.3 -> -1.0
    drawOrbitingArc(124.0, 3 * pi / 2, -1.0, pi * 0.1, 4.0, 0.7); // -0.3 -> -1.0
    
    drawOrbitingArc(155.0, pi / 4, 1.0, pi * 0.15, 2.0, 0.4); // 0.4 -> 1.0

    // 3. Floating particles (dots)
    final random = Random(1234);
    for (int i = 0; i < 40; i++) {
        final rOffset = 110.0 + random.nextDouble() * 45.0;
        final angleOffset = random.nextDouble() * 2 * pi;
        // Speeds must be integers
        final speed = (random.nextInt(2) + 1).toDouble() * (random.nextBool() ? 1.0 : -1.0); 
        final currentAngle = angleOffset + (progress * 2 * pi * speed);
        
        final size = 1.0 + random.nextDouble() * 2.5;
        // A multiple of 4 means 4 full pulses per cycle, seamlessly looping
        final pulse = (sin(progress * 2 * pi * 4 + angleOffset) + 1) / 2;
        final opacity = (0.3 + 0.7 * pulse) * glowOpacity;
        
        final x = center.dx + rOffset * cos(currentAngle);
        final y = center.dy + rOffset * sin(currentAngle);
        
        final pPaint = Paint()
          ..color = baseColor.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), size, pPaint);
        
        final pGlow = Paint()
          ..color = baseColor.withValues(alpha: opacity * 0.6)
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 2);
        canvas.drawCircle(Offset(x, y), size * 2, pGlow);
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

