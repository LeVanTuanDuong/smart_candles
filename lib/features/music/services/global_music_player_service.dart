import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:smart_candles/features/music/models/music_track.dart';

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
  List<MusicTrack> _currentPlaylist = [];
  int _currentTrackIndex = -1;
  bool _isPlaying = false;
  bool _isLoading = false;
  double _volume = 0.5;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  DateTime? _lastPositionUpdate;

  MusicTrack? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  double get volume => _volume;
  Duration get duration => _duration;
  Duration get position => _position;

  Future<void> _initializePlayer() async {
    if (_audioPlayer == null) {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setVolume(_volume);
      _setupListeners();
    }
  }

  void _setupListeners() {
    if (_audioPlayer == null) return;
    _playerStateSubscription?.cancel();
    _playerStateSubscription =
        _audioPlayer!.playerStateStream.distinct().listen((state) {
      final wasPlaying = _isPlaying;
      _isPlaying = state.playing;
      _isLoading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      if (wasPlaying != _isPlaying) notifyListeners();
      if (state.processingState == ProcessingState.completed) {
        _isPlaying = false;
        notifyListeners();
      }
    });
    _durationSubscription?.cancel();
    _durationSubscription = _audioPlayer!.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });
    _positionSubscription?.cancel();
    _lastPositionUpdate = null;
    _positionSubscription = _audioPlayer!.positionStream.listen((position) {
      final now = DateTime.now();
      if (_lastPositionUpdate == null ||
          now.difference(_lastPositionUpdate!).inMilliseconds >= 200) {
        _position = position;
        _lastPositionUpdate = now;
        notifyListeners();
      } else {
        _position = position;
      }
    });
  }

  Future<void> playTrack(MusicTrack track, {List<MusicTrack>? playlist}) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _initializePlayer();
      if (_audioPlayer == null) return;
      try {
        if (_audioPlayer!.playing) await _audioPlayer!.pause();
        await _audioPlayer!.stop();
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        debugPrint('Error stopping previous track: $e');
      }
      _currentTrack = track;
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
            rethrow;
          }
        }
      }
      if (!loaded) {
        throw Exception(
            'Không thể nạp file nhạc sau nhiều lần thử: $lastError');
      }
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

  Future<void> togglePlayPause() async {
    if (_audioPlayer == null) return;
    try {
      _isPlaying = !_isPlaying;
      notifyListeners();
      if (_isPlaying) {
        await _audioPlayer!.play();
      } else {
        await _audioPlayer!.pause();
      }
    } catch (e) {
      _isPlaying = !_isPlaying;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    if (_audioPlayer == null) return;
    try {
      await _audioPlayer!.stop();
      _isPlaying = false;
      notifyListeners();
    } catch (e) {}
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_audioPlayer != null) {
      await _audioPlayer!.setVolume(_volume);
    }
  }

  Future<void> setVolumeSilent(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_audioPlayer != null) {
      await _audioPlayer!.setVolume(_volume);
    }
  }

  Future<void> setVolumeAndNotify(double volume) async {
    await setVolume(volume);
    notifyListeners();
  }

  Future<void> playPreviousTrack() async {
    if (_currentPlaylist.isEmpty || _currentTrackIndex <= 0) return;
    _currentTrackIndex--;
    await playTrack(_currentPlaylist[_currentTrackIndex]);
  }

  Future<void> playNextTrack() async {
    if (_currentPlaylist.isEmpty ||
        _currentTrackIndex >= _currentPlaylist.length - 1) return;
    _currentTrackIndex++;
    await playTrack(_currentPlaylist[_currentTrackIndex]);
  }

  bool get hasPreviousTrack =>
      _currentPlaylist.isNotEmpty && _currentTrackIndex > 0;

  bool get hasNextTrack =>
      _currentPlaylist.isNotEmpty &&
      _currentTrackIndex < _currentPlaylist.length - 1;

  Future<void> seek(Duration position) async {
    if (_audioPlayer == null) return;
    try {
      await _audioPlayer!.seek(position);
    } catch (e) {}
  }

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
