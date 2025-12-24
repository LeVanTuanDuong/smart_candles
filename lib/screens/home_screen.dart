import 'dart:io';
import 'package:flutter/material.dart';
import 'chatbot_screen.dart';
import 'dashboard_home_screen.dart';
import '../models/device_status.dart';
import '../models/mood_type.dart';
import '../models/music_track.dart';
import '../services/global_music_player_service.dart';
import '../services/music_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _chatbotKey = 0; // Key to force reset chatbot when switching back
  DeviceStatus _deviceStatus = DeviceStatus(
    temperature: 35.0,
    isBluetoothConnected: false,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardHomeScreen(
            key: ValueKey(_deviceStatus.hashCode),
            deviceStatus: _deviceStatus,
            onStatusChanged: (newStatus) {
              setState(() {
                _deviceStatus = newStatus;
              });
            },
            onNavigateToChatbot: () {
              setState(() {
                _currentIndex = 1;
              });
            },
          ),
          ChatbotScreen(
            key: ValueKey(_chatbotKey),
            onMoodSelected: _handleMoodSelected,
            onMusicSuggested: _handleMusicSuggested,
            onLightSuggested: _handleLightSuggested,
            onEssentialOilSuggested: _handleEssentialOilSuggested,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            // If switching away from chatbot (index 1), increment key to reset it
            if (_currentIndex == 1 && index != 1) {
              _chatbotKey++;
            }
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.purple[600],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chatbot',
          ),
        ],
      ),
    );
  }

  void _handleMoodSelected(MoodType mood) {
    // Update device status based on mood
    setState(() {
      // Could update temperature simulation based on mood
      // This is just a demo, real implementation would communicate with ESP32
    });
  }


  void _handleLightSuggested(String lightMode) {
    setState(() {
      _deviceStatus = _deviceStatus.copyWith(
        isLightOn: true,
        lightMode: lightMode,
      );
    });
  }

  void _handleEssentialOilSuggested(String essentialOil) {
    // Update will be handled by SuggestionService
  }

  void _handleMusicSuggested(String music) async {
    // Automatically play music when chatbot suggests it
    try {
      final globalPlayer = GlobalMusicPlayerService();
      
      // Map music suggestion to category
      String category = 'Thiền'; // default
      if (music.toLowerCase().contains('piano')) {
        category = 'Nhạc Piano';
      } else if (music.toLowerCase().contains('ambient')) {
        category = 'Ambient';
      } else if (music.toLowerCase().contains('nature') || music.toLowerCase().contains('mưa') || music.toLowerCase().contains('thiên nhiên')) {
        category = 'Thiên nhiên';
      } else if (music.toLowerCase().contains('lofi') || music.toLowerCase().contains('lo-fi')) {
        category = 'Thiền'; // fallback to meditation
      } else if (music.toLowerCase().contains('thiền') || music.toLowerCase().contains('meditation')) {
        category = 'Thiền';
      }
      
      // Get tracks for this category (static method)
      final tracks = MusicService.getDefaultTracksForCategory(category);
      
      // Find a track with valid audio source (local file or valid URL)
      MusicTrack? playableTrack;
      for (final track in tracks) {
        // Check if track has valid audio source
        bool hasValidSource = false;
        
        // Check local file
        if (track.audioPath != null && track.audioPath!.isNotEmpty) {
          try {
            final file = File(track.audioPath!);
            if (file.existsSync()) {
              hasValidSource = true;
            }
          } catch (e) {
            // File doesn't exist or can't be accessed
          }
        }
        
        // Check URL (but skip Openwhyd/YouTube URLs)
        if (!hasValidSource && track.audioUrl != null && track.audioUrl!.isNotEmpty) {
          final url = track.audioUrl!;
          // Skip URLs that cannot be played directly
          if (!url.startsWith('https://openwhyd.org/') &&
              !url.contains('youtube.com/watch') &&
              !url.contains('youtu.be/')) {
            hasValidSource = true;
          }
        }
        
        if (hasValidSource) {
          playableTrack = track;
          break;
        }
      }
      
      if (playableTrack != null) {
        // Play the track automatically
        try {
          await globalPlayer.playTrack(playableTrack);
          
          setState(() {
            _deviceStatus = _deviceStatus.copyWith(
              isMusicPlaying: true,
              currentMusic: playableTrack!.name,
            );
          });
          print('✅ Auto-playing music: ${playableTrack.name}');
        } catch (e) {
          print('❌ Error auto-playing music: $e');
          // Don't update status if playback failed
          // User can manually play from music library
          // Don't throw - just log the error and continue
        }
      } else {
        // No playable tracks found
        print('⚠️ No playable tracks found for category: $category');
        print('💡 User should upload music files or check network connection');
        // Don't update status - let user know they need to upload music
        setState(() {
          _deviceStatus = _deviceStatus.copyWith(
            isMusicPlaying: false,
            currentMusic: music, // Just store the suggestion name
          );
        });
      }
    } catch (e) {
      print('❌ Error in _handleMusicSuggested: $e');
      // Don't update status on error
      setState(() {
        _deviceStatus = _deviceStatus.copyWith(
          isMusicPlaying: false,
          currentMusic: music,
        );
      });
    }
  }
}

