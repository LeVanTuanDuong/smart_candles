import 'dart:async';
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
import '../screens/profile_screen.dart';
import '../screens/mood_journal_screen.dart';
import '../screens/safety_history_screen.dart';
import '../screens/meditation_guide_screen.dart';
import '../screens/music_library_screen.dart';
import '../services/chatbot_service.dart' show ChatbotService;
import '../services/temperature_history_service.dart';
import '../models/temperature_history_entry.dart';
import '../services/global_music_player_service.dart';
import '../services/suggestion_service.dart';
import '../services/music_service.dart';
import '../services/settings_service.dart';
import '../services/bluetooth_service.dart';
import '../services/essential_oil_service.dart';
import '../models/music_track.dart';
import '../models/essential_oil.dart';

class DashboardHomeScreen extends StatefulWidget {
  final DeviceStatus deviceStatus;
  final Function(DeviceStatus) onStatusChanged;
  final Function(MoodType)? onNavigateToChatbotWithMood;

  const DashboardHomeScreen({
    super.key,
    required this.deviceStatus,
    required this.onStatusChanged,
    this.onNavigateToChatbotWithMood,
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
  final GlobalMusicPlayerService _globalMusicPlayer =
      GlobalMusicPlayerService();
  final SuggestionService _suggestionService = SuggestionService();
  final BluetoothService _bluetoothService = BluetoothService();
  StreamSubscription? _temperatureSubscription;
  MusicTrack? _suggestedMusicTrack; // Track from library to display
  EssentialOil? _suggestedEssentialOil; // EssentialOil from library to display

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

    // Initialize suggested music track and essential oil
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSuggestedMusicTrack();
      _updateSuggestedEssentialOil();
    });

    // Listen to Bluetooth service for temperature updates
    _bluetoothService.addListener(_onBluetoothTemperatureUpdate);

    // Start reading temperature from Bluetooth if connected
    if (_bluetoothService.isConnected) {
      _startTemperatureReading();
    }

    // Save initial temperature to history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final historyEntry = TemperatureHistoryEntry(
        timestamp: DateTime.now(),
        temperature: _deviceStatus.temperature,
        status: _deviceStatus.status,
      );
      TemperatureHistoryService.saveEntry(historyEntry);

      // Check for danger temperature using settings threshold
      _checkTemperatureThreshold(_deviceStatus.temperature);
    });
  }

  void _onBluetoothTemperatureUpdate() {
    if (!mounted) return;

    // Update temperature from Bluetooth
    final bluetoothTemp = _bluetoothService.currentTemperature;
    final isConnected = _bluetoothService.isConnected;

    // Check if temperature or connection status changed
    final tempChanged = (bluetoothTemp - _deviceStatus.temperature).abs() > 0.1;
    final connectionChanged = isConnected != _deviceStatus.isBluetoothConnected;

    if (tempChanged || connectionChanged) {
      final newStatus = _deviceStatus.copyWith(
        temperature: bluetoothTemp,
        isBluetoothConnected: isConnected,
      );
      _updateStatus(newStatus);
    }
  }

  void _startTemperatureReading() {
    // Cancel existing subscription if any
    _temperatureSubscription?.cancel();

    // Request temperature reading every 5 seconds as backup
    // (Main updates come from notifications, this is just a fallback)
    _temperatureSubscription =
        Stream.periodic(const Duration(seconds: 5)).listen((
      _,
    ) async {
      if (_bluetoothService.isConnected && mounted) {
        try {
          final temp = await _bluetoothService.readTemperature();
          if (temp != null) {
            // Temperature will be updated via notifyListeners in BluetoothService
            // This just triggers a read, the update happens automatically
          }
        } catch (e) {}
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
    if (!mounted) return;

    // Update suggested mood if detected
    if (_suggestionService.detectedMood != null) {
      setState(() {
        _suggestedMood = _suggestionService.detectedMood;
      });
    }

    // Update suggested music track from library (async, don't need setState)
    _updateSuggestedMusicTrack();

    // Update suggested essential oil from library (async, don't need setState)
    _updateSuggestedEssentialOil();
  }

  Future<void> _updateSuggestedMusicTrack() async {
    try {
      // Use the current detected mood from SuggestionService (most up-to-date)
      final currentMood =
          _suggestionService.detectedMood ?? _suggestedMood ?? MoodType.normal;

      // Get the suggested music type from chatbot (prioritize from SuggestionService)
      final musicType = _suggestionService.musicSuggestion ??
          ChatbotService.getMusicSuggestions(currentMood).first;

      // Map music type to category (handle both Vietnamese and English, and exact matches)
      String category = 'Thiền'; // default
      final musicLower = musicType.toLowerCase().trim();

      // Exact matches first (more precise)
      if (musicLower == 'nhạc piano' ||
          musicLower == 'piano chậm' ||
          musicLower == 'piano ấm' ||
          musicLower.contains('piano') && !musicLower.contains('ambient')) {
        category = 'Nhạc Piano';
      } else if (musicLower == 'ambient' ||
          musicLower == 'ambient nhẹ' ||
          musicLower == 'ambient tối' ||
          (musicLower.contains('ambient') && !musicLower.contains('piano'))) {
        category = 'Ambient';
      } else if (musicLower == 'thiên nhiên' ||
          musicLower == 'nature sound' ||
          musicLower == 'mưa nhẹ' ||
          musicLower.contains('nature') ||
          musicLower.contains('mưa') ||
          musicLower.contains('rain') ||
          musicLower.contains('ocean')) {
        category = 'Thiên nhiên';
      } else if (musicLower == 'thiền' ||
          musicLower == 'meditation music' ||
          musicLower == 'meditation' ||
          musicLower.contains('thiền') ||
          musicLower.contains('zen')) {
        category = 'Thiền';
      }
      // Get tracks for this category from library
      final allTracksByCategory = await MusicService.getAllTracksByCategory();
      final allTracks = allTracksByCategory[category] ?? [];
      // Find first track with audio source
      MusicTrack? track;
      for (final t in allTracks) {
        if (t.audioPath != null && t.audioPath!.isNotEmpty) {
          track = t;
          break;
        }
      }

      if (mounted) {
        setState(() {
          _suggestedMusicTrack = track;
        });
      }
    } catch (e) {}
  }

  Future<void> _updateSuggestedEssentialOil() async {
    try {
      // Use the current detected mood from SuggestionService (most up-to-date)
      final currentMood =
          _suggestionService.detectedMood ?? _suggestedMood ?? MoodType.normal;

      // Get the suggested essential oil name from chatbot
      final suggestedOilName = _suggestionService.essentialOilSuggestion;

      // Get all oils from library and suggestions
      final allOils = await EssentialOilService.getAllOils();

      // Try to find matching oil by name
      EssentialOil? matchedOil;

      if (suggestedOilName != null && suggestedOilName.isNotEmpty) {
        // Try exact match first
        try {
          matchedOil = allOils.firstWhere(
            (oil) => oil.name.toLowerCase() == suggestedOilName.toLowerCase(),
          );
        } catch (e) {
          // Try partial match
          try {
            matchedOil = allOils.firstWhere(
              (oil) =>
                  oil.name.toLowerCase().contains(
                        suggestedOilName.toLowerCase(),
                      ) ||
                  suggestedOilName.toLowerCase().contains(
                        oil.name.toLowerCase(),
                      ),
            );
          } catch (e) {
            // Try normalized match
            matchedOil = _findOilByName(suggestedOilName, allOils);
          }
        }
      }

      // If no match found, use default for mood
      matchedOil ??= _findOilByName(
        _getDefaultOilNameForMood(currentMood),
        allOils,
      );
      if (mounted) {
        setState(() {
          _suggestedEssentialOil = matchedOil;
        });
      }
    } catch (e) {}
  }

  EssentialOil? _findOilByName(String name, List<EssentialOil> oils) {
    final normalizedName = _normalizeOilName(name);

    // Try exact match
    try {
      return oils.firstWhere(
        (oil) => _normalizeOilName(oil.name) == normalizedName,
      );
    } catch (e) {
      // Try partial match
      try {
        return oils.firstWhere(
          (oil) =>
              _normalizeOilName(oil.name).contains(normalizedName) ||
              normalizedName.contains(_normalizeOilName(oil.name)),
        );
      } catch (e) {
        // Try English name mapping
        return _findOilByEnglishName(name, oils);
      }
    }
  }

  EssentialOil? _findOilByEnglishName(
    String englishName,
    List<EssentialOil> oils,
  ) {
    final nameLower = englishName.toLowerCase();

    // Map English names to Vietnamese names
    final nameMap = {
      'lavender': ['oải hương', 'lavender'],
      'sweet orange': ['hương cam', 'cam ngot'],
      'peppermint': ['bạc hà', 'bac ha'],
      'chamomile': ['chamomile'],
      'frankincense': ['hương trầm', 'huong tram'],
      'eucalyptus': ['khuynh diệp', 'khuynh diep'],
      'tea tree': ['tràm trà', 'tram tra'],
      'grapefruit': ['bưởi', 'buoi'],
      'lemongrass': ['sả chanh', 'sa chanh'],
      'ginger': ['gừng', 'gung'],
      'ylang-ylang': ['ngọc lan tây', 'ngoc lan tay'],
      'jasmine': ['hoa nhài', 'hoa nhai'],
      'lemon': ['chanh'],
    };

    for (final entry in nameMap.entries) {
      if (nameLower.contains(entry.key)) {
        for (final vnName in entry.value) {
          try {
            return oils.firstWhere(
              (oil) => _normalizeOilName(oil.name).contains(vnName),
            );
          } catch (e) {
            continue;
          }
        }
      }
    }

    return oils.isNotEmpty ? oils.first : null;
  }

  String _normalizeOilName(String name) {
    return name
        .toLowerCase()
        .replaceAll('tinh dầu', '')
        .replaceAll('tinhdầu', '')
        .trim();
  }

  String _getDefaultOilNameForMood(MoodType mood) {
    switch (mood) {
      case MoodType.stressed:
        return 'Tinh dầu Oải Hương';
      case MoodType.sad:
        return 'Tinh dầu Hương Cam';
      case MoodType.tired:
        return 'Tinh dầu Bạc Hà';
      case MoodType.insomnia:
        return 'Tinh dầu Oải Hương';
      case MoodType.normal:
        return 'Tinh dầu Oải Hương';
    }
  }

  /// Play track with playlist for navigation
  Future<void> _playTrackWithPlaylist(MusicTrack track,
      {List<MusicTrack>? playlist}) async {
    // If no playlist provided, get tracks from same category
    List<MusicTrack> tracksToPlay = playlist ?? [];
    if (tracksToPlay.isEmpty) {
      final allTracksByCategory = await MusicService.getAllTracksByCategory();
      final categoryTracks = allTracksByCategory[track.category] ?? [];
      // Filter to only tracks with valid audio paths
      tracksToPlay = categoryTracks
          .where((t) => t.audioPath != null && t.audioPath!.isNotEmpty)
          .toList();
    }

    await _globalMusicPlayer.playTrack(track, playlist: tracksToPlay);
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
      // Check for danger temperature using settings threshold
      _checkTemperatureThreshold(_deviceStatus.temperature);
    }
  }

  void _updateStatus(DeviceStatus newStatus) {
    if (!mounted) return; // Don't update if widget is disposed

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
      // Check for danger temperature using settings threshold
      _checkTemperatureThreshold(newStatus.temperature);
    });
    widget.onStatusChanged(newStatus);
  }

  Future<void> _checkTemperatureThreshold(double temperature) async {
    if (!mounted) return;

    try {
      // Get temperature threshold from settings
      final threshold = await SettingsService.getTemperatureThreshold();
      final notificationsEnabled =
          await SettingsService.getNotificationsEnabled();

      // Check if temperature exceeds threshold
      if (temperature > threshold && notificationsEnabled && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            DangerAlertDialog.show(context, temperature);
          }
        });
      }
    } catch (e) {
      // Fallback to default threshold (50.0)
      if (temperature > 50.0 && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            DangerAlertDialog.show(context, temperature);
          }
        });
      }
    }
  }

  void _handleMoodSelected(MoodType mood) {
    if (!mounted) return; // Don't update if widget is disposed

    setState(() {
      _selectedMood = mood;
      _suggestedMood = mood;

      final lightMode = ChatbotService.getLightSuggestion(mood);
      final suggestedMusic = _suggestionService.musicSuggestion ??
          ChatbotService.getMusicSuggestions(mood).first;
      _deviceStatus = _deviceStatus.copyWith(
        isLightOn: true,
        lightMode: lightMode,
        isMusicPlaying: false, // User will click "Bật ngay" to start
        currentMusic: suggestedMusic,
      );
    });
    _updateStatus(_deviceStatus);
    // Update suggested music track and essential oil based on new mood
    _updateSuggestedMusicTrack();
    _updateSuggestedEssentialOil();

    // Navigate to chatbot and pass the mood message
    if (widget.onNavigateToChatbotWithMood != null) {
      widget.onNavigateToChatbotWithMood!(mood);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.person, color: Colors.white),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProfileScreen(
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
          'Nến Thông Minh',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor:
            const Color.fromARGB(255, 139, 223, 245), // Xanh da trời
        elevation: 0,
        centerTitle: true,
        actions: [
          // Calendar icon
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
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
                icon: const Icon(Icons.notifications_none, color: Colors.white),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 146, 225, 245), // Xanh dương đậm
              Color.fromRGBO(171, 230, 244, 1), // Xanh dương vừa
              Color.fromARGB(255, 193, 238, 244), // Xanh dương nhạt
              Color.fromARGB(255, 228, 244, 247), // Xanh dương rất nhạt
            ],
            stops: [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Temperature Card
              TemperatureCardHome(deviceStatus: _deviceStatus),

              // Chatbot Section
              ChatbotSectionHome(
                selectedMood: _selectedMood,
                onMoodSelected: _handleMoodSelected,
                onChatbotTap: () {
                  if (widget.onNavigateToChatbotWithMood != null) {
                    widget.onNavigateToChatbotWithMood!(MoodType.normal);
                  }
                },
              ),

              // Music Control Widget (always show with suggested or current music)
              MusicControlHome(
                currentTrack:
                    _globalMusicPlayer.currentTrack, // Pass the track for image
                musicTitle: _globalMusicPlayer.currentTrack?.name ??
                    _deviceStatus.currentMusic ??
                    ChatbotService.getMusicSuggestions(
                      _suggestedMood ?? MoodType.normal,
                    ).first,
                musicSubtitle: _globalMusicPlayer.currentTrack?.category ??
                    (_deviceStatus.currentMusic != null &&
                            _suggestedMood != null
                        ? '(Gợi ý)'
                        : ''),
                isPlaying: _globalMusicPlayer.isPlaying ||
                    _deviceStatus.isMusicPlaying,
                volume: _globalMusicPlayer.volume,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MeditationGuideScreen(),
                    ),
                  );
                },
                onPlayPause: () async {
                  try {
                    // If there's a current track in the global player, toggle play/pause
                    if (_globalMusicPlayer.currentTrack != null) {
                      await _globalMusicPlayer.togglePlayPause();
                    } else {
                      // No track is currently loaded, need to play a track first
                      // Try to use suggested track if available
                      if (_suggestedMusicTrack != null) {
                        await _globalMusicPlayer
                            .playTrack(_suggestedMusicTrack!);
                        if (mounted) {
                          _updateStatus(
                            _deviceStatus.copyWith(
                              isMusicPlaying: true,
                              currentMusic: _suggestedMusicTrack!.name,
                            ),
                          );
                        }
                      } else {
                        // No suggested track, try to find and play a default track based on mood
                        final currentMood = _suggestedMood ?? MoodType.normal;
                        final musicType = _suggestionService.musicSuggestion ??
                            ChatbotService.getMusicSuggestions(currentMood)
                                .first;

                        // Map music type to category and get a track
                        String category = 'Thiền';
                        final musicLower = musicType.toLowerCase().trim();
                        if (musicLower.contains('piano')) {
                          category = 'Nhạc Piano';
                        } else if (musicLower.contains('ambient')) {
                          category = 'Ambient';
                        } else if (musicLower.contains('nature') ||
                            musicLower.contains('thiên nhiên') ||
                            musicLower.contains('mưa')) {
                          category = 'Thiên nhiên';
                        }

                        final allTracksByCategory =
                            await MusicService.getAllTracksByCategory();
                        final tracks = allTracksByCategory[category] ?? [];

                        // Find first playable track
                        MusicTrack? trackToPlay;
                        for (final track in tracks) {
                          if (track.audioPath != null &&
                              track.audioPath!.isNotEmpty) {
                            trackToPlay = track;
                            break;
                          }
                        }

                        if (trackToPlay != null) {
                          await _globalMusicPlayer.playTrack(trackToPlay);
                          if (mounted) {
                            setState(() {
                              _suggestedMusicTrack = trackToPlay;
                            });
                            _updateStatus(
                              _deviceStatus.copyWith(
                                isMusicPlaying: true,
                                currentMusic: trackToPlay.name,
                              ),
                            );
                          }
                        }
                      }
                    }
                  } catch (e) {
                    // If play failed, at least toggle the UI state
                    if (mounted) {
                      _updateStatus(
                        _deviceStatus.copyWith(
                          isMusicPlaying: !_deviceStatus.isMusicPlaying,
                        ),
                      );
                    }
                  }
                },
                onPrevious: () async {
                  try {
                    await _globalMusicPlayer.playPreviousTrack();
                    if (mounted && _globalMusicPlayer.currentTrack != null) {
                      setState(() {
                        _suggestedMusicTrack = _globalMusicPlayer.currentTrack;
                      });
                      _updateStatus(
                        _deviceStatus.copyWith(
                          isMusicPlaying: _globalMusicPlayer.isPlaying,
                          currentMusic: _globalMusicPlayer.currentTrack!.name,
                        ),
                      );
                    }
                  } catch (e) {
                    // Error handled silently
                  }
                },
                onNext: () async {
                  try {
                    await _globalMusicPlayer.playNextTrack();
                    if (mounted && _globalMusicPlayer.currentTrack != null) {
                      setState(() {
                        _suggestedMusicTrack = _globalMusicPlayer.currentTrack;
                      });
                      _updateStatus(
                        _deviceStatus.copyWith(
                          isMusicPlaying: _globalMusicPlayer.isPlaying,
                          currentMusic: _globalMusicPlayer.currentTrack!.name,
                        ),
                      );
                    }
                  } catch (e) {
                    // Error handled silently
                  }
                },
                onVolumeChanged: (newVolume) async {
                  // Volume is updated smoothly via _VolumeSlider
                  // This callback is called during dragging for immediate feedback
                  await _globalMusicPlayer.setVolumeSilent(newVolume);
                },
              ),

              // Essential Oil Suggestion Card (always show with current or default mood)
              EssentialOilSuggestionCard(
                mood: _suggestedMood ?? MoodType.normal,
                customEssentialOil: _suggestionService.essentialOilSuggestion,
                suggestedOil: _suggestedEssentialOil,
              ),

              // Music Suggestion Card (always show with current or default mood)
              MusicSuggestionCard(
                suggestedTrack: _suggestedMusicTrack,
                musicType: _suggestionService.musicSuggestion ??
                    ChatbotService.getMusicSuggestions(
                      _suggestionService.detectedMood ??
                          _suggestedMood ??
                          MoodType.normal,
                    ).first,
                onPlayPressed: () async {
                  // Use the suggested track if available
                  if (_suggestedMusicTrack != null) {
                    try {
                      await _globalMusicPlayer.playTrack(_suggestedMusicTrack!);

                      // Update device status (only if still mounted)
                      if (mounted) {
                        _updateStatus(
                          _deviceStatus.copyWith(
                            isMusicPlaying: true,
                            currentMusic: _suggestedMusicTrack!.name,
                          ),
                        );
                      }
                    } catch (e) {
                      // Show error message to user
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Không thể phát nhạc. Vui lòng tải lên file nhạc từ thư viện.',
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  } else {
                    // Try to get a track from library
                    final musicType = _suggestionService.musicSuggestion ??
                        ChatbotService.getMusicSuggestions(
                          _suggestedMood ?? MoodType.normal,
                        ).first;

                    // Map music type to category
                    String category = 'Thiền'; // default
                    if (musicType.toLowerCase().contains('piano')) {
                      category = 'Nhạc Piano';
                    } else if (musicType.toLowerCase().contains('ambient')) {
                      category = 'Ambient';
                    } else if (musicType.toLowerCase().contains('nature') ||
                        musicType.toLowerCase().contains('mưa') ||
                        musicType.toLowerCase().contains('thiên nhiên')) {
                      category = 'Thiên nhiên';
                    } else if (musicType.toLowerCase().contains('thiền') ||
                        musicType.toLowerCase().contains('meditation')) {
                      category = 'Thiền';
                    }

                    // Get tracks for this category
                    final allTracksByCategory =
                        await MusicService.getAllTracksByCategory();
                    final allTracks = allTracksByCategory[category] ?? [];

                    // Find first track with audio source
                    MusicTrack? track;
                    for (final t in allTracks) {
                      if (t.audioPath != null && t.audioPath!.isNotEmpty) {
                        track = t;
                        break;
                      }
                    }

                    if (track != null) {
                      try {
                        await _playTrackWithPlaylist(track,
                            playlist: allTracks);

                        if (mounted) {
                          setState(() {
                            _suggestedMusicTrack = track;
                          });
                          _updateStatus(
                            _deviceStatus.copyWith(
                              isMusicPlaying: true,
                              currentMusic: track.name,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Không thể phát nhạc. Vui lòng tải lên file nhạc từ thư viện.',
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    } else {
                      // No tracks available - prompt user to upload
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Chưa có nhạc cho "$musicType". Vui lòng tải lên từ thư viện.',
                            ),
                            duration: const Duration(seconds: 3),
                            action: SnackBarAction(
                              label: 'Mở thư viện',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const MusicLibraryScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }
                    }
                  }
                },
              ),

              // Smartwatch Data Card
              SmartwatchCardHome(smartwatchData: _smartwatchData),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
