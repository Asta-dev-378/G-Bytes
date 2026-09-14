import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/interval_timer_provider.dart';
import '../../providers/settings_provider.dart';
import 'active_interval_timer_screen.dart';

class WorkoutPlansScreen extends StatelessWidget {
  const WorkoutPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timerProvider = context.watch<IntervalTimerProvider>();
    final settings     = context.watch<SettingsProvider>();
    final primary      = settings.appSeedColor;
    final plans        = timerProvider.savedPlans;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Text(
          'Workout Plans',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _showAddDialog(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.40),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
      body: plans.isEmpty
          ? _EmptyState(primary: primary, onAdd: () => _showAddDialog(context))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  'Saved Plans',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white30,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 14),
                ...plans.map(
                  (plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _PlanCard(
                      plan: plan,
                      primary: primary,
                      onTap: () => _showPlanOptions(context, plan),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddPlanSheet(),
    );
  }

  void _showPlanOptions(BuildContext context, WorkoutPlan plan) {
    final primary = context.read<SettingsProvider>().appSeedColor;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF12121A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withAlpha(14)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.fitness_center_rounded, color: primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${plan.items.length} exercises  •  ${plan.items.fold(0, (s, i) => s + i.sets)} total sets',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: Colors.white.withAlpha(14)),
            // Play
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.play_arrow_rounded, color: primary, size: 22),
              ),
              title: Text(
                'Play Workout',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                'Starts the interval timer with this plan',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white38),
              ),
              onTap: () {
                Navigator.pop(ctx);
                final provider = context.read<IntervalTimerProvider>();
                provider.loadFromPlan(plan);
                provider.startWorkout();
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, a, b) => const ActiveIntervalTimerScreen(),
                    transitionsBuilder: (_, anim, sa, child) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.08),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeOut,
                        )),
                        child: child,
                      ),
                    ),
                    transitionDuration: const Duration(milliseconds: 350),
                  ),
                );
              },
            ),
            // Delete
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444), size: 22),
              ),
              title: Text(
                'Delete Plan',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFEF4444),
                ),
              ),
              onTap: () {
                context.read<IntervalTimerProvider>().deletePlan(plan.id);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ── Plan Card (dark glass) ────────────────────────────────────────────────────

class _PlanCard extends StatefulWidget {
  final WorkoutPlan plan;
  final Color primary;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.primary,
    required this.onTap,
  });

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _sc;

  @override
  void initState() {
    super.initState();
    _sc = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  String _formatTotalTime() {
    final total = widget.plan.totalSeconds;
    final m = total ~/ 60;
    final s = total % 60;
    if (s == 0) return '${m}m';
    return '${m}m ${s}s';
  }

  int get totalSets =>
      widget.plan.items.fold(0, (sum, item) => sum + item.sets);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _sc.forward(),
      onTapUp: (_) { _sc.reverse(); widget.onTap(); },
      onTapCancel: () => _sc.reverse(),
      child: AnimatedBuilder(
        animation: _sc,
        builder: (_, child) => Transform.scale(
          scale: 1.0 - _sc.value * 0.02,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF12121A),
            borderRadius: BorderRadius.circular(20),
            border: Border(
              top: BorderSide(color: widget.primary.withValues(alpha: 0.6), width: 2),
              left: BorderSide(color: Colors.white.withAlpha(10)),
              right: BorderSide(color: Colors.white.withAlpha(10)),
              bottom: BorderSide(color: Colors.white.withAlpha(10)),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.primary.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon box
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: widget.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: widget.primary.withValues(alpha: 0.20),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(Icons.fitness_center_rounded,
                    color: widget.primary, size: 26),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.plan.name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Chip(
                          icon: Icons.list_alt_rounded,
                          label: '${widget.plan.items.length} exercises',
                          color: widget.primary,
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          icon: Icons.repeat_rounded,
                          label: '$totalSets sets',
                          color: const Color(0xFF22C55E),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Total time + arrow
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTotalTime(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: widget.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'total',
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.white30),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final Color primary;
  final VoidCallback onAdd;
  const _EmptyState({required this.primary, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.20),
                  blurRadius: 32,
                ),
              ],
            ),
            child: Icon(Icons.fitness_center_rounded, color: primary, size: 44),
          ),
          const SizedBox(height: 24),
          Text(
            'No Workout Plans',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a plan to quickly start\nyour favourite workout.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white38,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.40),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Create Plan',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add Plan Sheet ────────────────────────────────────────────────────────────

class _TempItem {
  final TextEditingController nameCtrl = TextEditingController();
  int sets = 4;
  int workSec = 45;
  int restSec = 15;

  void dispose() {
    nameCtrl.dispose();
  }
}

class _AddPlanSheet extends StatefulWidget {
  const _AddPlanSheet();

  @override
  State<_AddPlanSheet> createState() => _AddPlanSheetState();
}

class _AddPlanSheetState extends State<_AddPlanSheet> {
  final _planNameCtrl = TextEditingController();
  final List<_TempItem> _items = [_TempItem()];

  @override
  void dispose() {
    _planNameCtrl.dispose();
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addExercise() {
    setState(() {
      _items.add(_TempItem());
    });
  }

  void _removeExercise(int index) {
    if (_items.length > 1) {
      setState(() {
        _items[index].dispose();
        _items.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.read<SettingsProvider>().appSeedColor;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withAlpha(14)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 16, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'New Workout Plan',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Plan Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan Name',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _planNameCtrl,
                  maxLength: 30,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Morning HIIT',
                    hintStyle: GoogleFonts.poppins(color: Colors.white30),
                    filled: true,
                    fillColor: Colors.white.withAlpha(8),
                    counterText: '',
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: primary.withValues(alpha: 0.30)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: primary, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Exercise List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exercises',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addExercise,
                  icon: Icon(Icons.add_rounded, size: 18, color: primary),
                  label: Text(
                    'Add',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Exercises List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withAlpha(14)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: item.nameCtrl,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              scrollPadding: const EdgeInsets.only(bottom: 320),
                              decoration: InputDecoration(
                                hintText: 'Exercise ${index + 1} (e.g. Push-ups)',
                                hintStyle: GoogleFonts.poppins(
                                    fontSize: 14, color: Colors.white30),
                                isDense: true,
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          if (_items.length > 1)
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              color: const Color(0xFFEF4444),
                              onPressed: () => _removeExercise(index),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _NumberPicker(
                              label: 'Sets',
                              value: item.sets,
                              min: 1, max: 20,
                              color: primary,
                              onChanged: (v) => setState(() => item.sets = v),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _NumberPicker(
                              label: 'Work',
                              value: item.workSec,
                              min: 5, max: 300, step: 5,
                              color: const Color(0xFF22C55E),
                              onChanged: (v) => setState(() => item.workSec = v),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _NumberPicker(
                              label: 'Rest',
                              value: item.restSec,
                              min: 0, max: 300, step: 5,
                              color: const Color(0xFF3AB8E8),
                              onChanged: (v) => setState(() => item.restSec = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Save Button
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final planName = _planNameCtrl.text.trim();
                  if (planName.isEmpty) return;

                  final List<WorkoutItem> workoutItems = [];
                  for (var i = 0; i < _items.length; i++) {
                    final tmp = _items[i];
                    final exName = tmp.nameCtrl.text.trim().isEmpty
                        ? 'Exercise ${i + 1}'
                        : tmp.nameCtrl.text.trim();
                    workoutItems.add(WorkoutItem(
                      name: exName,
                      sets: tmp.sets,
                      workSeconds: tmp.workSec,
                      restSeconds: tmp.restSec,
                    ));
                  }

                  final plan = WorkoutPlan(
                    id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
                    name: planName,
                    items: workoutItems,
                  );
                  context.read<IntervalTimerProvider>().addPlan(plan);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: primary.withValues(alpha: 0.4),
                ),
                child: Text(
                  'Save Plan',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Number Picker ─────────────────────────────────────────────────────────────

class _NumberPicker extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final Color color;
  final ValueChanged<int> onChanged;

  const _NumberPicker({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.color,
    required this.onChanged,
    this.step = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _IconBtn(
                icon: Icons.remove,
                color: color,
                onTap: () {
                  final next = (value - step).clamp(min, max);
                  onChanged(next);
                },
              ),
              const SizedBox(width: 8),
              _IconBtn(
                icon: Icons.add,
                color: color,
                onTap: () {
                  final next = (value + step).clamp(min, max);
                  onChanged(next);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
