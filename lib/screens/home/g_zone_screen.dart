import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/settings_provider.dart';
import '../games/training_hub_screen.dart';
import '../knowledge/did_you_know_screen.dart';
import '../../models/league.dart';
import '../profile/profile_screen.dart';
import '../../features/streak/models/daily_task.dart';
import 'xp_history_screen.dart';

class GZoneScreen extends StatelessWidget {
  const GZoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final game = context.watch<GameProvider>();
    final primary = context.watch<SettingsProvider>().appSeedColor;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: const Color(0xFFF5F5F5),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${user.userName ?? 'Champion'} 👋',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'G-Zone',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  child: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    radius: 20,
                    child: Text(
                      (user.userName?[0] ?? 'G').toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Calendar + Streaks Section
                _CalendarStreakCard(
                  streak: game.streak,
                  bestStreak: game.bestStreak,
                  weeklyPoints: game.weeklyPoints,
                  streakStartDate: game.streakStartDate,
                  lastStreakDate: game.lastStreakDate,
                  weekStartDate: game.weekStartDate,
                  primary: primary,
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 16),

                // League Badge
                _LeagueBadgeCard(
                  league: game.league,
                  totalPoints: game.totalPoints,
                  progress: game.leagueProgress,
                  pointsToNext: game.pointsToNextLeague,
                  isMax: game.isMaxLeague,
                ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.15, end: 0),
                const SizedBox(height: 16),

                // Daily Tasks Card
                _DailyTasksCard(
                  tasks: game.dailyTasks,
                  completedCount: game.completedTaskCount,
                  primary: primary,
                ).animate(delay: 130.ms).fadeIn().slideY(begin: 0.15, end: 0),
                const SizedBox(height: 22),

                // Section Label
                _sectionLabel('Brain Training'),
                const SizedBox(height: 12),

                // Brain Game Card
                _BrainGameCard(
                  primary: primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TrainingHubScreen(),
                    ),
                  ),
                ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.15, end: 0),
                const SizedBox(height: 24),

                _sectionLabel('Did You Know?'),
                const SizedBox(height: 12),
                _DidYouKnowCard(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DidYouKnowScreen()),
                  ),
                ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.15, end: 0),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A1A1A),
      ),
    );
  }
}

// ── Calendar + Streak Card ──────────────────────────────────────────────────

class _CalendarStreakCard extends StatelessWidget {
  final int streak;
  final int bestStreak;
  final int weeklyPoints;
  final DateTime? streakStartDate;
  final String lastStreakDate;
  final String weekStartDate;
  final Color primary;
  const _CalendarStreakCard({
    required this.streak,
    required this.bestStreak,
    required this.weeklyPoints,
    required this.streakStartDate,
    required this.lastStreakDate,
    required this.weekStartDate,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final today = now.day;

    // Generate week day headers
    const weekDays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    // First weekday of this month (0=Mon through 6=Sun)
    final firstDay = DateTime(now.year, now.month, 1).weekday - 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: month name + streak
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _monthName(now.month),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    '${now.year}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              // Streak chip
              Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary, primary.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$streak Day Streak!',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
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
          const SizedBox(height: 18),

          // Week day headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays
                .map(
                  (d) => SizedBox(
                    width: 32,
                    child: Center(
                      child: Text(
                        d,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),

          // Calendar grid
          _CalendarGrid(
            daysInMonth: daysInMonth,
            firstWeekday: firstDay,
            today: today,
            now: now,
            streakStartDate: streakStartDate,
            lastStreakDate: lastStreakDate,
            primary: primary,
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Bottom stats row
          Row(
            children: [
              _StatBubble(
                icon: Icons.star_rounded,
                value: '$weeklyPoints pts',
                label: _weekLabel(weekStartDate),
                color: const Color(0xFF6C63FF),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const XpHistoryScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              _StatBubble(
                icon: Icons.emoji_events_rounded,
                value: '$bestStreak days',
                label: 'Best Streak',
                color: primary,
              ),
              const SizedBox(width: 12),
              _StatBubble(
                icon: Icons.calendar_today_rounded,
                value: '${now.day}',
                label: _monthName(now.month).substring(0, 3),
                color: const Color(0xFF20BC68),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[m - 1];
  }

  /// Returns a short label like "Mon Apr 7 – Sun Apr 13"
  String _weekLabel(String weekStartStr) {
    if (weekStartStr.isEmpty) return 'pts this week';
    try {
      final parts = weekStartStr.split('-');
      if (parts.length < 3) return 'pts this week';
      final start = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final end = start.add(const Duration(days: 6));
      const monthAbbr = [
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec',
      ];
      return '${monthAbbr[start.month-1]} ${start.day} - ${monthAbbr[end.month-1]} ${end.day}';
    } catch (_) {
      return 'pts this week';
    }
  }
}

class _CalendarGrid extends StatelessWidget {
  final int daysInMonth;
  final int firstWeekday;
  final int today;
  final DateTime now;
  final DateTime? streakStartDate;
  final String lastStreakDate;
  final Color primary;
  const _CalendarGrid({
    required this.daysInMonth,
    required this.firstWeekday,
    required this.today,
    required this.now,
    required this.streakStartDate,
    required this.lastStreakDate,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final totalCells = firstWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();
    // Copy nullable field to local for flow analysis promotion
    final localStreakStart = streakStartDate;

    // Parse lastStreakDate to know the end of streak
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

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (col) {
            final index = row * 7 + col;
            final day = index - firstWeekday + 1;
            if (day < 1 || day > daysInMonth) {
              return const SizedBox(width: 32, height: 32);
            }
            final isToday = day == today;

            // Check if this calendar day falls within the streak range
            // using actual dates (safe across month boundaries)
            bool isStreakDay = false;
            if (localStreakStart != null && lastStreakDay != null) {
              final start = localStreakStart;
              final end = lastStreakDay;
              final cellDate = DateTime(now.year, now.month, day);
              isStreakDay = !cellDate.isBefore(start) &&
                  !cellDate.isAfter(end) &&
                  !isToday;
            }

            Color bg = Colors.transparent;
            Color textColor = const Color(0xFF1A1A1A);
            if (isToday) {
              bg = primary;
              textColor = Colors.white;
            } else if (isStreakDay) {
              bg = primary.withValues(alpha: 0.15);
              textColor = primary;
            }

            return SizedBox(
              width: 32,
              height: 36,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: GoogleFonts.poppins(
                        fontSize: isToday ? 13 : 12,
                        fontWeight: isToday || isStreakDay
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }
}

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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );

    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return Expanded(child: content);
  }
}

// ── Brain Game Card ─────────────────────────────────────────────────────────

class _BrainGameCard extends StatelessWidget {
  final VoidCallback onTap;
  final Color primary;
  const _BrainGameCard({required this.onTap, required this.primary});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.psychology_alt_rounded,
                color: primary,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Brain Training',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    'Memory • Logic • Math Sprint',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: primary),
          ],
        ),
      ),
    );
  }
}

// ── Did You Know Card ───────────────────────────────────────────────────────

class _DidYouKnowCard extends StatelessWidget {
  final VoidCallback onTap;
  const _DidYouKnowCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6C63FF).withValues(alpha: 0.9),
              const Color(0xFF9C88FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Did You Know?',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Explore 10 Mind-Blowing Facts',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to Discover →',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.lightbulb_rounded,
              size: 48,
              color: Colors.white54,
            ),
          ],
        ),
      ),
    );
  }
}

// ── League Badge Card ──────────────────────────────────────────────────────

class _LeagueBadgeCard extends StatelessWidget {
  final LeagueInfo league;
  final int totalPoints;
  final double progress;
  final int pointsToNext;
  final bool isMax;

  const _LeagueBadgeCard({
    required this.league,
    required this.totalPoints,
    required this.progress,
    required this.pointsToNext,
    required this.isMax,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: league.bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: league.color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: league.color.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // League icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: league.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: league.color.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Icon(league.icon, color: league.color, size: 28),
          ),
          const SizedBox(width: 16),

          // League name + progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  league.displayName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: league.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isMax
                      ? 'Max League Reached! 🏆'
                      : '$pointsToNext pts to next level',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: league.color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(league.color),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Total points badge
          Column(
            children: [
              Text(
                '$totalPoints',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: league.color,
                ),
              ),
              Text(
                'pts',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade500,
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

// ── Daily Tasks Card ─────────────────────────────────────────────────────────

class _DailyTasksCard extends StatelessWidget {
  final List<DailyTask> tasks;
  final int completedCount;
  final Color primary;

  const _DailyTasksCard({
    required this.tasks,
    required this.completedCount,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final total = tasks.isEmpty ? 3 : tasks.length;
    final allDone = completedCount >= total && total > 0;
    final progress = total > 0 ? completedCount / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Tasks',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    allDone
                        ? 'All done! Come back tomorrow 🌟'
                        : '$completedCount / $total tasks complete',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: allDone ? primary : Colors.grey.shade500,
                      fontWeight:
                          allDone ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
              if (allDone)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF20BC68).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '🎉 All Done!',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF20BC68),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(
                allDone ? const Color(0xFF20BC68) : primary,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Task rows
          if (tasks.isEmpty)
            Center(
              child: Text(
                'Loading tasks...',
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            )
          else
            ...tasks.asMap().entries.map((entry) {
              final i = entry.key;
              final task = entry.value;
              return _TaskRow(
                task: task,
                slotIndex: i,
                primary: primary,
              );
            }),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final DailyTask task;
  final int slotIndex;
  final Color primary;

  const _TaskRow({
    required this.task,
    required this.slotIndex,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF20BC68), // Easy — green
      const Color(0xFF6C63FF), // Medium — purple
      const Color(0xFFFF6B6B), // Hard — red-orange
    ];
    final slotColor = colors[slotIndex.clamp(0, 2)];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: task.isCompleted
              ? slotColor.withValues(alpha: 0.08)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: task.isCompleted
                ? slotColor.withValues(alpha: 0.35)
                : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Text(task.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),

            // Title + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: task.isCompleted
                          ? slotColor
                          : const Color(0xFF1A1A1A),
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: slotColor,
                    ),
                  ),
                  Text(
                    task.description,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // XP chip
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: slotColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '+${task.xpReward} XP',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: slotColor,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Checkmark
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: task.isCompleted
                  ? Icon(
                      Icons.check_circle_rounded,
                      key: const ValueKey('check'),
                      color: slotColor,
                      size: 22,
                    )
                  : Icon(
                      Icons.radio_button_unchecked_rounded,
                      key: const ValueKey('uncheck'),
                      color: Colors.grey.shade300,
                      size: 22,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
