import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/timer_provider.dart';
import '../../providers/interval_timer_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/app_scale.dart';
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
    final bg      = Theme.of(context).scaffoldBackgroundColor;
    final primary = context.watch<SettingsProvider>().appSeedColor;
    final top     = MediaQuery.of(context).padding.top;
    final s       = AppScale.of(context);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // Fixed header: title + pill tab bar — dark themed
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: EdgeInsets.only(top: top),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A).withValues(alpha: 0.95),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(24 * s, 14 * s, 24 * s, 4 * s),
                      child: Row(
                        children: [
                          Icon(Icons.bolt_rounded, color: primary, size: 22),
                          const SizedBox(width: 6),
                          Text(
                            'G-Timer',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16 * s, 0, 16 * s, 10 * s),
                      child: Container(
                        height: 44 * s,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.40),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          overlayColor: WidgetStateProperty.resolveWith(
                            (states) {
                              if (states.contains(WidgetState.pressed) ||
                                  states.contains(WidgetState.hovered)) {
                                return primary.withValues(alpha: 0.12);
                              }
                              return Colors.transparent;
                            },
                          ),
                          splashBorderRadius: BorderRadius.circular(22),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white38,
                          labelStyle: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13 * s,
                          ),
                          unselectedLabelStyle: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 13 * s,
                          ),
                          dividerHeight: 0,
                          indicatorSize: TabBarIndicatorSize.tab,
                          tabs: const [
                            Tab(text: 'Classic'),
                            Tab(text: 'Interval'),
                            Tab(text: 'Plans'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tab content fills remaining screen
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const ClampingScrollPhysics(),
              children: const [
                _ClassicTimerTab(),
                IntervalTimerSetupScreen(),
                WorkoutPlansScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassicTimerTab extends StatelessWidget {
  const _ClassicTimerTab();
  @override
  Widget build(BuildContext context) => const TimerScreen();
}
