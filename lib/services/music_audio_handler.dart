import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Handles audio playback and exposes notification controls via audio_service.
/// Notification shows play/pause + skip prev/next. Stops when app is cleared.
class MusicAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer player = AudioPlayer();

  MusicAudioHandler() {
    // Pipe player state → AudioService playback state (drives the notification)
    player.playbackEventStream.map(_toPlaybackState).pipe(playbackState);

    // Auto-advance when a track completes (handled by MusicProvider via listener,
    // but playbackState still needs to stay in sync)
    player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        // Signal completion so clients can advance to next track
        playbackState.add(
          playbackState.value.copyWith(
            processingState: AudioProcessingState.completed,
          ),
        );
      }
    });
  }

  // ── AudioHandler interface ───────────────────────────────────────────────

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> skipToPrevious() async {
    // Delegate to MusicProvider via playback state — handled externally
    // We re-broadcast so the notification button works
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.loading,
      ),
    );
  }

  @override
  Future<void> skipToNext() async {
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.loading,
      ),
    );
  }

  @override
  Future<void> stop() async {
    await player.stop();
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
    await super.stop();
  }

  /// Call this whenever the current track changes to update the notification.
  @override
  Future<void> updateMediaItem(MediaItem item) async {
    mediaItem.add(item);
  }

  // ── State builder ────────────────────────────────────────────────────────

  PlaybackState _toPlaybackState(PlaybackEvent event) {
    final pState = player.processingState;
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[pState]!,
      playing: player.playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: event.currentIndex,
    );
  }

  // ── Cleanup ──────────────────────────────────────────────────────────────

  Future<void> disposePlayer() async {
    await player.dispose();
  }
}
