import 'package:flutter/material.dart';
import 'dart:async';
import 'package:smart_candles/features/music/services/music_service.dart';
import 'package:smart_candles/features/music/services/global_music_player_service.dart';
import 'package:smart_candles/features/music/models/music_track.dart';
import 'dart:io';

class MeditationGuideScreen extends StatefulWidget {
  const MeditationGuideScreen({
    super.key,
  });

  @override
  State<MeditationGuideScreen> createState() => _MeditationGuideScreenState();
}

class _MeditationGuideScreenState extends State<MeditationGuideScreen>
    with SingleTickerProviderStateMixin {
  final GlobalMusicPlayerService _musicPlayer = GlobalMusicPlayerService();
  late AnimationController _waveformController;
  List<MusicTrack> _suggestedTracks = [];
  List<MusicTrack> _allTracks = []; // Full playlist for navigation
  bool _isLoadingTracks = true;

  @override
  void initState() {
    super.initState();
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Load suggested tracks from library
    _loadSuggestedTracks();

    // Listen to music player changes
    _musicPlayer.addListener(_onMusicPlayerChanged);

    // Position updates are handled by GlobalMusicPlayerService listeners

    // Start waveform animation if playing
    if (_musicPlayer.isPlaying) {
      _waveformController.repeat();
    }
  }

  @override
  void dispose() {
    _waveformController.dispose();
    _musicPlayer.removeListener(_onMusicPlayerChanged);
    super.dispose();
  }

  void _onMusicPlayerChanged() {
    if (mounted) {
      setState(() {
        // Update waveform animation
        if (_musicPlayer.isPlaying) {
          if (!_waveformController.isAnimating) {
            _waveformController.repeat();
          }
        } else {
          _waveformController.stop();
        }
      });
    }
  }

  Future<void> _loadSuggestedTracks() async {
    setState(() {
      _isLoadingTracks = true;
    });

    try {
      // Get all tracks from library (default + uploaded)
      final tracksByCategory = await MusicService.getAllTracksByCategory();

      // Get meditation tracks from "Thiền" category
      List<MusicTrack> meditationTracks = tracksByCategory['Thiền'] ?? [];

      // Also include some tracks from other categories for variety
      final otherCategories = ['Thiên nhiên', 'Nhạc Piano', 'Ambient'];
      for (var category in otherCategories) {
        final tracks = tracksByCategory[category] ?? [];
        if (tracks.isNotEmpty) {
          meditationTracks
              .addAll(tracks.take(2)); // Add 2 tracks from each category
        }
      }

      // Store all tracks as playlist for navigation (filter only tracks with valid audio)
      _allTracks = meditationTracks
          .where(
              (track) => track.audioPath != null && track.audioPath!.isNotEmpty)
          .toList();

      // Shuffle the full playlist for variety
      _allTracks.shuffle();

      // If there's a current track, try to include it in the playlist if not already there
      final currentTrack = _musicPlayer.currentTrack;
      if (currentTrack != null) {
        final existsInPlaylist =
            _allTracks.any((track) => track.id == currentTrack.id);
        if (!existsInPlaylist &&
            currentTrack.audioPath != null &&
            currentTrack.audioPath!.isNotEmpty) {
          _allTracks.insert(0, currentTrack);
        }
      }

      // Remove current playing track from suggestions
      List<MusicTrack> suggestedTracks = List.from(_allTracks);
      if (currentTrack != null) {
        suggestedTracks.removeWhere((track) => track.id == currentTrack.id);
      }

      // Take 4-6 tracks for suggestions display
      suggestedTracks = suggestedTracks.take(6).toList();

      setState(() {
        _suggestedTracks = suggestedTracks;
        _isLoadingTracks = false;
      });
    } catch (e) {
      // Error loading tracks - silently fail to avoid log spam
      setState(() {
        _isLoadingTracks = false;
      });
    }
  }

  Future<void> _playTrack(MusicTrack track) async {
    try {
      await _musicPlayer.playTrack(track);

      // Reload suggestions to remove the newly playing track
      await _loadSuggestedTracks();

      // Start waveform animation
      if (!_waveformController.isAnimating) {
        _waveformController.repeat();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể phát nhạc: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _togglePlayPause() {
    // If no track is playing, play the first track in playlist
    if (_musicPlayer.currentTrack == null && _allTracks.isNotEmpty) {
      _playTrack(_allTracks.first);
    } else {
      _musicPlayer.togglePlayPause();
      // Waveform animation will be updated by _onMusicPlayerChanged listener
    }
  }

  Future<void> _playPreviousTrack() async {
    if (_allTracks.isEmpty) return;

    final currentTrack = _musicPlayer.currentTrack;
    if (currentTrack == null) {
      // If no track is playing, play the last track
      await _playTrack(_allTracks.last);
      return;
    }

    // Find current track index in playlist
    final currentIndex =
        _allTracks.indexWhere((track) => track.id == currentTrack.id);
    if (currentIndex == -1) {
      // Current track not in playlist, play last track
      await _playTrack(_allTracks.last);
      return;
    }

    // Play previous track (wrap around to end if at beginning)
    final previousIndex =
        currentIndex > 0 ? currentIndex - 1 : _allTracks.length - 1;
    await _playTrack(_allTracks[previousIndex]);
  }

  Future<void> _playNextTrack() async {
    if (_allTracks.isEmpty) return;

    final currentTrack = _musicPlayer.currentTrack;
    if (currentTrack == null) {
      // If no track is playing, play the first track
      await _playTrack(_allTracks.first);
      return;
    }

    // Find current track index in playlist
    final currentIndex =
        _allTracks.indexWhere((track) => track.id == currentTrack.id);
    if (currentIndex == -1) {
      // Current track not in playlist, play first track
      await _playTrack(_allTracks.first);
      return;
    }

    // Play next track (wrap around to beginning if at end)
    final nextIndex = (currentIndex + 1) % _allTracks.length;
    await _playTrack(_allTracks[nextIndex]);
  }

  Future<void> _seekTo(Duration position) async {
    await _musicPlayer.seek(position);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildTrackImage(MusicTrack track) {
    if (track.imagePath != null && track.imagePath!.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          track.imagePath!,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultImage();
          },
        ),
      );
    } else if (track.imagePath != null) {
      // Local file
      final file = File(track.imagePath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultImage();
            },
          ),
        );
      }
    }

    return _buildDefaultImage();
  }

  Widget _buildDefaultImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange[300]!,
            Colors.pink[300]!,
          ],
        ),
      ),
      child: Icon(
        Icons.music_note,
        size: 40,
        color: Colors.blue[900],
      ),
    );
  }

  /// Build circular image for current track (for center of audio visualizer)
  Widget _buildCurrentTrackImage() {
    final currentTrack = _musicPlayer.currentTrack;

    // If no track or no image, show default circular image
    if (currentTrack == null ||
        currentTrack.imagePath == null ||
        currentTrack.imagePath!.isEmpty) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange[200]!,
              Colors.pink[200]!,
            ],
          ),
        ),
        child: Icon(
          Icons.music_note,
          size: 60,
          color: Colors.blue[900],
        ),
      );
    }

    // Build circular image from track's image path
    if (currentTrack.imagePath!.startsWith('assets/')) {
      // Asset image
      return ClipOval(
        child: Image.asset(
          currentTrack.imagePath!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultCircularImage();
          },
        ),
      );
    } else {
      // Local file
      final file = File(currentTrack.imagePath!);
      if (file.existsSync()) {
        return ClipOval(
          child: Image.file(
            file,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultCircularImage();
            },
          ),
        );
      } else {
        return _buildDefaultCircularImage();
      }
    }
  }

  /// Build default circular image (fallback)
  Widget _buildDefaultCircularImage() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange[200]!,
            Colors.pink[200]!,
          ],
        ),
      ),
      child: Icon(
        Icons.music_note,
        size: 60,
        color: Colors.blue[900],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTrack = _musicPlayer.currentTrack;
    final currentTrackTitle = currentTrack?.name ?? 'Chưa có nhạc đang phát';
    final position = _musicPlayer.position;
    final duration = _musicPlayer.duration;

    return Scaffold(
      backgroundColor: Colors.amber[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Hướng dẫn Thiền',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Track Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                currentTrackTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Audio Visualizer
            Center(
              child: _buildAudioVisualizer(),
            ),
            const SizedBox(height: 40),
            // Playback Controls
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlButton(
                    Icons.skip_previous,
                    onPressed:
                        _allTracks.isNotEmpty ? _playPreviousTrack : null,
                  ),
                  const SizedBox(width: 20),
                  _buildPlayPauseButton(),
                  const SizedBox(width: 20),
                  _buildControlButton(
                    Icons.skip_next,
                    onPressed: _allTracks.isNotEmpty ? _playNextTrack : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.blue[700],
                      inactiveTrackColor: Colors.grey[300],
                      thumbColor: Colors.white,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: duration.inSeconds > 0
                          ? position.inSeconds.toDouble()
                          : 0.0,
                      min: 0,
                      max: duration.inSeconds > 0
                          ? duration.inSeconds.toDouble()
                          : 100.0,
                      onChanged: (value) {
                        _seekTo(Duration(seconds: value.toInt()));
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        duration.inSeconds > 0
                            ? '-${_formatDuration(Duration(seconds: duration.inSeconds - position.inSeconds))}'
                            : '--:--',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Suggestions Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Gợi ý',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Suggestion Cards
            if (_isLoadingTracks)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_suggestedTracks.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: Text(
                    'Chưa có nhạc gợi ý',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              )
            else
              ..._suggestedTracks.map((track) => _buildSuggestionCard(track)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioVisualizer() {
    return AnimatedBuilder(
      animation: _waveformController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left waveform
            _buildWaveform(isLeft: true),
            const SizedBox(width: 20),
            // Center track image (circular)
            _buildCurrentTrackImage(),
            const SizedBox(width: 20),
            // Right waveform
            _buildWaveform(isLeft: false),
          ],
        );
      },
    );
  }

  Widget _buildWaveform({required bool isLeft}) {
    final bars = List.generate(8, (index) {
      final delay = index * 0.1;
      final animationValue = (_waveformController.value + delay) % 1.0;
      final height = _musicPlayer.isPlaying ? 20 + (animationValue * 40) : 20.0;

      return Container(
        width: 4,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.blue[900],
          borderRadius: BorderRadius.circular(2),
        ),
      );
    });

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: bars,
    );
  }

  Widget _buildControlButton(IconData icon, {VoidCallback? onPressed}) {
    final isEnabled = onPressed != null;
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isEnabled ? Colors.blue[700] : Colors.grey[400],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.blue[700],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          _musicPlayer.isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 32,
        ),
        onPressed: _togglePlayPause,
      ),
    );
  }

  Widget _buildSuggestionCard(MusicTrack track) {
    final isCurrentTrack = _musicPlayer.currentTrack?.id == track.id;

    return GestureDetector(
      onTap: () => _playTrack(track),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isCurrentTrack
              ? Border.all(color: Colors.blue[700]!, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            _buildTrackImage(track),
            const SizedBox(width: 16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.description.isNotEmpty
                        ? track.description
                        : track.category,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Play icon
            Icon(
              isCurrentTrack
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_fill,
              color: Colors.blue[700],
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}
