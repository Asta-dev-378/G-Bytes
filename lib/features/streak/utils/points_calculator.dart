import '../models/daily_task.dart';

/// Central XP constants for G-Bytes' task-based reward system.
///
/// XP is awarded once per completed daily task — NOT per individual
/// game answer. Game-specific per-answer calculations have been removed.
///
/// To add new XP values or task types, update [TaskXp] in daily_task.dart
/// and add a corresponding [TaskType] entry there.
class PointsCalculator {
  PointsCalculator._();

  /// Returns the XP reward for a task in the given slot index (0, 1, 2).
  /// Slot 0 = easy (10 XP), slot 1 = medium (20 XP), slot 2 = hard (30 XP).
  static int xpForSlot(int slotIndex) {
    switch (slotIndex) {
      case 0:
        return TaskXp.task1;
      case 1:
        return TaskXp.task2;
      case 2:
        return TaskXp.task3;
      default:
        return TaskXp.task1;
    }
  }
}
