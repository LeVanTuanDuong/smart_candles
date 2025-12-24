import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/mood_type.dart';
import '../services/chatbot_service.dart';
import '../services/dialogflow_service.dart';
import '../services/suggestion_service.dart';
import '../services/chatbot_response_variations.dart';
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

  @override
  void initState() {
    super.initState();
    // Reset response variations when starting new conversation
    ChatbotResponseVariations.resetCounts();
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
          _messages.add(ChatMessage(
            text: greeting,
            isBot: true,
            timestamp: DateTime.now(),
          ));
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

  void _handleConfirmation(bool confirmed) {
    if (confirmed) {
      // Add user's confirmation to messages
      setState(() {
        _messages.add(ChatMessage(
          text: 'Có',
          isBot: false,
          timestamp: DateTime.now(),
        ));
      });
      _conversationHistory.add('Có');
      
      // Apply suggestions automatically
      _applySuggestionsAutomatically();
    } else {
      // Add user's decline to messages
      setState(() {
        _messages.add(ChatMessage(
          text: 'Không',
          isBot: false,
          timestamp: DateTime.now(),
        ));
      });
      _conversationHistory.add('Không');
      
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: 'Không sao cả. Mình vẫn ở đây nếu bạn cần nhé.',
            isBot: true,
            timestamp: DateTime.now(),
          ));
        });
        _conversationHistory.add('Không sao cả. Mình vẫn ở đây nếu bạn cần nhé.');
        _scrollToBottom();
      }
    }
  }

  void _applySuggestionsAutomatically() {
    print('🔵 Applying suggestions automatically...');
    
    // Find the last message with suggestion data
    ChatMessage? suggestionMessage;
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].needsConfirmation == true && _messages[i].suggestionData != null) {
        suggestionMessage = _messages[i];
        print('✅ Found suggestion message with data: ${suggestionMessage.suggestionData}');
        break;
      }
    }
    
    if (suggestionMessage?.suggestionData != null) {
      final data = suggestionMessage!.suggestionData!;
      
      print('🎵 Applying: Oil=${data['essential_oil']}, Music=${data['music']}, Light=${data['light_mode']}');
      
      // Apply suggestions automatically
      widget.onEssentialOilSuggested?.call(data['essential_oil'] as String);
      widget.onMusicSuggested?.call(data['music'] as String);
      widget.onLightSuggested?.call(data['light_mode'] as String);
      
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: 'Đã bật nhạc và đèn theo gợi ý. Bạn cứ thả lỏng nhé 🎵💡\n\n'
                'Nếu bạn muốn, bạn có thể tiếp tục chia sẻ với mình.',
            isBot: true,
            timestamp: DateTime.now(),
          ));
        });
        _conversationHistory.add('Đã bật nhạc và đèn theo gợi ý.');
        _scrollToBottom();
      }
    } else {
      print('⚠️ No suggestion message found, trying fallback...');
      // Fallback: try to get suggestions from current mood
      if (_currentMood != null) {
        // Get default suggestions
        final suggestions = ChatbotFlowService.getEssentialOilSuggestions(_currentMood!);
        final musicSuggestions = ChatbotFlowService.getMusicSuggestions(_currentMood!);
        final lightSuggestion = ChatbotFlowService.getLightSuggestion(_currentMood!, _currentIntensity);
        
        if (suggestions['primary']!.isNotEmpty && musicSuggestions.isNotEmpty) {
          print('🎵 Fallback: Applying default suggestions for ${_currentMood!.label}');
          widget.onEssentialOilSuggested?.call(suggestions['primary']!.first);
          widget.onMusicSuggested?.call(musicSuggestions.first['type']!);
          widget.onLightSuggested?.call(lightSuggestion['mode'] as String);
          
          if (mounted) {
            setState(() {
              _messages.add(ChatMessage(
                text: 'Đã bật nhạc và đèn theo gợi ý. Bạn cứ thả lỏng nhé 🎵💡',
                isBot: true,
                timestamp: DateTime.now(),
              ));
            });
            _scrollToBottom();
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
      _messages.add(ChatMessage(
        text: text.trim(),
        isBot: false,
        timestamp: DateTime.now(),
      ));
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
        if (_messages[i].needsConfirmation == true && _messages[i].suggestionData != null) {
          hasPendingSuggestion = true;
          break;
        }
      }
      
      if (hasPendingSuggestion) {
        if (inputLower == 'có' || 
            inputLower == 'ok' || 
            inputLower == 'yes' ||
            inputLower.contains('đồng ý') || 
            inputLower.contains('bật') ||
            inputLower.contains('phát')) {
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
                   inputLower.contains('không cần')) {
          // User declined
          _conversationHistory.add(input);
          if (mounted) {
            setState(() {
              _messages.add(ChatMessage(
                text: 'Không sao cả. Mình vẫn ở đây nếu bạn cần nhé.',
                isBot: true,
                timestamp: DateTime.now(),
              ));
              _isLoading = false;
            });
            _conversationHistory.add('Không sao cả. Mình vẫn ở đây nếu bạn cần nhé.');
            _scrollToBottom();
          }
          return; // Don't call Dialogflow
        }
      }
    }

    // Add user message to conversation history
    _conversationHistory.add(input);

    try {
      // Get response from Dialogflow
      final response = await DialogflowService.getResponse(input, conversationHistory: _conversationHistory);
      
      // Add bot response to conversation history
      _conversationHistory.add(response);

      // Analyze mood if not already selected
      if (!_hasSelectedMood) {
        final detectedMood = await DialogflowService.analyzeMood(input);
        
        if (detectedMood != null) {
          _hasSelectedMood = true;
          _currentMood = detectedMood;
          widget.onMoodSelected?.call(detectedMood);

          // Get suggestions from Dialogflow
          final suggestions = await DialogflowService.getSuggestions(detectedMood);
          
          // Update suggestion service
          final suggestionService = SuggestionService();
          suggestionService.updateSuggestions(
            mood: detectedMood,
            essentialOil: suggestions['essential_oil'],
            music: suggestions['music'],
            light: suggestions['light'],
          );
          
          // Store context for future use
          _currentContext = input;
          
          // Use varied response instead of Dialogflow response
          final variedResponse = ChatbotResponseVariations.getResponseForMood(
            detectedMood,
            _currentIntensity,
            _currentContext,
          );
          
          // Get light suggestion details
          final lightSuggestion = ChatbotFlowService.getLightSuggestion(
            detectedMood,
            _currentIntensity,
          );
          
          // Create suggestion message with confirmation
          final suggestionMessage = ChatbotResponseVariations.getSuggestionMessageWithOptions(
            mood: detectedMood,
            essentialOil: suggestions['essential_oil'] ?? detectedMood.essentialOil,
            music: suggestions['music'] ?? 'Thiền',
            lightMode: lightSuggestion['mode'] as String,
            lightBrightness: lightSuggestion['brightness'] as double,
          );
          
          // Add main response
          if (mounted) {
            setState(() {
              _messages.add(ChatMessage(
                text: variedResponse,
                isBot: true,
                timestamp: DateTime.now(),
              ));
              
              // Add suggestion message with confirmation buttons
              _messages.add(ChatMessage(
                text: suggestionMessage,
                isBot: true,
                timestamp: DateTime.now(),
                needsConfirmation: true,
                suggestionData: {
                  'essential_oil': suggestions['essential_oil'] ?? detectedMood.essentialOil,
                  'music': suggestions['music'] ?? 'Thiền',
                  'light_mode': lightSuggestion['mode'] as String,
                  'light_brightness': lightSuggestion['brightness'] as double,
                },
              ));
            });
          }
        } else {
          // Just add bot response without suggestions
          if (mounted) {
            setState(() {
              _messages.add(ChatMessage(
                text: response,
                isBot: true,
                timestamp: DateTime.now(),
              ));
            });
          }
        }
      } else {
        // Mood already selected, check if user is confirming or continuing conversation
        final inputLower = input.toLowerCase().trim();
        
        // Check if there's a pending suggestion that needs confirmation
        bool hasPendingSuggestion = false;
        for (int i = _messages.length - 1; i >= 0; i--) {
          if (_messages[i].needsConfirmation == true && _messages[i].suggestionData != null) {
            hasPendingSuggestion = true;
            break;
          }
        }
        
        if (hasPendingSuggestion && 
            (inputLower == 'có' || 
             inputLower == 'ok' || 
             inputLower == 'yes' ||
             inputLower.contains('đồng ý') || 
             inputLower.contains('bật') ||
             inputLower.contains('phát'))) {
          // User confirmed, apply suggestions automatically
          print('✅ User confirmed via text input: $input');
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
                    inputLower.contains('không cần'))) {
          // User declined
          _conversationHistory.add(input);
          if (mounted) {
            setState(() {
              _messages.add(ChatMessage(
                text: 'Không sao cả. Mình vẫn ở đây nếu bạn cần nhé.',
                isBot: true,
                timestamp: DateTime.now(),
              ));
              _isLoading = false;
            });
            _conversationHistory.add('Không sao cả. Mình vẫn ở đây nếu bạn cần nhé.');
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
          _messages.add(ChatMessage(
            text: finalResponse,
            isBot: true,
            timestamp: DateTime.now(),
          ));
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
          
          _messages.add(ChatMessage(
            text: fallbackResponse,
            isBot: true,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _selectMoodQuickly(MoodType mood) async {
    if (_hasSelectedMood || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(
        text: '${mood.emoji} ${mood.label}',
        isBot: false,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _hasSelectedMood = true;
    _currentMood = mood;
    widget.onMoodSelected?.call(mood);

    try {
      // Get response and suggestions from Dialogflow
      final response = await DialogflowService.getResponse('Tôi cảm thấy ${mood.label.toLowerCase()}');
      final suggestions = await DialogflowService.getSuggestions(mood);
      
      // Update suggestion service
      final suggestionService = SuggestionService();
      suggestionService.updateSuggestions(
        mood: mood,
        essentialOil: suggestions['essential_oil'],
        music: suggestions['music'],
        light: suggestions['light'],
      );

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: response,
            isBot: true,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });

        // Automatically apply suggestions without showing messages
        // These callbacks will trigger device control automatically
        final lightMode = suggestions['light'] ?? 'warm';
        widget.onEssentialOilSuggested?.call(suggestions['essential_oil'] ?? mood.essentialOil);
        widget.onMusicSuggested?.call(suggestions['music'] ?? 'Thiền');
        widget.onLightSuggested?.call(lightMode);
        _scrollToBottom();
      }
    } catch (e) {
      print('Error getting suggestions: $e');
      // Fallback to default suggestions
      if (mounted) {
        final suggestions = ChatbotService.analyzeMoodAndSuggest(mood);
        setState(() {
          _messages.addAll(suggestions);
          _isLoading = false;
        });
    _scrollToBottom();
      }
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
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
                        MoodButtonsChat(
                          onMoodSelected: _selectMoodQuickly,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Input field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                            ),
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
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : IconButton(
                        icon: const Icon(
                          Icons.arrow_upward,
                          color: Colors.white,
                          size: 20,
                        ),
                              onPressed: _isLoading ? null : () => _sendMessage(_textController.text),
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

