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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Album art placeholder
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.music_note,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          // Music info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Music',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  musicTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (musicSubtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    musicSubtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Playback controls
          IconButton(
            icon: const Icon(Icons.skip_previous),
            onPressed: onPrevious,
            color: Colors.grey[700],
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
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            onPressed: onNext,
            color: Colors.grey[700],
          ),
        ],
      ),
    );
  }
}

