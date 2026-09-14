import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

enum TimerMode { countdown, stopwatch }

/// IDLE    — no timer running, clean slate
/// RUNNING — actively counting
/// PAUSED  — mid-session, time preserved
/// COMPLETED — countdown reached 00:00, celebration plays, then settles back to IDLE
enum TimerStatus { idle, running, paused, completed }

class TimerProvider extends ChangeNotifier {
  TimerMode _mode = TimerMode.countdown;
  TimerStatus _status = TimerStatus.idle;
  Duration _duration = const Duration(minutes: 25);

  // Timestamp-based accuracy: elapsed is recomputed every tick so drift from
  // animation/render load is eliminated.
  DateTime? _startTimestamp; // set when timer starts / resumes
  Duration _elapsedBeforePause = Duration.zero; // accumulated before each pause

  Timer? _timer;

  // Replaces Future.delayed — cancellable in dispose() to prevent
  // notifyListeners() firing on a disposed ChangeNotifier.
  Timer? _completionTimer;

  // Sound / haptics — synced from SettingsProvider via timer_screen
  bool soundEnabled = true;
  bool hapticsEnabled = true;

  // Audio players: assets loaded ONCE in constructor; subsequent plays only
  // seek to zero and play — eliminates per-tick platform-channel asset loads.
  final AudioPlayer _tickPlayer = AudioPlayer();
  final AudioPlayer _stopPlayer = AudioPlayer();
  bool _audioReady = false;

  // ── Ring progress notifier ────────────────────────────────────────────────
  // The ring painter subscribes directly via AnimatedBuilder, bypassing the
  // full Provider rebuild fan-out for the 60fps redraw path.
  final ValueNotifier<double> ringProgress = ValueNotifier(1.0);

  // Preset durations
  final List<Duration> presets = const [
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 25),
    Duration(minutes: 45),
    Duration(hours: 1),
  ];

  TimerProvider();
  // Audio is loaded lazily on first play — not in the constructor —
  // so startup time is not affected when the timer tab hasn't been visited.

  // ── Getters ──────────────────────────────────────────────────────────────

  TimerMode get mode => _mode;
  TimerStatus get status => _status;
  Duration get duration => _duration;

  /// Live elapsed time — recomputed from wall-clock when running.
  Duration get elapsed {
    if (_status == TimerStatus.running && _startTimestamp != null) {
      return _elapsedBeforePause + DateTime.now().difference(_startTimestamp!);
    }
    return _elapsedBeforePause;
  }

  /// Time remaining (countdown) or time elapsed (stopwatch).
  Duration get remaining {
    if (_mode == TimerMode.countdown) {
      final rem = _duration - elapsed;
      return rem.isNegative ? Duration.zero : rem;
    }
    return elapsed;
  }

  /// 0.0 → 1.0 continuous fraction for the smooth progress ring.
  /// In countdown mode: 1.0 when full, 0.0 when done.
  /// In stopwatch mode: always 0.0 (ring unused).
  double get fractionRemaining {
    if (_mode == TimerMode.countdown) {
      if (_duration.inMilliseconds == 0) return 0.0;
      return (remaining.inMilliseconds / _duration.inMilliseconds)
          .clamp(0.0, 1.0);
    }
    return 0.0;
  }

  /// 0.0 (nothing elapsed) → 1.0 (fully elapsed). Inverse of fractionRemaining.
  double get progress => 1.0 - fractionRemaining;

  bool get isFinished =>
      _mode == TimerMode.countdown && elapsed >= _duration;

  bool get isLastTenSeconds =>
      _mode == TimerMode.countdown &&
      _status == TimerStatus.running &&
      remaining.inSeconds <= 10 &&
      remaining.inSeconds > 0;

  // Lazily load audio on first play. Subsequent calls are no-ops.
  Future<void> _ensureAudioReady() async {
    if (_audioReady) return;
    try {
      await _tickPlayer.setAsset('assets/audio/Tick2.mp3');
      await _tickPlayer.setVolume(0.7);
      await _stopPlayer.setAsset('assets/audio/Stop.mp3');
      await _stopPlayer.setVolume(1.0);
      _audioReady = true;
    } catch (_) {} // audio failure is always silent
  }

  Future<void> _playTick() async {
    if (!soundEnabled) return;
    await _ensureAudioReady();
    if (!_audioReady) return;
    try {
      await _tickPlayer.seek(Duration.zero);
      await _tickPlayer.play();
    } catch (_) {}
  }

  Future<void> _playStop() async {
    if (!soundEnabled) return;
    await _ensureAudioReady();
    if (!_audioReady) return;
    try {
      await _stopPlayer.seek(Duration.zero);
      await _stopPlayer.play();
    } catch (_) {}
  }

  // ── Controls ─────────────────────────────────────────────────────────────

  void setMode(TimerMode mode) {
    reset();
    _mode = mode;
    notifyListeners();
  }

  void setDuration(Duration d) {
    _duration = d;
    _elapsedBeforePause = Duration.zero;
    _startTimestamp = null;
    ringProgress.value = 1.0;
    notifyListeners();
  }

  void start() {
    if (_status == TimerStatus.running) return;
    _startTimestamp = DateTime.now();
    _status = TimerStatus.running;
    // Tick at ~60fps for smooth ring; sound only on whole-second boundaries.
    // ringProgress ValueNotifier updated here for the ring painter — does NOT
    // trigger a full Provider rebuild tree.
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      ringProgress.value = fractionRemaining; // paint-only, no rebuild

      if (isFinished) {
        _handleCompletion();
      } else {
        notifyListeners(); // status-dependent widgets
        // Play tick only once per second crossing
        final e = elapsed;
        if (e.inMilliseconds % 1000 < 30) {
          _playTick();
        }
      }
    });
    notifyListeners();
  }

  void pause() {
    if (_status != TimerStatus.running) return;
    _elapsedBeforePause = elapsed;
    _startTimestamp = null;
    _timer?.cancel();
    _timer = null;
    _status = TimerStatus.paused;
    _tickPlayer.stop();
    notifyListeners();
  }

  void reset() {
    _completionTimer?.cancel();
    _completionTimer = null;
    _timer?.cancel();
    _timer = null;
    _status = TimerStatus.idle;
    _elapsedBeforePause = Duration.zero;
    _startTimestamp = null;
    ringProgress.value = 1.0;
    _tickPlayer.stop();
    _stopPlayer.stop();
    notifyListeners();
  }

  void _handleCompletion() {
    _timer?.cancel();
    _timer = null;
    _elapsedBeforePause = _duration;
    _startTimestamp = null;
    _status = TimerStatus.completed;
    ringProgress.value = 0.0;
    _playStop();
    notifyListeners();

    // Stored Timer (not Future.delayed) — cancelled in dispose() so it cannot
    // call notifyListeners() on a disposed ChangeNotifier.
    _completionTimer = Timer(const Duration(milliseconds: 3500), () {
      if (_status == TimerStatus.completed) {
        _status = TimerStatus.idle;
        _elapsedBeforePause = Duration.zero;
        ringProgress.value = 1.0;
        notifyListeners();
      }
    });
  }

  /// Acknowledge/dismiss a completed state manually.
  void acknowledgeComplete() {
    _completionTimer?.cancel();
    _completionTimer = null;
    if (_status == TimerStatus.completed) {
      _status = TimerStatus.idle;
      _elapsedBeforePause = Duration.zero;
      ringProgress.value = 1.0;
      notifyListeners();
    }
  }

  void stopAllSounds() {
    _tickPlayer.stop();
    _stopPlayer.stop();
  }

  void adjustDuration(int minutes) {
    final newDuration = _duration + Duration(minutes: minutes);
    if (newDuration.inMinutes > 0 && newDuration.inHours < 2) {
      _duration = newDuration;
      if (_status == TimerStatus.idle) {
        _elapsedBeforePause = Duration.zero;
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    _timer?.cancel();
    _tickPlayer.dispose();
    _stopPlayer.dispose();
    ringProgress.dispose();
    super.dispose();
  }
}
