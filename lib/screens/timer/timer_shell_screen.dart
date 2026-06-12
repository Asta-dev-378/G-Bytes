import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/timer_provider.dart';
import '../../providers/interval_timer_provider.dart';
import 'timer_screen.dart';
import 'interval_timer_setup_screen.dart';
import 'workout_plans_screen.dart';

class TimerShellScreen extends StatefulWidget {
  const TimerShellScreen({super.key});

  @override
  State<TimerShellScreen> createState() => _TimerShellScreenState();
}

class _TimerShellScreenState extends State<TimerShellScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    context.read<TimerProvider>().stopAllSounds();
    context.read<IntervalTimerProvider>().stopWorkout();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'G Timer',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: primary,
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          indicatorColor: primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Classic'),
            Tab(text: 'Interval'),
            Tab(text: 'Plans'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          _ClassicTimerTab(),
          IntervalTimerSetupScreen(),
          WorkoutPlansScreen(),
        ],
      ),
    );
  }
}

class _ClassicTimerTab extends StatelessWidget {
  const _ClassicTimerTab();
  @override
  Widget build(BuildContext context) {
    return const TimerScreen();
  }
}
