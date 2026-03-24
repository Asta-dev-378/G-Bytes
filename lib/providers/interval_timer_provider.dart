import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';

enum IntervalPhase { work, rest, complete }

class IntervalTimerProvider extends ChangeNotifier {
  int _workSeconds = 45;
  int _restSeconds = 15;
  int _totalRounds = 4;

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
  final AudioPlayer _tickPlayer = AudioPlayer();
  final AudioPlayer _stopPlayer = AudioPlayer();

  int get workSeconds => _workSeconds;
  int get restSeconds => _restSeconds;
  int get totalRounds => _totalRounds;
  int get currentRound => _currentRound;
  IntervalPhase get phase => _phase;
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;

  int get totalWorkoutTime {
    return (_workSeconds + _restSeconds) * _totalRounds;
  }

  Future<void> _playTick() async {
    if (!soundEnabled) return;
    try {
      await _tickPlayer.stop();
      await _tickPlayer.setAsset('assets/audio/Tick2.mp3');
      await _tickPlayer.setVolume(0.8);
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

  void setWork(int seconds) {
    if (seconds >= 5 && seconds <= 300) {
      _workSeconds = seconds;
      _resetTimer();
    }
  }

  void setRest(int seconds) {
    if (seconds >= 0 && seconds <= 300) {
      _restSeconds = seconds;
      _resetTimer();
    }
  }

  void setRounds(int rounds) {
    if (rounds >= 1 && rounds <= 20) {
      _totalRounds = rounds;
      _resetTimer();
    }
  }

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
      if (_restSeconds > 0) {
        _phase = IntervalPhase.rest;
        _remainingSeconds = _restSeconds;
      } else {
        _moveToNextRoundOrComplete();
      }
    } else if (_phase == IntervalPhase.rest) {
      _moveToNextRoundOrComplete();
    }
    notifyListeners();
  }

  void _moveToNextRoundOrComplete() {
    if (_currentRound < _totalRounds) {
      _currentRound++;
      _phase = IntervalPhase.work;
      _remainingSeconds = _workSeconds;
      _playTick();
    } else {
      _phase = IntervalPhase.complete;
      _isRunning = false;
      _timer?.cancel();
      _playStop();
      // Call completion callback
      onWorkoutComplete?.call();
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
