import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_candles/features/music/models/music_track.dart';

class MusicService {
  static const String _uploadedTracksKey = 'uploaded_music_tracks';
  static SharedPreferences? _prefs;

  static Future<SharedPreferences?> _getPreferences() async {
    if (_prefs != null) return _prefs;
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      _prefs = await SharedPreferences.getInstance();
      return _prefs;
    } catch (e) {
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        _prefs = await SharedPreferences.getInstance();
        return _prefs;
      } catch (e2) {
        return null;
      }
    }
  }

  static List<String> getDefaultCategories() {
    return ['Thiên nhiên', 'Nhạc Piano', 'Thiền', 'Ambient'];
  }

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

  static List<MusicTrack> getDefaultTracksForCategory(String category) {
    final audioCategories = _getAudioFileCategories();
    final audioToImage = _getAudioToImageMapping();
    final audioDescriptions = _getAudioDescriptions();
    final List<MusicTrack> tracks = [];
    audioCategories.forEach((audioFile, audioCategory) {
      if (audioCategory == category) {
        String trackName = audioFile.replaceAll('.mp3', '');
        final imageFileName = audioToImage[audioFile] ?? '';
        final imagePath =
            imageFileName.isNotEmpty ? 'assets/images/$imageFileName' : null;
        final description = audioDescriptions[audioFile] ?? '';
        tracks.add(MusicTrack(
          id: 'asset_${audioFile.hashCode}',
          name: trackName,
          description:
              description.isNotEmpty ? description : 'Nhạc từ thư viện',
          category: category,
          audioPath: 'assets/sounds/$audioFile',
          imagePath: imagePath,
          isUploaded: false,
        ));
      }
    });
    return tracks;
  }

  static Future<List<MusicTrack>> loadUploadedTracks() async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return [];
      final jsonString = prefs.getString(_uploadedTracksKey);
      if (jsonString == null || jsonString.isEmpty) return [];
      final List<dynamic> tracksList = jsonDecode(jsonString);
      return tracksList.map((item) => MusicTrack.fromMap(item)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveUploadedTracks(List<MusicTrack> tracks) async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return;
      final tracksList = tracks.map((track) => track.toMap()).toList();
      await prefs.setString(_uploadedTracksKey, jsonEncode(tracksList));
    } catch (e) {}
  }

  static Future<void> addUploadedTrack(MusicTrack track) async {
    final tracks = await loadUploadedTracks();
    tracks.add(track);
    await saveUploadedTracks(tracks);
  }

  static Future<void> updateUploadedTrack(MusicTrack updatedTrack) async {
    final tracks = await loadUploadedTracks();
    final index = tracks.indexWhere((track) => track.id == updatedTrack.id);
    if (index >= 0) {
      tracks[index] = updatedTrack;
      await saveUploadedTracks(tracks);
    }
  }

  static Future<void> deleteUploadedTrack(String trackId) async {
    final tracks = await loadUploadedTracks();
    tracks.removeWhere((track) => track.id == trackId);
    await saveUploadedTracks(tracks);
  }

  static Future<Map<String, List<MusicTrack>>> getAllTracksByCategory() async {
    final uploadedTracks = await loadUploadedTracks();
    final categories = getDefaultCategories();
    final Map<String, List<MusicTrack>> tracksByCategory = {};
    for (var category in categories) {
      tracksByCategory[category] = getDefaultTracksForCategory(category);
    }
    for (var track in uploadedTracks) {
      if (tracksByCategory.containsKey(track.category)) {
        tracksByCategory[track.category]!.add(track);
      } else {
        tracksByCategory[track.category] = [track];
      }
    }
    return tracksByCategory;
  }
}
