// lib/providers/player_progress_provider.dart
// All XP, streak, weekly reset, daily tasks, league progress, and high-score
// records extracted from the old God-Object GameProvider.
//
// GameProvider now owns only the 5 game state machines.
// Screens that previously read progress from GameProvider switch here.

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/league.dart';
import '../models/xp_entry.dart';
import '../features/streak/models/daily_task.dart';
import '../services/storage_service.dart';
import '../services/app_logger.dart';

class PlayerProgressProvider extends ChangeNotifier {
  final StorageService _storage;

  PlayerProgressProvider({required StorageService storage})
      : _storage = storage {
    _init();
  }

  // ---- State ---------------------------------------------------------------

  int _totalPoints   = 0;
  int _weeklyPoints  = 0;
  int _streak        = 0;
  int _bestStreak    = 0;
  String _lastStreakDate = '';
  String _weekStartDate  = '';
  List<XpEntry> _xpHistory = [];

  // Daily tasks
  List<DailyTask> _dailyTasks = [];
  String _taskDate = '';
  int _completedCount = 0; // cached — O(1) access, not recomputed per build

  // High scores (records only — not in-session scores)
  int _memoryHighScore  = 0;
  int _logicHighScore   = 0;
  int _mathHighScore    = 0;
  int _schulteHighScore = 0;
  int _stroopHighScore  = 0;

  // ---- Getters -------------------------------------------------------------

  int    get totalPoints    => _totalPoints;
  int    get weeklyPoints   => _weeklyPoints;
  int    get streak         => _streak;
  int    get bestStreak     => _bestStreak;
  String get lastStreakDate => _lastStreakDate;
  String get weekStartDate  => _weekStartDate;
  List<XpEntry> get xpHistory => List.unmodifiable(_xpHistory);

  List<DailyTask> get dailyTasks    => List.unmodifiable(_dailyTasks);
  int  get completedTaskCount       => _completedCount;
  bool get allTasksDoneToday        => _dailyTasks.isNotEmpty && _completedCount == _dailyTasks.length;
  bool isTaskCompleted(TaskType t)  => _dailyTasks.any((d) => d.type == t && d.isCompleted);

  int get memoryHighScore  => _memoryHighScore;
  int get logicHighScore   => _logicHighScore;
  int get mathHighScore    => _mathHighScore;
  int get schulteHighScore => _schulteHighScore;
  int get stroopHighScore  => _stroopHighScore;

  LeagueInfo get league           => LeagueInfo.fromPoints(_totalPoints);
  double     get leagueProgress   => LeagueInfo.progressInTier(_totalPoints);
  int        get pointsToNextLeague => LeagueInfo.pointsToNextTier(_totalPoints);
  bool       get isMaxLeague      => league.tierIndex >= LeagueInfo.allTiers.length - 1;

  int get lastWeekPoints {
    if (_xpHistory.isEmpty) return 0;
    return _xpHistory.first.points;
  }

  DateTime? get streakStartDate {
    if (_streak == 0 || _lastStreakDate.isEmpty) return null;
    final parts = _lastStreakDate.split('-');
    if (parts.length < 3) return null;
    final last = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    return last.subtract(Duration(days: _streak - 1));
  }

  // ---- Initialisation ------------------------------------------------------

  Future<void> _init() async {
    try {
      _memoryHighScore  = _storage.getHighScore('memory_high_score');
      _logicHighScore   = _storage.getHighScore('logic_high_score');
      _mathHighScore    = _storage.getHighScore('math_high_score');
      _schulteHighScore = _storage.getHighScore('schulte_high_score');
      _stroopHighScore  = _storage.getHighScore('stroop_high_score');
      _totalPoints      = _storage.getTotalPoints();
      _streak           = _storage.getStreak();
      _bestStreak       = _storage.getBestStreak();
      _lastStreakDate   = _storage.getLastStreakDate();
      _weeklyPoints     = _storage.getWeeklyPoints();
      _weekStartDate    = _storage.getWeekStartDate();
      _xpHistory        = _storage.getXpHistory();

      final today = _todayStr();
      await _resetWeeklyIfNeeded(today);
      _loadOrGenerateTasks(today);
      _checkStreakBreak(today);

      notifyListeners();
    } catch (e, s) {
      AppLogger.error('PlayerProgressProvider._init', e, s);
    }
  }

  // ---- Date helpers --------------------------------------------------------

  /// Compute today string ONCE per call chain — eliminates the midnight race
  /// where 4 separate DateTime.now() calls could straddle midnight.
  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String _dateStr(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  static int _dayOfYear(DateTime date) =>
      date.difference(DateTime(date.year, 1, 1)).inDays + 1;

  // ---- Task system ---------------------------------------------------------

  void _loadOrGenerateTasks(String today) {
    _taskDate = _storage.getTaskDate();
    if (_taskDate == today) {
      final savedJson = _storage.getDailyTasksJson();
      if (savedJson != null) {
        try {
          final list = jsonDecode(savedJson) as List<dynamic>;
          _dailyTasks = list
              .map((e) => DailyTask.fromJson(e as Map<String, dynamic>))
              .toList();
          _completedCount = _dailyTasks.where((t) => t.isCompleted).length;
          return;
        } catch (e, s) {
          AppLogger.error('PlayerProgressProvider._loadOrGenerateTasks', e, s);
        }
      }
    }
    _dailyTasks = _generateTasksForDate(DateTime.now(), today);
    _taskDate = today;
    _completedCount = 0;
    _persistTasks(today);
  }

  List<DailyTask> _generateTasksForDate(DateTime date, String today) {
    final dayOfYear = _dayOfYear(date);
    final dateSeed  = date.year * 1000 + dayOfYear;
    final userName  = _storage.getUserName().isNotEmpty ? _storage.getUserName() : 'guest';
    final seed      = userName.hashCode ^ dateSeed;
    final rng       = Random(seed);

    final easyCopy   = List<TaskType>.from(GameTier.easy)  ..shuffle(rng);
    final mediumCopy = List<TaskType>.from(GameTier.medium) ..shuffle(rng);
    final hardCopy   = List<TaskType>.from(GameTier.hard)   ..shuffle(rng);

    return [
      _taskForType(easyCopy.first,   slotIndex: 0),
      _taskForType(mediumCopy.first, slotIndex: 1),
      _taskForType(hardCopy.first,   slotIndex: 2),
    ];
  }

  Future<void> _persistTasks(String today) async {
    try {
      final encoded = jsonEncode(_dailyTasks.map((t) => t.toJson()).toList());
      await _storage.setDailyTasksJson(encoded);
      await _storage.setTaskDate(today);
    } catch (e, s) {
      AppLogger.error('PlayerProgressProvider._persistTasks', e, s);
    }
  }

  // ---- Game completion (called by game screens) ----------------------------

  /// Call when a game session ends. Awards XP if this game is today's task
  /// and it has not already been completed today.
  Future<void> markGameComplete(TaskType type) async {
    final today = _todayStr(); // computed once for this entire operation
    try {
      final idx = _dailyTasks.indexWhere((t) => t.type == type);
      if (idx == -1 || _dailyTasks[idx].isCompleted) return;

      _dailyTasks[idx] = _dailyTasks[idx].complete();
      _completedCount++;

      final xp = _dailyTasks[idx].xpReward;
      await _awardXp(xp, today);

      if (allTasksDoneToday) {
        await _incrementStreak(today);
      }

      await _persistTasks(today);
      notifyListeners();
    } catch (e, s) {
      AppLogger.error('PlayerProgressProvider.markGameComplete', e, s);
    }
  }

  // ---- High scores (called by GameProvider after in-session check) ---------

  Future<void> recordHighScore(String gameKey, int score) async {
    try {
      switch (gameKey) {
        case 'memory_high_score':  _memoryHighScore  = score;
        case 'logic_high_score':   _logicHighScore   = score;
        case 'math_high_score':    _mathHighScore    = score;
        case 'schulte_high_score': _schulteHighScore = score;
        case 'stroop_high_score':  _stroopHighScore  = score;
      }
      await _storage.setHighScore(gameKey, score);
      notifyListeners();
    } catch (e, s) {
      AppLogger.error('PlayerProgressProvider.recordHighScore', e, s);
    }
  }

  // ---- XP / streak internals -----------------------------------------------

  Future<void> _awardXp(int xp, String today) async {
    if (xp <= 0) return;
    await _resetWeeklyIfNeeded(today);
    _weeklyPoints += xp;
    _totalPoints  += xp;
    await _storage.setTotalPoints(_totalPoints);
    await _storage.setWeeklyPoints(_weeklyPoints);
  }

  Future<void> _incrementStreak(String today) async {
    if (_lastStreakDate == today) return; // already counted today
    _streak++;
    _lastStreakDate = today;
    if (_streak > _bestStreak) {
      _bestStreak = _streak;
      await _storage.setBestStreak(_bestStreak);
    }
    await _storage.setStreak(_streak);
    await _storage.setLastStreakDate(_lastStreakDate);
  }

  void _checkStreakBreak(String today) {
    if (_streak == 0 || _lastStreakDate.isEmpty) return;
    final now       = DateTime.now();
    final yesterday = _dateStr(now.subtract(const Duration(days: 1)));
    if (_lastStreakDate != today && _lastStreakDate != yesterday) {
      _streak = 0;
      _storage.setStreak(0);
    }
  }

  Future<void> _resetWeeklyIfNeeded(String today) async {
    final now      = DateTime.parse(today.isEmpty ? _todayStr() : today);
    final todayDt  = DateTime(now.year, now.month, now.day);
    final monday   = todayDt.subtract(Duration(days: todayDt.weekday - 1));
    final weekStr  = _dateStr(monday);

    if (_weekStartDate != weekStr) {
      if (_weekStartDate.isNotEmpty && _weeklyPoints > 0) {
        await _storage.addXpHistoryEntry(
          XpEntry(weekStartDate: _weekStartDate, points: _weeklyPoints),
        );
        _xpHistory = _storage.getXpHistory();
      }
      _weeklyPoints = 0;
      _weekStartDate = weekStr;
      await _storage.setWeeklyPoints(0);
      await _storage.setWeekStartDate(weekStr);
    } else {
      _weekStartDate = weekStr;
    }
  }

  // ---- Reset ---------------------------------------------------------------

  Future<void> resetAllData() async {
    try {
      await _storage.clearAll();
      _totalPoints = _weeklyPoints = _streak = _bestStreak = 0;
      _memoryHighScore = _logicHighScore = _mathHighScore = 0;
      _schulteHighScore = _stroopHighScore = 0;
      _lastStreakDate = _weekStartDate = '';
      _xpHistory = [];
      final today = _todayStr();
      _dailyTasks = _generateTasksForDate(DateTime.now(), today);
      _taskDate = today;
      _completedCount = 0;
      notifyListeners();
    } catch (e, s) {
      AppLogger.error('PlayerProgressProvider.resetAllData', e, s);
    }
  }

  // ---- Task metadata -------------------------------------------------------
  // (Full switch — moved from GameProvider._taskForType)

  DailyTask _taskForType(TaskType type, {required int slotIndex}) {
    final xp = [TaskXp.task1, TaskXp.task2, TaskXp.task3][slotIndex];
    return switch (type) {
      TaskType.mathSprint      => DailyTask(type: type, title: 'Math Sprint',       description: 'Solve equations as fast as you can in 60s!',            icon: '⚡',   xpReward: xp),
      TaskType.memory          => DailyTask(type: type, title: 'Memory Flash',      description: 'Memorize blinking tiles — levels get harder!',           icon: '🧠',  xpReward: xp),
      TaskType.logic           => DailyTask(type: type, title: 'Number Series',     description: 'Find the missing number in the sequence',                icon: '🔷',  xpReward: xp),
      TaskType.schulte         => DailyTask(type: type, title: 'Schulte Grid',      description: 'Find numbers 1→N in order as fast as possible',          icon: '🔢',  xpReward: xp),
      TaskType.stroop          => DailyTask(type: type, title: 'Stroop Challenge',  description: 'Tap the INK color, not what the word says!',             icon: '🎨',  xpReward: xp),
      TaskType.reactionTimeTap => DailyTask(type: type, title: 'Reaction Time Tap', description: 'Tap the instant the screen turns green!',                icon: '⚡',  xpReward: xp),
      TaskType.numberRush      => DailyTask(type: type, title: 'Number Rush',       description: 'Tap numbers in ascending order as fast as you can',       icon: '🔢',  xpReward: xp),
      TaskType.whackATarget    => DailyTask(type: type, title: 'Whack-a-Target',    description: 'Tap the targets before they disappear!',                  icon: '🎯',  xpReward: xp),
      TaskType.speedSort       => DailyTask(type: type, title: 'Speed Sort',        description: 'Sort the items into categories at speed',                 icon: '🚀',  xpReward: xp),
      TaskType.cardMatch       => DailyTask(type: type, title: 'Card Match',        description: 'Find matching pairs before time runs out',                icon: '🃏',  xpReward: xp),
      TaskType.sequenceRecall  => DailyTask(type: type, title: 'Sequence Recall',   description: 'Remember and repeat the flashing sequence',               icon: '🔦',  xpReward: xp),
      TaskType.nBack           => DailyTask(type: type, title: 'N-Back',            description: 'Remember what appeared N steps ago',                      icon: '🔁',  xpReward: xp),
      TaskType.memoryPalace    => DailyTask(type: type, title: 'Memory Palace',     description: 'Place objects in rooms and recall them',                  icon: '🏛️', xpReward: xp),
      TaskType.stroopTest      => DailyTask(type: type, title: 'Stroop Test',       description: 'Tap the INK color of the word, not the word itself',      icon: '🌈',  xpReward: xp),
      TaskType.sart            => DailyTask(type: type, title: 'Focus Streak',      description: 'Tap every number EXCEPT the target — stay focused!',     icon: '👁️', xpReward: xp),
      TaskType.spotTheDifference=>DailyTask(type: type, title: 'Spot the Diff',     description: 'Find all differences between two images',                 icon: '🔍',  xpReward: xp),
      TaskType.twentyFourGame  => DailyTask(type: type, title: '24 Game',           description: 'Make 24 using four numbers and basic operations',          icon: '🧮',  xpReward: xp),
      TaskType.slidingPuzzle   => DailyTask(type: type, title: 'Sliding Puzzle',    description: 'Slide tiles into the correct order',                      icon: '🧩',  xpReward: xp),
      TaskType.patternCompletion=>DailyTask(type: type, title: 'Pattern Completion',description: 'Complete the visual pattern',                             icon: '🔮',  xpReward: xp),
      TaskType.miniSudoku      => DailyTask(type: type, title: 'Mini Sudoku',       description: 'Fill the 4x4 or 6x6 Sudoku grid',                        icon: '🔢',  xpReward: xp),
      TaskType.wordChains      => DailyTask(type: type, title: 'Word Chains',       description: 'Build word chains where each word shares letters',         icon: '🔗',  xpReward: xp),
      TaskType.anagramSolver   => DailyTask(type: type, title: 'Anagram Solver',    description: 'Unscramble the letters to find the word',                 icon: '🔤',  xpReward: xp),
      TaskType.categoryBlitz   => DailyTask(type: type, title: 'Category Blitz',    description: 'Name as many items in the category as you can!',           icon: '📋',  xpReward: xp),
      TaskType.mentalRotation  => DailyTask(type: type, title: 'Mental Rotation',   description: 'Pick the matching rotated shape',                         icon: '🔄',  xpReward: xp),
      TaskType.mazeNavigator   => DailyTask(type: type, title: 'Maze Navigator',    description: 'Find the exit as fast as possible',                       icon: '🗺️', xpReward: xp),
    };
  }
}
