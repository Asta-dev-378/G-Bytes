import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/music_audio_handler.dart';

// ── Track Model ───────────────────────────────────────────────────────────

class MusicTrack {
  final String title;
  final String artist;
  final String album;
  final int colorValue;
  final String? storedPath;

  const MusicTrack({
    required this.title,
    required this.artist,
    required this.album,
    required this.colorValue,
    this.storedPath,
  });

  bool get isBuiltIn => storedPath == null;

  factory MusicTrack.fromMap(Map<String, dynamic> m) => MusicTrack(
    title: m['title'] as String,
    artist: m['artist'] as String,
    album: m['album'] as String,
    colorValue: m['colorValue'] as int,
    storedPath: m['storedPath'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'title': title,
    'artist': artist,
    'album': album,
    'colorValue': colorValue,
    'storedPath': storedPath,
  };
}

// ── Provider ──────────────────────────────────────────────────────────────

class MusicProvider extends ChangeNotifier {
  final MusicAudioHandler _handler;

  // Convenience getter — used by UI for streams
  AudioPlayer get _player => _handler.player;

  int _currentIndex = 0;
  bool _isShuffle = false;
  bool _isRepeat = false;
  bool _isInitialized = false;

  final List<MusicTrack> _tracks = [];

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration?>? _durationSub;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  static const _trackColors = [
    0xFFFF8C00,
    0xFF6C63FF,
    0xFF20BC68,
    0xFFFF4F7B,
    0xFF00BCD4,
    0xFFFFB300,
    0xFF9C27B0,
    0xFF2196F3,
    0xFFE91E63,
    0xFF4CAF50,
  ];

  MusicProvider(this._handler) {
    _init();
  }

  // ── Getters ───────────────────────────────────────────────────────────

  List<MusicTrack> get tracks => List.unmodifiable(_tracks);
  MusicTrack? get current => _tracks.isEmpty ? null : _tracks[_currentIndex];
  int get currentIndex => _currentIndex;
  int get colorValue => current?.colorValue ?? _trackColors[0];
  bool get isPlaying => _player.playing;
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;
  bool get isInitialized => _isInitialized;
  Duration get duration => _duration;
  Duration get position => _position;
  Stream<Duration> get positionStream => _player.positionStream;

  // ── Initialization ────────────────────────────────────────────────────

  Future<void> _init() async {
    await _loadPlaylist();
    _setupListeners();
    _isInitialized = true;
    notifyListeners();
  }

  void _setupListeners() {
    _player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _player.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });

    _player.playerStateStream.listen((state) {
      notifyListeners();
      if (state.processingState == ProcessingState.completed) {
        if (_isRepeat) {
          _player.seek(Duration.zero);
          _player.play();
        } else {
          next();
        }
      }
    });
  }

  // ── Playlist Persistence ──────────────────────────────────────────────

  Future<void> _loadPlaylist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('music_playlist') ?? [];

      String? docsDirPath;
      try {
        if (!kIsWeb) {
          final dir = await getApplicationDocumentsDirectory();
          docsDirPath = dir.path;
        }
      } catch (_) {}

      for (final raw in saved) {
        try {
          final parts = raw.split('|||');
          if (parts.length >= 4) {
            String? storedFileName = parts.length > 4 ? parts[4] : null;
            String? resolvedPath;

            if (storedFileName != null && docsDirPath != null && !kIsWeb) {
              final fileName = storedFileName
                  .split(Platform.pathSeparator)
                  .last;
              resolvedPath =
                  '$docsDirPath${Platform.pathSeparator}g_bytes_music${Platform.pathSeparator}$fileName';
            } else if (storedFileName != null && kIsWeb) {
              resolvedPath = storedFileName;
            }

            final track = MusicTrack(
              title: parts[0],
              artist: parts[1],
              album: parts[2],
              colorValue: int.parse(parts[3]),
              storedPath: resolvedPath,
            );

            if (track.storedPath == null) {
              _tracks.add(track);
            } else if (!kIsWeb && resolvedPath != null) {
              if (await File(resolvedPath).exists()) {
                _tracks.add(track);
              }
            } else if (kIsWeb) {
              _tracks.add(track);
            }
          }
        } catch (e) {
          debugPrint('Error loading track entry: $e');
        }
      }
    } catch (e) {
      debugPrint('Critical error loading playlist: $e');
    }
  }

  Future<void> _savePlaylist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _tracks.map((t) {
        String? fileNameToSave;
        if (t.storedPath != null) {
          fileNameToSave = kIsWeb
              ? t.storedPath
              : t.storedPath!.split(Platform.pathSeparator).last;
        }
        final parts = [
          t.title,
          t.artist,
          t.album,
          t.colorValue.toString(),
          ?fileNameToSave,
        ];
        return parts.join('|||');
      }).toList();
      await prefs.setStringList('music_playlist', list);
    } catch (e) {
      debugPrint('Error saving playlist: $e');
    }
  }

  // ── Add File from Device ──────────────────────────────────────────────

  Future<MusicTrack?> importFile({
    required String sourcePath,
    required String fileName,
  }) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${docsDir.path}/g_bytes_music');
      if (!musicDir.existsSync()) musicDir.createSync(recursive: true);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final destPath = '${musicDir.path}/${timestamp}_$fileName';
      await File(sourcePath).copy(destPath);

      final title = fileName.contains('.')
          ? fileName.substring(0, fileName.lastIndexOf('.'))
          : fileName;
      final colorValue = _trackColors[_tracks.length % _trackColors.length];

      final track = MusicTrack(
        title: title,
        artist: 'My Library',
        album: 'Imported',
        colorValue: colorValue,
        storedPath: destPath,
      );

      _tracks.add(track);
      await _savePlaylist();
      notifyListeners();
      return track;
    } catch (e) {
      debugPrint('Error importing music file: $e');
      return null;
    }
  }

  Future<MusicTrack?> importFileBytes({
    required String fileName,
    required List<int> bytes,
  }) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${docsDir.path}/g_bytes_music');
      if (!musicDir.existsSync()) musicDir.createSync(recursive: true);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final destPath = '${musicDir.path}/${timestamp}_$fileName';
      await File(destPath).writeAsBytes(bytes);

      final title = fileName.contains('.')
          ? fileName.substring(0, fileName.lastIndexOf('.'))
          : fileName;
      final colorValue = _trackColors[_tracks.length % _trackColors.length];

      final track = MusicTrack(
        title: title,
        artist: 'My Library',
        album: 'Imported',
        colorValue: colorValue,
        storedPath: destPath,
      );

      _tracks.add(track);
      await _savePlaylist();
      notifyListeners();
      return track;
    } catch (e) {
      debugPrint('Error importing music bytes: $e');
      return null;
    }
  }

  // ── Playback ──────────────────────────────────────────────────────────

  Future<void> selectAndPlay(int index) async {
    if (_tracks.isEmpty) return;
    _currentIndex = index.clamp(0, _tracks.length - 1);
    await _loadCurrentTrack();
    await _handler.play();
    notifyListeners();
  }

  Future<void> _loadCurrentTrack() async {
    if (_tracks.isEmpty) return;
    final track = _tracks[_currentIndex];
    try {
      if (track.storedPath != null) {
        await _player.setAudioSource(
          AudioSource.uri(Uri.file(track.storedPath!)),
        );
      }
      // Update the notification with current track info
      await _handler.updateMediaItem(
        MediaItem(
          id: '${_currentIndex}_${track.title}',
          title: track.title,
          artist: track.artist,
          album: track.album,
        ),
      );
    } catch (e) {
      debugPrint('Error loading track: $e');
    }
  }

  Future<void> togglePlay() async {
    if (_tracks.isEmpty) return;
    if (_player.playing) {
      await _handler.pause();
    } else {
      if (_player.processingState == ProcessingState.idle ||
          _player.processingState == ProcessingState.completed) {
        await _loadCurrentTrack();
      }
      await _handler.play();
    }
    notifyListeners();
  }

  Future<void> next() async {
    if (_tracks.isEmpty) return;
    if (_isShuffle) {
      _currentIndex = DateTime.now().millisecondsSinceEpoch % _tracks.length;
    } else {
      _currentIndex = (_currentIndex + 1) % _tracks.length;
    }
    await _loadCurrentTrack();
    await _handler.play();
    notifyListeners();
  }

  Future<void> previous() async {
    if (_tracks.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _tracks.length) % _tracks.length;
    await _loadCurrentTrack();
    await _handler.play();
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    _player.setLoopMode(_isRepeat ? LoopMode.one : LoopMode.off);
    notifyListeners();
  }

  Future<void> seekTo(Duration position) async {
    await _handler.seek(position);
  }

  // ── Remove Track ─────────────────────────────────────────────────────

  Future<void> removeTrack(int index) async {
    if (_tracks.isEmpty) return;
    final track = _tracks[index];
    final wasPlaying = _player.playing && _currentIndex == index;
    final wasCurrent = _currentIndex == index;
    
    _tracks.removeAt(index);

    try {
      if (_tracks.isEmpty) {
        try {
          await _handler.stop();
        } catch (e) {
          debugPrint('Error stopping handler: $e');
        }
        _currentIndex = 0;
      } else {
        if (_currentIndex >= _tracks.length) _currentIndex = _tracks.length - 1;
        if (wasPlaying || wasCurrent) {
          await _loadCurrentTrack();
          if (wasPlaying) await _handler.play();
        }
      }
    } finally {
      if (track.storedPath != null) {
        try {
          final file = File(track.storedPath!);
          if (file.existsSync()) file.deleteSync();
        } catch (_) {}
      }

      await _savePlaylist();
      notifyListeners();
    }
  }

  void reorderTracks(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final track = _tracks.removeAt(oldIndex);
    _tracks.insert(newIndex, track);

    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }

    _savePlaylist();
    notifyListeners();
  }

  // ── Stop everything (e.g. when app is killed) ─────────────────────────

  Future<void> stopAll() async {
    await _handler.stop();
    notifyListeners();
  }

  // ── Dispose ───────────────────────────────────────────────────────────

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _durationSub?.cancel();
    super.dispose();
  }
}
