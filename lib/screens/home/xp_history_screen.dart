import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/game_provider.dart';
import '../../providers/settings_provider.dart';

class XpHistoryScreen extends StatelessWidget {
  const XpHistoryScreen({super.key});

  String _formatWeekStr(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        final date = DateTime(year, month, day);
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return 'Week of ${months[date.month - 1]} ${date.day}';
      }
    } catch (_) {}
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final primary = context.watch<SettingsProvider>().appSeedColor;

    final history = game.xpHistory;
    final currentPoints = game.weeklyPoints;
    final lastWeekPoints = game.lastWeekPoints;

    // Efficiency: how much of the weekly max (60 XP/day × 7 = 420) was earned
    final efficiency = (currentPoints / 420 * 100).clamp(0.0, 100.0).round();
    final delta = currentPoints - lastWeekPoints;
    final hasLastWeek = lastWeekPoints > 0;

    int totalXp = currentPoints;
    int bestXp = currentPoints;
    int activeWeeks = 1;

    for (final item in history) {
      final parts = item.split('|');
      if (parts.length == 2) {
        final pts = int.tryParse(parts[1]) ?? 0;
        totalXp += pts;
        if (pts > bestXp) bestXp = pts;
        activeWeeks++;
      }
    }

    final averageXp = (totalXp / activeWeeks).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: const Color(0xFFF5F5F5),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              title: Text(
                'XP History',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
            iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Analytics Cards
                Row(
                  children: [
                    Expanded(
                      child: _AnalyticsCard(
                        title: 'Total XP',
                        value: '$totalXp',
                        icon: Icons.auto_awesome_rounded,
                        color: primary,
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _AnalyticsCard(
                        title: 'Best Week',
                        value: '$bestXp',
                        icon: Icons.emoji_events_rounded,
                        color: const Color(0xFFFFB300),
                      ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
                    ),
                    const SizedBox(width: 16),
                     Expanded(
                      child: _AnalyticsCard(
                        title: 'Avg / Week',
                        value: '$averageXp',
                        icon: Icons.trending_up_rounded,
                        color: const Color(0xFF20BC68),
                      ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                Text(
                  'Weekly Breakdown',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ).animate(delay: 300.ms).fadeIn(),
                const SizedBox(height: 16),

                // Current Week
                _HistoryRow(
                  title: 'This Week',
                  points: currentPoints,
                  isCurrent: true,
                  color: primary,
                  efficiency: efficiency,
                  delta: hasLastWeek ? delta : null,
                ).animate(delay: 350.ms).fadeIn().slideX(begin: 0.1),

                const SizedBox(height: 12),

                if (history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No past history yet.\nKeep training to build your legacy!",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ).animate(delay: 400.ms).fadeIn(),
                    ),
                  ),

                // Past Weeks
                ...List.generate(history.length, (index) {
                  final parts = history[index].split('|');
                  if (parts.length != 2) return const SizedBox.shrink();
                  
                  final dateLabel = _formatWeekStr(parts[0]);
                  final pts = int.tryParse(parts[1]) ?? 0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HistoryRow(
                      title: dateLabel,
                      points: pts,
                      isCurrent: false,
                      color: primary,
                    ).animate(delay: (400 + (index * 50)).ms).fadeIn().slideX(begin: 0.05),
                  );
                }),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final String title;
  final int points;
  final bool isCurrent;
  final Color color;
  final int? efficiency; // 0-100 percent
  final int? delta;      // delta vs last week (null = no data)

  const _HistoryRow({
    required this.title,
    required this.points,
    required this.isCurrent,
    required this.color,
    this.efficiency,
    this.delta,
  });

  @override
  Widget build(BuildContext context) {
    final deltaColor = (delta ?? 0) >= 0
        ? const Color(0xFF1A7A50)
        : Colors.red.shade600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isCurrent ? color.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrent
            ? Border.all(color: color.withValues(alpha: 0.3), width: 1.5)
            : Border.all(color: Colors.transparent, width: 1.5),
        boxShadow: isCurrent
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCurrent ? color : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCurrent ? Icons.star_rounded : Icons.check_circle_rounded,
                      color: isCurrent ? Colors.white : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight:
                          isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$points',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isCurrent ? color : const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'pts',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Efficiency + delta sub-row (current week only)
          if (isCurrent && efficiency != null) ...[  
            const SizedBox(height: 10),
            Row(
              children: [
                // Efficiency badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$efficiency% efficiency',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                if (delta != null) ...[  
                  const SizedBox(width: 8),
                  Icon(
                    delta! >= 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 14,
                    color: deltaColor,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    delta! >= 0
                        ? '+$delta pts vs last week'
                        : '$delta pts vs last week',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: deltaColor,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
