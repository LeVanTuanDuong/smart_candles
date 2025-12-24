import 'package:flutter/material.dart';
import 'chatbot_screen.dart';
import 'dashboard_home_screen.dart';
import '../models/device_status.dart';
import '../models/mood_type.dart';

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
            onMoodSelected: _handleMoodSelected,
            onMusicSuggested: _handleMusicSuggested,
            onLightSuggested: _handleLightSuggested,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
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

  void _handleMusicSuggested(String music) {
    setState(() {
      _deviceStatus = _deviceStatus.copyWith(
        isMusicPlaying: true,
        currentMusic: music,
      );
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
}

