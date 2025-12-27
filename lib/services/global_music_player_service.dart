import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/music_track.dart';

/// Global service to manage music playback across the entire app
/// This allows music played in MusicLibraryScreen to be controlled from Home screen
class GlobalMusicPlayerService extends ChangeNotifier {
  static final GlobalMusicPlayerService _instance = GlobalMusicPlayerService._internal();
  factory GlobalMusicPlayerService() => _instance;
  GlobalMusicPlayerService._internal();

  AudioPlayer? _audioPlayer;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  
  MusicTrack? _currentTrack;
  bool _isPlaying = false;
  bool _isLoading = false;
  double _volume = 0.5;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

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
    _playerStateSubscription = _audioPlayer!.playerStateStream
        .distinct()
        .listen((state) {
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

    // Listen to position
    _positionSubscription?.cancel();
    _positionSubscription = _audioPlayer!.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });
  }

  /// Play a track
  Future<void> playTrack(MusicTrack track) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _initializePlayer();
      if (_audioPlayer == null) return;

      // Stop current playback
      try {
        await _audioPlayer!.stop();
      } catch (e) {
        print('Error stopping previous track: $e');
      }

      // Set the new track
      _currentTrack = track;
      
      // Check if it's an asset path (starts with "assets/")
      if (track.audioPath != null && track.audioPath!.isNotEmpty) {
        if (track.audioPath!.startsWith('assets/')) {
          // Play from assets
          await _audioPlayer!.setAsset(track.audioPath!);
          print('✅ Playing from assets: ${track.audioPath}');
        } else {
          // Play from local file (user uploaded tracks)
          try {
            final file = File(track.audioPath!);
            if (file.existsSync()) {
              await _audioPlayer!.setFilePath(track.audioPath!);
              print('✅ Playing from local file: ${track.audioPath}');
            } else {
              throw Exception('File nhạc không tồn tại. Vui lòng tải lại file nhạc từ thư viện.');
            }
          } catch (e) {
            if (e.toString().contains('File nhạc không tồn tại')) {
              rethrow;
            }
            throw Exception('Không thể phát file nhạc: $e');
          }
        }
      } else {
        // No audio source available
        throw Exception('File nhạc không tồn tại. Vui lòng tải lại file nhạc từ thư viện.');
      }

      // Start playing
      await _audioPlayer!.play();
      _isPlaying = true;
      _isLoading = false;
      notifyListeners();
      
      print('✅ Global player: Started playing ${track.name}');
    } catch (e) {
      print('❌ Error playing track in global player: $e');
      _isLoading = false;
      _isPlaying = false;
      
      // Log network errors specifically
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('offline') || 
          errorStr.contains('network') || 
          errorStr.contains('connection') ||
          errorStr.contains('socketexception') ||
          errorStr.contains('failed host lookup')) {
        print('⚠️ Global player: Network error - device may be offline');
      }
      
      notifyListeners();
      rethrow;
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_audioPlayer == null) return;
    
    try {
      if (_isPlaying) {
        await _audioPlayer!.pause();
      } else {
        await _audioPlayer!.play();
      }
      // State will be updated by listener
    } catch (e) {
      print('Error toggling play/pause: $e');
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
      print('Error stopping playback: $e');
    }
  }

  /// Set volume
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_audioPlayer != null) {
      await _audioPlayer!.setVolume(_volume);
    }
    notifyListeners();
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    if (_audioPlayer == null) return;
    
    try {
      await _audioPlayer!.seek(position);
    } catch (e) {
      print('Error seeking: $e');
    }
  }

  /// Dispose the service
  void dispose() {
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _audioPlayer?.dispose();
    _audioPlayer = null;
    super.dispose();
  }
}

