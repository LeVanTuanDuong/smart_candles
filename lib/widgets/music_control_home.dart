import 'package:flutter/material.dart';

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
              // Album art placeholder - tappable
              GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.piano,
                    color: Colors.white,
                    size: 40,
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
                  child: Slider(
                    value: volume,
                    onChanged: onVolumeChanged,
                    min: 0.0,
                    max: 1.0,
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
}

