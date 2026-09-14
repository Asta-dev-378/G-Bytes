/// Identifies the type of brain game tied to a daily task.
/// 25 games total: 5 original G-Bytes games + 20 Brain Hub games.
enum TaskType {
  // ── Original 5 G-Bytes games ─────────────────────────────────────────
  mathSprint,
  memory,
  logic,
  schulte,
  stroop,

  // ── Brain Hub games ── Speed ──────────────────────────────────────────
  reactionTimeTap,
  numberRush,
  whackATarget,
  speedSort,

  // ── Brain Hub games ── Memory ─────────────────────────────────────────
  cardMatch,
  sequenceRecall,
  nBack,
  memoryPalace,

  // ── Brain Hub games ── Focus ──────────────────────────────────────────
  stroopTest,
  sart,
  spotTheDifference,

  // ── Brain Hub games ── Logic ──────────────────────────────────────────
  twentyFourGame,
  slidingPuzzle,
  patternCompletion,
  miniSudoku,

  // ── Brain Hub games ── Verbal ─────────────────────────────────────────
  wordChains,
  anagramSolver,
  categoryBlitz,

  // ── Brain Hub games ── Spatial ────────────────────────────────────────
  mentalRotation,
  mazeNavigator,
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
        '_v': 1,
        'type': type.name,
        'title': title,
        'description': description,
        'icon': icon,
        'xpReward': xpReward,
        'isCompleted': isCompleted,
      };

  factory DailyTask.fromJson(Map<String, dynamic> json) {
    // '_v' field added in schema v1. Absent == v0, treated identically.
    // Future versions: check json['_v'] and apply migrations here.
    return DailyTask(
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
}

/// Difficulty tiers for the daily task rotation.
/// Each tier contains games of roughly equivalent cognitive demand.
/// When adding new games, assign them to the appropriate tier.
class GameTier {
  /// Easy games — assigned to Task slot 0 (10 XP).
  /// Fast, instinctive, low rule complexity.
  static const List<TaskType> easy = [
    TaskType.mathSprint,
    TaskType.memory,
    TaskType.reactionTimeTap,
    TaskType.numberRush,
    TaskType.whackATarget,
    TaskType.speedSort,
    TaskType.cardMatch,
    TaskType.sequenceRecall,
  ];

  /// Medium games — assigned to Task slot 1 (20 XP).
  /// Require sustained attention or working memory.
  static const List<TaskType> medium = [
    TaskType.logic,
    TaskType.schulte,
    TaskType.stroopTest,
    TaskType.sart,
    TaskType.wordChains,
    TaskType.anagramSolver,
    TaskType.categoryBlitz,
    TaskType.patternCompletion,
    TaskType.memoryPalace,
    TaskType.spotTheDifference,
  ];

  /// Hard games — assigned to Task slot 2 (30 XP).
  /// High rule complexity, sustained focus, or multi-step reasoning.
  static const List<TaskType> hard = [
    TaskType.stroop,
    TaskType.nBack,
    TaskType.twentyFourGame,
    TaskType.slidingPuzzle,
    TaskType.mentalRotation,
    TaskType.mazeNavigator,
    TaskType.miniSudoku,
  ];
}

/// XP values for each task slot (ordered easy → hard).
class TaskXp {
  static const int task1 = 10; // Easy
  static const int task2 = 20; // Medium
  static const int task3 = 30; // Hard
  static const int dailyMax = task1 + task2 + task3; // 60 XP / day
  static const int weeklyMax = dailyMax * 7; // 420 XP / week
}
