// timer_screen.dart  â€” Thunder-themed countdown/stopwatch screen.
// Dark bg throughout (matches app palette), no grey/white surfaces,
// all accents derive from Theme.colorScheme.primary.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/timer_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/app_scale.dart';
import 'timer_motion.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});
  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  static String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }

  static String _pct(double fraction) => '${(fraction * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final timer    = context.watch<TimerProvider>();
    final settings = context.watch<SettingsProvider>();
    timer.soundEnabled = settings.soundEffectsEnabled;

    final primary   = Theme.of(context).colorScheme.primary;
    final surface   = Theme.of(context).colorScheme.surface;      // 0xFF141414
    final bg        = Theme.of(context).scaffoldBackgroundColor;  // 0xFF0A0A0A

    final isActive  = timer.status == TimerStatus.running ||
                      timer.status == TimerStatus.paused;
    final bottomPad = MediaQuery.of(context).padding.bottom + 68 + 22 + 16;

    return Stack(
      children: [
        Scaffold(
          // Always use the app's dark scaffold â€” no black-to-grey shift
          backgroundColor: bg,
          body: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPad),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availH = constraints.maxHeight;
                  return Column(
                    children: [
                      SizedBox(height: availH * 0.025),

                      // â”€â”€ Mode Toggle (hidden while running) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: isActive
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 28),
                                child: _ModeToggle(
                                  mode: timer.mode,
                                  primary: primary,
                                  surface: surface,
                                  enabled: timer.status == TimerStatus.idle,
                                  onSelect: timer.setMode,
                                ).animate().fadeIn(delay: 80.ms),
                              ),
                      ),

                      // â”€â”€ Preset Pills (hidden while running) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: isActive || timer.mode != TimerMode.countdown
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(
                                    left: 28, right: 28, top: 14),
                                child: _PresetRow(
                                  presets: timer.presets,
                                  selected: timer.duration,
                                  primary: primary,
                                  surface: surface,
                                  enabled: timer.status == TimerStatus.idle,
                                  onSelect: timer.setDuration,
                                ).animate().fadeIn(delay: 140.ms),
                              ),
                      ),

                      SizedBox(height: availH * 0.02),

                      // â”€â”€ Animation / Ring â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      Expanded(
                        child: isActive
                            ? ThunderHaloWidget(
                                progress:    timer.fractionRemaining,
                                timeText:    _fmt(timer.remaining),
                                pctText:     _pct(timer.fractionRemaining),
                                accentColor: primary,
                                onComplete:  timer.acknowledgeComplete,
                              )
                            : Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 28),
                                  child: _TimerRingDisplay(
                                    timer:    timer,
                                    primary:  primary,
                                    surface:  surface,
                                    fmt:      _fmt,
                                    ringSize: (availH * 0.38).clamp(
                                      AppScale.dp(context, 180),
                                      AppScale.dp(context, 280),
                                    ),
                                  ),
                                ),
                              ),
                      ),

                      SizedBox(height: availH * 0.04),

                      // â”€â”€ Controls â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: _ControlRow(
                          timer:   timer,
                          primary: primary,
                          surface: surface,
                        ).animate(delay: 200.ms).fadeIn(),
                      ),

                      SizedBox(height: availH * 0.025),
                    ],
                  );
                },
              ),
            ),
          ),
        ),

        // â”€â”€ Completion Overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (timer.status == TimerStatus.completed)
          CompletionOverlay(
            accentColor: primary,
            onDismiss:   timer.acknowledgeComplete,
          ),
      ],
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// MODE TOGGLE â€” dark pill, no grey.shade100
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ModeToggle extends StatelessWidget {
  final TimerMode mode;
  final Color primary;
  final Color surface;
  final bool enabled;
  final ValueChanged<TimerMode> onSelect;

  const _ModeToggle({
    required this.mode,
    required this.primary,
    required this.surface,
    required this.enabled,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Row(
        children: [
          _ModeBtn(
            label:    'Countdown',
            selected: mode == TimerMode.countdown,
            primary:  primary,
            surface:  surface,
            onTap:    enabled ? () => onSelect(TimerMode.countdown) : null,
          ),
          _ModeBtn(
            label:    'Stopwatch',
            selected: mode == TimerMode.stopwatch,
            primary:  primary,
            surface:  surface,
            onTap:    enabled ? () => onSelect(TimerMode.stopwatch) : null,
          ),
        ],
      ),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color primary;
  final Color surface;
  final VoidCallback? onTap;

  const _ModeBtn({
    required this.label,
    required this.selected,
    required this.primary,
    required this.surface,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: TimerMotion.standard,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [BoxShadow(color: primary.withAlpha(70), blurRadius: 12, offset: const Offset(0, 4))]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? Colors.white : Colors.white38,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// PRESET ROW â€” dark pills
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PresetRow extends StatelessWidget {
  final List<Duration> presets;
  final Duration selected;
  final Color primary;
  final Color surface;
  final bool enabled;
  final ValueChanged<Duration> onSelect;

  const _PresetRow({
    required this.presets,
    required this.selected,
    required this.primary,
    required this.surface,
    required this.enabled,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        separatorBuilder: (_, value) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final p = presets[i];
          final label = p.inHours >= 1 ? '${p.inHours}h' : '${p.inMinutes}m';
          final isSelected = selected == p;
          return TimerPressButton(
            onTap: enabled ? () => onSelect(p) : null,
            child: AnimatedContainer(
              duration: TimerMotion.standard,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? primary : surface,
                borderRadius: BorderRadius.circular(21),
                border: Border.all(
                  color: isSelected ? primary : Colors.white.withAlpha(20),
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: primary.withAlpha(90), blurRadius: 14, offset: const Offset(0, 3))]
                    : null,
              ),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isSelected ? Colors.white : Colors.white54,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// RING DISPLAY â€” idle state, dark theme
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TimerRingDisplay extends StatelessWidget {
  final TimerProvider timer;
  final Color primary;
  final Color surface;
  final String Function(Duration) fmt;
  final double ringSize;

  const _TimerRingDisplay({
    required this.timer,
    required this.primary,
    required this.surface,
    required this.fmt,
    required this.ringSize,
  });

  @override
  Widget build(BuildContext context) {
    const strokeWidth = 12.0;
    final displayDuration = timer.mode == TimerMode.countdown
        ? timer.remaining
        : timer.elapsed;
    final timeFontSize  = (ringSize * 0.175).clamp(34.0, 50.0);
    final labelFontSize = (ringSize * 0.05).clamp(11.0, 14.0);
    final adjustBtnSize = (ringSize * 0.135).clamp(30.0, 40.0);

    final ring = SizedBox(
      width: ringSize,
      height: ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ring painter
          CustomPaint(
            size: Size(ringSize, ringSize),
            painter: TimerRingPainter(
              fractionRemaining: timer.mode == TimerMode.countdown
                  ? timer.fractionRemaining
                  : 0,
              ringColor:         primary,
              trackColor:        Colors.white.withAlpha(18),  // dark track
              strokeWidth:       strokeWidth,
              isLastTenSeconds:  timer.isLastTenSeconds,
            ),
          ),

          // Inner content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: TimerMotion.micro,
                style: GoogleFonts.poppins(
                  fontSize: timer.isLastTenSeconds
                      ? timeFontSize + 4 : timeFontSize,
                  fontWeight: FontWeight.w800,
                  color: primary,
                  height: 1,
                ),
                child: Text(fmt(displayDuration)),
              ),
              const SizedBox(height: 4),
              Text(
                timer.mode == TimerMode.countdown ? 'remaining' : 'elapsed',
                style: GoogleFonts.poppins(
                  fontSize: labelFontSize,
                  color: Colors.white38,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Â±5m adjust buttons (idle countdown only)
              if (timer.mode == TimerMode.countdown &&
                  timer.status == TimerStatus.idle) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AdjustBtn(
                      size:    adjustBtnSize,
                      icon:    Icons.remove_rounded,
                      primary: primary,
                      surface: surface,
                      onTap:   () => timer.adjustDuration(-5),
                    ),
                    const SizedBox(width: 12),
                    _AdjustBtn(
                      size:    adjustBtnSize,
                      icon:    Icons.add_rounded,
                      primary: primary,
                      surface: surface,
                      onTap:   () => timer.adjustDuration(5),
                      filled:  true,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (timer.isLastTenSeconds) {
      return LastSecondsWidget(
        color: primary,
        size: ringSize + 16,
        child: ring,
      );
    }
    return ring;
  }
}

class _AdjustBtn extends StatelessWidget {
  final double size;
  final IconData icon;
  final Color primary;
  final Color surface;
  final VoidCallback onTap;
  final bool filled;

  const _AdjustBtn({
    required this.size,
    required this.icon,
    required this.primary,
    required this.surface,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return TimerPressButton(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color:  filled ? primary.withAlpha(30) : surface,
          shape:  BoxShape.circle,
          border: Border.all(
            color: filled ? primary.withAlpha(80) : Colors.white.withAlpha(20),
          ),
        ),
        child: Icon(icon,
          size:  size * 0.48,
          color: filled ? primary : Colors.white54,
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// CONTROL ROW â€” centered, dark
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ControlRow extends StatelessWidget {
  final TimerProvider timer;
  final Color primary;
  final Color surface;

  const _ControlRow({
    required this.timer,
    required this.primary,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning   = timer.status == TimerStatus.running;
    final isPaused    = timer.status == TimerStatus.paused;
    final isCompleted = timer.status == TimerStatus.completed;

    final screenW    = MediaQuery.of(context).size.width;
    final mainBtnW   = (screenW * 0.52).clamp(140.0, 200.0);
    final iconBtnSz  = (screenW * 0.145).clamp(52.0, 66.0);
    final btnHeight  = iconBtnSz;

    final mainColor = isCompleted
        ? const Color(0xFF22C55E)
        : isRunning
            ? surface
            : primary;
    final mainBorderColor = isRunning
        ? primary.withAlpha(60)
        : Colors.transparent;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // RESET â€” left of main button
        TimerPressButton(
          onTap: timer.reset,
          child: Container(
            width:  iconBtnSz,
            height: btnHeight,
            decoration: BoxDecoration(
              color:  surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withAlpha(20)),
            ),
            child: Icon(Icons.refresh_rounded, color: Colors.white54, size: iconBtnSz * 0.38),
          ),
        ),

        const SizedBox(width: 14),

        // START / PAUSE / DONE
        TimerPressButton(
          onTap: isCompleted
              ? timer.acknowledgeComplete
              : isRunning
                  ? timer.pause
                  : timer.start,
          child: AnimatedContainer(
            duration: TimerMotion.standard,
            width:  mainBtnW,
            height: btnHeight,
            decoration: BoxDecoration(
              color:          mainColor,
              borderRadius:   BorderRadius.circular(22),
              border:         Border.all(color: mainBorderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color:     (isRunning ? primary : mainColor).withAlpha(80),
                  blurRadius: 20,
                  offset:    const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCompleted ? Icons.check_rounded
                      : isRunning ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: isRunning ? primary : Colors.white,
                  size: btnHeight * 0.40,
                ),
                SizedBox(width: btnHeight * 0.13),
                Text(
                  isCompleted ? 'Done'
                      : isRunning ? 'Pause'
                      : isPaused  ? 'Resume'
                      : 'Start',
                  style: GoogleFonts.poppins(
                    fontSize: (btnHeight * 0.27).clamp(13.0, 17.0),
                    fontWeight: FontWeight.w700,
                    color: isRunning ? primary : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 14),

        // LIGHTNING bolt â€” visual flair (toggles sound or acts as lap)
        TimerPressButton(
          onTap: () {},
          child: Container(
            width:  iconBtnSz,
            height: btnHeight,
            decoration: BoxDecoration(
              color: primary.withAlpha(18),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: primary.withAlpha(50)),
            ),
            child: Icon(Icons.bolt_rounded, color: primary, size: iconBtnSz * 0.42),
          ),
        ),
      ],
    );
  }
}
