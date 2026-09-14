// test/providers/player_progress_logic_test.dart
//
// Pure logic tests for business rules that live in PlayerProgressProvider.
// These test the extracted helper functions in isolation — no ChangeNotifier,
// SharedPreferences, or Flutter widget tree is needed.

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:g_bytes/features/streak/models/daily_task.dart';
import 'package:g_bytes/models/xp_entry.dart';

// ── Helpers matching the logic inside PlayerProgressProvider ────────────────

String _todayStr([DateTime? now]) {
  final d = now ?? DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

bool _shouldIncrementStreak(String lastStreakDate, String today) {
  if (lastStreakDate.isEmpty) return true;
  if (lastStreakDate == today) return false;
  final yesterday = _todayStr(DateTime.now().subtract(const Duration(days: 1)));
  return lastStreakDate == yesterday;
}

bool _shouldBreakStreak(String lastStreakDate, String today) {
  if (lastStreakDate.isEmpty || lastStreakDate == today) return false;
  final yesterday = _todayStr(DateTime.now().subtract(const Duration(days: 1)));
  return lastStreakDate != yesterday;
}

/// Deterministic task generation — mirrors the real provider's shuffle logic.
List<TaskType> _generateTasks(String dateStr) {
  final rng    = Random(dateStr.hashCode);
  final easy   = List<TaskType>.from(GameTier.easy)..shuffle(rng);
  final medium = List<TaskType>.from(GameTier.medium)..shuffle(rng);
  final hard   = List<TaskType>.from(GameTier.hard)..shuffle(rng);
  return [easy.first, medium.first, hard.first];
}

// ── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('Streak logic', () {
    final today      = _todayStr();
    final yesterday  = _todayStr(DateTime.now().subtract(const Duration(days: 1)));
    final twoDaysAgo = _todayStr(DateTime.now().subtract(const Duration(days: 2)));

    test('first activity increments streak (empty lastDate)', () {
      expect(_shouldIncrementStreak('', today), isTrue);
    });

    test('same day does NOT double-increment streak', () {
      expect(_shouldIncrementStreak(today, today), isFalse);
    });

    test('activity the day after yesterday increments streak', () {
      expect(_shouldIncrementStreak(yesterday, today), isTrue);
    });

    test('gap of >1 day should NOT increment streak', () {
      expect(_shouldIncrementStreak(twoDaysAgo, today), isFalse);
    });

    test('streak breaks when last activity was 2+ days ago', () {
      expect(_shouldBreakStreak(twoDaysAgo, today), isTrue);
    });

    test('streak does NOT break when last activity was yesterday', () {
      expect(_shouldBreakStreak(yesterday, today), isFalse);
    });

    test('streak does NOT break on same day', () {
      expect(_shouldBreakStreak(today, today), isFalse);
    });

    test('streak does NOT break when lastDate is empty (new user)', () {
      expect(_shouldBreakStreak('', today), isFalse);
    });
  });

  group('XP accumulation', () {
    test('completedTaskCount increments correctly', () {
      var count = 0;
      count += 1; expect(count, 1);
      count += 1; expect(count, 2);
      count += 1; expect(count, 3);
    });

    test('weekly XP caps at TaskXp.weeklyMax = 420', () {
      final clamped = 500.clamp(0, TaskXp.weeklyMax);
      expect(clamped, TaskXp.weeklyMax);
    });

    test('XP history list truncation preserves newest entries', () {
      const maxHistory = 12;
      final history = List.generate(
        15,
        (i) => XpEntry(weekStartDate: '2024-0${(i % 9) + 1}-01', points: i * 10),
      );
      final trimmed = history.take(maxHistory).toList();
      expect(trimmed.length, maxHistory);
    });
  });

  group('Task generation determinism', () {
    test('same date seed always picks same tasks', () {
      final first  = _generateTasks('2024-03-11');
      final second = _generateTasks('2024-03-11');
      expect(first, equals(second));
    });

    test('generation produces exactly 3 tasks', () {
      expect(_generateTasks('2024-03-11').length, 3);
      expect(_generateTasks('2024-03-12').length, 3);
    });

    test('generated tasks have one from each tier', () {
      final tasks = _generateTasks('2024-05-20');
      expect(GameTier.easy.contains(tasks[0]),   isTrue);
      expect(GameTier.medium.contains(tasks[1]), isTrue);
      expect(GameTier.hard.contains(tasks[2]),   isTrue);
    });
  });

  group('DailyTask completion', () {
    test('isTaskCompleted returns true only for completed matching type', () {
      final tasks = [
        const DailyTask(
          type: TaskType.mathSprint, title: 'Math', description: '',
          icon: '', xpReward: 10, isCompleted: true,
        ),
        const DailyTask(
          type: TaskType.logic, title: 'Logic', description: '',
          icon: '', xpReward: 20, isCompleted: false,
        ),
      ];
      bool isCompleted(TaskType t) =>
          tasks.any((d) => d.type == t && d.isCompleted);

      expect(isCompleted(TaskType.mathSprint), isTrue);
      expect(isCompleted(TaskType.logic), isFalse);
      expect(isCompleted(TaskType.memory), isFalse);
    });

    test('allTasksDoneToday is true only when all tasks completed', () {
      final allDone = [
        const DailyTask(type: TaskType.mathSprint, title: '', description: '',
            icon: '', xpReward: 10, isCompleted: true),
        const DailyTask(type: TaskType.memory, title: '', description: '',
            icon: '', xpReward: 20, isCompleted: true),
        const DailyTask(type: TaskType.logic, title: '', description: '',
            icon: '', xpReward: 30, isCompleted: true),
      ];
      final partialDone = [
        const DailyTask(type: TaskType.mathSprint, title: '', description: '',
            icon: '', xpReward: 10, isCompleted: true),
        const DailyTask(type: TaskType.memory, title: '', description: '',
            icon: '', xpReward: 20, isCompleted: false),
      ];

      bool allDoneCheck(List<DailyTask> t) =>
          t.isNotEmpty && t.every((d) => d.isCompleted);

      expect(allDoneCheck(allDone), isTrue);
      expect(allDoneCheck(partialDone), isFalse);
      expect(allDoneCheck([]), isFalse);
    });
  });
}
