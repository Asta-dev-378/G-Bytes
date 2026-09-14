import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_plan_model.dart';
import '../services/app_logger.dart';

export '../models/workout_plan_model.dart';

enum IntervalPhase { work, rest, complete }

class IntervalTimerProvider extends ChangeNotifier {
  // Legacy fields kept for quick-start backward compatibility
  int _workSeconds = 45;
  int _restSeconds = 15;
  int _totalRounds = 4;

  List<WorkoutItem> _activeItems = [
    const WorkoutItem(name: 'Workout', sets: 4, workSeconds: 45, restSeconds: 15)
  ];
  int _currentItemIndex = 0;

  int _currentRound = 1;
  IntervalPhase _phase = IntervalPhase.work;
  int _remainingSeconds = 45;
  bool _isRunning = false;
  Timer? _timer;

  // Sound control — injected from outside or defaulting to true
  bool soundEnabled = true;

  // Callback when workout completes
  VoidCallback? onWorkoutComplete;

  // Audio
  // Assets loaded ONCE in constructor; subsequent plays seek to zero and
  // play — eliminates per-tick platform-channel asset reloads.
  final AudioPlayer _tickPlayer = AudioPlayer();
  final AudioPlayer _stopPlayer = AudioPlayer();
  bool _audioReady = false;

  // Cached after _loadPlans() — reused in _savePlans() to avoid repeated
  // platform-channel getInstance() calls on every plan save.
  SharedPreferences? _cachedPrefs;

  // ── Saved Workout Plans ───────────────────────────────────────────────
  final List<WorkoutPlan> _savedPlans = [];
  List<WorkoutPlan> get savedPlans => List.unmodifiable(_savedPlans);

  static const _plansKey = 'workout_plans';

  int get workSeconds => _workSeconds;
  int get restSeconds => _restSeconds;
  int get totalRounds => _totalRounds;
  int get currentRound => _currentRound;
  IntervalPhase get phase => _phase;
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;

  List<WorkoutItem> get activeItems => _activeItems;
  int get currentItemIndex => _currentItemIndex;
  WorkoutItem get currentActiveItem => _activeItems[_currentItemIndex];
  String get currentItemName => currentActiveItem.name;

  int get totalWorkoutTime {
    return _activeItems.fold(0, (sum, i) => sum + i.totalSeconds);
  }

  IntervalTimerProvider() {
    _loadPlans();
    _preloadAudio();
  }

  // ── Plans Persistence ─────────────────────────────────────────────────

  Future<void> _loadPlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedPrefs = prefs; // cache for all subsequent saves
      final raw = prefs.getStringList(_plansKey) ?? [];
      _savedPlans.clear();
      for (final s in raw) {
        final plan = WorkoutPlan.decode(s);
        if (plan != null) _savedPlans.add(plan);
      }
      notifyListeners();
    } catch (e, s) {
      AppLogger.error('IntervalTimerProvider._loadPlans', e, s);
    }
  }

  Future<void> _savePlans() async {
    try {
      final prefs = _cachedPrefs ?? await SharedPreferences.getInstance();
      await prefs.setStringList(
        _plansKey,
        _savedPlans.map((p) => p.encode()).toList(),
      );
    } catch (e, s) {
      AppLogger.error('IntervalTimerProvider._savePlans', e, s);
    }
  }

  void addPlan(WorkoutPlan plan) {
    _savedPlans.add(plan);
    _savePlans();
    notifyListeners();
  }

  void deletePlan(String id) {
    _savedPlans.removeWhere((p) => p.id == id);
    _savePlans();
    notifyListeners();
  }

  /// Apply a saved plan's settings and reset the timer.
  void loadFromPlan(WorkoutPlan plan) {
    if (plan.items.isNotEmpty) {
      _activeItems = List.from(plan.items);
      _currentItemIndex = 0;
      _applyCurrentItemSettings();
      _resetTimer();
    }
  }

  void _applyCurrentItemSettings() {
    final item = currentActiveItem;
    _workSeconds = item.workSeconds;
    _restSeconds = item.restSeconds;
    _totalRounds = item.sets;
  }

  void _updateQuickStartItem() {
    _activeItems = [
      WorkoutItem(
        name: 'Workout',
        sets: _totalRounds,
        workSeconds: _workSeconds,
        restSeconds: _restSeconds,
      )
    ];
    _currentItemIndex = 0;
  }

  // ── Audio ────────────────────────────────────────────────────────

  Future<void> _preloadAudio() async {
    try {
      await _tickPlayer.setAsset('assets/audio/Tick2.mp3');
      await _tickPlayer.setVolume(0.8);
      await _stopPlayer.setAsset('assets/audio/Stop.mp3');
      await _stopPlayer.setVolume(1.0);
      _audioReady = true;
    } catch (_) {}
  }

  Future<void> _playTick() async {
    if (!soundEnabled || !_audioReady) return;
    try {
      await _tickPlayer.seek(Duration.zero);
      await _tickPlayer.play();
    } catch (_) {}
  }

  Future<void> _playStop() async {
    if (!soundEnabled || !_audioReady) return;
    try {
      await _stopPlayer.seek(Duration.zero);
      await _stopPlayer.play();
    } catch (_) {}
  }

  // ── Configuration ─────────────────────────────────────────────────────

  void setWork(int seconds) {
    if (seconds >= 5 && seconds <= 300) {
      _workSeconds = seconds;
      _updateQuickStartItem();
      _resetTimer();
    }
  }

  void setRest(int seconds) {
    if (seconds >= 0 && seconds <= 300) {
      _restSeconds = seconds;
      _updateQuickStartItem();
      _resetTimer();
    }
  }

  void setRounds(int rounds) {
    if (rounds >= 1 && rounds <= 20) {
      _totalRounds = rounds;
      _updateQuickStartItem();
      _resetTimer();
    }
  }

  // ── Control ───────────────────────────────────────────────────────────

  void startWorkout() {
    _resetTimer();
    _startTicker();
    _playTick();
  }

  void pauseResume() {
    if (_isRunning) {
      _timer?.cancel();
      _tickPlayer.stop();
      _isRunning = false;
      notifyListeners();
    } else {
      if (_phase != IntervalPhase.complete) {
        _startTicker();
      }
    }
  }

  void stopWorkout() {
    _tickPlayer.stop();
    _stopPlayer.stop();
    _resetTimer();
  }

  void _resetTimer() {
    _timer?.cancel();
    _isRunning = false;
    _currentItemIndex = 0;
    _applyCurrentItemSettings();
    _currentRound = 1;
    _phase = IntervalPhase.work;
    _remainingSeconds = _workSeconds;
    notifyListeners();
  }

  void _startTicker() {
    _isRunning = true;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        if (_phase == IntervalPhase.work) {
          _playTick();
        }
        notifyListeners();
      } else {
        _handlePhaseTransition();
      }
    });
  }

  void _handlePhaseTransition() {
    if (_phase == IntervalPhase.work) {
      _playStop();

      // Rest only plays BETWEEN rounds — never after the last round of an item.
      final bool isLastRoundOfItem = _currentRound >= _totalRounds;

      if (!isLastRoundOfItem && _restSeconds > 0) {
        // Mid-workout: go to rest before next round
        _phase = IntervalPhase.rest;
        _remainingSeconds = _restSeconds;
      } else {
        // Last round finished — skip rest, move to next item or complete
        _moveToNextRoundOrComplete();
      }
    } else if (_phase == IntervalPhase.rest) {
      _moveToNextRoundOrComplete();
    }
    notifyListeners();
  }

  void _moveToNextRoundOrComplete() {
    if (_currentRound < _totalRounds) {
      // Advance to next round within the same item
      _currentRound++;
      _phase = IntervalPhase.work;
      _remainingSeconds = _workSeconds;
      _playTick();
    } else {
      // All rounds of this item done — check for more items in the plan
      if (_currentItemIndex < _activeItems.length - 1) {
        _currentItemIndex++;
        _applyCurrentItemSettings();
        _currentRound = 1;
        _phase = IntervalPhase.work;
        _remainingSeconds = _workSeconds;
        _playTick();
      } else {
        // Entire workout complete
        _phase = IntervalPhase.complete;
        _isRunning = false;
        _timer?.cancel();
        _playStop();
        onWorkoutComplete?.call();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tickPlayer.dispose();
    _stopPlayer.dispose();
    super.dispose();
  }
}
