import 'dart:async';
import 'package:flutter/material.dart';

enum TimerMode { countdown, stopwatch }

enum TimerStatus { idle, running, paused }

class TimerProvider extends ChangeNotifier {
  TimerMode _mode = TimerMode.countdown;
  TimerStatus _status = TimerStatus.idle;
  Duration _duration = const Duration(minutes: 25);
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  // Preset durations
  final List<Duration> presets = const [
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 25),
    Duration(minutes: 45),
    Duration(hours: 1),
  ];

  TimerMode get mode => _mode;
  TimerStatus get status => _status;
  Duration get duration => _duration;
  Duration get elapsed => _elapsed;

  Duration get remaining {
    if (_mode == TimerMode.countdown) {
      final rem = _duration - _elapsed;
      return rem.isNegative ? Duration.zero : rem;
    }
    return _elapsed;
  }

  double get progress {
    if (_mode == TimerMode.countdown) {
      if (_duration.inSeconds == 0) return 0;
      return (_elapsed.inSeconds / _duration.inSeconds).clamp(0.0, 1.0);
    }
    return 0;
  }

  bool get isFinished => _mode == TimerMode.countdown && _elapsed >= _duration;

  void setMode(TimerMode mode) {
    reset();
    _mode = mode;
    notifyListeners();
  }

  void setDuration(Duration d) {
    _duration = d;
    _elapsed = Duration.zero;
    notifyListeners();
  }

  void start() {
    if (_status == TimerStatus.running) return;
    _status = TimerStatus.running;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      if (isFinished) {
        _timer?.cancel();
        _status = TimerStatus.idle;
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    _status = TimerStatus.paused;
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _status = TimerStatus.idle;
    _elapsed = Duration.zero;
    notifyListeners();
  }

  void adjustDuration(int minutes) {
    final newDuration = _duration + Duration(minutes: minutes);
    if (newDuration.inMinutes > 0 && newDuration.inHours < 2) {
      _duration = newDuration;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
