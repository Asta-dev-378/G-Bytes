import 'package:flutter/material.dart';

class MusicTrack {
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final Color color;
  final String? filePath; // null = built-in demo track

  const MusicTrack({
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.color,
    this.filePath,
  });

  MusicTrack copyWith({
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    Color? color,
    String? filePath,
  }) {
    return MusicTrack(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      color: color ?? this.color,
      filePath: filePath ?? this.filePath,
    );
  }
}

class MusicProvider extends ChangeNotifier {
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isShuffle = false;
  bool _isRepeat = false;
  Duration _position = Duration.zero;

  final List<MusicTrack> _tracks = [
    const MusicTrack(
      title: 'Focus Flow',
      artist: 'BrainBeats',
      album: 'Neural Waves',
      duration: Duration(minutes: 3, seconds: 24),
      color: Color(0xFFFF8C00),
    ),
    const MusicTrack(
      title: 'Deep Concentration',
      artist: 'MindMasters',
      album: 'Alpha State',
      duration: Duration(minutes: 4, seconds: 12),
      color: Color(0xFF6C63FF),
    ),
    const MusicTrack(
      title: 'Power Surge',
      artist: 'G-Bytes Studio',
      album: 'Gain Mode',
      duration: Duration(minutes: 2, seconds: 58),
      color: Color(0xFF20BC68),
    ),
    const MusicTrack(
      title: 'Morning Clarity',
      artist: 'ZenFlow',
      album: 'Rise Up',
      duration: Duration(minutes: 3, seconds: 45),
      color: Color(0xFFFF4F7B),
    ),
    const MusicTrack(
      title: 'Logic Loop',
      artist: 'BrainBeats',
      album: 'Neural Waves',
      duration: Duration(minutes: 3, seconds: 10),
      color: Color(0xFF00BCD4),
    ),
    const MusicTrack(
      title: 'Hustle Hard',
      artist: 'G-Bytes Studio',
      album: 'Gain Mode',
      duration: Duration(minutes: 4, seconds: 5),
      color: Color(0xFFFFB300),
    ),
  ];

  List<MusicTrack> get tracks => _tracks;
  MusicTrack get current => _tracks[_currentIndex];
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;
  Duration get position => _position;

  // Pick a color for user-added tracks (cycles through palette)
  static const _trackColors = [
    Color(0xFF9C27B0),
    Color(0xFF2196F3),
    Color(0xFFE91E63),
    Color(0xFF4CAF50),
    Color(0xFFFF5722),
    Color(0xFF00BCD4),
    Color(0xFF795548),
    Color(0xFF607D8B),
  ];

  void addTrack(MusicTrack track) {
    _tracks.add(track);
    notifyListeners();
  }

  void addFileTrack({
    required String filePath,
    required String title,
    required String artist,
  }) {
    final colorIndex = _tracks.length % _trackColors.length;
    _tracks.add(
      MusicTrack(
        title: title,
        artist: artist,
        album: 'My Files',
        duration: const Duration(minutes: 3, seconds: 30), // placeholder
        color: _trackColors[colorIndex],
        filePath: filePath,
      ),
    );
    notifyListeners();
  }

  void removeTrack(int index) {
    if (_tracks.length <= 1) return; // don't remove last track
    _tracks.removeAt(index);
    // Adjust current index if needed
    if (_currentIndex >= _tracks.length) {
      _currentIndex = _tracks.length - 1;
    } else if (_currentIndex == index) {
      _currentIndex = index.clamp(0, _tracks.length - 1);
    }
    _position = Duration.zero;
    notifyListeners();
  }

  void reorderTracks(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final track = _tracks.removeAt(oldIndex);
    _tracks.insert(newIndex, track);
    // Update current index to follow the moved track
    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else if (_currentIndex == newIndex) {
      _currentIndex = _currentIndex < oldIndex ? newIndex + 1 : newIndex - 1;
    }
    notifyListeners();
  }

  void togglePlay() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void next() {
    if (_isShuffle) {
      _currentIndex = (DateTime.now().millisecond % _tracks.length);
    } else {
      _currentIndex = (_currentIndex + 1) % _tracks.length;
    }
    _position = Duration.zero;
    notifyListeners();
  }

  void previous() {
    _currentIndex = (_currentIndex - 1 + _tracks.length) % _tracks.length;
    _position = Duration.zero;
    notifyListeners();
  }

  void selectTrack(int index) {
    _currentIndex = index;
    _isPlaying = true;
    _position = Duration.zero;
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    notifyListeners();
  }

  void seekTo(Duration position) {
    _position = position;
    notifyListeners();
  }

  void tick() {
    if (_isPlaying) {
      final duration = current.duration;
      if (_position < duration) {
        _position += const Duration(seconds: 1);
      } else {
        if (_isRepeat) {
          _position = Duration.zero;
        } else {
          next();
        }
      }
      notifyListeners();
    }
  }
}
