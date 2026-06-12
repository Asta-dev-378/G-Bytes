import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/streak_provider.dart';

class StreakCalendarWidget extends StatelessWidget {
  final Color primaryColor;

  const StreakCalendarWidget({
    super.key,
    this.primaryColor = const Color(0xFF6C63FF), // Default purple
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<StreakProvider>(builder: (context, provider, _) {
      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      
      // Weekday: 1=Monday -> 7=Sunday. We map to 0=Monday -> 6=Sunday.
      final firstDay = DateTime(now.year, now.month, 1).weekday - 1;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            // Top Header: Month + Current Streak chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _monthName(now.month),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      '${now.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_fire_department, color: primaryColor, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${provider.currentStreak} Day Streak',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            
            // Days of the Week Header Map
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                  .map((e) => SizedBox(
                        width: 36,
                        child: Center(
                          child: Text(e,
                              style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            
            // Calendar Grid generated row by row
            _buildCalendarGrid(daysInMonth, firstDay, now, provider),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            
            // Helpful indicators mapping
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Info: Weekly points
                Row(
                  children: [
                    Icon(Icons.star_rounded, color: Colors.orange, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${provider.weeklyPoints} Pts This Week',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      );
    });
  }

  Widget _buildCalendarGrid(
      int daysInMonth, int firstDay, DateTime now, StreakProvider provider) {
    int totalCells = firstDay + daysInMonth;
    int numRows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(numRows, (row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (col) {
              int index = row * 7 + col;
              int day = index - firstDay + 1;

              if (day < 1 || day > daysInMonth) {
                // Empty slots before 1st and after the end of month
                return const SizedBox(width: 40, height: 40);
              }

              // Normalizing dates for dict lookup
              final dt = DateTime(now.year, now.month, day);
              final dateStr = _getDateStr(dt);
              final yesterdayStr = _getDateStr(dt.subtract(const Duration(days: 1)));
              final tomorrowStr = _getDateStr(dt.add(const Duration(days: 1)));

              final isCompleted = provider.history[dateStr]?.isCompleted ?? false;
              final prevCompleted = provider.history[yesterdayStr]?.isCompleted ?? false;
              final nextCompleted = provider.history[tomorrowStr]?.isCompleted ?? false;

              // Streak connections apply only if the neighbor is in the SAME week (same row).
              bool connectLeft = isCompleted && prevCompleted && col > 0;
              bool connectRight = isCompleted && nextCompleted && col < 6;
              final isToday = day == now.day;

              return SizedBox(
                width: 40,
                height: 48,
                child: Stack(
                  children: [
                    // Connected line background behind the circle
                    if (isCompleted)
                      Positioned(
                        top: 8,
                        bottom: 8,
                        left: connectLeft ? 0 : 20,
                        right: connectRight ? 0 : 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.horizontal(
                              left: connectLeft
                                  ? Radius.zero
                                  : const Radius.circular(16),
                              right: connectRight
                                  ? Radius.zero
                                  : const Radius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    
                    // The day circle itself
                    Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? primaryColor
                              : isToday 
                                ? primaryColor.withValues(alpha: 0.1) 
                                : Colors.transparent,
                          border: isToday && !isCompleted 
                              ? Border.all(color: primaryColor, width: 2) 
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              color: isCompleted 
                                ? Colors.white 
                                : (isToday ? primaryColor : Colors.black87),
                              fontWeight: isCompleted || isToday 
                                ? FontWeight.w800 
                                : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  String _getDateStr(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  String _monthName(int month) {
    const list = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return list[month - 1];
  }
}
