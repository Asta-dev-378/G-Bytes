import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

enum TimerMode { countdown, stopwatch }

enum TimerStatus { idle, running, paused }

class TimerProvider extends ChangeNotifier {
  TimerMode _mode = TimerMode.countdown;
  TimerStatus _status = TimerStatus.idle;
  Duration _duration = const Duration(minutes: 25);
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  // Sound control — synced from SettingsProvider via timer_screen
  bool soundEnabled = true;
  final AudioPlayer _tickPlayer = AudioPlayer();
  final AudioPlayer _stopPlayer = AudioPlayer();

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

  Future<void> _playTick() async {
    if (!soundEnabled) return;
    try {
      await _tickPlayer.stop();
      await _tickPlayer.setAsset('assets/audio/Tick2.mp3');
      await _tickPlayer.setVolume(0.7);
      await _tickPlayer.play();
    } catch (_) {}
  }

  Future<void> _playStop() async {
    if (!soundEnabled) return;
    try {
      await _stopPlayer.stop();
      await _stopPlayer.setAsset('assets/audio/Stop.mp3');
      await _stopPlayer.setVolume(1.0);
      await _stopPlayer.play();
    } catch (_) {}
  }

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
        _playStop();
      } else {
        _playTick();
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    _status = TimerStatus.paused;
    _tickPlayer.stop();
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _status = TimerStatus.idle;
    _elapsed = Duration.zero;
    _tickPlayer.stop();
    _stopPlayer.stop();
    notifyListeners();
  }

  void stopAllSounds() {
    _tickPlayer.stop();
    _stopPlayer.stop();
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
    _tickPlayer.dispose();
    _stopPlayer.dispose();
    super.dispose();
  }
}
