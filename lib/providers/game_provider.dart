import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/league.dart';
import '../features/streak/models/daily_task.dart';

enum GameType { memory, logic, mathSprint, schulte, stroop }

enum GameState { idle, playing, paused, roundComplete, finished }

class GameProvider extends ChangeNotifier {
  GameState _state = GameState.idle;
  GameType _currentGame = GameType.memory;
  int _score = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _totalPoints = 0;
  int _weeklyPoints = 0;
  List<String> _xpHistory = [];
  String _lastStreakDate = '';
  String _weekStartDate = '';
  int? _highlightedIndex;

  // ─── Daily Task System ───────────────────────────────────────────────
  List<DailyTask> _dailyTasks = [];
  String _taskDate = ''; // date string for which tasks were generated

  // High scores
  int _memoryHighScore = 0;
  int _logicHighScore = 0;
  int _mathHighScore = 0;
  int _schulteHighScore = 0;
  int _stroopHighScore = 0;
  bool _newMemoryRecord = false;
  bool _newLogicRecord = false;
  bool _newMathRecord = false;
  bool _newSchulteRecord = false;
  bool _newStroopRecord = false;

  // ─── Memory game ─────────────────────────────────────────────────────
  List<bool> _memoryPattern = [];
  List<bool?> _playerPattern = [];
  int _memoryLevel = 1;
  bool _showingPattern = false;
  int get memoryGridCols => _memoryLevel < 5 ? 3 : (_memoryLevel < 10 ? 4 : 5);
  int get memorySize => memoryGridCols * memoryGridCols;

  // ─── Logic game ──────────────────────────────────────────────────────
  List<int> _logicPattern = [];
  int? _logicAnswer;
  List<int> _logicChoices = [];
  String _logicSeriesName = '';
  int _logicSessionScore = 0;
  int _logicQuestionsAnswered = 0;
  int _logicMissingIndex = 4;

  // ─── Math sprint ─────────────────────────────────────────────────────
  int _mathA = 0;
  int _mathB = 0;
  String _mathOp = '+';
  int _mathCorrect = 0;
  List<int> _mathChoices = [];
  int _mathScore = 0;
  int _mathCorrectCount = 0;
  int _mathTotal = 0;
  int _mathTimeLeft = 60;
  Timer? _mathTimer;
  int _mathStreak = 0;
  int _mathMaxStreak = 0;
  int _mathPlusScore = 0;
  int _mathMinusScore = 0;
  int _mathMulScore = 0;
  int _mathLastCorrect = -1;

  // ─── Schulte Table ───────────────────────────────────────────────────
  int _schulteLevel = 1;
  List<int> _schulteGrid = [];
  int _schulteNext = 1;
  int _schulteTimeElapsed = 0;
  int _schulteGridSize = 3;
  Timer? _schulteTimer;
  bool _schulteComplete = false;

  // ─── Stroop Effect ────────────────────────────────────────────────────
  String _stroopWord = '';
  Color _stroopInkColor = Colors.red;
  String _stroopInkName = 'Red';
  List<String> _stroopColorOptions = [];
  int _stroopScore = 0;
  int _stroopCorrectCount = 0;
  int _stroopTotal = 0;
  int _stroopTimeLeft = 60;
  Timer? _stroopTimer;
  int _stroopStreak = 0;
  int _stroopMaxStreak = 0;
  bool _stroopAnswered = false;
  bool _stroopLastCorrect = false;

  static const _stroopColors = {
    'Red': Color(0xFFE53935),
    'Blue': Color(0xFF1E88E5),
    'Green': Color(0xFF43A047),
    'Yellow': Color(0xFFFFB300),
    'Purple': Color(0xFF8E24AA),
    'Orange': Color(0xFFFF6D00),
  };

  // ── Getters ──────────────────────────────────────────────────────────
  GameState get state => _state;
  GameType get currentGame => _currentGame;
  int get score => _score;
  int get streak => _streak;
  int get bestStreak => _bestStreak;
  int get totalPoints => _totalPoints;
  int get weeklyPoints => _weeklyPoints;
  List<String> get xpHistory => _xpHistory;
  String get lastStreakDate => _lastStreakDate;
  String get weekStartDate => _weekStartDate;

  // ── Daily task getters ───────────────────────────────────────────────
  List<DailyTask> get dailyTasks => List.unmodifiable(_dailyTasks);
  int get completedTaskCount =>
      _dailyTasks.where((t) => t.isCompleted).length;
  bool get allTasksDoneToday =>
      _dailyTasks.isNotEmpty &&
      _dailyTasks.every((t) => t.isCompleted);
  bool isTaskCompleted(TaskType type) =>
      _dailyTasks.any((t) => t.type == type && t.isCompleted);

  /// Points scored in the previous week (first xpHistory entry).
  int get lastWeekPoints {
    if (_xpHistory.isEmpty) return 0;
    final parts = _xpHistory.first.split('|');
    if (parts.length != 2) return 0;
    return int.tryParse(parts[1]) ?? 0;
  }

  /// Returns the date when the current streak started.
  DateTime? get streakStartDate {
    if (_streak == 0 || _lastStreakDate.isEmpty) return null;
    final parts = _lastStreakDate.split('-');
    if (parts.length < 3) return null;
    final last = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    return last.subtract(Duration(days: _streak - 1));
  }

  // League getters
  LeagueInfo get league => LeagueInfo.fromPoints(_totalPoints);
  double get leagueProgress => LeagueInfo.progressInTier(_totalPoints);
  int get pointsToNextLeague => LeagueInfo.pointsToNextTier(_totalPoints);
  bool get isMaxLeague => league.tierIndex >= LeagueInfo.allTiers.length - 1;

  int get memoryHighScore => _memoryHighScore;
  int get logicHighScore => _logicHighScore;
  int get mathHighScore => _mathHighScore;
  int get schulteHighScore => _schulteHighScore;
  int get stroopHighScore => _stroopHighScore;
  bool get newMemoryRecord => _newMemoryRecord;
  bool get newLogicRecord => _newLogicRecord;
  bool get newMathRecord => _newMathRecord;
  bool get newSchulteRecord => _newSchulteRecord;
  bool get newStroopRecord => _newStroopRecord;

  List<bool> get memoryPattern => _memoryPattern;
  List<bool?> get playerPattern => _playerPattern;
  int get memoryLevel => _memoryLevel;
  bool get showingPattern => _showingPattern;
  int? get highlightedIndex => _highlightedIndex;

  List<int> get logicPattern => _logicPattern;
  int? get logicAnswer => _logicAnswer;
  List<int> get logicChoices => _logicChoices;
  String get logicSeriesName => _logicSeriesName;
  int get logicSessionScore => _logicSessionScore;
  int get logicQuestionsAnswered => _logicQuestionsAnswered;
  int get logicMissingIndex => _logicMissingIndex;

  int get mathA => _mathA;
  int get mathB => _mathB;
  String get mathOp => _mathOp;
  int get mathCorrect => _mathCorrect;
  List<int> get mathChoices => _mathChoices;
  int get mathScore => _mathScore;
  int get mathCorrectCount => _mathCorrectCount;
  int get mathTotal => _mathTotal;
  int get mathTimeLeft => _mathTimeLeft;
  int get mathStreak => _mathStreak;
  int get mathMaxStreak => _mathMaxStreak;
  int get mathPlusScore => _mathPlusScore;
  int get mathMinusScore => _mathMinusScore;
  int get mathMulScore => _mathMulScore;
  int get mathLastCorrect => _mathLastCorrect;

  // Schulte getters
  List<int> get schulteGrid => _schulteGrid;
  int get schulteNext => _schulteNext;
  int get schulteTimeElapsed => _schulteTimeElapsed;
  int get schulteGridSize => _schulteGridSize;
  int get schulteLevel => _schulteLevel;
  bool get schulteComplete => _schulteComplete;
  int get schulteTotal => _schulteGridSize * _schulteGridSize;

  // Stroop getters
  String get stroopWord => _stroopWord;
  Color get stroopInkColor => _stroopInkColor;
  String get stroopInkName => _stroopInkName;
  List<String> get stroopColorOptions => _stroopColorOptions;
  int get stroopScore => _stroopScore;
  int get stroopCorrectCount => _stroopCorrectCount;
  int get stroopTotal => _stroopTotal;
  int get stroopTimeLeft => _stroopTimeLeft;
  int get stroopStreak => _stroopStreak;
  int get stroopMaxStreak => _stroopMaxStreak;
  bool get stroopAnswered => _stroopAnswered;
  bool get stroopLastCorrect => _stroopLastCorrect;
  Map<String, Color> get stroopColorMap => _stroopColors;

  final _rng = Random();

  GameProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadData();
  }

  // ─── Persistence ─────────────────────────────────────────────────────

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _memoryHighScore = prefs.getInt('memory_high_score') ?? 0;
    _logicHighScore = prefs.getInt('logic_high_score') ?? 0;
    _mathHighScore = prefs.getInt('math_high_score') ?? 0;
    _schulteHighScore = prefs.getInt('schulte_high_score') ?? 0;
    _stroopHighScore = prefs.getInt('stroop_high_score') ?? 0;
    _totalPoints = prefs.getInt('total_points') ?? 0;
    _streak = prefs.getInt('user_streak') ?? 0;
    _bestStreak = prefs.getInt('best_streak') ?? 0;
    _lastStreakDate = prefs.getString('last_streak_date') ?? '';
    _weeklyPoints = prefs.getInt('weekly_points') ?? 0;
    _weekStartDate = prefs.getString('week_start_date') ?? '';
    _xpHistory = prefs.getStringList('xp_history') ?? [];

    await _resetWeeklyPointsIfNeeded(prefs);
    _loadOrGenerateDailyTasks(prefs);

    // Break streak if yesterday was missed
    _checkStreakBreak(prefs);

    notifyListeners();
  }

  Future<void> _saveHighScore(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  // ─── Daily Task Generation ───────────────────────────────────────────

  String get _todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Loads saved tasks for today, or generates fresh ones if it's a new day.
  void _loadOrGenerateDailyTasks(SharedPreferences prefs) {
    _taskDate = prefs.getString('task_date') ?? '';
    final today = _todayStr;

    if (_taskDate == today) {
      // Load persisted task completion state
      final savedJson = prefs.getString('daily_tasks_json');
      if (savedJson != null) {
        try {
          final list = jsonDecode(savedJson) as List<dynamic>;
          _dailyTasks = list
              .map((e) => DailyTask.fromJson(e as Map<String, dynamic>))
              .toList();
          return;
        } catch (_) {}
      }
    }

    // New day — generate fresh tasks
    _dailyTasks = _generateTasksForDate(DateTime.now());
    _taskDate = today;
    _persistTasks(prefs);
  }

  /// Generates today's 3 tasks using a day-based deterministic rotation.
  ///
  /// Algorithm:
  ///   day = day-of-year (1–365)
  ///   easyGame  = GameTier.easy [day % easy.length]
  ///   mediumGame = GameTier.medium [(day ~/ 2) % medium.length]
  ///   hardGame  = GameTier.hard [day % hard.length]
  ///
  /// This means the same calendar date always yields the same tasks, but
  /// adding new games to a tier immediately expands the rotation pool.
  List<DailyTask> _generateTasksForDate(DateTime date) {
    final dayOfYear = _dayOfYear(date);

    final easyType = GameTier.easy[dayOfYear % GameTier.easy.length];
    final mediumType =
        GameTier.medium[(dayOfYear ~/ 2) % GameTier.medium.length];
    final hardType = GameTier.hard[dayOfYear % GameTier.hard.length];

    return [
      _taskForType(easyType, slotIndex: 0),
      _taskForType(mediumType, slotIndex: 1),
      _taskForType(hardType, slotIndex: 2),
    ];
  }

  int _dayOfYear(DateTime date) {
    return date.difference(DateTime(date.year, 1, 1)).inDays + 1;
  }

  DailyTask _taskForType(TaskType type, {required int slotIndex}) {
    final xp = [TaskXp.task1, TaskXp.task2, TaskXp.task3][slotIndex];
    switch (type) {
      case TaskType.mathSprint:
        return DailyTask(
          type: type,
          title: 'Math Sprint',
          description: 'Complete a full 60-second Math Sprint session',
          icon: '⚡',
          xpReward: xp,
        );
      case TaskType.memory:
        return DailyTask(
          type: type,
          title: 'Memory Game',
          description: 'Play a Memory Game session',
          icon: '🧠',
          xpReward: xp,
        );
      case TaskType.logic:
        return DailyTask(
          type: type,
          title: 'Logic Game',
          description: 'Answer at least 1 Logic sequence question',
          icon: '🔷',
          xpReward: xp,
        );
      case TaskType.schulte:
        return DailyTask(
          type: type,
          title: 'Schulte Table',
          description: 'Clear a full Schulte Table grid',
          icon: '🔢',
          xpReward: xp,
        );
      case TaskType.stroop:
        return DailyTask(
          type: type,
          title: 'Stroop Effect',
          description: 'Complete a full 60-second Stroop session',
          icon: '🎨',
          xpReward: xp,
        );
    }
  }

  Future<void> _persistTasks(SharedPreferences prefs) async {
    final json = jsonEncode(_dailyTasks.map((t) => t.toJson()).toList());
    await prefs.setString('daily_tasks_json', json);
    await prefs.setString('task_date', _taskDate);
  }

  // ─── Task Completion & XP Award ──────────────────────────────────────

  /// Call this when the player finishes a game session.
  /// Awards XP for the matching daily task (once per day per type).
  Future<void> markGameComplete(TaskType type) async {
    // Find the task index
    final idx = _dailyTasks.indexWhere((t) => t.type == type);
    if (idx == -1) return; // this game isn't today's task
    if (_dailyTasks[idx].isCompleted) return; // already done today

    // Mark complete
    _dailyTasks[idx] = _dailyTasks[idx].complete();

    final xp = _dailyTasks[idx].xpReward;
    await _awardXp(xp);

    // Check if all tasks are now done → increment streak
    if (allTasksDoneToday) {
      await _incrementStreak();
    }

    final prefs = await SharedPreferences.getInstance();
    await _persistTasks(prefs);
    notifyListeners();
  }

  Future<void> _awardXp(int xp) async {
    if (xp <= 0) return;
    final prefs = await SharedPreferences.getInstance();

    await _resetWeeklyPointsIfNeeded(prefs);

    _weeklyPoints += xp;
    _totalPoints += xp;

    await prefs.setInt('total_points', _totalPoints);
    await prefs.setInt('weekly_points', _weeklyPoints);
    notifyListeners();
  }

  Future<void> _incrementStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr;

    // Don't double-count streak for the same day
    if (_lastStreakDate == today) return;

    _streak++;
    _lastStreakDate = today;

    if (_streak > _bestStreak) {
      _bestStreak = _streak;
      await prefs.setInt('best_streak', _bestStreak);
    }

    await prefs.setInt('user_streak', _streak);
    await prefs.setString('last_streak_date', today);
  }

  void _checkStreakBreak(SharedPreferences prefs) {
    if (_streak == 0 || _lastStreakDate.isEmpty) return;

    final today = DateTime.now();
    final todayStr = _todayStr;
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    // Streak is still valid if last activity was today or yesterday
    if (_lastStreakDate != todayStr && _lastStreakDate != yesterdayStr) {
      _streak = 0;
      prefs.setInt('user_streak', 0);
    }
  }

  Future<void> _resetWeeklyPointsIfNeeded(SharedPreferences prefs) async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final monday = todayDate.subtract(Duration(days: todayDate.weekday - 1));
    final weekStr =
        '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
    final savedWeek = prefs.getString('week_start_date') ?? '';

    if (savedWeek != weekStr) {
      if (savedWeek.isNotEmpty && _weeklyPoints > 0) {
        _xpHistory.insert(0, '$savedWeek|$_weeklyPoints');
        await prefs.setStringList('xp_history', _xpHistory);
      }
      _weeklyPoints = 0;
      _weekStartDate = weekStr;
      await prefs.setInt('weekly_points', 0);
      await prefs.setString('week_start_date', weekStr);
    } else {
      _weekStartDate = weekStr;
    }
  }

  // ─── Shared ──────────────────────────────────────────────────────────

  void selectGame(GameType type) {
    _currentGame = type;
    _state = GameState.idle;
    notifyListeners();
  }

  // ─── Memory Game ─────────────────────────────────────────────────────

  Future<void> startMemoryGame() async {
    _state = GameState.playing;
    _score = 0;
    _memoryLevel = 1;
    _newMemoryRecord = false;
    await _generateMemoryRound();
  }

  Future<void> nextMemoryRound() async {
    _memoryLevel++;
    _state = GameState.playing;
    await _generateMemoryRound();
  }

  Future<void> _generateMemoryRound() async {
    final size = memorySize;
    int activeCount = min(2 + _memoryLevel, size - 1);
    _memoryPattern = List.generate(size, (_) => false);
    final indices = List.generate(size, (i) => i)..shuffle(_rng);

    final sequence = <int>[];
    for (int i = 0; i < activeCount; i++) {
      _memoryPattern[indices[i]] = true;
      sequence.add(indices[i]);
    }
    _playerPattern = List.filled(size, null);

    _showingPattern = true;
    _highlightedIndex = null;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1000));

    for (int idx in sequence) {
      _highlightedIndex = idx;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 600));
      _highlightedIndex = null;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    _showingPattern = false;
    notifyListeners();
  }

  void tapMemoryCell(int index) {
    if (_showingPattern || _state != GameState.playing) return;
    if (_playerPattern[index] != null) return;

    _playerPattern[index] = _memoryPattern[index];
    notifyListeners();

    final tapped = _playerPattern.where((p) => p != null).length;
    final activeCount = _memoryPattern.where((p) => p).length;

    if (tapped >= activeCount) {
      final anyWrong = _playerPattern.any((p) => p == false);
      if (!anyWrong) {
        _score += _memoryLevel; // score tracks performance, not XP
        _state = GameState.roundComplete;
        _checkMemoryHighScore();
      } else {
        _state = GameState.finished;
        _checkMemoryHighScore();
      }
      notifyListeners();
    }
  }

  void _checkMemoryHighScore() {
    if (_score > _memoryHighScore) {
      _memoryHighScore = _score;
      _newMemoryRecord = true;
      _saveHighScore('memory_high_score', _memoryHighScore);
    }
  }

  // ─── Logic Game ──────────────────────────────────────────────────────

  void startLogicGame() {
    _state = GameState.playing;
    _logicSessionScore = 0;
    _logicQuestionsAnswered = 0;
    _newLogicRecord = false;
    _generateLogicRound();
  }

  void _generateLogicRound() {
    List<int> fullSeq = [];
    final type = _rng.nextInt(7);
    switch (type) {
      case 0: // Arithmetic
        final d = _rng.nextInt(8) + 1;
        final a = _rng.nextInt(15) + 1;
        fullSeq = List.generate(5, (i) => a + d * i);
        _logicSeriesName = 'Arithmetic (+$d each step)';
        break;

      case 1: // Geometric
        final r = _rng.nextInt(3) + 2;
        final a = _rng.nextInt(3) + 1;
        fullSeq = List.generate(5, (i) => a * pow(r, i).toInt());
        _logicSeriesName = 'Geometric (×$r each step)';
        break;

      case 2: // Squares
        final start = _rng.nextInt(5) + 1;
        fullSeq = List.generate(5, (i) => pow(start + i, 2).toInt());
        _logicSeriesName = 'Perfect Squares';
        break;

      case 3: // Fibonacci-style
        final a = _rng.nextInt(5) + 1;
        final b = _rng.nextInt(5) + 1;
        final c = a + b;
        final d2 = a + 2 * b;
        final e = 2 * a + 3 * b;
        fullSeq = [a, b, c, d2, e];
        _logicSeriesName = 'Fibonacci-style (each = sum of previous two)';
        break;

      case 4: // Alternating +/×
        final stepA = _rng.nextInt(4) + 2;
        final stepB = _rng.nextInt(3) + 2;
        final s0 = _rng.nextInt(5) + 2;
        final s1 = s0 + stepA;
        final s2 = s1 * stepB;
        final s3 = s2 + stepA;
        final s4 = s3 * stepB;
        fullSeq = [s0, s1, s2, s3, s4];
        _logicSeriesName = 'Alternating (+$stepA, ×$stepB)';
        break;

      case 5: // Primes
        const primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29];
        final startIdx = _rng.nextInt(primes.length - 5);
        fullSeq = primes.sublist(startIdx, startIdx + 5);
        _logicSeriesName = 'Prime Numbers';
        break;

      default: // n² - 1 pattern
        final offset = _rng.nextInt(3);
        fullSeq = List.generate(5, (i) => pow(i + 1, 2).toInt() - 1 + offset);
        _logicSeriesName = 'n²${offset > 0 ? '+$offset' : ''} pattern';
        break;
    }

    _logicMissingIndex = _rng.nextInt(5);
    _logicAnswer = fullSeq[_logicMissingIndex];
    _logicPattern = fullSeq;

    final sequenceNumbers = fullSeq.toSet();
    final wrongs = <int>{};
    int attempts = 0;
    while (wrongs.length < 3 && attempts < 100) {
      attempts++;
      final delta = _rng.nextInt(12) - 6;
      final wrong = _logicAnswer! + delta;
      if (wrong != _logicAnswer &&
          !sequenceNumbers.contains(wrong) &&
          wrong > 0) {
        wrongs.add(wrong);
      }
    }

    int extra = _logicAnswer! + 7;
    while (wrongs.length < 3) {
      if (extra != _logicAnswer && !sequenceNumbers.contains(extra)) {
        wrongs.add(extra);
      }
      extra++;
    }

    _logicChoices = [_logicAnswer!, ...wrongs]..shuffle(_rng);
    notifyListeners();
  }

  void answerLogic(int answer) {
    _logicQuestionsAnswered++;
    if (answer == _logicAnswer) {
      _logicSessionScore += 10; // tracks in-session accuracy, not XP
    } else {
      _logicSessionScore = max(0, _logicSessionScore - 5);
    }
    _state = GameState.finished;
    _checkLogicHighScore();
    notifyListeners();
  }

  void stopLogicGame() {
    _state = GameState.idle;
    notifyListeners();
  }

  void nextLogicRound() {
    _state = GameState.playing;
    _generateLogicRound();
    notifyListeners();
  }

  void _checkLogicHighScore() {
    if (_logicSessionScore > _logicHighScore) {
      _logicHighScore = _logicSessionScore;
      _newLogicRecord = true;
      _saveHighScore('logic_high_score', _logicHighScore);
    }
  }

  // ─── Workout Completion (kept for API compatibility) ──────────────────
  void completeWorkout() {}

  // ─── Math Sprint ──────────────────────────────────────────────────────

  void startMathSprint() {
    _mathTimer?.cancel();
    _state = GameState.playing;
    _mathScore = 0;
    _mathCorrectCount = 0;
    _mathTotal = 0;
    _mathTimeLeft = 60;
    _mathStreak = 0;
    _mathMaxStreak = 0;
    _mathPlusScore = 0;
    _mathMinusScore = 0;
    _mathMulScore = 0;
    _mathLastCorrect = -1;
    _newMathRecord = false;
    _generateMathQuestion();
    _mathTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      tickMathTimer();
    });
  }

  void _generateMathQuestion() {
    final ops = ['+', '-', '×'];
    _mathOp = ops[_rng.nextInt(3)];
    switch (_mathOp) {
      case '+':
        _mathA = _rng.nextInt(50) + 1;
        _mathB = _rng.nextInt(50) + 1;
        _mathCorrect = _mathA + _mathB;
        break;
      case '-':
        _mathA = _rng.nextInt(50) + 20;
        _mathB = _rng.nextInt(_mathA) + 1;
        _mathCorrect = _mathA - _mathB;
        break;
      case '×':
        _mathA = _rng.nextInt(12) + 1;
        _mathB = _rng.nextInt(12) + 1;
        _mathCorrect = _mathA * _mathB;
        break;
      default:
        _mathA = 5;
        _mathB = 5;
        _mathCorrect = 10;
    }
    final wrongs = <int>{};
    while (wrongs.length < 3) {
      int wrong = _mathCorrect + (_rng.nextInt(20) - 10);
      if (wrong != _mathCorrect && wrong >= 0) wrongs.add(wrong);
    }
    _mathChoices = [_mathCorrect, ...wrongs]..shuffle(_rng);
    _mathLastCorrect = -1;
    notifyListeners();
  }

  void answerMath(int answer) {
    _mathTotal++;
    final isCorrect = answer == _mathCorrect;
    _mathLastCorrect = isCorrect ? _mathChoices.indexOf(answer) : -2;
    notifyListeners();

    if (isCorrect) {
      _mathCorrectCount++;
      _mathStreak++;
      if (_mathStreak > _mathMaxStreak) _mathMaxStreak = _mathStreak;
      _mathScore += 2 + (_mathStreak >= 5 ? 1 : 0); // local session score
      switch (_mathOp) {
        case '+':
          _mathPlusScore++;
          break;
        case '-':
          _mathMinusScore++;
          break;
        case '×':
          _mathMulScore++;
          break;
      }
    } else {
      _mathStreak = 0;
      _mathScore = max(0, _mathScore - 1);
    }
    Future.delayed(const Duration(milliseconds: 300), _generateMathQuestion);
  }

  void tickMathTimer() {
    if (_mathTimeLeft > 0) {
      _mathTimeLeft--;
      if (_mathTimeLeft == 0) {
        _state = GameState.finished;
        _mathTimer?.cancel();
        _checkMathHighScore();
      }
      notifyListeners();
    }
  }

  void _checkMathHighScore() {
    if (_mathScore > _mathHighScore) {
      _mathHighScore = _mathScore;
      _newMathRecord = true;
      _saveHighScore('math_high_score', _mathHighScore);
    }
  }

  void stopMathTimer() => _mathTimer?.cancel();

  // ─── Schulte Table ────────────────────────────────────────────────────

  void startSchulteGame({int level = 1}) {
    _schulteTimer?.cancel();
    _schulteLevel = level;
    _schulteGridSize = level == 1
        ? 3
        : level == 2
        ? 4
        : 5;
    _schulteNext = 1;
    _schulteTimeElapsed = 0;
    _schulteComplete = false;
    _newSchulteRecord = false;
    _state = GameState.playing;

    final n = _schulteGridSize * _schulteGridSize;
    _schulteGrid = List.generate(n, (i) => i + 1)..shuffle(_rng);

    notifyListeners();

    _schulteTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _schulteTimeElapsed++;
      notifyListeners();
    });
  }

  bool tapSchulteCell(int number) {
    if (_state != GameState.playing || _schulteComplete) return false;
    if (number != _schulteNext) return false;

    _schulteNext++;
    if (_schulteNext > schulteTotal) {
      _schulteTimer?.cancel();
      _schulteComplete = true;
      _state = GameState.roundComplete;
      _checkSchulteHighScore();
    }
    notifyListeners();
    return true;
  }

  void _checkSchulteHighScore() {
    if (_schulteHighScore == 0 || _schulteTimeElapsed < _schulteHighScore) {
      _schulteHighScore = _schulteTimeElapsed;
      _newSchulteRecord = true;
      _saveHighScore('schulte_high_score', _schulteHighScore);
    }
  }

  void stopSchulte() {
    _schulteTimer?.cancel();
    _state = GameState.idle;
    notifyListeners();
  }

  // ─── Stroop Effect ────────────────────────────────────────────────────

  void startStroopGame() {
    _stroopTimer?.cancel();
    _stroopScore = 0;
    _stroopCorrectCount = 0;
    _stroopTotal = 0;
    _stroopTimeLeft = 60;
    _stroopStreak = 0;
    _stroopMaxStreak = 0;
    _stroopAnswered = false;
    _newStroopRecord = false;
    _state = GameState.playing;
    _generateStroopRound();
    _stroopTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickStroopTimer();
    });
  }

  void _generateStroopRound() {
    List<String> pool = ['Red', 'Blue', 'Green', 'Yellow'];
    if (_stroopStreak >= 10) pool = _stroopColors.keys.toList();

    final inkName = pool[_rng.nextInt(pool.length)];
    String wordName;
    do {
      wordName = pool[_rng.nextInt(pool.length)];
    } while (wordName == inkName);

    _stroopWord = wordName;
    _stroopInkName = inkName;
    _stroopInkColor = _stroopColors[inkName]!;

    final others = pool.where((c) => c != inkName).toList()..shuffle(_rng);
    _stroopColorOptions = [inkName, ...others.take(3)]..shuffle(_rng);
    _stroopAnswered = false;
    notifyListeners();
  }

  void answerStroop(String colorName) {
    if (_stroopAnswered || _state != GameState.playing) return;
    _stroopAnswered = true;
    _stroopTotal++;
    final correct = colorName == _stroopInkName;
    _stroopLastCorrect = correct;

    if (correct) {
      _stroopCorrectCount++;
      _stroopStreak++;
      if (_stroopStreak > _stroopMaxStreak) _stroopMaxStreak = _stroopStreak;
      _stroopScore += 3 + (_stroopStreak >= 5 ? 2 : 0); // local session score
    } else {
      _stroopStreak = 0;
      _stroopScore = max(0, _stroopScore - 2);
    }
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (_state == GameState.playing) _generateStroopRound();
    });
  }

  void _tickStroopTimer() {
    if (_stroopTimeLeft > 0) {
      _stroopTimeLeft--;
      if (_stroopTimeLeft == 0) {
        _state = GameState.finished;
        _stroopTimer?.cancel();
        _checkStroopHighScore();
      }
      notifyListeners();
    }
  }

  void _checkStroopHighScore() {
    if (_stroopScore > _stroopHighScore) {
      _stroopHighScore = _stroopScore;
      _newStroopRecord = true;
      _saveHighScore('stroop_high_score', _stroopHighScore);
    }
  }

  void stopStroop() {
    _stroopTimer?.cancel();
    _state = GameState.idle;
    notifyListeners();
  }

  // ─── Game reset ──────────────────────────────────────────────────────

  void resetGame() {
    _mathTimer?.cancel();
    _schulteTimer?.cancel();
    _stroopTimer?.cancel();
    _state = GameState.idle;
    _score = 0;
    _mathCorrectCount = 0;
    _stroopCorrectCount = 0;
    _newMemoryRecord = false;
    _newLogicRecord = false;
    _newMathRecord = false;
    _newSchulteRecord = false;
    _newStroopRecord = false;
    notifyListeners();
  }

  /// Clears ALL persisted data and resets in-memory state.
  Future<void> resetAllData() async {
    _mathTimer?.cancel();
    _schulteTimer?.cancel();
    _stroopTimer?.cancel();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _state = GameState.idle;
    _score = 0;
    _streak = 0;
    _bestStreak = 0;
    _totalPoints = 0;
    _weeklyPoints = 0;
    _xpHistory = [];
    _lastStreakDate = '';
    _weekStartDate = '';
    _memoryHighScore = 0;
    _logicHighScore = 0;
    _mathHighScore = 0;
    _schulteHighScore = 0;
    _stroopHighScore = 0;
    _dailyTasks = _generateTasksForDate(DateTime.now());
    _taskDate = _todayStr;
    notifyListeners();
  }

  @override
  void dispose() {
    _mathTimer?.cancel();
    _schulteTimer?.cancel();
    _stroopTimer?.cancel();
    super.dispose();
  }
}
