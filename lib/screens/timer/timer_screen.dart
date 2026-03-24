import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../providers/timer_provider.dart';
import '../../providers/settings_provider.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();
    final settings = context.watch<SettingsProvider>();

    // Sync sound setting
    timer.soundEnabled = settings.soundEffectsEnabled;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orange = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('G-Timer')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Mode toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _ModeBtn(
                    label: 'Countdown',
                    selected: timer.mode == TimerMode.countdown,
                    onTap: () => timer.setMode(TimerMode.countdown),
                  ),
                  _ModeBtn(
                    label: 'Stopwatch',
                    selected: timer.mode == TimerMode.stopwatch,
                    onTap: () => timer.setMode(TimerMode.stopwatch),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 32),

            // Presets (only for countdown)
            if (timer.mode == TimerMode.countdown)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: timer.presets.map((p) {
                    final label = p.inHours >= 1
                        ? '${p.inHours}h'
                        : '${p.inMinutes}m';
                    final selected = timer.duration == p;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => timer.setDuration(p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? orange : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            label,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 48),

            // Circular timer
            CircularPercentIndicator(
              radius: 130,
              lineWidth: 12,
              percent: timer.mode == TimerMode.countdown
                  ? (1.0 - timer.progress).clamp(0.0, 1.0)
                  : 0,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    timer.mode == TimerMode.countdown
                        ? _fmt(timer.remaining)
                        : _fmt(timer.elapsed),
                    style: GoogleFonts.poppins(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? const Color(0xFFD500F9)
                          : const Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    timer.mode == TimerMode.countdown ? 'remaining' : 'elapsed',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),

                  // +/- buttons for countdown
                  if (timer.mode == TimerMode.countdown &&
                      timer.status == TimerStatus.idle)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => timer.adjustDuration(-5),
                          color: Colors.grey.shade500,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => timer.adjustDuration(5),
                          color: orange,
                        ),
                      ],
                    ),
                ],
              ),
              progressColor: timer.isFinished
                  ? const Color(0xFF20BC68)
                  : orange,
              backgroundColor: Colors.grey.shade100,
              animation: false,
              circularStrokeCap: CircularStrokeCap.round,
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

            const SizedBox(height: 48),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (timer.status != TimerStatus.running)
                  ElevatedButton.icon(
                    onPressed: timer.start,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('START'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(160, 54),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: timer.pause,
                    icon: const Icon(Icons.pause_rounded),
                    label: const Text('PAUSE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      minimumSize: const Size(160, 54),
                    ),
                  ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: timer.reset,
                  icon: Icon(Icons.refresh_rounded, color: orange),
                  label: Text(
                    'RESET',
                    style: GoogleFonts.poppins(
                      color: orange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: orange, width: 2),
                    minimumSize: const Size(120, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ).animate(delay: 200.ms).fadeIn(),

            if (timer.isFinished)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  '🎉 Time\'s up! Great work!',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF20BC68),
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? Colors.white : Colors.grey.shade500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
