import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/music_track.dart';

class MusicService {
  static const String _uploadedTracksKey = 'uploaded_music_tracks';
  static SharedPreferences? _prefs;
  static bool _isOffline = false; // Track offline state to reduce log noise

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

  // Get default tracks for each category (with real playable MP3 URLs)
  static List<MusicTrack> getDefaultTracksForCategory(String category) {
    // Using reliable free music sources with direct MP3 stream URLs
    // These URLs are from public test audio files and free music archives
    switch (category) {
      case 'Thiên nhiên':
        return [
          MusicTrack(
            id: 'nature_1',
            name: 'Thiên nhiên - Rain Sounds',
            description: 'Âm thanh mưa thư giãn',
            category: category,
            // Using Internet Archive - free public domain audio
            audioUrl: 'https://archive.org/download/testmp3testfile/mpthreetest.mp3',
            imagePath: null,
            isUploaded: false,
          ),
          MusicTrack(
            id: 'nature_2',
            name: 'Thiên nhiên - Ocean Waves',
            description: 'Sóng biển êm đềm',
            category: category,
            // Alternative: using a test audio file
            audioUrl: 'https://www2.cs.uic.edu/~i101/SoundFiles/BabyElephantWalk60.wav',
            imagePath: null,
            isUploaded: false,
          ),
        ];
      case 'Nhạc Piano':
        return [
          MusicTrack(
            id: 'piano_1',
            name: 'Nhạc Piano - Relaxing',
            description: 'Nhạc piano nhẹ nhàng',
            category: category,
            // Using Internet Archive - free public domain music
            audioUrl: 'https://archive.org/download/testmp3testfile/mpthreetest.mp3',
            imagePath: null,
            isUploaded: false,
          ),
          MusicTrack(
            id: 'piano_2',
            name: 'Nhạc Piano - Peaceful',
            description: 'Piano thanh bình',
            category: category,
            // Using a reliable test audio URL
            audioUrl: 'https://www2.cs.uic.edu/~i101/SoundFiles/StarWars60.wav',
            imagePath: null,
            isUploaded: false,
          ),
        ];
      case 'Thiền':
        return [
          MusicTrack(
            id: 'meditation_1',
            name: 'Thiền - Meditation Music',
            description: 'Nhạc thiền định tâm',
            category: category,
            // Using Internet Archive
            audioUrl: 'https://archive.org/download/testmp3testfile/mpthreetest.mp3',
            imagePath: null,
            isUploaded: false,
          ),
          MusicTrack(
            id: 'meditation_2',
            name: 'Thiền - Zen Music',
            description: 'Nhạc thiền zen',
            category: category,
            // Alternative test audio
            audioUrl: 'https://www2.cs.uic.edu/~i101/SoundFiles/PinkPanther60.wav',
            imagePath: null,
            isUploaded: false,
          ),
        ];
      case 'Ambient':
        return [
          MusicTrack(
            id: 'ambient_1',
            name: 'Ambient - Calm',
            description: 'Nhạc ambient nhẹ nhàng',
            category: category,
            // Using Internet Archive
            audioUrl: 'https://archive.org/download/testmp3testfile/mpthreetest.mp3',
            imagePath: null,
            isUploaded: false,
          ),
          MusicTrack(
            id: 'ambient_2',
            name: 'Ambient - Space',
            description: 'Nhạc ambient không gian',
            category: category,
            // Alternative test audio
            audioUrl: 'https://www2.cs.uic.edu/~i101/SoundFiles/StarWars60.wav',
            imagePath: null,
            isUploaded: false,
          ),
        ];
      case 'Meditation music':
        return [
          MusicTrack(
            id: 'meditation_music_1',
            name: 'Meditation Music - Deep',
            description: 'Nhạc thiền sâu lắng',
            category: category,
            // Using Internet Archive
            audioUrl: 'https://archive.org/download/testmp3testfile/mpthreetest.mp3',
            imagePath: null,
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
      
      // Skip API call if we know we're offline
      if (_isOffline) {
        return getDefaultTracksForCategory(category);
      }
      
      if (!_isOffline) {
        print('Fetching from Openwhyd: $apiUrl');
      }
      final url = Uri.parse(apiUrl);
      
      // Try to fetch from Openwhyd API
      final response = await http.get(url).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (!_isOffline) {
        print('Openwhyd API response status: ${response.statusCode}');
        print('Openwhyd API response body length: ${response.body.length}');
      }

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

          // Always start with default tracks
          List<MusicTrack> tracks = getDefaultTracksForCategory(category);
          print('✅ Added ${tracks.length} default tracks for $category');

          if (data.isEmpty) {
            print('No tracks from Openwhyd, using default tracks only');
            return tracks;
          }

          // Parse Openwhyd tracks and add to default tracks
          int count = 0;
          
          for (var item in data) {
            if (count >= 10) break; // Limit to 10 additional tracks per category
            
            try {
              final track = _parseOpenwhydTrack(item, category);
              if (track != null && track.audioUrl != null && track.audioUrl!.isNotEmpty) {
                // Skip YouTube tracks as they cannot be played directly
                if (track.audioUrl!.contains('youtube.com') || 
                    track.audioUrl!.startsWith('https://openwhyd.org/yt/')) {
                  print('⏭️ Skipping YouTube track: ${track.name}');
                  continue;
                }
                tracks.add(track);
                count++;
                print('✅ Added Openwhyd track: ${track.name}');
              }
            } catch (e) {
              print('Error parsing track: $e');
              continue;
            }
          }
          
          print('✅ Total tracks for $category: ${tracks.length} (${tracks.length - count} default + $count from Openwhyd)');
          return tracks;
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
      // Check if it's a network error
      final errorStr = e.toString().toLowerCase();
      final isNetworkError = errorStr.contains('socketexception') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('network') ||
          errorStr.contains('connection') ||
          errorStr.contains('offline');
      
      if (isNetworkError) {
        if (!_isOffline) {
          // Only log once when first detecting offline
          print('⚠️ Network error - device is offline. Using default tracks only.');
          _isOffline = true;
        }
        // Don't print full error when offline to reduce log noise
      } else {
        print('Error fetching tracks from Openwhyd: $e');
      }
      
      return getDefaultTracksForCategory(category);
    }
  }

  // Get stream URL from Openwhyd post ID or eId (public method)
  static Future<String?> getOpenwhydStreamUrl(String identifier) async {
    try {
      print('🔵 Getting stream URL for Openwhyd identifier: $identifier');
      
      // Clean identifier - remove leading/trailing slashes
      String cleanId = identifier.trim();
      if (cleanId.startsWith('/')) {
        cleanId = cleanId.substring(1);
      }
      if (cleanId.endsWith('/')) {
        cleanId = cleanId.substring(0, cleanId.length - 1);
      }
      
      // Check if it's a YouTube track (format: yt/VIDEO_ID)
      if (cleanId.startsWith('yt/')) {
        final youtubeId = cleanId.replaceFirst('yt/', '');
        print('📺 Detected YouTube track, video ID: $youtubeId');
        
        // Try multiple methods to get stream URL
        
        // Method 1: Try Openwhyd API with format=links
        try {
          final linksUrl = 'https://openwhyd.org/$cleanId?format=links';
          print('🔗 Trying format=links: $linksUrl');
          final linksResponse = await http.get(Uri.parse(linksUrl)).timeout(
            const Duration(seconds: 10),
          );
          
          if (linksResponse.statusCode == 200) {
            try {
              final linksData = jsonDecode(linksResponse.body);
              if (linksData is Map) {
                String? streamUrl = linksData['url']?.toString() ?? 
                                   linksData['src']?.toString() ??
                                   linksData['streamUrl']?.toString();
                if (streamUrl != null && streamUrl.isNotEmpty &&
                    (streamUrl.startsWith('http://') || streamUrl.startsWith('https://'))) {
                  print('✅ Found stream URL from format=links: $streamUrl');
                  return streamUrl;
                }
              } else if (linksData is List && linksData.isNotEmpty) {
                String? streamUrl = linksData[0]?.toString();
                if (streamUrl != null && streamUrl.isNotEmpty &&
                    (streamUrl.startsWith('http://') || streamUrl.startsWith('https://'))) {
                  print('✅ Found stream URL from format=links list: $streamUrl');
                  return streamUrl;
                }
              }
            } catch (e) {
              print('⚠️ Error parsing format=links response: $e');
            }
          }
        } catch (e) {
          print('⚠️ Error fetching format=links: $e');
        }
        
        // Method 2: Try Openwhyd API with format=json to get track details
        try {
          String apiUrl = 'https://openwhyd.org/$cleanId?format=json';
          print('🔗 Trying format=json: $apiUrl');
          final response = await http.get(Uri.parse(apiUrl)).timeout(
            const Duration(seconds: 10),
          );
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data is Map) {
              // Look for URL in various fields
              String? streamUrl = data['url']?.toString() ?? 
                                 data['src']?.toString() ??
                                 data['streamUrl']?.toString();
              
              if (data['track'] != null && data['track'] is Map) {
                final track = data['track'] as Map;
                streamUrl ??= track['url']?.toString() ?? 
                            track['src']?.toString() ??
                            track['streamUrl']?.toString();
              }
              
              // Also check for YouTube embed URL
              if (data['embedUrl'] != null) {
                streamUrl ??= data['embedUrl'].toString();
              }
              
              if (streamUrl != null && streamUrl.isNotEmpty &&
                  (streamUrl.startsWith('http://') || streamUrl.startsWith('https://'))) {
                print('✅ Found stream URL from format=json: $streamUrl');
                return streamUrl;
              }
              
              // Print full response for debugging
              print('📋 Full response keys: ${data.keys.toList()}');
            }
          } else {
            print('⚠️ format=json returned status ${response.statusCode}');
          }
        } catch (e) {
          print('⚠️ Error fetching format=json: $e');
        }
        
        // Method 3: Try YouTube stream extractor service
        final youtubeStreamUrl = await _getYouTubeStreamUrl(youtubeId);
        if (youtubeStreamUrl != null) {
          print('✅ Using YouTube stream URL: $youtubeStreamUrl');
          return youtubeStreamUrl;
        }
        
        // If all else fails, return null (track cannot be played)
        print('❌ Cannot get stream URL for YouTube track: $youtubeId');
        return null;
      }
      
      // Try method 1: Get track details with format=json
      String apiUrl = 'https://openwhyd.org/c/$cleanId?format=json';
      try {
        final response = await http.get(Uri.parse(apiUrl)).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Request timeout');
          },
        );

        if (response.statusCode == 200) {
          try {
            final data = jsonDecode(response.body);
            // Try to extract stream URL from response
            if (data is Map) {
              // Check for direct URL fields
              String? streamUrl = data['url']?.toString() ?? 
                                 data['src']?.toString() ??
                                 data['streamUrl']?.toString() ??
                                 data['stream']?.toString();
              
              if (streamUrl != null && streamUrl.isNotEmpty && 
                  (streamUrl.startsWith('http://') || streamUrl.startsWith('https://'))) {
                print('✅ Found stream URL: $streamUrl');
                return streamUrl;
              }
              
              // Check for track object
              if (data['track'] != null && data['track'] is Map) {
                final track = data['track'] as Map;
                streamUrl = track['url']?.toString() ?? 
                           track['src']?.toString() ??
                           track['streamUrl']?.toString() ??
                           track['stream']?.toString();
                if (streamUrl != null && streamUrl.isNotEmpty &&
                    (streamUrl.startsWith('http://') || streamUrl.startsWith('https://'))) {
                  print('✅ Found stream URL in track object: $streamUrl');
                  return streamUrl;
                }
              }
              
              // Check for eId and try to get URL from it
              if (data['eId'] != null) {
                final eId = data['eId'].toString();
                // Try format=links
                final linksUrl = 'https://openwhyd.org/$eId?format=links';
                try {
                  final linksResponse = await http.get(Uri.parse(linksUrl)).timeout(
                    const Duration(seconds: 5),
                  );
                  if (linksResponse.statusCode == 200) {
                    final linksData = jsonDecode(linksResponse.body);
                    if (linksData is Map) {
                      streamUrl = linksData['url']?.toString() ?? 
                                 linksData['src']?.toString();
                      if (streamUrl != null && streamUrl.isNotEmpty &&
                          (streamUrl.startsWith('http://') || streamUrl.startsWith('https://'))) {
                        print('✅ Found stream URL from links: $streamUrl');
                        return streamUrl;
                      }
                    } else if (linksData is List && linksData.isNotEmpty) {
                      streamUrl = linksData[0]?.toString();
                      if (streamUrl != null && streamUrl.isNotEmpty &&
                          (streamUrl.startsWith('http://') || streamUrl.startsWith('https://'))) {
                        print('✅ Found stream URL from links list: $streamUrl');
                        return streamUrl;
                      }
                    }
                  }
                } catch (e) {
                  print('⚠️ Error getting links format: $e');
                }
              }
            } else if (data is List && data.isNotEmpty) {
              // If response is a list, get first item
              final firstItem = data[0];
              if (firstItem is Map) {
                String? streamUrl = firstItem['url']?.toString() ?? 
                                  firstItem['src']?.toString() ??
                                  firstItem['streamUrl']?.toString();
                if (streamUrl != null && streamUrl.isNotEmpty &&
                    (streamUrl.startsWith('http://') || streamUrl.startsWith('https://'))) {
                  print('✅ Found stream URL from list: $streamUrl');
                  return streamUrl;
                }
              }
            }
          } catch (e) {
            print('⚠️ Error parsing JSON response: $e');
          }
        } else {
          print('⚠️ API returned status ${response.statusCode}');
        }
      } catch (e) {
        print('⚠️ Error fetching from /c/ endpoint: $e');
      }
      
      // Try method 2: If identifier looks like eId, try direct format=links
      if (!cleanId.contains('/') && !cleanId.startsWith('http')) {
        try {
          final linksUrl = 'https://openwhyd.org/$cleanId?format=links';
          final linksResponse = await http.get(Uri.parse(linksUrl)).timeout(
            const Duration(seconds: 5),
          );
          if (linksResponse.statusCode == 200) {
            final linksData = jsonDecode(linksResponse.body);
            if (linksData is Map) {
              String? streamUrl = linksData['url']?.toString() ?? 
                                 linksData['src']?.toString();
              if (streamUrl != null && streamUrl.isNotEmpty &&
                  (streamUrl.startsWith('http://') || streamUrl.startsWith('https://'))) {
                print('✅ Found stream URL from direct links: $streamUrl');
                return streamUrl;
              }
            } else if (linksData is List && linksData.isNotEmpty) {
              String? streamUrl = linksData[0]?.toString();
              if (streamUrl != null && streamUrl.isNotEmpty &&
                  (streamUrl.startsWith('http://') || streamUrl.startsWith('https://'))) {
                print('✅ Found stream URL from links list: $streamUrl');
                return streamUrl;
              }
            }
          }
        } catch (e) {
          print('⚠️ Error getting direct links: $e');
        }
      }
      
      print('❌ Could not find stream URL for identifier: $cleanId');
      return null;
    } catch (e) {
      print('❌ Error fetching stream URL: $e');
      return null;
    }
  }
  
  // Get YouTube stream URL from video ID
  static Future<String?> _getYouTubeStreamUrl(String videoId) async {
    // Note: just_audio cannot directly play YouTube watch URLs
    // We need to extract the actual stream URL
    
    // Try using a public YouTube stream extractor API
    // Option 1: Use yt-dlp or similar service (if you have a server)
    // Option 2: Use YouTube embed API to get stream URL
    // Option 3: Use a public extractor service
    
    try {
      // Try using a public YouTube stream extractor service
      // Note: These services may not always work and may violate YouTube ToS
      // For production, consider using YouTube Data API or your own server
      
      print('📺 YouTube video ID: $videoId');
      print('💡 YouTube tracks require a stream extractor service');
      print('💡 Consider implementing YouTube Data API or using a server-side extractor');
      
      // Return null - YouTube tracks need special handling
      return null;
      
      // If you have a stream extractor service, uncomment and use:
      // final response = await http.get(Uri.parse('YOUR_EXTRACTOR_SERVICE_URL?video_id=$videoId'));
      // if (response.statusCode == 200) {
      //   final data = jsonDecode(response.body);
      //   return data['stream_url']?.toString();
      // }
    } catch (e) {
      print('❌ Error getting YouTube stream URL: $e');
      return null;
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
      
      // Check eId first to skip YouTube tracks early
      String? eId = item['eId']?.toString();
      if (eId != null && (eId.startsWith('/yt/') || eId.startsWith('yt/'))) {
        // Skip YouTube tracks - they cannot be played directly
        print('⏭️ Skipping YouTube track (eId: $eId)');
        return null;
      }
      
      // Method 1: Check for direct stream URL fields first (most reliable)
      audioUrl = item['url']?.toString() ?? 
                 item['src']?.toString() ??
                 item['streamUrl']?.toString() ??
                 item['audioUrl']?.toString() ??
                 item['stream']?.toString();
      
      // Method 2: Check for track object with URL
      if ((audioUrl == null || audioUrl.isEmpty) && item['track'] != null) {
        final track = item['track'];
        if (track is Map) {
          audioUrl = track['url']?.toString() ?? 
                     track['src']?.toString() ??
                     track['streamUrl']?.toString() ??
                     track['stream']?.toString();
        }
      }
      
      // Method 3: Fallback to eId format (only if not YouTube)
      if (audioUrl == null || audioUrl.isEmpty) {
        if (eId != null) {
          // Clean eId - remove leading slash if present
          String cleanEId = eId;
          if (cleanEId.startsWith('/')) {
            cleanEId = cleanEId.substring(1);
          }
          
          // Skip if it's YouTube
          if (cleanEId.startsWith('yt/')) {
            print('⏭️ Skipping YouTube track (eId: $eId)');
            return null;
          }
          
          // Store eId URL - we'll resolve to stream URL when playing
          audioUrl = 'https://openwhyd.org/$cleanEId';
        } else if (item['_id'] != null) {
          // Use post ID to create URL - we'll resolve to stream URL when playing
          String postId = item['_id'].toString();
          audioUrl = 'https://openwhyd.org/c/$postId';
        }
      }
      
      // Final check: Skip if URL contains YouTube
      if (audioUrl != null && (audioUrl.contains('youtube.com') || audioUrl.contains('/yt/'))) {
        print('⏭️ Skipping YouTube track (URL: $audioUrl)');
        return null;
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
      try {
        final apiTracks = await fetchTracksFromOpenwhyd(category);
        if (apiTracks.isNotEmpty) {
          tracksByCategory[category]!.addAll(apiTracks);
        } else {
          // If no tracks from API, ensure we have default tracks
          if (tracksByCategory[category]!.isEmpty) {
            final defaultTracks = getDefaultTracksForCategory(category);
            tracksByCategory[category]!.addAll(defaultTracks);
          }
        }
      } catch (e) {
        print('Error fetching tracks for $category: $e');
        // Ensure we have default tracks even if API fails
        if (tracksByCategory[category]!.isEmpty) {
          final defaultTracks = getDefaultTracksForCategory(category);
          tracksByCategory[category]!.addAll(defaultTracks);
        }
      }
    }

    return tracksByCategory;
  }
}

