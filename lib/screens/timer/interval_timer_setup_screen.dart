import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/interval_timer_provider.dart';
import '../../utils/app_scale.dart';
import 'active_interval_timer_screen.dart';

class IntervalTimerSetupScreen extends StatelessWidget {
  const IntervalTimerSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timer  = context.watch<IntervalTimerProvider>();
    final orange = Theme.of(context).colorScheme.primary;
    final cs     = Theme.of(context).colorScheme;
    final s      = AppScale.of(context);

    // Bottom clearance: floating nav bar (68) + bottom margin (22) + safe area
    final navBarClearance = MediaQuery.of(context).padding.bottom + 68 + 22 + 8;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availH = constraints.maxHeight;
        // Hero card uses a proportional slice of available height
        final heroH = (availH * 0.26).clamp(130.0, 200.0);

        return Column(
          children: [
            // Total Time Hero Card
            Container(
              margin: EdgeInsets.fromLTRB(20 * s, 16 * s, 20 * s, 0),
              height: heroH,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [orange.withValues(alpha: 0.85), orange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22 * s),
                boxShadow: [
                  BoxShadow(
                    color: orange.withValues(alpha: 0.30),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'TOTAL WORKOUT TIME',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 10 * s,
                      letterSpacing: 2.0,
                      color: Colors.white60,
                    ),
                  ),
                  SizedBox(height: 4 * s),
                  Text(
                    _formatTime(timer.totalWorkoutTime),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      fontSize: (heroH * 0.32).clamp(32.0, 52.0),
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(height: 10 * s),
                  Wrap(
                    spacing: 8 * s,
                    children: [
                      _HeroPill(
                        icon: Icons.repeat_rounded,
                        label: '${timer.totalRounds} Rounds',
                        color: Colors.white,
                        scale: s,
                      ),
                      _HeroPill(
                        icon: Icons.bolt_rounded,
                        label: '${timer.workSeconds}s work',
                        color: Colors.white,
                        scale: s,
                      ),
                      _HeroPill(
                        icon: Icons.self_improvement_rounded,
                        label: '${timer.restSeconds}s rest',
                        color: Colors.white,
                        scale: s,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Configure section — fills rest of screen
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20 * s, 16 * s, 20 * s, navBarClearance),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Configure Intervals',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 16 * s,
                        color: cs.onSurface,
                      ),
                    ),
                    SizedBox(height: 12 * s),

                    // Work / Rest Inputs
                    Row(
                      children: [
                        Expanded(
                          child: _TimePickerCard(
                            label: 'Work Period',
                            icon: Icons.fitness_center_rounded,
                            value: timer.workSeconds,
                            color: orange,
                            onChanged: (v) =>
                                context.read<IntervalTimerProvider>().setWork(v),
                            min: 5,
                            max: 300,
                          ),
                        ),
                        SizedBox(width: 12 * s),
                        Expanded(
                          child: _TimePickerCard(
                            label: 'Rest Period',
                            icon: Icons.self_improvement_rounded,
                            value: timer.restSeconds,
                            color: const Color(0xFF3AB8E8),
                            onChanged: (v) =>
                                context.read<IntervalTimerProvider>().setRest(v),
                            min: 0,
                            max: 300,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12 * s),

                    // Rounds Slider Card
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 18 * s, vertical: 14 * s),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(18 * s),
                          border: Border.all(color: cs.outlineVariant),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Rounds',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15 * s,
                                    color: cs.onSurface,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14 * s, vertical: 4 * s),
                                  decoration: BoxDecoration(
                                    color: orange,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    '${timer.totalRounds}',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15 * s,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8 * s),
                            SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: orange,
                                inactiveTrackColor: cs.outlineVariant,
                                thumbColor: orange,
                                overlayColor: orange.withValues(alpha: 0.18),
                                trackHeight: 7,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 9),
                              ),
                              child: Slider(
                                value: timer.totalRounds.toDouble(),
                                min: 1,
                                max: 20,
                                divisions: 19,
                                onChanged: (v) {
                                  HapticFeedback.selectionClick();
                                  context
                                      .read<IntervalTimerProvider>()
                                      .setRounds(v.toInt());
                                },
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6 * s),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('1', style: _sliderLabelStyle(context, s)),
                                  Text('10', style: _sliderLabelStyle(context, s)),
                                  Text('20', style: _sliderLabelStyle(context, s)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 12 * s),

                    // Start Button
                    ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.read<IntervalTimerProvider>().startWorkout();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ActiveIntervalTimerScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orange,
                        minimumSize: Size(double.infinity, 52 * s),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18 * s),
                        ),
                        elevation: 6,
                        shadowColor: orange.withValues(alpha: 0.45),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 26 * s),
                          SizedBox(width: 8 * s),
                          Text(
                            'Start Workout',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 16 * s,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Formats seconds into MM:SS, or H:MM:SS when >= 1 hour.
  String _formatTime(int totalSeconds) {
    final int h = totalSeconds ~/ 3600;
    final int m = (totalSeconds % 3600) ~/ 60;
    final int s = totalSeconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  TextStyle _sliderLabelStyle(BuildContext context, double s) {
    return GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      fontSize: 12 * s,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
    );
  }
}

// Hero Pill widget for the summary row inside the hero card
class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double scale;

  const _HeroPill({
    required this.icon,
    required this.label,
    required this.color,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 6 * scale),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13 * scale, color: color),
          SizedBox(width: 5 * scale),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 12 * scale,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Time Picker Card
class _TimePickerCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final int value;
  final Color color;
  final Function(int) onChanged;
  final int min;
  final int max;

  const _TimePickerCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.color,
    required this.onChanged,
    required this.min,
    required this.max,
  });

  @override
  State<_TimePickerCard> createState() => _TimePickerCardState();
}

class _TimePickerCardState extends State<_TimePickerCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(_TimePickerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final selection = _controller.selection;
      _controller.text = widget.value.toString();
      try {
        _controller.selection = selection;
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Shows seconds in a human-readable form: "45s", "1m", "1m 30s"
  String _formatSeconds(int s) {
    if (s == 0) return '0s';
    if (s < 60) return '${s}s';
    final m = s ~/ 60;
    final rem = s % 60;
    return rem == 0 ? '${m}m' : '${m}m ${rem}s';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            children: [
              Icon(widget.icon, size: 14, color: widget.color),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  widget.label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Value display tap target
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                _showPickerDialog(context);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: widget.color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatSeconds(widget.value),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: widget.color,
                      ),
                    ),
                    Icon(Icons.edit_rounded, size: 16, color: widget.color),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Quick +/-5s buttons
          Row(
            children: [
              _QuickBtn(
                icon: Icons.remove,
                color: widget.color,
                onTap: () {
                  HapticFeedback.selectionClick();
                  final next =
                      (widget.value - 5).clamp(widget.min, widget.max);
                  widget.onChanged(next);
                },
              ),
              const Spacer(),
              _QuickBtn(
                icon: Icons.add,
                color: widget.color,
                onTap: () {
                  HapticFeedback.selectionClick();
                  final next =
                      (widget.value + 5).clamp(widget.min, widget.max);
                  widget.onChanged(next);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPickerDialog(BuildContext context) {
    _controller.text = widget.value.toString();
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(widget.icon, color: widget.color, size: 20),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter duration in seconds (${widget.min}–${widget.max})',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                filled: true,
                fillColor: widget.color.withValues(alpha: 0.08),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: widget.color.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: widget.color, width: 2),
                ),
                suffixText: 'sec',
                suffixStyle: GoogleFonts.poppins(
                  color: widget.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: widget.color,
              ),
              textAlign: TextAlign.center,
              onSubmitted: (_) {
                final val = int.tryParse(_controller.text) ?? widget.value;
                widget.onChanged(val.clamp(widget.min, widget.max));
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              final val = int.tryParse(_controller.text) ?? widget.value;
              widget.onChanged(val.clamp(widget.min, widget.max));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.color,
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Set',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Quick +/-5s circular button
class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
