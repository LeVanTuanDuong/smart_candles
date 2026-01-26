import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/music_track.dart';

/// Global service to manage music playback across the entire app
/// This allows music played in MusicLibraryScreen to be controlled from Home screen
class GlobalMusicPlayerService extends ChangeNotifier {
  static final GlobalMusicPlayerService _instance =
      GlobalMusicPlayerService._internal();
  factory GlobalMusicPlayerService() => _instance;
  GlobalMusicPlayerService._internal();

  AudioPlayer? _audioPlayer;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  MusicTrack? _currentTrack;
  List<MusicTrack> _currentPlaylist = []; // Current playlist for navigation
  int _currentTrackIndex = -1; // Index of current track in playlist
  bool _isPlaying = false;
  bool _isLoading = false;
  double _volume = 0.5;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  DateTime? _lastPositionUpdate; // For throttling position updates

  // Getters
  MusicTrack? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  double get volume => _volume;
  Duration get duration => _duration;
  Duration get position => _position;

  /// Initialize the audio player
  Future<void> _initializePlayer() async {
    if (_audioPlayer == null) {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setVolume(_volume);
      _setupListeners();
    }
  }

  /// Setup listeners for player state changes
  void _setupListeners() {
    if (_audioPlayer == null) return;

    // Listen to player state
    _playerStateSubscription?.cancel();
    _playerStateSubscription =
        _audioPlayer!.playerStateStream.distinct().listen((state) {
      final wasPlaying = _isPlaying;
      _isPlaying = state.playing;
      _isLoading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;

      if (wasPlaying != _isPlaying) {
        notifyListeners();
      }

      if (state.processingState == ProcessingState.completed) {
        _isPlaying = false;
        notifyListeners();
      }
    });

    // Listen to duration
    _durationSubscription?.cancel();
    _durationSubscription = _audioPlayer!.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });

    // Listen to position - throttle updates to reduce rebuilds (update every 200ms instead of every frame)
    _positionSubscription?.cancel();
    _lastPositionUpdate = null;
    _positionSubscription = _audioPlayer!.positionStream.listen((position) {
      // Only update UI every 200ms to reduce rebuilds
      final now = DateTime.now();
      if (_lastPositionUpdate == null ||
          now.difference(_lastPositionUpdate!).inMilliseconds >= 200) {
        _position = position;
        _lastPositionUpdate = now;
        notifyListeners();
      } else {
        // Still update internal state without notifying listeners
        _position = position;
      }
    });
  }

  /// Play a track
  Future<void> playTrack(MusicTrack track, {List<MusicTrack>? playlist}) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _initializePlayer();
      if (_audioPlayer == null) return;

      // Stop current playback more gracefully
      try {
        if (_audioPlayer!.playing) {
          await _audioPlayer!.pause();
        }
        await _audioPlayer!.stop();
        // Small delay to let the OS release audio resources
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        debugPrint('Error stopping previous track: $e');
      }

      // Set the new track and playlist
      _currentTrack = track;

      // Update playlist if provided
      if (playlist != null && playlist.isNotEmpty) {
        _currentPlaylist = playlist;
        _currentTrackIndex = playlist.indexWhere((t) => t.id == track.id);
      } else if (_currentPlaylist.isEmpty ||
          !_currentPlaylist.any((t) => t.id == track.id)) {
        _currentPlaylist = [track];
        _currentTrackIndex = 0;
      } else {
        _currentTrackIndex =
            _currentPlaylist.indexWhere((t) => t.id == track.id);
      }

      // Load and play with retry for error -11849
      int retryCount = 0;
      bool loaded = false;
      String? lastError;

      while (retryCount < 2 && !loaded) {
        try {
          if (track.audioPath != null && track.audioPath!.isNotEmpty) {
            if (track.audioPath!.startsWith('assets/')) {
              await _audioPlayer!.setAsset(track.audioPath!);
              loaded = true;
            } else {
              final file = File(track.audioPath!);
              if (file.existsSync()) {
                await _audioPlayer!.setFilePath(track.audioPath!);
                loaded = true;
              } else {
                throw Exception('File nhạc không tồn tại trong máy.');
              }
            }
          } else {
            throw Exception('Đường dẫn file nhạc trống.');
          }
        } catch (e) {
          lastError = e.toString();
          debugPrint('Playback load attempt ${retryCount + 1} failed: $e');
          if (lastError.contains('-11849') || lastError.contains('Stopped')) {
            retryCount++;
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
          } else {
            rethrow; // Don't retry for other errors
          }
        }
      }

      if (!loaded) {
        throw Exception(
            'Không thể nạp file nhạc sau nhiều lần thử: $lastError');
      }

      // Start playing
      await _audioPlayer!.play();
      _isPlaying = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _isPlaying = false;
      notifyListeners();
      debugPrint('GlobalMusicPlayer error: $e');
      rethrow;
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_audioPlayer == null) return;

    try {
      // Update state immediately for instant UI feedback (optimistic update)
      _isPlaying = !_isPlaying;
      notifyListeners();

      // Then perform the actual play/pause operation based on the NEW state
      if (_isPlaying) {
        await _audioPlayer!.play();
      } else {
        await _audioPlayer!.pause();
      }
      // Note: Listener will confirm the actual state from audio player,
      // but UI has already been updated optimistically for better UX
    } catch (e) {
      // Error toggling play/pause - handled by state revert
      // Revert state on error
      _isPlaying = !_isPlaying;
      notifyListeners();
    }
  }

  /// Stop playback
  Future<void> stop() async {
    if (_audioPlayer == null) return;

    try {
      await _audioPlayer!.stop();
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      // Error stopping playback
    }
  }

  /// Set volume
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_audioPlayer != null) {
      await _audioPlayer!.setVolume(_volume);
    }
    // Don't notify listeners here for smoother volume adjustment
    // Listeners will be notified when volume change is complete
  }

  /// Set volume without notifying (for smooth dragging)
  Future<void> setVolumeSilent(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_audioPlayer != null) {
      await _audioPlayer!.setVolume(_volume);
    }
  }

  /// Set volume and notify (for when dragging ends)
  Future<void> setVolumeAndNotify(double volume) async {
    await setVolume(volume);
    notifyListeners();
  }

  /// Play previous track in playlist
  Future<void> playPreviousTrack() async {
    if (_currentPlaylist.isEmpty || _currentTrackIndex <= 0) {
      return; // No previous track available
    }

    _currentTrackIndex--;
    final previousTrack = _currentPlaylist[_currentTrackIndex];
    await playTrack(previousTrack);
  }

  /// Play next track in playlist
  Future<void> playNextTrack() async {
    if (_currentPlaylist.isEmpty ||
        _currentTrackIndex >= _currentPlaylist.length - 1) {
      return; // No next track available
    }

    _currentTrackIndex++;
    final nextTrack = _currentPlaylist[_currentTrackIndex];
    await playTrack(nextTrack);
  }

  /// Check if previous track is available
  bool get hasPreviousTrack =>
      _currentPlaylist.isNotEmpty && _currentTrackIndex > 0;

  /// Check if next track is available
  bool get hasNextTrack =>
      _currentPlaylist.isNotEmpty &&
      _currentTrackIndex < _currentPlaylist.length - 1;

  /// Seek to position
  Future<void> seek(Duration position) async {
    if (_audioPlayer == null) return;

    try {
      await _audioPlayer!.seek(position);
    } catch (e) {
      // Error seeking
    }
  }

  /// Dispose the service
  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _audioPlayer?.dispose();
    _audioPlayer = null;
    super.dispose();
  }
}
