import 'dart:io';
import 'package:flutter/material.dart';
import '../models/music_track.dart';

class MusicControlHome extends StatelessWidget {
  final String musicTitle;
  final String musicSubtitle;
  final bool isPlaying;
  final double volume;
  final VoidCallback? onPlayPause;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<double>? onVolumeChanged;
  final VoidCallback? onTap;
  final MusicTrack? currentTrack; // Track để lấy ảnh

  const MusicControlHome({
    super.key,
    required this.musicTitle,
    this.musicSubtitle = '',
    this.isPlaying = false,
    this.volume = 0.5,
    this.onPlayPause,
    this.onPrevious,
    this.onNext,
    this.onVolumeChanged,
    this.onTap,
    this.currentTrack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
      ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title "Music" at the top
          const Text(
            'Music',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // Player section with album art, info, and controls
          Row(
            children: [
              // Album art - tappable
              GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 80,
                  height: 80,
            decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
            ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildTrackImage(),
                  ),
            ),
          ),
              const SizedBox(width: 16),
              // Music info - tappable
          Expanded(
                child: GestureDetector(
                  onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                      const Text(
                  'Music',
                  style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                        musicSubtitle.isNotEmpty 
                            ? '$musicTitle $musicSubtitle'
                            : musicTitle,
                    style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                    ),
                  ),
                ],
                  ),
            ),
          ),
              // Playback controls - not tappable (use their own onPressed)
          IconButton(
            icon: const Icon(Icons.skip_previous),
            onPressed: onPrevious,
            color: Colors.grey[700],
                iconSize: 28,
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.purple[600],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: onPlayPause,
              color: Colors.white,
                  iconSize: 28,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            onPressed: onNext,
            color: Colors.grey[700],
                iconSize: 28,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Volume control section
          Row(
            children: [
              // Low volume icon
              Icon(
                Icons.volume_down,
                size: 20,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 12),
              // Volume slider
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.blue[400],
                    inactiveTrackColor: Colors.grey[300],
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    trackHeight: 4,
                  ),
                  child: _VolumeSlider(
                    value: volume,
                    onChanged: onVolumeChanged,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // High volume icon
              Icon(
                Icons.volume_up,
                size: 24,
                color: Colors.grey[600],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackImage() {
    // If we have a track with imagePath, use it
    if (currentTrack != null && currentTrack!.imagePath != null && currentTrack!.imagePath!.isNotEmpty) {
      final imagePath = currentTrack!.imagePath!;
      
      // Check if it's an asset path (starts with "assets/")
      if (imagePath.startsWith('assets/')) {
        return Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultImage(currentTrack!.category);
          },
        );
      } 
      // Check if it's a URL
      else if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        return Image.network(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultImage(currentTrack!.category);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        );
      } 
      // Local file (user uploaded)
      else {
        if (File(imagePath).existsSync()) {
          return Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultImage(currentTrack!.category);
            },
          );
        }
      }
    }
    
    // Default image based on category from subtitle or track
    String category = 'Thiền'; // default
    if (currentTrack != null) {
      category = currentTrack!.category;
    } else if (musicSubtitle.toLowerCase().contains('thiên nhiên') || 
               musicTitle.toLowerCase().contains('thiên nhiên')) {
      category = 'Thiên nhiên';
    } else if (musicSubtitle.toLowerCase().contains('piano') || 
               musicTitle.toLowerCase().contains('piano')) {
      category = 'Nhạc Piano';
    } else if (musicSubtitle.toLowerCase().contains('ambient') || 
               musicTitle.toLowerCase().contains('ambient')) {
      category = 'Ambient';
    }
    
    return _buildDefaultImage(category);
  }

  Widget _buildDefaultImage(String category) {
    switch (category) {
      case 'Thiên nhiên':
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green[400]!, Colors.green[600]!],
            ),
          ),
          child: const Icon(Icons.nature, color: Colors.white, size: 40),
        );
      case 'Nhạc Piano':
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.brown[400]!, Colors.brown[600]!],
            ),
          ),
          child: const Icon(Icons.piano, color: Colors.white, size: 40),
        );
      case 'Thiền':
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.orange[300]!, Colors.pink[300]!],
            ),
          ),
          child: const Icon(
            Icons.self_improvement,
            color: Colors.white,
            size: 40,
          ),
        );
      case 'Ambient':
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.purple[300]!, Colors.blue[300]!],
            ),
          ),
          child: const Icon(Icons.music_note, color: Colors.white, size: 40),
        );
      default:
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[800],
          ),
          child: const Icon(Icons.music_note, color: Colors.white, size: 40),
        );
    }
  }
}

/// Custom volume slider widget for smoother volume adjustment
class _VolumeSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double>? onChanged;

  const _VolumeSlider({
    required this.value,
    this.onChanged,
  });

  @override
  State<_VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<_VolumeSlider> {
  double? _dragValue;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final displayValue = _isDragging ? (_dragValue ?? widget.value) : widget.value;

    return Slider(
      value: displayValue.clamp(0.0, 1.0),
      onChanged: (value) {
        setState(() {
          _dragValue = value;
          _isDragging = true;
        });
        // Update volume immediately while dragging (silent update)
        widget.onChanged?.call(value);
      },
      onChangeStart: (value) {
        setState(() {
          _dragValue = value;
          _isDragging = true;
        });
      },
      onChangeEnd: (value) {
        setState(() {
          _isDragging = false;
          _dragValue = null;
        });
        // Final update when dragging ends
        widget.onChanged?.call(value);
      },
      min: 0.0,
      max: 1.0,
    );
  }
}

