import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/interval_timer_provider.dart';
import 'active_interval_timer_screen.dart';

class IntervalTimerSetupScreen extends StatelessWidget {
  const IntervalTimerSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<IntervalTimerProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orange = isDark ? Colors.orangeAccent : const Color(0xFFFF8C00);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Total Time Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D0D1A), Color(0xFF1A1030)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: orange.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'TOTAL WORKOUT TIME',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 1.8,
                    color: Colors.white38,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _formatTime(timer.totalWorkoutTime),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    fontSize: 60,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: orange.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.repeat, size: 15, color: orange),
                      const SizedBox(width: 6),
                      Text(
                        '${timer.totalRounds} Rounds',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Configure Intervals',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),

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
              const SizedBox(width: 16),
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
          const SizedBox(height: 20),

          // Rounds Slider Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rounds',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: orange,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${timer.totalRounds}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: orange,
                    inactiveTrackColor: Colors.grey.shade200,
                    thumbColor: orange,
                    overlayColor: orange.withValues(alpha: 0.2),
                    trackHeight: 8,
                  ),
                  child: Slider(
                    value: timer.totalRounds.toDouble(),
                    min: 1,
                    max: 20,
                    divisions: 19,
                    onChanged: (v) => context
                        .read<IntervalTimerProvider>()
                        .setRounds(v.toInt()),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1', style: _sliderLabelStyle()),
                      Text('10', style: _sliderLabelStyle()),
                      Text('20', style: _sliderLabelStyle()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Start Button
          ElevatedButton(
            onPressed: () {
              context.read<IntervalTimerProvider>().startWorkout();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ActiveIntervalTimerScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: orange,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 8,
              shadowColor: orange.withValues(alpha: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'Start Workout',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    int m = totalSeconds ~/ 60;
    int s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  TextStyle _sliderLabelStyle() {
    return GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: Colors.grey.shade400,
    );
  }
}

// ── Time Picker Card ──────────────────────────────────────────────────
class _TimePickerCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
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
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Value display + tap to edit
          GestureDetector(
            onTap: () => _showPickerDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${value}s',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: color,
                    ),
                  ),
                  Icon(Icons.edit_rounded, size: 16, color: color),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Quick ± buttons
          Row(
            children: [
              _QuickBtn(
                icon: Icons.remove,
                color: color,
                onTap: () {
                  final next = (value - 5).clamp(min, max);
                  onChanged(next);
                },
              ),
              const Spacer(),
              _QuickBtn(
                icon: Icons.add,
                color: color,
                onTap: () {
                  final next = (value + 5).clamp(min, max);
                  onChanged(next);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPickerDialog(BuildContext context) {
    final controller = TextEditingController(text: value.toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          label,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter duration in seconds ($min–$max)',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                filled: true,
                fillColor: color.withValues(alpha: 0.08),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: color.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: color, width: 2),
                ),
                suffixText: 'sec',
                suffixStyle: GoogleFonts.poppins(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text) ?? value;
              onChanged(val.clamp(min, max));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
