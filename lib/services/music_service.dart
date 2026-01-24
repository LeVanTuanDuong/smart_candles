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
      'Nature_Ocean_Waves.mp3': 'Thiên nhiên',
      'Nature_Tieng_mua_trong_rung.mp3': 'Thiên nhiên',
      'Piano_Relaxing.mp3': 'Nhạc Piano',
      'Piano_Peaceful.mp3': 'Nhạc Piano',
      'Meditation_tinh_tam.mp3': 'Thiền',
      'Meditation_Vo_uu.mp3': 'Thiền',
      'Meditation_Music.mp3': 'Thiền',
      'Ambient_Calm.mp3': 'Ambient',
      'Ambient_Space.mp3': 'Ambient',
    };
  }

  // Map audio file names to image file names
  static Map<String, String> _getAudioToImageMapping() {
    return {
      'Nature_Ocean_Waves.mp3': 'Alaskan Lake.jpg',
      'Nature_Tieng_mua_trong_rung.mp3': 'Amazon Rainforest.jpg',
      'Piano_Relaxing.mp3': 'Alaskan Dawn.jpg',
      'Piano_Peaceful.mp3': 'Autumn Forest.jpg',
      'Meditation_tinh_tam.mp3': 'Cloudforest Africa.jpg',
      'Meditation_Vo_uu.mp3': 'Alpine Cow Bells.jpg',
      'Meditation_Music.mp3': 'Ambient India.jpg',
      'Ambient_Calm.mp3': 'Evening Marsh.jpg',
      'Ambient_Space.mp3': 'Desert Evening.jpg',
    };
  }

  // Map audio file names to descriptions
  static Map<String, String> _getAudioDescriptions() {
    return {
      'Nature_Ocean_Waves.mp3': 'Sóng biển êm đềm',
      'Nature_Tieng_mua_trong_rung.mp3': 'Âm thanh mưa thư giãn',
      'Piano_Relaxing.mp3': 'Nhạc piano nhẹ nhàng',
      'Piano_Peaceful.mp3': 'Piano thanh bình',
      'Meditation_tinh_tam.mp3': 'Nhạc thiền định tâm',
      'Meditation_Vo_uu.mp3': 'Nhạc thiền vô ưu',
      'Meditation_Music.mp3': 'Nhạc thiền sâu lắng',
      'Ambient_Calm.mp3': 'Nhạc ambient nhẹ nhàng',
      'Ambient_Space.mp3': 'Nhạc ambient không gian',
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
        final imagePath =
            imageFileName.isNotEmpty ? 'assets/images/$imageFileName' : null;

        // Get description
        final description = audioDescriptions[audioFile] ?? '';

        // Create track with asset path
        tracks.add(MusicTrack(
          id: 'asset_${audioFile.hashCode}',
          name: trackName,
          description:
              description.isNotEmpty ? description : 'Nhạc từ thư viện',
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
