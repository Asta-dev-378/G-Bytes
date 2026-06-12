/// Identifies the type of brain game tied to a daily task.
/// Add new game types here as new games are introduced — the rotation
/// system in GameProvider will automatically pick them up.
enum TaskType {
  mathSprint,
  memory,
  logic,
  schulte,
  stroop,
}

/// A single daily task that the user must complete to earn XP.
/// Tasks are ordered by difficulty (slot 0 = easiest, slot 2 = hardest).
class DailyTask {
  /// Which game must be played to complete this task.
  final TaskType type;

  /// Display title shown in the task card UI.
  final String title;

  /// Short description shown beneath the title.
  final String description;

  /// Emoji icon for the task card.
  final String icon;

  /// XP awarded on completion (slot-based: 10, 20, or 30).
  final int xpReward;

  /// Whether the user has already completed this task today.
  final bool isCompleted;

  const DailyTask({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.xpReward,
    this.isCompleted = false,
  });

  /// Returns a copy with [isCompleted] set to true.
  DailyTask complete() => DailyTask(
        type: type,
        title: title,
        description: description,
        icon: icon,
        xpReward: xpReward,
        isCompleted: true,
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'title': title,
        'description': description,
        'icon': icon,
        'xpReward': xpReward,
        'isCompleted': isCompleted,
      };

  factory DailyTask.fromJson(Map<String, dynamic> json) => DailyTask(
        type: TaskType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => TaskType.mathSprint,
        ),
        title: json['title'] as String,
        description: json['description'] as String,
        icon: json['icon'] as String,
        xpReward: json['xpReward'] as int,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}

/// Difficulty tier used to organize games for daily rotation.
/// When adding new games, assign them to the appropriate tier.
class GameTier {
  /// Easy games — assigned to Task 1 (10 XP).
  static const List<TaskType> easy = [TaskType.mathSprint, TaskType.memory];

  /// Medium games — assigned to Task 2 (20 XP).
  static const List<TaskType> medium = [TaskType.logic, TaskType.schulte];

  /// Hard games — assigned to Task 3 (30 XP).
  static const List<TaskType> hard = [TaskType.stroop];
}

/// XP values for each task slot (ordered easy → hard).
class TaskXp {
  static const int task1 = 10; // Easy
  static const int task2 = 20; // Medium
  static const int task3 = 30; // Hard
  static const int dailyMax = task1 + task2 + task3; // 60 XP / day
  static const int weeklyMax = dailyMax * 7; // 420 XP / week
}
