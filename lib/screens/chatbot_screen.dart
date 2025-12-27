import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/mood_type.dart';
import '../services/chatbot_service.dart';
import '../services/dialogflow_service.dart';
import '../services/suggestion_service.dart';
import '../services/chatbot_response_variations.dart';
import '../services/emotion_analysis_service.dart';
import '../services/conversation_manager.dart';
import '../services/settings_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/mood_buttons_chat.dart';
import '../services/chatbot_flow_service.dart';

class ChatbotScreen extends StatefulWidget {
  final Function(MoodType)? onMoodSelected;
  final Function(String)? onMusicSuggested;
  final Function(String)? onLightSuggested;
  final Function(String)? onEssentialOilSuggested;

  const ChatbotScreen({
    super.key,
    this.onMoodSelected,
    this.onMusicSuggested,
    this.onLightSuggested,
    this.onEssentialOilSuggested,
  });

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final List<String> _conversationHistory = [];
  bool _hasSelectedMood = false;
  bool _isLoading = false;
  MoodType? _currentMood;
  int? _currentIntensity;
  String? _currentContext;
  final ConversationManager _conversationManager = ConversationManager();

  // Track adjustment status
  bool _lastAdjustmentSuccess = false;
  DateTime? _lastAdjustmentTime;
  Map<String, dynamic>? _lastAppliedSuggestions;

  @override
  void initState() {
    super.initState();
    // Reset response variations when starting new conversation
    ChatbotResponseVariations.resetCounts();
    _conversationManager.reset();
    _loadGreeting();
  }

  Future<void> _loadGreeting() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final greeting = await DialogflowService.getGreetingMessage();
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(text: greeting, isBot: true, timestamp: DateTime.now()),
          );
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      print('Error loading greeting: $e');
      if (mounted) {
        setState(() {
          _messages.add(ChatbotService.getGreetingMessage());
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Detect mood from input (buttons or keywords)
  MoodType? _detectMoodFromInput(String input) {
    final inputLower = input.toLowerCase().trim();

    // Check for mood button labels
    for (final mood in MoodType.values) {
      final labelLower = mood.label.toLowerCase();
      // Check if input contains mood label or key parts
      if (inputLower.contains(labelLower) ||
          inputLower == mood.label.toLowerCase()) {
        return mood;
      }
    }

    // Check for mood keywords
    final moodKeywords = {
      MoodType.stressed: [
        'căng thẳng',
        'lo âu',
        'stress',
        'anxious',
        'worried',
        'nervous',
      ],
      MoodType.sad: ['buồn', 'trầm', 'sad', 'depressed', 'down', 'unhappy'],
      MoodType.tired: ['mệt', 'mệt mỏi', 'tired', 'exhausted', 'fatigue'],
      MoodType.insomnia: ['khó ngủ', 'mất ngủ', 'insomnia', 'sleepless'],
      MoodType.normal: [
        'bình thường',
        'tích cực',
        'vui',
        'ổn',
        'ok',
        'normal',
        'happy',
        'good',
      ],
    };

    for (final entry in moodKeywords.entries) {
      for (final keyword in entry.value) {
        if (inputLower.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return null;
  }

  // Provide suggestions directly without encouragement
  Future<void> _provideSuggestionsDirectly(MoodType mood) async {
    try {
      // Get suggestions from Dialogflow
      final suggestions = await DialogflowService.getSuggestions(mood);

      // Update suggestion service
      final suggestionService = SuggestionService();
      suggestionService.updateSuggestions(
        mood: mood,
        essentialOil: suggestions['essential_oil'],
        music: suggestions['music'],
        light: suggestions['light'],
      );

      // Get light suggestion details
      final lightSuggestion = ChatbotFlowService.getLightSuggestion(mood, null);

      // Create suggestion message with confirmation (skip encouragement)
      final suggestionMessage =
          ChatbotResponseVariations.getSuggestionMessageWithOptions(
            mood: mood,
            essentialOil: suggestions['essential_oil'] ?? mood.essentialOil,
            music: suggestions['music'] ?? 'Thiền',
            lightMode: lightSuggestion['mode'] as String,
            lightBrightness: lightSuggestion['brightness'] as double,
          );

      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: suggestionMessage,
              isBot: true,
              timestamp: DateTime.now(),
              needsConfirmation: true,
              suggestionData: {
                'essential_oil':
                    suggestions['essential_oil'] ?? mood.essentialOil,
                'music': suggestions['music'] ?? 'Thiền',
                'light_mode': lightSuggestion['mode'] as String,
                'light_brightness': lightSuggestion['brightness'] as double,
              },
            ),
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error providing suggestions: $e');
    }
  }

  // Provide alternative suggestions when user declines
  Future<void> _provideAlternativeSuggestions() async {
    if (_currentMood == null) return;

    try {
      final oils = ChatbotFlowService.getEssentialOilSuggestions(_currentMood!);
      final musicOptions = ChatbotFlowService.getMusicSuggestions(
        _currentMood!,
      );
      final lightSuggestion = ChatbotFlowService.getLightSuggestion(
        _currentMood!,
        null,
      );

      // Get alternative options (second choices)
      String alternativeOil = oils['primary']!.length > 1
          ? oils['primary']![1]
          : oils['primary']!.first;
      String alternativeMusic = musicOptions.length > 1
          ? musicOptions[1]['type']!
          : musicOptions.first['type']!;
      String alternativeLight = lightSuggestion['mode'] as String;

      // Try different light mode
      if (alternativeLight == 'warm') {
        alternativeLight = 'cool';
      } else if (alternativeLight == 'cool') {
        alternativeLight = 'warm';
      }

      final alternativeMessage =
          '\n\nMình gợi ý khác cho bạn:\n'
          '• Tinh dầu $alternativeOil\n'
          '• Nhạc $alternativeMusic\n'
          '• Đèn $alternativeLight\n\n'
          'Bạn muốn thử lựa chọn này không?';

      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'Không sao cả. Mình vẫn ở đây nếu bạn cần nhé.',
              isBot: true,
              timestamp: DateTime.now(),
            ),
          );
          _messages.add(
            ChatMessage(
              text: alternativeMessage,
              isBot: true,
              timestamp: DateTime.now(),
              needsConfirmation: true,
              suggestionData: {
                'essential_oil': alternativeOil,
                'music': alternativeMusic,
                'light_mode': alternativeLight,
                'light_brightness': lightSuggestion['brightness'] as double,
              },
            ),
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error providing alternative suggestions: $e');
    }
  }

  // Parse music request from user input
  String? _parseMusicRequest(String inputLower) {
    final musicKeywords = {
      'piano': ['piano', 'nhạc piano'],
      'ambient': ['ambient', 'nhạc ambient'],
      'thiền': ['thiền', 'meditation', 'zen'],
      'nature': ['nature', 'thiên nhiên', 'mưa', 'rain', 'ocean'],
      'lofi': ['lofi', 'lo-fi', 'lo fi'],
    };

    for (final entry in musicKeywords.entries) {
      for (final keyword in entry.value) {
        if (inputLower.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return null;
  }

  // Parse light color request from user input
  String? _parseLightRequest(String inputLower) {
    final lightKeywords = {
      'warm': ['warm', 'ấm', 'vàng', 'yellow', 'amber'],
      'cool': ['cool', 'mát', 'trắng', 'white', 'xanh', 'blue'],
      'red': ['đỏ', 'red'],
      'green': ['xanh lá', 'green'],
      'blue': ['xanh dương', 'blue'],
    };

    for (final entry in lightKeywords.entries) {
      for (final keyword in entry.value) {
        if (inputLower.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return null;
  }

  // Apply custom music/light request
  Future<void> _applyCustomRequest(
    String? musicRequest,
    String? lightRequest,
  ) async {
    if (_currentMood == null) return;

    try {
      // Get current suggestions
      final suggestions = await DialogflowService.getSuggestions(_currentMood!);
      final lightSuggestion = ChatbotFlowService.getLightSuggestion(
        _currentMood!,
        null,
      );

      // Update with custom requests
      String finalMusic = musicRequest ?? (suggestions['music'] ?? 'Thiền');
      String finalLight = lightRequest ?? (lightSuggestion['mode'] as String);

      // Map music request to proper format
      if (musicRequest != null) {
        final musicMap = {
          'piano': 'Nhạc Piano',
          'ambient': 'Ambient',
          'thiền': 'Thiền',
          'nature': 'Thiên nhiên',
          'lofi': 'Thiền',
        };
        finalMusic = musicMap[musicRequest] ?? finalMusic;
      }

      // Check automation settings before applying
      final autoLightEnabled = await SettingsService.getAutoLightEnabled();
      final autoMusicEnabled = await SettingsService.getAutoMusicEnabled();

      // Apply essential oil suggestion (always)
      widget.onEssentialOilSuggested?.call(
        suggestions['essential_oil'] ?? _currentMood!.essentialOil,
      );

      // Apply music only if auto music is enabled
      if (autoMusicEnabled) {
        widget.onMusicSuggested?.call(finalMusic);
      }

      // Apply light only if auto light is enabled
      if (autoLightEnabled) {
        widget.onLightSuggested?.call(finalLight);
      }

      // Mark as successful
      _lastAdjustmentSuccess = true;
      _lastAdjustmentTime = DateTime.now();
      _lastAppliedSuggestions = {
        'essential_oil':
            suggestions['essential_oil'] ?? _currentMood!.essentialOil,
        'music': finalMusic,
        'light_mode': finalLight,
      };

      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text:
                  'Ok, mình sẽ thực hiện cho bạn! 🎵💡\n\n'
                  'Mình đã điều chỉnh:\n'
                  '• Nhạc: $finalMusic\n'
                  '• Đèn: $finalLight\n'
                  '• Tinh dầu: ${suggestions['essential_oil'] ?? _currentMood!.essentialOil}',
              isBot: true,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error applying custom request: $e');
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text:
                  'Xin lỗi, mình gặp vấn đề khi điều chỉnh. Bạn có thể thử lại sau nhé.',
              isBot: true,
              timestamp: DateTime.now(),
            ),
          );
        });
      }
    }
  }

  void _handleConfirmation(bool confirmed) {
    if (confirmed) {
      // Add user's confirmation to messages
      setState(() {
        _messages.add(
          ChatMessage(text: 'Có', isBot: false, timestamp: DateTime.now()),
        );
      });
      _conversationHistory.add('Có');

      // Apply suggestions automatically
      _applySuggestionsAutomatically();
    } else {
      // Add user's decline to messages
      setState(() {
        _messages.add(
          ChatMessage(text: 'Không', isBot: false, timestamp: DateTime.now()),
        );
      });
      _conversationHistory.add('Không');

      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'Không sao cả. Mình vẫn ở đây nếu bạn cần nhé.',
              isBot: true,
              timestamp: DateTime.now(),
            ),
          );
        });
        _conversationHistory.add(
          'Không sao cả. Mình vẫn ở đây nếu bạn cần nhé.',
        );
        _scrollToBottom();
      }
    }
  }

  Future<void> _applySuggestionsAutomatically() async {
    print('🔵 Applying suggestions automatically...');

    // Find the last message with suggestion data
    ChatMessage? suggestionMessage;
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].needsConfirmation == true &&
          _messages[i].suggestionData != null) {
        suggestionMessage = _messages[i];
        print(
          '✅ Found suggestion message with data: ${suggestionMessage.suggestionData}',
        );
        break;
      }
    }

    if (suggestionMessage?.suggestionData != null) {
      final data = suggestionMessage!.suggestionData!;

      print(
        '🎵 Applying: Oil=${data['essential_oil']}, Music=${data['music']}, Light=${data['light_mode']}',
      );

      // Try to apply suggestions with error handling
      try {
        // Check automation settings before applying
        final autoLightEnabled = await SettingsService.getAutoLightEnabled();
        final autoMusicEnabled = await SettingsService.getAutoMusicEnabled();

        // Apply essential oil suggestion (always)
        widget.onEssentialOilSuggested?.call(data['essential_oil'] as String);

        // Apply music only if auto music is enabled
        if (autoMusicEnabled) {
          widget.onMusicSuggested?.call(data['music'] as String);
        }

        // Apply light only if auto light is enabled
        if (autoLightEnabled) {
          widget.onLightSuggested?.call(data['light_mode'] as String);
        }

        // Mark as successful
        _lastAdjustmentSuccess = true;
        _lastAdjustmentTime = DateTime.now();
        _lastAppliedSuggestions = Map<String, dynamic>.from(data);

        if (mounted) {
          setState(() {
            _messages.add(
              ChatMessage(
                text:
                    'Đã điều chỉnh xong rồi nhé! 🎵💡\n\n'
                    'Mình đã bật nhạc ${data['music']} và đèn ${data['light_mode']} cho bạn.\n'
                    'Tinh dầu ${data['essential_oil']} cũng đã được gợi ý.\n\n'
                    'Bạn cứ thả lỏng và thư giãn nhé. Nếu bạn muốn, bạn có thể tiếp tục chia sẻ với mình.',
                isBot: true,
                timestamp: DateTime.now(),
              ),
            );
          });
          _conversationHistory.add('Đã điều chỉnh xong.');
          _scrollToBottom();
        }
      } catch (e) {
        print('❌ Error applying suggestions: $e');
        _lastAdjustmentSuccess = false;

        // Provide manual guidance
        final brightness = ((data['light_brightness'] as double? ?? 0.5) * 100)
            .toInt();
        if (mounted) {
          setState(() {
            _messages.add(
              ChatMessage(
                text:
                    'Xin lỗi, mình gặp một chút vấn đề khi điều chỉnh tự động.\n\n'
                    'Bạn có thể tự điều chỉnh thủ công như sau:\n\n'
                    '• Tinh dầu: ${data['essential_oil']} - Vào thư viện tinh dầu để chọn\n'
                    '• Nhạc: ${data['music']} - Vào thư viện nhạc để phát\n'
                    '• Đèn: ${data['light_mode']} $brightness% - Vào cài đặt để điều chỉnh\n\n'
                    'Hoặc bạn có thể thử lại sau một chút nhé.',
                isBot: true,
                timestamp: DateTime.now(),
              ),
            );
          });
          _conversationHistory.add(
            'Gặp lỗi khi điều chỉnh, đã hướng dẫn thủ công.',
          );
          _scrollToBottom();
        }
      }
    } else {
      print('⚠️ No suggestion message found, trying fallback...');
      // Fallback: try to get suggestions from current mood
      if (_currentMood != null) {
        // Get default suggestions
        final suggestions = ChatbotFlowService.getEssentialOilSuggestions(
          _currentMood!,
        );
        final musicSuggestions = ChatbotFlowService.getMusicSuggestions(
          _currentMood!,
        );
        final lightSuggestion = ChatbotFlowService.getLightSuggestion(
          _currentMood!,
          _currentIntensity,
        );

        if (suggestions['primary']!.isNotEmpty && musicSuggestions.isNotEmpty) {
          print(
            '🎵 Fallback: Applying default suggestions for ${_currentMood!.label}',
          );

          try {
            // Check automation settings before applying
            final autoLightEnabled =
                await SettingsService.getAutoLightEnabled();
            final autoMusicEnabled =
                await SettingsService.getAutoMusicEnabled();

            // Apply essential oil suggestion (always)
            widget.onEssentialOilSuggested?.call(suggestions['primary']!.first);

            // Apply music only if auto music is enabled
            if (autoMusicEnabled) {
              widget.onMusicSuggested?.call(musicSuggestions.first['type']!);
            }

            // Apply light only if auto light is enabled
            if (autoLightEnabled) {
              widget.onLightSuggested?.call(lightSuggestion['mode'] as String);
            }

            _lastAdjustmentSuccess = true;
            _lastAdjustmentTime = DateTime.now();
            _lastAppliedSuggestions = {
              'essential_oil': suggestions['primary']!.first,
              'music': musicSuggestions.first['type']!,
              'light_mode': lightSuggestion['mode'] as String,
            };

            if (mounted) {
              setState(() {
                _messages.add(
                  ChatMessage(
                    text:
                        'Đã điều chỉnh xong rồi nhé! 🎵💡\n\n'
                        'Mình đã bật nhạc và đèn theo gợi ý cho bạn.',
                    isBot: true,
                    timestamp: DateTime.now(),
                  ),
                );
              });
              _scrollToBottom();
            }
          } catch (e) {
            print('❌ Error applying fallback suggestions: $e');
            _lastAdjustmentSuccess = false;
            if (mounted) {
              setState(() {
                _messages.add(
                  ChatMessage(
                    text:
                        'Xin lỗi, mình gặp vấn đề khi điều chỉnh. Bạn có thể tự điều chỉnh từ màn hình chính nhé.',
                    isBot: true,
                    timestamp: DateTime.now(),
                  ),
                );
              });
            }
          }
        } else {
          print('❌ No default suggestions available');
        }
      } else {
        print('❌ No current mood set');
      }
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(text: text.trim(), isBot: false, timestamp: DateTime.now()),
      );
    });

    _textController.clear();
    _scrollToBottom();

    // Simulate bot response
    Future.delayed(const Duration(milliseconds: 500), () {
      _handleUserInput(text.trim());
    });
  }

  Future<void> _handleUserInput(String input) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Check if this is a simple confirmation first (before calling Dialogflow)
    final inputLower = input.toLowerCase().trim();

    if (_hasSelectedMood) {
      // Check if there's a pending suggestion
      bool hasPendingSuggestion = false;
      for (int i = _messages.length - 1; i >= 0; i--) {
        if (_messages[i].needsConfirmation == true &&
            _messages[i].suggestionData != null) {
          hasPendingSuggestion = true;
          break;
        }
      }

      if (hasPendingSuggestion) {
        // Check for confirmation words (expanded list)
        final confirmationWords = [
          'có',
          'ok',
          'yes',
          'được',
          'vâng',
          'dạ',
          'ừ',
          'ừm',
          'okay',
          'đồng ý',
          'bật',
          'phát',
          'thử',
          'làm đi',
          'điều chỉnh',
          'được rồi',
          'ok rồi',
          'được đó',
          'thử xem',
          'làm thử',
        ];

        bool isConfirmation = false;
        for (final word in confirmationWords) {
          if (inputLower == word || inputLower.contains(word)) {
            isConfirmation = true;
            break;
          }
        }

        if (isConfirmation) {
          // User confirmed - apply suggestions immediately
          print('✅ User confirmed: $input');
          _conversationHistory.add(input);

          // Apply suggestions
          _applySuggestionsAutomatically();

          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            _scrollToBottom();
          }
          return; // Don't call Dialogflow
        } else if (inputLower == 'không' ||
            inputLower == 'no' ||
            inputLower.contains('thôi') ||
            inputLower.contains('không cần') ||
            inputLower.contains('đừng') ||
            inputLower.contains('chưa')) {
          // User declined
          _conversationHistory.add(input);
          if (mounted) {
            setState(() {
              _messages.add(
                ChatMessage(
                  text: 'Không sao cả. Mình vẫn ở đây nếu bạn cần nhé.',
                  isBot: true,
                  timestamp: DateTime.now(),
                ),
              );
              _isLoading = false;
            });
            _conversationHistory.add(
              'Không sao cả. Mình vẫn ở đây nếu bạn cần nhé.',
            );
            _scrollToBottom();
          }
          return; // Don't call Dialogflow
        }
      }

      // Check if user is asking about adjustment status
      final adjustmentStatusKeywords = [
        'đã điều chỉnh chưa',
        'điều chỉnh chưa',
        'đã bật chưa',
        'bật chưa',
        'đã phát chưa',
        'phát chưa',
        'đã làm chưa',
        'làm chưa',
        'xong chưa',
        'đã xong chưa',
        'đã hoàn thành chưa',
        'hoàn thành chưa',
      ];

      bool isAskingStatus = false;
      for (final keyword in adjustmentStatusKeywords) {
        if (inputLower.contains(keyword)) {
          isAskingStatus = true;
          break;
        }
      }

      if (isAskingStatus) {
        _conversationHistory.add(input);
        if (_lastAdjustmentSuccess && _lastAdjustmentTime != null) {
          // Check if adjustment was recent (within last 5 minutes)
          final timeSinceAdjustment = DateTime.now().difference(
            _lastAdjustmentTime!,
          );
          if (timeSinceAdjustment.inMinutes < 5) {
            if (mounted) {
              setState(() {
                String response =
                    'Mình đã điều chỉnh cho bạn rồi nhé! 🎵💡\n\n';
                if (_lastAppliedSuggestions != null) {
                  response += '• Nhạc: ${_lastAppliedSuggestions!['music']}\n';
                  response +=
                      '• Đèn: ${_lastAppliedSuggestions!['light_mode']}\n';
                  response +=
                      '• Tinh dầu: ${_lastAppliedSuggestions!['essential_oil']}\n\n';
                }
                response +=
                    'Bạn có thể kiểm tra trên màn hình chính. Nếu có vấn đề gì, hãy cho mình biết nhé.';

                _messages.add(
                  ChatMessage(
                    text: response,
                    isBot: true,
                    timestamp: DateTime.now(),
                  ),
                );
                _isLoading = false;
              });
              _conversationHistory.add('Đã điều chỉnh rồi.');
              _scrollToBottom();
            }
            return; // Don't call Dialogflow
          }
        }

        // If no recent successful adjustment
        if (mounted) {
          setState(() {
            _messages.add(
              ChatMessage(
                text:
                    'Mình chưa điều chỉnh gì cả. Bạn muốn mình điều chỉnh gì không?',
                isBot: true,
                timestamp: DateTime.now(),
              ),
            );
            _isLoading = false;
          });
          _scrollToBottom();
        }
        return; // Don't call Dialogflow
      }
    }

    // Add user message to conversation history
    _conversationHistory.add(input);

    // Check if input is a mood keyword (from buttons or text)
    MoodType? detectedMoodFromInput = _detectMoodFromInput(input);

    // If mood detected, skip Dialogflow and go straight to suggestions
    if (detectedMoodFromInput != null && !_hasSelectedMood) {
      _hasSelectedMood = true;
      _currentMood = detectedMoodFromInput;
      widget.onMoodSelected?.call(detectedMoodFromInput);

      // Skip encouragement, go straight to suggestions
      await _provideSuggestionsDirectly(detectedMoodFromInput);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
      return;
    }

    try {
      // Get response from Dialogflow
      final response = await DialogflowService.getResponse(
        input,
        conversationHistory: _conversationHistory,
      );

      // Add bot response to conversation history
      _conversationHistory.add(response);

      // Analyze mood if not already selected
      if (!_hasSelectedMood) {
        // Use detailed emotion analysis
        final now = DateTime.now();
        final hour = now.hour;
        String timeOfDay = 'afternoon';
        if (hour >= 5 && hour < 12) {
          timeOfDay = 'morning';
        } else if (hour >= 12 && hour < 17) {
          timeOfDay = 'afternoon';
        } else if (hour >= 17 && hour < 22) {
          timeOfDay = 'evening';
        } else {
          timeOfDay = 'night';
        }

        final emotionAnalysis = EmotionAnalysisService.analyze(
          userMessage: input,
          selfReport: _currentIntensity,
          timeOfDay: timeOfDay,
          recentMoods: [], // TODO: Track recent moods
          isCandleOn: false, // TODO: Get from device status
          isMusicPlaying: false, // TODO: Get from device status
        );

        final detectedMood = emotionAnalysis.primaryEmotion;

        if (detectedMood != null) {
          _hasSelectedMood = true;
          _currentMood = detectedMood;
          _currentIntensity = emotionAnalysis.intensityLevel;
          widget.onMoodSelected?.call(detectedMood);

          // Check for safety flags
          if (emotionAnalysis.shouldActivateSafety) {
            if (mounted) {
              setState(() {
                _messages.add(
                  ChatMessage(
                    text: ChatbotFlowService.getSafetyMessage(),
                    isBot: true,
                    timestamp: DateTime.now(),
                  ),
                );
              });
            }
          }

          // Get suggestions from Dialogflow (with ESS context)
          final suggestions = await DialogflowService.getSuggestions(
            detectedMood,
          );

          // Update suggestion service
          final suggestionService = SuggestionService();
          suggestionService.updateSuggestions(
            mood: detectedMood,
            essentialOil: suggestions['essential_oil'],
            music: suggestions['music'],
            light: suggestions['light'],
          );

          // Store context for future use (may be used for alternative suggestions)
          _currentContext = input;

          // Skip encouragement messages - go straight to suggestions
          // Get light suggestion details (with ESS)
          final lightSuggestion = ChatbotFlowService.getLightSuggestion(
            detectedMood,
            emotionAnalysis.intensityLevel,
            ess: emotionAnalysis.ess,
          );

          // Create suggestion message with confirmation (skip encouragement)
          final suggestionMessage =
              ChatbotResponseVariations.getSuggestionMessageWithOptions(
                mood: detectedMood,
                essentialOil:
                    suggestions['essential_oil'] ?? detectedMood.essentialOil,
                music: suggestions['music'] ?? 'Thiền',
                lightMode: lightSuggestion['mode'] as String,
                lightBrightness: lightSuggestion['brightness'] as double,
              );

          // Only add suggestion message if not in high risk
          if (!emotionAnalysis.shouldActivateSafety) {
            if (mounted) {
              setState(() {
                _messages.add(
                  ChatMessage(
                    text: suggestionMessage,
                    isBot: true,
                    timestamp: DateTime.now(),
                    needsConfirmation: true,
                    suggestionData: {
                      'essential_oil':
                          suggestions['essential_oil'] ??
                          detectedMood.essentialOil,
                      'music': suggestions['music'] ?? 'Thiền',
                      'light_mode': lightSuggestion['mode'] as String,
                      'light_brightness':
                          lightSuggestion['brightness'] as double,
                    },
                  ),
                );
              });
            }
          }
        } else {
          // Just add bot response without suggestions
          // Check for repetition and get variation if needed
          String finalResponse = response;
          if (_conversationManager.isResponseRepetitive(response)) {
            finalResponse = _conversationManager.getVariation(
              response,
              context: _conversationManager.getConversationSummary(),
            );
          }

          // Track response to prevent future repetition
          _conversationManager.addResponse(finalResponse);

          if (mounted) {
            setState(() {
              _messages.add(
                ChatMessage(
                  text: finalResponse,
                  isBot: true,
                  timestamp: DateTime.now(),
                ),
              );
            });
          }
        }
      } else {
        // Mood already selected, check if user is confirming or continuing conversation
        final inputLower = input.toLowerCase().trim();

        // Check if there's a pending suggestion that needs confirmation
        bool hasPendingSuggestion = false;
        for (int i = _messages.length - 1; i >= 0; i--) {
          if (_messages[i].needsConfirmation == true &&
              _messages[i].suggestionData != null) {
            hasPendingSuggestion = true;
            break;
          }
        }

        // Check for confirmation words (expanded list)
        final confirmationWords = [
          'có',
          'ok',
          'yes',
          'được',
          'vâng',
          'dạ',
          'ừ',
          'ừm',
          'okay',
          'đồng ý',
          'bật',
          'phát',
          'thử',
          'làm đi',
          'điều chỉnh',
          'được rồi',
          'ok rồi',
          'được đó',
          'thử xem',
          'làm thử',
        ];

        bool isConfirmation = false;
        for (final word in confirmationWords) {
          if (inputLower == word || inputLower.contains(word)) {
            isConfirmation = true;
            break;
          }
        }

        if (hasPendingSuggestion && isConfirmation) {
          // User confirmed, apply suggestions automatically
          print('✅ User confirmed via text input: $input');
          _conversationHistory.add(input);
          _applySuggestionsAutomatically();

          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            _scrollToBottom();
          }
          return; // Don't call Dialogflow
        } else if (hasPendingSuggestion &&
            (inputLower == 'không' ||
                inputLower == 'no' ||
                inputLower.contains('thôi') ||
                inputLower.contains('không cần') ||
                inputLower.contains('đừng') ||
                inputLower.contains('chưa'))) {
          // User declined - provide alternative suggestions
          _conversationHistory.add(input);
          await _provideAlternativeSuggestions();

          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            _scrollToBottom();
          }
          return; // Don't call Dialogflow
        }

        // Check if user is requesting different music or light color
        if (hasPendingSuggestion && _currentMood != null) {
          final musicRequest = _parseMusicRequest(inputLower);
          final lightRequest = _parseLightRequest(inputLower);

          if (musicRequest != null || lightRequest != null) {
            // User wants different music or light
            _conversationHistory.add(input);
            await _applyCustomRequest(musicRequest, lightRequest);

            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              _scrollToBottom();
            }
            return; // Don't call Dialogflow
          }
        }

        // Check if user is asking about adjustment status
        final adjustmentStatusKeywords = [
          'đã điều chỉnh chưa',
          'điều chỉnh chưa',
          'đã bật chưa',
          'bật chưa',
          'đã phát chưa',
          'phát chưa',
          'đã làm chưa',
          'làm chưa',
          'xong chưa',
          'đã xong chưa',
          'đã hoàn thành chưa',
          'hoàn thành chưa',
        ];

        bool isAskingStatus = false;
        for (final keyword in adjustmentStatusKeywords) {
          if (inputLower.contains(keyword)) {
            isAskingStatus = true;
            break;
          }
        }

        if (isAskingStatus) {
          _conversationHistory.add(input);
          if (_lastAdjustmentSuccess && _lastAdjustmentTime != null) {
            // Check if adjustment was recent (within last 5 minutes)
            final timeSinceAdjustment = DateTime.now().difference(
              _lastAdjustmentTime!,
            );
            if (timeSinceAdjustment.inMinutes < 5) {
              if (mounted) {
                setState(() {
                  String response =
                      'Mình đã điều chỉnh cho bạn rồi nhé! 🎵💡\n\n';
                  if (_lastAppliedSuggestions != null) {
                    response +=
                        '• Nhạc: ${_lastAppliedSuggestions!['music']}\n';
                    response +=
                        '• Đèn: ${_lastAppliedSuggestions!['light_mode']}\n';
                    response +=
                        '• Tinh dầu: ${_lastAppliedSuggestions!['essential_oil']}\n\n';
                  }
                  response +=
                      'Bạn có thể kiểm tra trên màn hình chính. Nếu có vấn đề gì, hãy cho mình biết nhé.';

                  _messages.add(
                    ChatMessage(
                      text: response,
                      isBot: true,
                      timestamp: DateTime.now(),
                    ),
                  );
                  _isLoading = false;
                });
                _conversationHistory.add('Đã điều chỉnh rồi.');
                _scrollToBottom();
              }
              return; // Don't call Dialogflow
            }
          }

          // If no recent successful adjustment
          if (mounted) {
            setState(() {
              _messages.add(
                ChatMessage(
                  text:
                      'Mình chưa điều chỉnh gì cả. Bạn muốn mình điều chỉnh gì không?',
                  isBot: true,
                  timestamp: DateTime.now(),
                ),
              );
              _isLoading = false;
            });
            _scrollToBottom();
          }
          return; // Don't call Dialogflow
        }
      }

      // Continue conversation - use varied response if mood is known
      String finalResponse = response;
      if (_currentMood != null) {
        // Try to use varied response for better conversation
        final variedResponse = ChatbotResponseVariations.getResponseForMood(
          _currentMood!,
          _currentIntensity,
          input,
        );
        // Only use varied response if it's different from Dialogflow response
        if (variedResponse != response && variedResponse.isNotEmpty) {
          finalResponse = variedResponse;
        }
      }

      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: finalResponse,
              isBot: true,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
        _conversationHistory.add(finalResponse);
        _scrollToBottom();
      }
    } catch (e, stackTrace) {
      print('❌ Error handling user input: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _isLoading = false;

          // Use fallback response instead of error message
          final fallbackResponse = DialogflowService.getFallbackResponse(input);

          _messages.add(
            ChatMessage(
              text: fallbackResponse,
              isBot: true,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _selectMoodQuickly(MoodType mood) async {
    if (_hasSelectedMood || _isLoading) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: '${mood.emoji} ${mood.label}',
          isBot: false,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });

    _hasSelectedMood = true;
    _currentMood = mood;
    widget.onMoodSelected?.call(mood);

    // Skip encouragement, go straight to suggestions
    await _provideSuggestionsDirectly(mood);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chatbot Tâm Lý',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: Container(
              color: Colors.lightBlue[50],
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isFirstMessage = index == 0 && message.isBot;
                  return Column(
                    children: [
                      ChatBubble(
                        message: message,
                        onConfirmation: message.needsConfirmation == true
                            ? (confirmed) {
                                if (confirmed) {
                                  _handleConfirmation(true);
                                } else {
                                  _handleConfirmation(false);
                                }
                              }
                            : null,
                      ),
                      // Show mood buttons only after the first bot message and if mood not selected
                      if (isFirstMessage && !_hasSelectedMood)
                        MoodButtonsChat(onMoodSelected: _selectMoodQuickly),
                    ],
                  );
                },
              ),
            ),
          ),

          // Input field
          Container(
            decoration: BoxDecoration(color: Colors.white),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: 'Nhập tin nhắn...',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            hintStyle: TextStyle(color: Colors.grey[400]),
                          ),
                          onSubmitted: _sendMessage,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.lightBlue[300],
                        shape: BoxShape.circle,
                      ),
                      child: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.arrow_upward,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : () => _sendMessage(_textController.text),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
