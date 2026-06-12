import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_progress.dart';

class StreakProvider extends ChangeNotifier {
  static const int dailyGoal = 100;

  int _currentStreak = 0;
  int _weeklyPoints = 0;
  
  // Maps a date string "YYYY-MM-DD" to the user's progress for that day
  Map<String, DailyProgress> _history = {};

  // -- Optional Improvement: Streak Freeze --
  // If true, missing a day won't reset the streak, but will consume the freeze.
  bool _hasStreakFreeze = false; 

  int get currentStreak => _currentStreak;
  int get weeklyPoints => _weeklyPoints;
  int get todayPoints => _getTodayProgress().pointsEarned;
  Map<String, DailyProgress> get history => _history;
  bool get hasStreakFreeze => _hasStreakFreeze;

  StreakProvider() {
    _loadData();
  }

  /// Returns today's date normalized as a string (YYYY-MM-DD).
  /// Optional Improvement: For a "late night" offset, you can subtract hours.
  /// Example: final now = DateTime.now().subtract(const Duration(hours: 3));
  String get _todayStr {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    _currentStreak = prefs.getInt('streak_count') ?? 0;
    _weeklyPoints = prefs.getInt('weekly_streak_points') ?? 0;
    _hasStreakFreeze = prefs.getBool('has_streak_freeze') ?? false;
    
    final historyJson = prefs.getString('streak_history');
    if (historyJson != null) {
      final decoded = jsonDecode(historyJson) as Map<String, dynamic>;
      _history = decoded.map((key, value) => MapEntry(key, DailyProgress.fromJson(value)));
    }
    
    _checkDailyReset(prefs);
    _checkWeeklyReset(prefs);
    notifyListeners();
  }

  DailyProgress _getTodayProgress() {
    return _history[_todayStr] ?? DailyProgress(date: _todayStr, pointsEarned: 0);
  }

  /// Add points to the current day. E.g. when completing a game.
  Future<void> addPoints(int points) async {
    if (points <= 0) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Always check for new day/week before modifying points
    _checkDailyReset(prefs);
    _checkWeeklyReset(prefs);

    DailyProgress todayProg = _getTodayProgress();
    
    final wasAlreadyCompleted = todayProg.isCompleted;
    final newPoints = todayProg.pointsEarned + points;
    final isNowCompleted = newPoints >= dailyGoal;

    _history[_todayStr] = DailyProgress(
      date: _todayStr,
      pointsEarned: newPoints,
      isCompleted: isNowCompleted,
    );

    // If they just crossed the 100 threshold today, increase streak
    if (!wasAlreadyCompleted && isNowCompleted) {
      _currentStreak++;
      await prefs.setInt('streak_count', _currentStreak);
    }
    
    // Weekly points accumulate continuously without a cap
    _weeklyPoints += points;
    await prefs.setInt('weekly_streak_points', _weeklyPoints);

    await _saveHistory(prefs);
    notifyListeners();
  }

  /// Evaluates if the streak needs to be reset due to an incomplete yesterday
  void _checkDailyReset(SharedPreferences prefs) {
    if (_currentStreak == 0) return; // Nothing to reset

    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr = "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

    bool todayCompleted = _history[_todayStr]?.isCompleted ?? false;
    bool yesterdayCompleted = _history[yesterdayStr]?.isCompleted ?? false;

    // The streak breaks ONLY if we didn't finish yesterday AND we haven't finished today yet.
    // That means yesterday was completely missed.
    if (!todayCompleted && !yesterdayCompleted) {
      if (_hasStreakFreeze) {
        // Consume the freeze instead of breaking the streak
        _hasStreakFreeze = false;
        prefs.setBool('has_streak_freeze', false);
        // We artificially "complete" yesterday to maintain continuous calendar (Optional)
        // _history[yesterdayStr] = DailyProgress(date: yesterdayStr, pointsEarned: 0, isCompleted: true);
      } else {
        _currentStreak = 0;
        prefs.setInt('streak_count', 0);
      }
    }
  }

  /// Resets weekly points if we entered a new week (Monday -> Sunday)
  void _checkWeeklyReset(SharedPreferences prefs) {
    final today = DateTime.now();
    // Shift days so Monday=1, Sunday=7. We figure out the date of this week's Monday.
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final weekStr = "${monday.year}-${monday.month}-${monday.day}";

    final savedWeek = prefs.getString('streak_week_start') ?? '';

    if (savedWeek != weekStr) {
      _weeklyPoints = 0;
      prefs.setInt('weekly_streak_points', 0);
      prefs.setString('streak_week_start', weekStr);
    }
  }

  /// Purchase a streak freeze (Optional improvement)
  Future<void> buyStreakFreeze() async {
    if (!_hasStreakFreeze) {
      _hasStreakFreeze = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_streak_freeze', true);
      notifyListeners();
    }
  }

  Future<void> _saveHistory(SharedPreferences prefs) async {
    final jsonStr = jsonEncode(_history.map((key, value) => MapEntry(key, value.toJson())));
    await prefs.setString('streak_history', jsonStr);
  }
}
