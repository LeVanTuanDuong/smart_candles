import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/music_track.dart';

class MusicService {
  static const String _uploadedTracksKey = 'uploaded_music_tracks';
  static SharedPreferences? _prefs;

  // Get SharedPreferences instance
  static Future<SharedPreferences?> _getPreferences() async {
    if (_prefs != null) return _prefs;
    
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      _prefs = await SharedPreferences.getInstance();
      return _prefs;
    } catch (e) {
      // Retry once if SharedPreferences fails
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        _prefs = await SharedPreferences.getInstance();
        return _prefs;
      } catch (e2) {
        return null;
      }
    }
  }

  // Get default music categories
  static List<String> getDefaultCategories() {
    return [
      'Thiên nhiên',
      'Nhạc Piano',
      'Thiền',
      'Ambient',
    ];
  }

  // Map audio file names to categories
  static Map<String, String> _getAudioFileCategories() {
    return {
      'Thiên nhiên - Ocean Waves.mp3': 'Thiên nhiên',
      'Thiên nhiên - Tiếng mưa trong rừng.mp3': 'Thiên nhiên',
      'Nhạc Piano - Relaxing.mp3': 'Nhạc Piano',
      'Nhạc Piano - Peaceful.mp3': 'Nhạc Piano',
      'Nhạc thiền tịnh tâm.mp3': 'Thiền',
      'Nhạc Thiền Vô Ưu.mp3': 'Thiền',
      'Meditation Music.mp3': 'Thiền',
      'Ambient - Calm.mp3': 'Ambient',
      'Ambient - Space.mp3': 'Ambient',
    };
  }

  // Map audio file names to image file names
  static Map<String, String> _getAudioToImageMapping() {
    return {
      'Thiên nhiên - Ocean Waves.mp3': 'Alaskan Lake.jpg',
      'Thiên nhiên - Tiếng mưa trong rừng.mp3': 'Amazon Rainforest.jpg',
      'Nhạc Piano - Relaxing.mp3': 'Alaskan Dawn.jpg',
      'Nhạc Piano - Peaceful.mp3': 'Autumn Forest.jpg',
      'Nhạc thiền tịnh tâm.mp3': 'Cloudforest Africa.jpg',
      'Nhạc Thiền Vô Ưu.mp3': 'Alpine Cow Bells.jpg',
      'Meditation Music.mp3': 'Ambient India.jpg',
      'Ambient - Calm.mp3': 'Evening Marsh.jpg',
      'Ambient - Space.mp3': 'Desert Evening.jpg',
    };
  }

  // Map audio file names to descriptions
  static Map<String, String> _getAudioDescriptions() {
    return {
      'Thiên nhiên - Ocean Waves.mp3': 'Sóng biển êm đềm',
      'Thiên nhiên - Tiếng mưa trong rừng.mp3': 'Âm thanh mưa thư giãn',
      'Nhạc Piano - Relaxing.mp3': 'Nhạc piano nhẹ nhàng',
      'Nhạc Piano - Peaceful.mp3': 'Piano thanh bình',
      'Nhạc thiền tịnh tâm.mp3': 'Nhạc thiền định tâm',
      'Nhạc Thiền Vô Ưu.mp3': 'Nhạc thiền vô ưu',
      'Meditation Music.mp3': 'Nhạc thiền sâu lắng',
      'Ambient - Calm.mp3': 'Nhạc ambient nhẹ nhàng',
      'Ambient - Space.mp3': 'Nhạc ambient không gian',
    };
  }

  // Get default tracks for each category (from assets/sounds/)
  static List<MusicTrack> getDefaultTracksForCategory(String category) {
    final audioCategories = _getAudioFileCategories();
    final audioToImage = _getAudioToImageMapping();
    final audioDescriptions = _getAudioDescriptions();

    // Find all audio files for this category
    final List<MusicTrack> tracks = [];
    
    audioCategories.forEach((audioFile, audioCategory) {
      if (audioCategory == category) {
        // Extract track name from file name (remove .mp3 extension)
        String trackName = audioFile.replaceAll('.mp3', '');
        
        // Get image file name
        final imageFileName = audioToImage[audioFile] ?? '';
        final imagePath = imageFileName.isNotEmpty 
            ? 'assets/images/$imageFileName'
            : null;
        
        // Get description
        final description = audioDescriptions[audioFile] ?? '';
        
        // Create track with asset path
        tracks.add(MusicTrack(
          id: 'asset_${audioFile.hashCode}',
          name: trackName,
          description: description.isNotEmpty ? description : 'Nhạc từ thư viện',
          category: category,
          audioPath: 'assets/sounds/$audioFile', // Use asset path, not URL
          imagePath: imagePath,
          isUploaded: false,
        ));
      }
    });

    return tracks;
  }

  // Load uploaded tracks from storage
  static Future<List<MusicTrack>> loadUploadedTracks() async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return [];

      final jsonString = prefs.getString(_uploadedTracksKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> tracksList = jsonDecode(jsonString);
      return tracksList.map((item) => MusicTrack.fromMap(item)).toList();
    } catch (e) {
      // Removed print statement: 'Error loading uploaded tracks: $e');
      return [];
    }
  }

  // Save uploaded tracks to storage
  static Future<void> saveUploadedTracks(List<MusicTrack> tracks) async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return;

      final tracksList = tracks.map((track) => track.toMap()).toList();
      final jsonString = jsonEncode(tracksList);
      await prefs.setString(_uploadedTracksKey, jsonString);
    } catch (e) {
      // Removed print statement: 'Error saving uploaded tracks: $e');
    }
  }

  // Add uploaded track
  static Future<void> addUploadedTrack(MusicTrack track) async {
    final tracks = await loadUploadedTracks();
    tracks.add(track);
    await saveUploadedTracks(tracks);
  }

  // Update uploaded track
  static Future<void> updateUploadedTrack(MusicTrack updatedTrack) async {
    final tracks = await loadUploadedTracks();
    final index = tracks.indexWhere((track) => track.id == updatedTrack.id);
    if (index >= 0) {
      tracks[index] = updatedTrack;
      await saveUploadedTracks(tracks);
    }
  }

  // Delete uploaded track
  static Future<void> deleteUploadedTrack(String trackId) async {
    final tracks = await loadUploadedTracks();
    tracks.removeWhere((track) => track.id == trackId);
    await saveUploadedTracks(tracks);
  }

  // Get all tracks grouped by category (only from assets, no API)
  static Future<Map<String, List<MusicTrack>>> getAllTracksByCategory() async {
    final uploadedTracks = await loadUploadedTracks();
    final categories = getDefaultCategories();
    final Map<String, List<MusicTrack>> tracksByCategory = {};

    // Initialize categories with asset tracks
    for (var category in categories) {
      tracksByCategory[category] = getDefaultTracksForCategory(category);
    }

    // Add uploaded tracks to their categories
    for (var track in uploadedTracks) {
      if (tracksByCategory.containsKey(track.category)) {
        tracksByCategory[track.category]!.add(track);
      } else {
        // Create new category if doesn't exist
        tracksByCategory[track.category] = [track];
      }
    }

    return tracksByCategory;
  }
}
