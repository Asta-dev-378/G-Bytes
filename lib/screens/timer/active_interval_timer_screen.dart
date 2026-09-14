import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/interval_timer_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/game_provider.dart';
import 'timer_motion.dart';

class ActiveIntervalTimerScreen extends StatefulWidget {
  const ActiveIntervalTimerScreen({super.key});

  @override
  State<ActiveIntervalTimerScreen> createState() =>
      _ActiveIntervalTimerScreenState();
}

class _ActiveIntervalTimerScreenState extends State<ActiveIntervalTimerScreen>
    with TickerProviderStateMixin {
  // Only the burst controller remains â€” all other animation is handled
  late AnimationController _burstCtrl;
  late Animation<double> _burstAnim;

  IntervalPhase? _lastPhase;
  bool _bursting = false;

  @override
  void initState() {
    super.initState();

    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

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

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
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
    final timer    = context.watch<IntervalTimerProvider>();
    final settings = context.watch<SettingsProvider>();

    timer.soundEnabled = settings.soundEffectsEnabled;

    final isWork     = timer.phase == IntervalPhase.work;
    final orange     = settings.appSeedColor;
    const coolColor  = Color(0xFF3AB8E8);
    final restColor  = Color.lerp(orange, Colors.white, 0.40)!;
    final activeColor = isWork ? orange : restColor;
    // Burst color matches the arriving phase (cool for rest, warm for work)
    final burstColor  = isWork ? orange : coolColor;

    if (_lastPhase != null && _lastPhase != timer.phase) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _triggerBurst());
    }
    _lastPhase = timer.phase;



    // Dark color scheme throughout
    const bgColor        = Color(0xFF1C1C1E);
    const textColor      = Colors.white;
    const mutedTextColor = Color(0xFF8E8E93);

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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Workout item chips
            if (timer.activeItems.length > 1)
              Container(
                height: 50,
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: timer.activeItems.length,
                  itemBuilder: (context, index) {
                    final item = timer.activeItems[index];
                    final isActiveItem = index == timer.currentItemIndex;
                    final isPast      = index < timer.currentItemIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActiveItem
                            ? activeColor.withValues(alpha: 0.18)
                            : (isPast ? Colors.white.withValues(alpha: 0.06) : Colors.transparent),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActiveItem ? activeColor : Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Center(
                        child: Text(item.name,
                          style: GoogleFonts.poppins(
                            fontWeight: isActiveItem ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                            color: isActiveItem ? activeColor : (isPast ? Colors.white38 : Colors.white60),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              const SizedBox(height: 8),

            // Thunder Ball Hexagon animation
            // Text (time + phase) is drawn directly inside the hex by the painter.
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: ThunderBallHexWidget(
                      accentColor:    activeColor,
                      secondaryColor: isWork ? coolColor : orange,
                      timeText:       _formatTime(timer.remainingSeconds),
                      phaseLabel:     isWork ? 'WORK' : 'REST',
                    ),
                  ),
                  if (_bursting) Center(child: _buildBurstOverlay(burstColor)),
                ],
              ),
            ),

            // Phase indicator cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: _PhaseChip(label: 'WORK', value: '${timer.workSeconds}s', isActive: isWork, color: orange)),
                  const SizedBox(width: 10),
                  Expanded(child: _PhaseChip(label: 'REST', value: '${timer.restSeconds}s', isActive: !isWork, color: restColor)),
                  const SizedBox(width: 10),
                  Expanded(child: _PhaseChip(label: 'ROUND', value: '${timer.currentRound}/${timer.totalRounds}', isActive: false, color: const Color(0xFF8E8E93))),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Controls
            Padding(
              padding: const EdgeInsets.only(bottom: 44),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ControlButton(
                    icon: timer.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    label: timer.isRunning ? 'Pause' : 'Resume',
                    onTap: timer.pauseResume,
                    isSecondary: true,
                    activeColor: orange,
                    lightTheme: false,
                  ),
                  _ControlButton(
                    icon: Icons.stop_rounded,
                    label: 'Stop',
                    onTap: () { timer.stopWorkout(); Navigator.pop(context); },
                    isPrimary: true,
                    activeColor: orange,
                    lightTheme: false,
                  ),
                  _ControlButton(
                    icon: Icons.refresh_rounded,
                    label: 'Restart',
                    onTap: () { timer.stopWorkout(); timer.startWorkout(); },
                    isSecondary: true,
                    activeColor: orange,
                    lightTheme: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBurstOverlay(Color activeColor) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _BurstPainter(progress: _burstAnim.value, color: activeColor),
        size: const Size(380, 380),
      ),
    );
  }
  String _formatTime(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// â”€â”€ Phase Chip â€” card style, spacious â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isActive ? color.withAlpha(22) : const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          top: BorderSide(
            color: isActive ? color : Colors.white.withAlpha(18),
            width: isActive ? 2.5 : 1,
          ),
          left: BorderSide(color: Colors.white.withAlpha(10)),
          right: BorderSide(color: Colors.white.withAlpha(10)),
          bottom: BorderSide(color: Colors.white.withAlpha(10)),
        ),
        boxShadow: isActive
            ? [BoxShadow(color: color.withAlpha(40), blurRadius: 16)]
            : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: isActive ? color : Colors.white38,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isActive ? color : Colors.white54,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Control Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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




// â”€â”€ Burst Painter (phase transition effect) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _BurstPainter extends CustomPainter {
  final double progress; // 0.0 â†’ 1.0
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

