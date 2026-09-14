import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/player_progress_provider.dart';
import '../../providers/settings_provider.dart';
import '../../features/streak/models/daily_task.dart';
import '../games/binary_puzzle_screen.dart';
import '../games/sum_snake_screen.dart';
import '../games/countdown_math_screen.dart';
import '../games/akari_screen.dart';
import '../games/balance_scale_screen.dart';
import '../games/attentional_blink_screen.dart';
import '../games/word_wheel_screen.dart';
import '../games/action_sequence_recall_screen.dart';
import '../knowledge/did_you_know_screen.dart';
import '../../models/league.dart';
import '../profile/profile_screen.dart';
import 'xp_history_screen.dart';


// ── Game icon & color helpers for Today's Plan cards ─────────────────────

IconData _taskIcon(TaskType type) {
  return switch (type) {
    TaskType.mathSprint       => Icons.calculate_rounded,
    TaskType.memory           => Icons.grid_on_rounded,
    TaskType.logic            => Icons.functions_rounded,
    TaskType.schulte          => Icons.apps_rounded,
    TaskType.stroop           => Icons.palette_rounded,
    TaskType.reactionTimeTap  => Icons.touch_app_rounded,
    TaskType.numberRush       => Icons.filter_9_plus_rounded,
    TaskType.whackATarget     => Icons.gps_fixed_rounded,
    TaskType.speedSort        => Icons.swap_horiz_rounded,
    TaskType.cardMatch        => Icons.style_rounded,
    TaskType.sequenceRecall   => Icons.linear_scale_rounded,
    TaskType.nBack            => Icons.history_rounded,
    TaskType.memoryPalace     => Icons.home_work_rounded,
    TaskType.stroopTest       => Icons.colorize_rounded,
    TaskType.sart             => Icons.track_changes_rounded,
    TaskType.spotTheDifference=> Icons.compare_rounded,
    TaskType.twentyFourGame   => Icons.tag_rounded,
    TaskType.slidingPuzzle    => Icons.dashboard_rounded,
    TaskType.patternCompletion=> Icons.pattern_rounded,
    TaskType.miniSudoku       => Icons.grid_4x4_rounded,
    TaskType.wordChains       => Icons.link_rounded,
    TaskType.anagramSolver    => Icons.text_rotate_vertical_rounded,
    TaskType.categoryBlitz    => Icons.category_rounded,
    TaskType.mentalRotation   => Icons.rotate_90_degrees_ccw_rounded,
    TaskType.mazeNavigator    => Icons.alt_route_rounded,
  };
}

// ── Helpers ────────────────────────────────────────────────────────────────

String _monthName(int m) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return months[m - 1];
}

String _todayLabel() {
  final now = DateTime.now();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return 'Today, ${now.day} ${months[now.month - 1]}';
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// ── G-Zone Screen ──────────────────────────────────────────────────────────

class GZoneScreen extends StatelessWidget {
  const GZoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final game = context.watch<GameProvider>();
    final progress = context.watch<PlayerProgressProvider>();
    final primary = context.watch<SettingsProvider>().appSeedColor;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: CustomScrollView(
        slivers: [
          // ── Glassmorphism App Bar ──────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 108,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0F).withValues(alpha: 0.88),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                  ),
                  child: FlexibleSpaceBar(
                    titlePadding:
                        const EdgeInsets.only(left: 24, bottom: 14),
                    title: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _todayLabel(),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.white38,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Hello, ${user.userName ?? 'Champion'} 👋',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              // Notification bell
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: const Icon(Icons.notifications_outlined,
                      size: 18, color: Colors.white60),
                ),
              ),
              // Profile avatar
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ProfileScreen()),
                  ),
                  child: Container(
                    width: 38,
                    height: 38,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.38),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        (user.userName?[0] ?? 'G').toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Content ───────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // 1. Hero Challenge Banner
                _HeroBannerCard(
                  completedCount: progress.completedTaskCount,
                  totalTasks: progress.dailyTasks.isEmpty
                      ? 3
                      : progress.dailyTasks.length,
                  streak: game.streak,
                  primary: primary,
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.18, end: 0),
                const SizedBox(height: 14),

                // 2. Week Strip (replaces full calendar)
                _WeekStripCard(
                  streak: game.streak,
                  bestStreak: game.bestStreak,
                  weeklyPoints: game.weeklyPoints,
                  streakStartDate: progress.streakStartDate,
                  lastStreakDate: progress.lastStreakDate,
                  weekStartDate: progress.weekStartDate,
                  league: progress.league,
                  primary: primary,
                ).animate(delay: 60.ms).fadeIn().slideY(begin: 0.14, end: 0),
                const SizedBox(height: 22),

                // 3. Today's Plan — horizontal game cards
                const _SectionHeader(title: "Today's Plan"),
                const SizedBox(height: 10),
                _TodaysPlanScroll(
                  tasks: progress.dailyTasks,
                  primary: primary,
                ).animate(delay: 130.ms).fadeIn().slideY(begin: 0.14, end: 0),
                const SizedBox(height: 22),


                // 6. Did You Know?
                const _SectionHeader(title: 'Did You Know?'),
                const SizedBox(height: 10),
                _DidYouKnowCard(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DidYouKnowScreen()),
                  ),
                ).animate(delay: 190.ms).fadeIn().slideY(begin: 0.14, end: 0),

                // Clearance for floating pill nav
                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );
  }
}

// ── Hero Banner Card ───────────────────────────────────────────────────────

class _HeroBannerCard extends StatelessWidget {
  final int completedCount;
  final int totalTasks;
  final int streak;
  final Color primary;

  const _HeroBannerCard({
    required this.completedCount,
    required this.totalTasks,
    required this.streak,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = completedCount >= totalTasks && totalTasks > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(primary, const Color(0xFF0A0A0F), 0.60)!,
            primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: primary.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.35),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pill label
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Daily Challenge',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isDone
                      ? 'All tasks done! 🎉'
                      : 'Complete all tasks\nbefore midnight',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.22,
                  ),
                ),
                const SizedBox(height: 16),
                // Progress segments
                Row(
                  children: List.generate(totalTasks > 0 ? totalTasks : 3, (i) {
                    return Expanded(
                      child: Container(
                        height: 6,
                        margin: EdgeInsets.only(right: i < totalTasks - 1 ? 6 : 0),
                        decoration: BoxDecoration(
                          color: i < completedCount
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right: streak counter
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 38)),
              const SizedBox(height: 2),
              Text(
                '$streak',
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              Text(
                'day streak',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Week Strip Card ────────────────────────────────────────────────────────

class _WeekStripCard extends StatelessWidget {
  final int streak;
  final int bestStreak;
  final int weeklyPoints;
  final DateTime? streakStartDate;
  final String lastStreakDate;
  final String weekStartDate;
  final LeagueInfo league;
  final Color primary;

  const _WeekStripCard({
    required this.streak,
    required this.bestStreak,
    required this.weeklyPoints,
    required this.streakStartDate,
    required this.lastStreakDate,
    required this.weekStartDate,
    required this.league,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Week starts on Monday (weekday == 1)
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    DateTime? lastStreakDay;
    if (lastStreakDate.isNotEmpty) {
      try {
        final parts = lastStreakDate.split('-');
        lastStreakDay = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      } catch (_) {}
    }

    const dayAbbrevs = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _monthName(now.month),
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${now.year}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
              // Streak pill
              Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC6E05B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: const Color(0xFFC6E05B).withValues(alpha: 0.35)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC6E05B).withValues(alpha: 0.20),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            color: Color(0xFFF07845), size: 15),
                        const SizedBox(width: 5),
                        Text(
                          '$streak day${streak == 1 ? '' : 's'}',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFC6E05B),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.03, 1.03),
                    duration: 1500.ms,
                    curve: Curves.easeInOut,
                  ),
            ],
          ),
          const SizedBox(height: 20),

          // 7-day week strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final day = weekStart.add(Duration(days: i));
              final isToday = _isSameDay(day, now);
              final isFuture = day.isAfter(now) && !isToday;

              bool isStreakDay = false;
              if (streakStartDate != null && lastStreakDay != null) {
                isStreakDay = !day.isBefore(streakStartDate!) &&
                    !day.isAfter(lastStreakDay) &&
                    !isToday;
              }

              return Column(
                children: [
                  // Day abbreviation
                  Text(
                    dayAbbrevs[i],
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isToday
                          ? Colors.white
                          : Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Day number circle
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isToday
                          ? Colors.white
                          : isStreakDay
                              ? primary.withValues(alpha: 0.09)
                              : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: isToday || isStreakDay
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isToday
                              ? const Color(0xFF1C1C1E)
                              : isStreakDay
                                  ? primary
                                  : isFuture
                                      ? Colors.white24
                                      : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Activity dot
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isStreakDay
                          ? primary
                          : isToday
                              ? const Color(0xFFC6E05B)
                              : Colors.transparent,
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          // Bottom stat bubbles
          Row(
            children: [
              _StatBubble(
                icon: Icons.star_rounded,
                value: '$weeklyPoints pts',
                label: _weekLabel(weekStartDate),
                color: primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const XpHistoryScreen()),
                ),
              ),
              const SizedBox(width: 10),
              _StatBubble(
                icon: Icons.emoji_events_rounded,
                value: '$bestStreak days',
                label: 'Best Streak',
                color: primary,
              ),
              const SizedBox(width: 10),
              // League indicator replacing the old date/month bubble
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: league.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: league.color.withValues(alpha: 0.22), width: 1),
                  ),
                  child: Column(
                    children: [
                      Icon(league.icon, color: league.color, size: 18),
                      const SizedBox(height: 4),
                      Text(
                        league.displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: league.color,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'League',
                        style: GoogleFonts.poppins(
                            fontSize: 9, color: Colors.white38),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _weekLabel(String weekStartStr) {
    if (weekStartStr.isEmpty) return 'pts this week';
    try {
      final parts = weekStartStr.split('-');
      if (parts.length < 3) return 'pts this week';
      final start = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final end = start.add(const Duration(days: 6));
      const ma = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${ma[start.month - 1]} ${start.day} – ${ma[end.month - 1]} ${end.day}';
    } catch (_) {
      return 'pts this week';
    }
  }
}

// ── Stat Bubble ────────────────────────────────────────────────────────────

class _StatBubble extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _StatBubble({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
                fontSize: 9, color: Colors.white38),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (onTap != null) {
      content = GestureDetector(onTap: onTap, child: content);
    }
    return Expanded(child: content);
  }
}

// ── Today's Plan Horizontal Scroll ─────────────────────────────────────────

class _TodaysPlanScroll extends StatelessWidget {
  final List<DailyTask> tasks;
  final Color primary;

  const _TodaysPlanScroll({required this.tasks, required this.primary});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          'Loading tasks…',
          style: GoogleFonts.poppins(
              color: Colors.white38, fontSize: 14),
        ),
      );
    }
    return SizedBox(
      height: 206,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: tasks.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) =>
            _PlanCard(task: tasks[i], slotIndex: i, primary: primary),
      ),
    );
  }
}

// ── Plan Card ──────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final DailyTask task;
  final int slotIndex;
  final Color primary;

  const _PlanCard({
    required this.task,
    required this.slotIndex,
    required this.primary,
  });

  static const _tagLabels = ['Easy', 'Medium', 'Hard'];

  /// Generate 3 harmonious card tints from the primary seed:
  /// slot 0 = primary lightened 55% (light/soft),
  /// slot 1 = primary itself,
  /// slot 2 = primary darkened 20% (rich/deep).
  List<Color> _cardColors() {
    return [
      Color.lerp(primary, Colors.white, 0.55)!,
      primary,
      Color.lerp(primary, Colors.black, 0.22)!,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final idx = slotIndex.clamp(0, 2);
    final colors = _cardColors();
    final bg = task.isCompleted ? colors[idx].withValues(alpha: 0.55) : colors[idx];
    final tag = _tagLabels[idx];

    // Light cards need dark text; dark cards need white text.
    final luminance = bg.computeLuminance();
    final textColor = luminance > 0.45 ? const Color(0xFF1C1C1E) : Colors.white;

    return GestureDetector(
      onTap: () => _navigate(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 158,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: colors[idx].withValues(alpha: 0.42),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Difficulty pill + optional done check
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
                if (task.isCompleted)
                  Icon(
                    Icons.check_circle_rounded,
                    color: textColor.withValues(alpha: 0.85),
                    size: 18,
                  ),
              ],
            ),
            const Spacer(),
            // Game icon from Brain Hub icon set
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _taskIcon(task.type),
                size: 24,
                color: textColor,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.06, 1.06),
                  duration: 1800.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 6),
            // Game name
            Text(
              task.title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textColor,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // XP reward
            Text(
              '+${task.xpReward} XP',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context) {
    // Brain game screens self-manage difficulty via BrainDifficultySelector.
    // The original 5 games are driven by GameProvider internally.
    final Widget screen = switch (task.type) {
      // ── Logic ─────────────────────────────────────────────────────────────
      TaskType.mathSprint        => const CountdownMathScreen(),
      TaskType.memory            => const ActionSequenceRecallScreen(),
      TaskType.logic             => const SumSnakeScreen(),
      TaskType.schulte           => const BinaryPuzzleScreen(),
      TaskType.stroop            => const AkariScreen(),
      // ── Speed ─────────────────────────────────────────────────────────────
      TaskType.reactionTimeTap   => const CountdownMathScreen(),
      TaskType.numberRush        => const CountdownMathScreen(),
      TaskType.whackATarget      => const AttentionalBlinkScreen(),
      TaskType.speedSort         => const CountdownMathScreen(),
      // ── Memory ────────────────────────────────────────────────────────────
      TaskType.cardMatch         => const ActionSequenceRecallScreen(),
      TaskType.sequenceRecall    => const ActionSequenceRecallScreen(),
      TaskType.nBack             => const ActionSequenceRecallScreen(),
      TaskType.memoryPalace      => const ActionSequenceRecallScreen(),
      // ── Focus ─────────────────────────────────────────────────────────────
      TaskType.stroopTest        => const AttentionalBlinkScreen(),
      TaskType.sart              => const AttentionalBlinkScreen(),
      TaskType.spotTheDifference => const AttentionalBlinkScreen(),
      // ── Logic ─────────────────────────────────────────────────────────────
      TaskType.twentyFourGame    => const CountdownMathScreen(),
      TaskType.slidingPuzzle     => const BinaryPuzzleScreen(),
      TaskType.patternCompletion => const AkariScreen(),
      TaskType.miniSudoku        => const BinaryPuzzleScreen(),
      // ── Verbal ────────────────────────────────────────────────────────────
      TaskType.wordChains        => const WordWheelScreen(),
      TaskType.anagramSolver     => const WordWheelScreen(),
      TaskType.categoryBlitz     => const WordWheelScreen(),
      TaskType.mentalRotation    => const BalanceScaleScreen(),
      TaskType.mazeNavigator     => const BalanceScaleScreen(),
    };

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

// ── Did You Know Card ──────────────────────────────────────────────────────

class _DidYouKnowCard extends StatelessWidget {
  final VoidCallback onTap;

  const _DidYouKnowCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0A2E), Color(0xFF6B21A8)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.30),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Did You Know?',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Explore Mind-Blowing Facts',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '10 facts inside  →',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
