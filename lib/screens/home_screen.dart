import 'dart:io';
import 'package:flutter/material.dart';
import 'chatbot_screen.dart';
import 'dashboard_home_screen.dart';
import '../models/device_status.dart';
import '../models/mood_type.dart';
import '../models/music_track.dart';
import '../services/global_music_player_service.dart';
import '../services/music_service.dart';
import '../services/settings_service.dart';
import '../services/bluetooth_service.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  DeviceStatus _deviceStatus = DeviceStatus(
    temperature: 35.0,
    isBluetoothConnected: false,
  );
  final BluetoothService _bluetoothService = BluetoothService();
  String? _initialChatbotMessage; // Store initial message for chatbot
  final PageController _pageController = PageController(initialPage: 0);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            if (_currentIndex == 1 && index != 1) {
              _initialChatbotMessage = null;
            }
            _currentIndex = index;
          });
        },
        children: [
          DashboardHomeScreen(
            key: ValueKey(_deviceStatus.hashCode),
            deviceStatus: _deviceStatus,
            onStatusChanged: (newStatus) {
              setState(() {
                _deviceStatus = newStatus;
              });
            },
            onNavigateToChatbotWithMood: (mood) {
              setState(() {
                _initialChatbotMessage = mood.label;
                _currentIndex = 1;
              });
              _pageController.animateToPage(
                1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
          ChatbotScreen(
            initialMessage: _initialChatbotMessage,
            onMoodSelected: _handleMoodSelected,
            onMusicSuggested: _handleMusicSuggested,
            onLightSuggested: _handleLightSuggested,
            onEssentialOilSuggested: _handleEssentialOilSuggested,
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          setState(() {
            if (_currentIndex == 1 && index != 1) {
              _initialChatbotMessage = null;
            }
            _currentIndex = index;
          });
        },
      ),
    );
  }

  void _handleMoodSelected(MoodType mood) {
    setState(() {});
  }

  void _handleLightSuggested(String lightMode, {double? brightness}) async {
    final autoLightEnabled = await SettingsService.getAutoLightEnabled();
    if (!autoLightEnabled) {
      return;
    }

    if (_bluetoothService.isConnected) {
      await _bluetoothService.setLightOn(true);
      await _bluetoothService.setLightMode(lightMode);
      if (brightness != null) {
        await _bluetoothService.setLightBrightness(brightness);
      }
    }

    setState(() {
      _deviceStatus = _deviceStatus.copyWith(
        isLightOn: true,
        lightMode: lightMode,
        lightBrightness: brightness ?? _deviceStatus.lightBrightness,
      );
    });
  }

  void _handleEssentialOilSuggested(String essentialOil) {
    // Currently we just update status to indicate active scent
    // In a real device, this would send a command to the diffuser
    debugPrint('Scent suggested and accepted: $essentialOil');
  }

  void _handleMusicSuggested(String music) async {
    // Check if auto music is enabled
    final autoMusicEnabled = await SettingsService.getAutoMusicEnabled();
    if (!autoMusicEnabled) {
      // Removed print statement: '⚠️ Auto music is disabled in settings');
      return;
    }

    // Automatically play music when chatbot suggests it
    try {
      debugPrint('--- Chatbot Suggested Music: $music ---');
      final globalPlayer = GlobalMusicPlayerService();
      final allTracksMap = await MusicService.getAllTracksByCategory();

      MusicTrack? playableTrack;

      // 1. Try to find the exact track by name or path matching
      for (var categoryList in allTracksMap.values) {
        for (var track in categoryList) {
          final nameMatch = track.name.toLowerCase() == music.toLowerCase();
          final pathMatch = track.audioPath != null &&
              track.audioPath!.toLowerCase().contains(music.toLowerCase());

          if (nameMatch || pathMatch) {
            playableTrack = track;
            debugPrint(
                'Found matching track: ${track.name} (${track.audioPath})');
            break;
          }
        }
        if (playableTrack != null) break;
      }

      if (playableTrack != null) {
        debugPrint('Attempting to play track: ${playableTrack.name}');
        await globalPlayer.playTrack(playableTrack);

        if (mounted) {
          setState(() {
            _deviceStatus = _deviceStatus.copyWith(
              isMusicPlaying: true,
              currentMusic: playableTrack!.name,
            );
          });
        }
        debugPrint('Music play command sent.');
      } else {
        debugPrint('Could not find a playable track for: $music');
        if (mounted) {
          setState(() {
            _deviceStatus = _deviceStatus.copyWith(
              isMusicPlaying: false,
              currentMusic: music,
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Error in _handleMusicSuggested: $e');
      if (mounted) {
        setState(() {
          _deviceStatus = _deviceStatus.copyWith(
            isMusicPlaying: false,
            currentMusic: music,
          );
        });
      }
    }
  }
}
