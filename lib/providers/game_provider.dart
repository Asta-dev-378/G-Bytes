// lib/providers/game_provider.dart
// Game state machines ONLY — XP, streaks, tasks, leagues, and high-score
// persistence all live in PlayerProgressProvider.
// This file owns: Memory, Logic, MathSprint, Schulte, Stroop state machines.

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'player_progress_provider.dart';

enum GameType { memory, logic, mathSprint, schulte, stroop }

enum GameState { idle, playing, paused, roundComplete, finished }

class GameProvider extends ChangeNotifier {
  final PlayerProgressProvider _progress;

  GameProvider({required PlayerProgressProvider progress})
      : _progress = progress;

  // ---- Shared game state ---------------------------------------------------
  GameState _state     = GameState.idle;
  GameType _currentGame = GameType.memory;
  int _score = 0;

  // ---- High scores (in-memory for current session comparison) --------------
  // Loaded lazily from _progress which initialises them from storage.
  bool _newMemoryRecord  = false;
  bool _newLogicRecord   = false;
  bool _newMathRecord    = false;
  bool _newSchulteRecord = false;
  bool _newStroopRecord  = false;

  // ---- Cancellable delay timers --------------------------------------------
  Timer? _mathDelayTimer;
  Timer? _stroopDelayTimer;

  // ---- Memory game ---------------------------------------------------------
  List<bool>  _memoryPattern  = [];
  List<bool?> _playerPattern  = [];
  int _memoryLevel    = 1;
  bool _showingPattern = false;
  int? _highlightedIndex;

  int get memoryGridCols => _memoryLevel < 5 ? 3 : (_memoryLevel < 10 ? 4 : 5);
  int get memorySize     => memoryGridCols * memoryGridCols;

  // ---- Logic game ----------------------------------------------------------
  List<int> _logicPattern  = [];
  int? _logicAnswer;
  List<int> _logicChoices  = [];
  String _logicSeriesName  = '';
  int _logicSessionScore   = 0;
  int _logicQuestionsAnswered = 0;
  int _logicMissingIndex   = 4;

  // ---- Math sprint ---------------------------------------------------------
  int _mathA = 0, _mathB = 0, _mathCorrect = 0;
  String _mathOp = '+';
  List<int> _mathChoices    = [];
  int _mathScore            = 0;
  int _mathCorrectCount     = 0;
  int _mathTotal            = 0;
  int _mathTimeLeft         = 60;
  Timer? _mathTimer;
  int _mathStreak = 0, _mathMaxStreak = 0;
  int _mathPlusScore = 0, _mathMinusScore = 0, _mathMulScore = 0;
  int _mathLastCorrect = -1;

  // ---- Schulte table -------------------------------------------------------
  int _schulteLevel = 1;
  List<int> _schulteGrid = [];
  int _schulteNext = 1, _schulteTimeElapsed = 0, _schulteGridSize = 3;
  Timer? _schulteTimer;
  bool _schulteComplete = false;

  // ---- Stroop effect -------------------------------------------------------
  String _stroopWord = '';
  Color _stroopInkColor = Colors.red;
  String _stroopInkName = 'Red';
  List<String> _stroopColorOptions = [];
  int _stroopScore = 0, _stroopCorrectCount = 0, _stroopTotal = 0;
  int _stroopTimeLeft = 60;
  Timer? _stroopTimer;
  int _stroopStreak = 0, _stroopMaxStreak = 0;
  bool _stroopAnswered = false, _stroopLastCorrect = false;

  static const _stroopColors = {
    'Red':    Color(0xFFE53935),
    'Blue':   Color(0xFF1E88E5),
    'Green':  Color(0xFF43A047),
    'Yellow': Color(0xFFFFB300),
    'Purple': Color(0xFF8E24AA),
    'Orange': Color(0xFFFF6D00),
  };

  final _rng = Random();

  // ---- Getters -------------------------------------------------------------
  GameState get state        => _state;
  GameType  get currentGame  => _currentGame;
  int  get score             => _score;

  // Progress getters forwarded from PlayerProgressProvider (backward-compat)
  int    get streak          => _progress.streak;
  int    get bestStreak      => _progress.bestStreak;
  int    get totalPoints     => _progress.totalPoints;
  int    get weeklyPoints    => _progress.weeklyPoints;

  bool get newMemoryRecord   => _newMemoryRecord;
  bool get newLogicRecord    => _newLogicRecord;
  bool get newMathRecord     => _newMathRecord;
  bool get newSchulteRecord  => _newSchulteRecord;
  bool get newStroopRecord   => _newStroopRecord;

  // High score getters forwarded from PlayerProgressProvider
  int get memoryHighScore    => _progress.memoryHighScore;
  int get logicHighScore     => _progress.logicHighScore;
  int get mathHighScore      => _progress.mathHighScore;
  int get schulteHighScore   => _progress.schulteHighScore;
  int get stroopHighScore    => _progress.stroopHighScore;

  List<bool>  get memoryPattern    => _memoryPattern;
  List<bool?> get playerPattern    => _playerPattern;
  int         get memoryLevel      => _memoryLevel;
  bool        get showingPattern   => _showingPattern;
  int?        get highlightedIndex => _highlightedIndex;

  List<int> get logicPattern          => _logicPattern;
  int?      get logicAnswer           => _logicAnswer;
  List<int> get logicChoices          => _logicChoices;
  String    get logicSeriesName       => _logicSeriesName;
  int       get logicSessionScore     => _logicSessionScore;
  int       get logicQuestionsAnswered => _logicQuestionsAnswered;
  int       get logicMissingIndex     => _logicMissingIndex;

  int    get mathA            => _mathA;
  int    get mathB            => _mathB;
  String get mathOp           => _mathOp;
  int    get mathCorrect      => _mathCorrect;
  List<int> get mathChoices   => _mathChoices;
  int    get mathScore        => _mathScore;
  int    get mathCorrectCount => _mathCorrectCount;
  int    get mathTotal        => _mathTotal;
  int    get mathTimeLeft     => _mathTimeLeft;
  int    get mathStreak       => _mathStreak;
  int    get mathMaxStreak    => _mathMaxStreak;
  int    get mathPlusScore    => _mathPlusScore;
  int    get mathMinusScore   => _mathMinusScore;
  int    get mathMulScore     => _mathMulScore;
  int    get mathLastCorrect  => _mathLastCorrect;

  List<int> get schulteGrid      => _schulteGrid;
  int       get schulteNext      => _schulteNext;
  int       get schulteTimeElapsed => _schulteTimeElapsed;
  int       get schulteGridSize  => _schulteGridSize;
  int       get schulteLevel     => _schulteLevel;
  bool      get schulteComplete  => _schulteComplete;
  int       get schulteTotal     => _schulteGridSize * _schulteGridSize;

  String    get stroopWord         => _stroopWord;
  Color     get stroopInkColor     => _stroopInkColor;
  String    get stroopInkName      => _stroopInkName;
  List<String> get stroopColorOptions => _stroopColorOptions;
  int       get stroopScore        => _stroopScore;
  int       get stroopCorrectCount => _stroopCorrectCount;
  int       get stroopTotal        => _stroopTotal;
  int       get stroopTimeLeft     => _stroopTimeLeft;
  int       get stroopStreak       => _stroopStreak;
  int       get stroopMaxStreak    => _stroopMaxStreak;
  bool      get stroopAnswered     => _stroopAnswered;
  bool      get stroopLastCorrect  => _stroopLastCorrect;
  Map<String, Color> get stroopColorMap => _stroopColors;

  // ---- Shared --------------------------------------------------------------

  void selectGame(GameType type) {
    _currentGame = type;
    _state = GameState.idle;
    notifyListeners();
  }

  // ---- Memory game ---------------------------------------------------------

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
    final int activeCount = min(2 + _memoryLevel, size - 1);
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
    for (final idx in sequence) {
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
    final tapped      = _playerPattern.where((p) => p != null).length;
    final activeCount = _memoryPattern.where((p) => p).length;
    if (tapped >= activeCount) {
      final anyWrong = _playerPattern.any((p) => p == false);
      if (!anyWrong) {
        _score += _memoryLevel;
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
    if (_score > _progress.memoryHighScore) {
      _newMemoryRecord = true;
      _progress.recordHighScore('memory_high_score', _score);
    }
  }

  // ---- Logic game ----------------------------------------------------------

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
      case 0:
        final d = _rng.nextInt(8) + 1;
        final a = _rng.nextInt(15) + 1;
        fullSeq = List.generate(5, (i) => a + d * i);
        _logicSeriesName = 'Arithmetic (+ each step)';
        break;
      case 1:
        final r = _rng.nextInt(3) + 2;
        final a = _rng.nextInt(3) + 1;
        fullSeq = List.generate(5, (i) => a * pow(r, i).toInt());
        _logicSeriesName = 'Geometric (x each step)';
        break;
      case 2:
        final start = _rng.nextInt(5) + 1;
        fullSeq = List.generate(5, (i) => pow(start + i, 2).toInt());
        _logicSeriesName = 'Perfect Squares';
        break;
      case 3:
        final a = _rng.nextInt(5) + 1;
        final b = _rng.nextInt(5) + 1;
        fullSeq = [a, b, a + b, a + 2 * b, 2 * a + 3 * b];
        _logicSeriesName = 'Fibonacci-style';
        break;
      case 4:
        final stepA = _rng.nextInt(4) + 2;
        final stepB = _rng.nextInt(3) + 2;
        final s0 = _rng.nextInt(5) + 2;
        final s1 = s0 + stepA;
        final s2 = s1 * stepB;
        final s3 = s2 + stepA;
        final s4 = s3 * stepB;
        fullSeq = [s0, s1, s2, s3, s4];
        _logicSeriesName = 'Alternating (+, x)';
        break;
      case 5:
        const primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29];
        final startIdx = _rng.nextInt(primes.length - 5);
        fullSeq = primes.sublist(startIdx, startIdx + 5);
        _logicSeriesName = 'Prime Numbers';
        break;
      default:
        final offset = _rng.nextInt(3);
        fullSeq = List.generate(5, (i) => pow(i + 1, 2).toInt() - 1 + offset);
        _logicSeriesName = 'n-squared pattern';
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
      if (wrong != _logicAnswer && !sequenceNumbers.contains(wrong) && wrong > 0) {
        wrongs.add(wrong);
      }
    }
    int extra = _logicAnswer! + 7;
    while (wrongs.length < 3) {
      if (extra != _logicAnswer && !sequenceNumbers.contains(extra)) wrongs.add(extra);
      extra++;
    }
    _logicChoices = [_logicAnswer!, ...wrongs]..shuffle(_rng);
    notifyListeners();
  }

  void answerLogic(int answer) {
    _logicQuestionsAnswered++;
    if (answer == _logicAnswer) {
      _logicSessionScore += 10;
    } else {
      _logicSessionScore = max(0, _logicSessionScore - 5);
    }
    _state = GameState.finished;
    _checkLogicHighScore();
    notifyListeners();
  }

  void stopLogicGame() { _state = GameState.idle; notifyListeners(); }

  void nextLogicRound() { _state = GameState.playing; _generateLogicRound(); notifyListeners(); }

  void _checkLogicHighScore() {
    if (_logicSessionScore > _progress.logicHighScore) {
      _newLogicRecord = true;
      _progress.recordHighScore('logic_high_score', _logicSessionScore);
    }
  }

  void completeWorkout() {}

  // ---- Math sprint ---------------------------------------------------------

  void startMathSprint() {
    _mathTimer?.cancel();
    _state = GameState.playing;
    _mathScore = _mathCorrectCount = _mathTotal = 0;
    _mathTimeLeft = 60;
    _mathStreak = _mathMaxStreak = 0;
    _mathPlusScore = _mathMinusScore = _mathMulScore = 0;
    _mathLastCorrect = -1;
    _newMathRecord = false;
    _generateMathQuestion();
    _mathTimer = Timer.periodic(const Duration(seconds: 1), (_) => tickMathTimer());
  }

  void _generateMathQuestion() {
    final ops = ['+', '-', 'x'];
    _mathOp = ops[_rng.nextInt(3)];
    switch (_mathOp) {
      case '+':
        _mathA = _rng.nextInt(50) + 1; _mathB = _rng.nextInt(50) + 1;
        _mathCorrect = _mathA + _mathB;
        break;
      case '-':
        _mathA = _rng.nextInt(50) + 20; _mathB = _rng.nextInt(_mathA) + 1;
        _mathCorrect = _mathA - _mathB;
        break;
      default:
        _mathA = _rng.nextInt(12) + 1; _mathB = _rng.nextInt(12) + 1;
        _mathCorrect = _mathA * _mathB;
    }
    final wrongs = <int>{};
    while (wrongs.length < 3) {
      final wrong = _mathCorrect + (_rng.nextInt(20) - 10);
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
      _mathScore += 2 + (_mathStreak >= 5 ? 1 : 0);
      switch (_mathOp) {
        case '+': _mathPlusScore++;  break;
        case '-': _mathMinusScore++; break;
        default:  _mathMulScore++;
      }
    } else {
      _mathStreak = 0;
      _mathScore = max(0, _mathScore - 1);
    }
    _mathDelayTimer?.cancel();
    _mathDelayTimer = Timer(const Duration(milliseconds: 300), () {
      if (_state == GameState.playing) _generateMathQuestion();
    });
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
    if (_mathScore > _progress.mathHighScore) {
      _newMathRecord = true;
      _progress.recordHighScore('math_high_score', _mathScore);
    }
  }

  void stopMathTimer() => _mathTimer?.cancel();

  // ---- Schulte table -------------------------------------------------------

  void startSchulteGame({int level = 1}) {
    _schulteTimer?.cancel();
    _schulteLevel = level;
    _schulteGridSize = level == 1 ? 3 : level == 2 ? 4 : 5;
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
    if (_progress.schulteHighScore == 0 || _schulteTimeElapsed < _progress.schulteHighScore) {
      _newSchulteRecord = true;
      _progress.recordHighScore('schulte_high_score', _schulteTimeElapsed);
    }
  }

  void stopSchulte() { _schulteTimer?.cancel(); _state = GameState.idle; notifyListeners(); }

  // ---- Stroop effect -------------------------------------------------------

  void startStroopGame() {
    _stroopTimer?.cancel();
    _stroopScore = _stroopCorrectCount = _stroopTotal = 0;
    _stroopTimeLeft = 60;
    _stroopStreak = _stroopMaxStreak = 0;
    _stroopAnswered = false;
    _newStroopRecord = false;
    _state = GameState.playing;
    _generateStroopRound();
    _stroopTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tickStroopTimer());
  }

  void _generateStroopRound() {
    List<String> pool = ['Red', 'Blue', 'Green', 'Yellow'];
    if (_stroopStreak >= 10) pool = _stroopColors.keys.toList();
    final inkName = pool[_rng.nextInt(pool.length)];
    String wordName;
    do { wordName = pool[_rng.nextInt(pool.length)]; } while (wordName == inkName);
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
      _stroopScore += 3 + (_stroopStreak >= 5 ? 2 : 0);
    } else {
      _stroopStreak = 0;
      _stroopScore = max(0, _stroopScore - 2);
    }
    notifyListeners();
    _stroopDelayTimer?.cancel();
    _stroopDelayTimer = Timer(const Duration(milliseconds: 500), () {
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
    if (_stroopScore > _progress.stroopHighScore) {
      _newStroopRecord = true;
      _progress.recordHighScore('stroop_high_score', _stroopScore);
    }
  }

  void stopStroop() { _stroopTimer?.cancel(); _state = GameState.idle; notifyListeners(); }

  // ---- Reset ---------------------------------------------------------------

  void resetGame() {
    _mathDelayTimer?.cancel();
    _stroopDelayTimer?.cancel();
    _mathTimer?.cancel();
    _schulteTimer?.cancel();
    _stroopTimer?.cancel();
    _state = GameState.idle;
    _score = 0;
    _mathCorrectCount = _stroopCorrectCount = 0;
    _newMemoryRecord = _newLogicRecord = _newMathRecord = false;
    _newSchulteRecord = _newStroopRecord = false;
    notifyListeners();
  }

  Future<void> resetAllData() async {
    _mathTimer?.cancel();
    _schulteTimer?.cancel();
    _stroopTimer?.cancel();
    _state = GameState.idle;
    _score = 0;
    await _progress.resetAllData();
    notifyListeners();
  }

  @override
  void dispose() {
    _mathDelayTimer?.cancel();
    _stroopDelayTimer?.cancel();
    _mathTimer?.cancel();
    _schulteTimer?.cancel();
    _stroopTimer?.cancel();
    super.dispose();
  }
}
