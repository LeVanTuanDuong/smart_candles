import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
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
      print('Error getting SharedPreferences: $e');
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        _prefs = await SharedPreferences.getInstance();
        return _prefs;
      } catch (e2) {
        print('Error getting SharedPreferences on retry: $e2');
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
      'Meditation music',
    ];
  }

  // Get default tracks for each category (mock data for now)
  static List<MusicTrack> getDefaultTracksForCategory(String category) {
    switch (category) {
      case 'Thiên nhiên':
        return [
          MusicTrack(
            id: 'nature_1',
            name: 'Thiên nhiên',
            description: 'Âm thanh thiên nhiên thư giãn',
            category: category,
            isUploaded: false,
          ),
        ];
      case 'Nhạc Piano':
        return [
          MusicTrack(
            id: 'piano_1',
            name: 'Nhạc Piano',
            description: 'Nhạc piano nhẹ nhàng',
            category: category,
            isUploaded: false,
          ),
        ];
      case 'Thiền':
        return [
          MusicTrack(
            id: 'meditation_1',
            name: 'Thiền',
            description: 'Nhạc thiền định tâm',
            category: category,
            isUploaded: false,
          ),
        ];
      default:
        return [];
    }
  }

  // Fetch tracks from Openwhyd API
  static Future<List<MusicTrack>> fetchTracksFromOpenwhyd(String category) async {
    try {
      // Map category to genre for Openwhyd API
      String? genre = _mapCategoryToGenre(category);
      
      // Build Openwhyd API URL with format=json
      String apiUrl = 'https://openwhyd.org/hot';
      if (genre != null) {
        apiUrl = 'https://openwhyd.org/hot/$genre';
      }
      apiUrl += '?format=json';
      
      print('Fetching from Openwhyd: $apiUrl');
      final url = Uri.parse(apiUrl);
      
      // Try to fetch from Openwhyd API
      final response = await http.get(url).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('Openwhyd API response status: ${response.statusCode}');
      print('Openwhyd API response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        try {
          // Parse JSON response
          final dynamic jsonData = jsonDecode(response.body);
          
          // Openwhyd API returns different structures, handle both
          List<dynamic> data = [];
          
          if (jsonData is List) {
            data = jsonData;
          } else if (jsonData is Map) {
            // Check for common keys that contain track arrays
            if (jsonData['tracks'] != null) {
              data = jsonData['tracks'] as List;
            } else if (jsonData['posts'] != null) {
              data = jsonData['posts'] as List;
            } else if (jsonData['data'] != null) {
              data = jsonData['data'] as List;
            } else {
              // Try to find any array in the response
              jsonData.forEach((key, value) {
                if (value is List && data.isEmpty) {
                  data = value;
                }
              });
            }
          }
          
          print('Parsed ${data.length} tracks from Openwhyd');

          if (data.isEmpty) {
            print('No tracks found, using default tracks');
            return getDefaultTracksForCategory(category);
          }

          // Parse Openwhyd tracks
          List<MusicTrack> tracks = [];
          int count = 0;
          
          for (var item in data) {
            if (count >= 10) break; // Limit to 10 tracks per category
            
            try {
              final track = _parseOpenwhydTrack(item, category);
              if (track != null && track.audioUrl != null && track.audioUrl!.isNotEmpty) {
                tracks.add(track);
                count++;
                print('Added track: ${track.name}');
              }
            } catch (e) {
              print('Error parsing track: $e');
              continue;
            }
          }
          
          print('Successfully parsed ${tracks.length} tracks');
          return tracks.isNotEmpty ? tracks : getDefaultTracksForCategory(category);
        } catch (e) {
          print('Error parsing Openwhyd response: $e');
          print('Response body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
          return getDefaultTracksForCategory(category);
        }
      } else {
        print('Openwhyd API returned status code: ${response.statusCode}');
        print('Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        return getDefaultTracksForCategory(category);
      }
    } catch (e) {
      print('Error fetching tracks from Openwhyd: $e');
      return getDefaultTracksForCategory(category);
    }
  }

  // Map category to Openwhyd genre
  static String? _mapCategoryToGenre(String category) {
    switch (category) {
      case 'Thiên nhiên':
        return 'nature';
      case 'Nhạc Piano':
        return 'piano';
      case 'Thiền':
        return 'meditation';
      case 'Ambient':
        return 'ambient';
      case 'Meditation music':
        return 'meditation';
      default:
        return null; // Use general /hot endpoint
    }
  }

  // Parse Openwhyd track data
  static MusicTrack? _parseOpenwhydTrack(dynamic item, String category) {
    try {
      // Openwhyd track structure - check common field names
      String id = item['_id']?.toString() ?? 
                  item['id']?.toString() ?? 
                  item['postId']?.toString() ??
                  DateTime.now().millisecondsSinceEpoch.toString();
      
      // Extract track name/title
      String name = item['name']?.toString() ?? 
                    item['title']?.toString() ?? 
                    item['track']?.toString() ??
                    item['trackName']?.toString() ??
                    item['name']?.toString() ??
                    'Unknown Track';
      
      // Extract description
      String description = item['description']?.toString() ?? 
                          item['text']?.toString() ?? 
                          item['msg']?.toString() ??
                          '';
      
      // Extract audio URL - Openwhyd uses eId format
      String? audioUrl;
      
      // Method 1: Check for eId (Openwhyd format)
      if (item['eId'] != null) {
        String eId = item['eId'].toString();
        // Openwhyd play URL format: https://openwhyd.org/<eId>
        audioUrl = 'https://openwhyd.org/$eId';
      }
      
      // Method 2: Check for direct URL fields
      if (audioUrl == null || audioUrl.isEmpty) {
        audioUrl = item['url']?.toString() ?? 
                   item['src']?.toString() ??
                   item['streamUrl']?.toString() ??
                   item['audioUrl']?.toString();
      }
      
      // Method 3: Check for track object with URL
      if ((audioUrl == null || audioUrl.isEmpty) && item['track'] != null) {
        final track = item['track'];
        if (track is Map) {
          audioUrl = track['url']?.toString() ?? 
                     track['src']?.toString() ??
                     track['streamUrl']?.toString();
        }
      }
      
      // Extract image URL
      String? imageUrl;
      if (item['img'] != null) {
        imageUrl = item['img'].toString();
      } else if (item['image'] != null) {
        imageUrl = item['image'].toString();
      } else if (item['thumbnail'] != null) {
        imageUrl = item['thumbnail'].toString();
      } else if (item['cover'] != null) {
        imageUrl = item['cover'].toString();
      } else if (item['track'] != null && item['track'] is Map) {
        final track = item['track'];
        imageUrl = track['img']?.toString() ?? 
                   track['image']?.toString() ??
                   track['thumbnail']?.toString();
      }
      
      // If no audio URL found, skip this track
      if (audioUrl == null || audioUrl.isEmpty) {
        print('No audio URL found for track: $name');
        return null;
      }
      
      return MusicTrack(
        id: id,
        name: name,
        description: description.isNotEmpty ? description : 'Nhạc từ Openwhyd',
        audioUrl: audioUrl,
        imagePath: imageUrl, // Store image URL in imagePath for now
        category: category,
        isUploaded: false,
      );
    } catch (e) {
      print('Error parsing Openwhyd track: $e');
      if (item is Map) {
        print('Item keys: ${item.keys.toList()}');
      } else {
        print('Item is not a map');
      }
      return null;
    }
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
      print('Error loading uploaded tracks: $e');
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
      print('Error saving uploaded tracks: $e');
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

  // Get all tracks grouped by category
  static Future<Map<String, List<MusicTrack>>> getAllTracksByCategory() async {
    final uploadedTracks = await loadUploadedTracks();
    final categories = getDefaultCategories();
    final Map<String, List<MusicTrack>> tracksByCategory = {};

    // Initialize categories
    for (var category in categories) {
      tracksByCategory[category] = [];
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

    // Fetch and add API tracks for each category
    for (var category in categories) {
      final apiTracks = await fetchTracksFromOpenwhyd(category);
      tracksByCategory[category]!.addAll(apiTracks);
    }

    return tracksByCategory;
  }
}

