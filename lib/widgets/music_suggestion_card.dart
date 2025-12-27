import 'dart:io';
import 'package:flutter/material.dart';
import '../screens/music_library_screen.dart';
import '../models/music_track.dart';

class MusicSuggestionCard extends StatelessWidget {
  final String? musicType; // Fallback if no track
  final MusicTrack? suggestedTrack; // Actual track from library
  final VoidCallback? onPlayPressed;

  const MusicSuggestionCard({
    super.key,
    this.musicType,
    this.suggestedTrack,
    this.onPlayPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const MusicLibraryScreen(),
          ),
        );
      },
      child: Container(
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
      child: Row(
        children: [
          // Track image or default icon
          Container(
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
          const SizedBox(width: 16),
          // Text content and button
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gợi ý nhạc:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  suggestedTrack?.name ?? musicType ?? 'Nhạc thư giãn',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (suggestedTrack?.description != null && suggestedTrack!.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    suggestedTrack!.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onPlayPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[300],
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Bật ngay',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildTrackImage() {
    // If we have a track with imagePath, use it
    if (suggestedTrack != null && suggestedTrack!.imagePath != null && suggestedTrack!.imagePath!.isNotEmpty) {
      final imagePath = suggestedTrack!.imagePath!;
      
      // Check if it's an asset path (starts with "assets/")
      if (imagePath.startsWith('assets/')) {
        return Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultImage(suggestedTrack!.category);
          },
        );
      } 
      // Check if it's a URL
      else if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        return Image.network(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultImage(suggestedTrack!.category);
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
              return _buildDefaultImage(suggestedTrack!.category);
            },
          );
        }
      }
    }
    
    // Default image based on category from track or musicType
    String category = 'Thiền'; // default
    if (suggestedTrack != null) {
      category = suggestedTrack!.category;
    } else if (musicType != null) {
      final lowerType = musicType!.toLowerCase();
      if (lowerType.contains('thiên nhiên') || lowerType.contains('nature')) {
        category = 'Thiên nhiên';
      } else if (lowerType.contains('piano')) {
        category = 'Nhạc Piano';
      } else if (lowerType.contains('ambient')) {
        category = 'Ambient';
      }
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

