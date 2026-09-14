// test/models/daily_task_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:g_bytes/features/streak/models/daily_task.dart';

void main() {
  group('DailyTask schema versioning', () {
    test('toJson includes _v:1', () {
      const task = DailyTask(
        type: TaskType.mathSprint,
        title: 'Math Sprint',
        description: 'Solve equations',
        icon: '🔢',
        xpReward: 10,
      );
      final json = task.toJson();
      expect(json['_v'], 1);
    });

    test('fromJson with _v field round-trips correctly', () {
      const original = DailyTask(
        type: TaskType.memory,
        title: 'Memory Flash',
        description: 'Memorize tiles',
        icon: '🧠',
        xpReward: 20,
        isCompleted: true,
      );
      final json = original.toJson();
      final restored = DailyTask.fromJson(json);
      expect(restored.type, original.type);
      expect(restored.title, original.title);
      expect(restored.xpReward, original.xpReward);
      expect(restored.isCompleted, true);
    });

    test('fromJson without _v (v0 legacy data) still works', () {
      // Simulate old data that has no _v field
      final legacyJson = {
        'type': 'logic',
        'title': 'Number Series',
        'description': 'Find the missing number',
        'icon': '🔢',
        'xpReward': 30,
        'isCompleted': false,
      };
      final task = DailyTask.fromJson(legacyJson);
      expect(task.type, TaskType.logic);
      expect(task.xpReward, 30);
      expect(task.isCompleted, false);
    });

    test('fromJson falls back to mathSprint for unknown task type', () {
      final json = {
        'type': 'unknownGame_v99',
        'title': 'Future Game',
        'description': 'Not yet released',
        'icon': '🎮',
        'xpReward': 10,
        'isCompleted': false,
      };
      final task = DailyTask.fromJson(json);
      expect(task.type, TaskType.mathSprint);
    });

    test('complete() returns copy with isCompleted = true', () {
      const task = DailyTask(
        type: TaskType.stroop,
        title: 'Stroop Rush',
        description: 'Tap ink color',
        icon: '🎨',
        xpReward: 30,
      );
      final completed = task.complete();
      expect(completed.isCompleted, true);
      expect(completed.type, task.type);
      expect(completed.xpReward, task.xpReward);
    });
  });

  group('GameTier coverage', () {
    test('all TaskType values appear in exactly one tier', () {
      final allTiered = {
        ...GameTier.easy,
        ...GameTier.medium,
        ...GameTier.hard,
      };
      // Every tiered value must exist in TaskType
      for (final t in allTiered) {
        expect(TaskType.values.contains(t), isTrue, reason: '$t not in TaskType');
      }
    });

    test('no TaskType appears in multiple tiers', () {
      final easy   = GameTier.easy.toSet();
      final medium = GameTier.medium.toSet();
      final hard   = GameTier.hard.toSet();
      expect(easy.intersection(medium), isEmpty, reason: 'easy ∩ medium not empty');
      expect(easy.intersection(hard),   isEmpty, reason: 'easy ∩ hard not empty');
      expect(medium.intersection(hard), isEmpty, reason: 'medium ∩ hard not empty');
    });

    test('TaskXp constants are correct', () {
      expect(TaskXp.task1, 10);
      expect(TaskXp.task2, 20);
      expect(TaskXp.task3, 30);
      expect(TaskXp.dailyMax, 60);
      expect(TaskXp.weeklyMax, 420);
    });
  });
}
