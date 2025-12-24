import 'package:flutter/material.dart';
import '../models/device_status.dart';
import '../models/mood_type.dart';
import '../models/smartwatch_data.dart';
import '../widgets/temperature_card_home.dart';
import '../widgets/chatbot_section_home.dart';
import '../widgets/essential_oil_suggestion_card.dart';
import '../widgets/music_suggestion_card.dart';
import '../widgets/music_control_home.dart';
import '../widgets/smartwatch_card_home.dart';
import '../widgets/danger_alert_dialog.dart';
import '../screens/settings_screen.dart';
import '../screens/mood_journal_screen.dart';
import '../screens/safety_history_screen.dart';
import '../screens/meditation_guide_screen.dart';
import '../services/chatbot_service.dart' show ChatbotService;
import '../services/temperature_history_service.dart';
import '../models/temperature_history_entry.dart';
import '../services/global_music_player_service.dart';
import '../services/suggestion_service.dart';

class DashboardHomeScreen extends StatefulWidget {
  final DeviceStatus deviceStatus;
  final Function(DeviceStatus) onStatusChanged;
  final VoidCallback? onNavigateToChatbot;

  const DashboardHomeScreen({
    super.key,
    required this.deviceStatus,
    required this.onStatusChanged,
    this.onNavigateToChatbot,
  });

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  late DeviceStatus _deviceStatus;
  MoodType? _selectedMood;
  final SmartwatchData _smartwatchData = SmartwatchData(
    heartRate: 72,
    isConnected: true,
  );
  MoodType? _suggestedMood;
  final GlobalMusicPlayerService _globalMusicPlayer = GlobalMusicPlayerService();
  final SuggestionService _suggestionService = SuggestionService();

  @override
  void initState() {
    super.initState();
    _deviceStatus = widget.deviceStatus;
    // Initialize with default mood to show suggestions from the start
    _suggestedMood = MoodType.normal;
    
    // Listen to global music player changes
    _globalMusicPlayer.addListener(_onMusicPlayerChanged);
    
    // Listen to suggestion service changes
    _suggestionService.addListener(_onSuggestionChanged);

    // Save initial temperature to history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final historyEntry = TemperatureHistoryEntry(
        timestamp: DateTime.now(),
        temperature: _deviceStatus.temperature,
        status: _deviceStatus.status,
      );
      TemperatureHistoryService.saveEntry(historyEntry);

      // Check for danger temperature
      if (_deviceStatus.temperature > 50.0) {
        DangerAlertDialog.show(context, _deviceStatus.temperature);
      }
    });
  }

  @override
  void dispose() {
    _globalMusicPlayer.removeListener(_onMusicPlayerChanged);
    _suggestionService.removeListener(_onSuggestionChanged);
    super.dispose();
  }

  void _onSuggestionChanged() {
    if (mounted) {
      setState(() {
        // Update suggested mood if detected
        if (_suggestionService.detectedMood != null) {
          _suggestedMood = _suggestionService.detectedMood;
        }
      });
    }
  }

  void _onMusicPlayerChanged() {
    if (mounted) {
      setState(() {
        // Update device status based on global music player
        _deviceStatus = _deviceStatus.copyWith(
          isMusicPlaying: _globalMusicPlayer.isPlaying,
          currentMusic: _globalMusicPlayer.currentTrack?.name,
          musicVolume: _globalMusicPlayer.volume,
        );
      });
    }
  }

  @override
  void didUpdateWidget(DashboardHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deviceStatus != widget.deviceStatus) {
      _deviceStatus = widget.deviceStatus;
      // Check for danger temperature
      if (_deviceStatus.temperature > 50.0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          DangerAlertDialog.show(context, _deviceStatus.temperature);
        });
      }
    }
  }

  void _updateStatus(DeviceStatus newStatus) {
    setState(() {
      // Save temperature history if temperature changed
      if (_deviceStatus.temperature != newStatus.temperature) {
        final historyEntry = TemperatureHistoryEntry(
          timestamp: DateTime.now(),
          temperature: newStatus.temperature,
          status: newStatus.status,
        );
        TemperatureHistoryService.saveEntry(historyEntry);
      }

      _deviceStatus = newStatus;
      // Check for danger temperature
      if (newStatus.temperature > 50.0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          DangerAlertDialog.show(context, newStatus.temperature);
        });
      }
    });
    widget.onStatusChanged(newStatus);
  }

  void _handleMoodSelected(MoodType mood) {
    setState(() {
      _selectedMood = mood;
      _suggestedMood = mood;

      final lightMode = ChatbotService.getLightSuggestion(mood);
      final suggestedMusic = _suggestionService.musicSuggestion ?? ChatbotService.getMusicSuggestions(mood).first;
      _deviceStatus = _deviceStatus.copyWith(
        isLightOn: true,
        lightMode: lightMode,
        isMusicPlaying: false, // User will click "Bật ngay" to start
        currentMusic: suggestedMusic,
      );
    });
    _updateStatus(_deviceStatus);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.settings, color: Colors.grey[800]),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SettingsScreen(
                  deviceStatus: _deviceStatus,
                  onStatusChanged: (newStatus) {
                    _updateStatus(newStatus);
                  },
                ),
              ),
            );
          },
        ),
        title: const Text(
          'Zenora Smart Comfort',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Calendar icon
          IconButton(
            icon: Icon(Icons.calendar_today, color: Colors.grey[800]),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MoodJournalScreen(),
                ),
              );
            },
          ),
          // Notification icon
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none, color: Colors.grey[800]),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SafetyHistoryScreen(),
                    ),
                  );
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Temperature Card
            TemperatureCardHome(deviceStatus: _deviceStatus),

            // Chatbot Section
            ChatbotSectionHome(
              selectedMood: _selectedMood,
              onMoodSelected: _handleMoodSelected,
              onChatbotTap: widget.onNavigateToChatbot,
            ),

            // Music Control Widget (always show with suggested or current music)
            MusicControlHome(
              musicTitle:
                  _globalMusicPlayer.currentTrack?.name ??
                  _deviceStatus.currentMusic ??
                  ChatbotService.getMusicSuggestions(
                    _suggestedMood ?? MoodType.normal,
                  ).first,
              musicSubtitle:
                  _globalMusicPlayer.currentTrack?.category ??
                  (_deviceStatus.currentMusic != null && _suggestedMood != null
                  ? '(Gợi ý)'
                  : ''),
              isPlaying: _globalMusicPlayer.isPlaying || _deviceStatus.isMusicPlaying,
              volume: _globalMusicPlayer.volume,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MeditationGuideScreen(
                      currentTrack:
                          _globalMusicPlayer.currentTrack?.name ??
                          _deviceStatus.currentMusic ??
                          ChatbotService.getMusicSuggestions(
                            _suggestedMood ?? MoodType.normal,
                          ).first,
                      isPlaying: _globalMusicPlayer.isPlaying || _deviceStatus.isMusicPlaying,
                    ),
                  ),
                );
              },
              onPlayPause: () async {
                // Use global music player if there's a current track
                if (_globalMusicPlayer.currentTrack != null) {
                  await _globalMusicPlayer.togglePlayPause();
                } else {
                  // If no current music, set it from suggestion
                  if (_deviceStatus.currentMusic == null) {
                    final currentMood = _suggestedMood ?? MoodType.normal;
                    final suggestedMusic = ChatbotService.getMusicSuggestions(
                      currentMood,
                    ).first;
                    _updateStatus(
                      _deviceStatus.copyWith(
                        isMusicPlaying: true,
                        currentMusic: suggestedMusic,
                      ),
                    );
                  } else {
                    _updateStatus(
                      _deviceStatus.copyWith(
                        isMusicPlaying: !_deviceStatus.isMusicPlaying,
                      ),
                    );
                  }
                }
              },
              onPrevious: () {
                // Handle previous track (TODO: implement playlist)
              },
              onNext: () {
                // Handle next track (TODO: implement playlist)
              },
              onVolumeChanged: (newVolume) async {
                await _globalMusicPlayer.setVolume(newVolume);
                _updateStatus(_deviceStatus.copyWith(musicVolume: newVolume));
              },
            ),

            // Essential Oil Suggestion Card (always show with current or default mood)
            EssentialOilSuggestionCard(
              mood: _suggestedMood ?? MoodType.normal,
              customEssentialOil: _suggestionService.essentialOilSuggestion,
            ),

            // Music Suggestion Card (always show with current or default mood)
            MusicSuggestionCard(
              musicType: _suggestionService.musicSuggestion ?? ChatbotService.getMusicSuggestions(
                _suggestedMood ?? MoodType.normal,
              ).first,
              onPlayPressed: () {
                final currentMood = _suggestedMood ?? MoodType.normal;
                final suggestedMusic = ChatbotService.getMusicSuggestions(
                  currentMood,
                ).first;
                _updateStatus(
                  _deviceStatus.copyWith(
                    isMusicPlaying: true,
                    currentMusic: suggestedMusic,
                  ),
                );
                // Update suggested mood if it was null
                if (_suggestedMood == null) {
                  setState(() {
                    _suggestedMood = currentMood;
                  });
                }
              },
            ),

            // Smartwatch Data Card
            SmartwatchCardHome(smartwatchData: _smartwatchData),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
