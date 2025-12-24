import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/mood_type.dart';
import '../services/chatbot_service.dart';
import '../services/dialogflow_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/mood_buttons_chat.dart';

class ChatbotScreen extends StatefulWidget {
  final Function(MoodType)? onMoodSelected;
  final Function(String)? onMusicSuggested;
  final Function(String)? onLightSuggested;

  const ChatbotScreen({
    super.key,
    this.onMoodSelected,
    this.onMusicSuggested,
    this.onLightSuggested,
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

  @override
  void initState() {
    super.initState();
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
      widget.onMoodSelected?.call(detectedMood);

          // Get suggestions from Dialogflow
          final suggestions = await DialogflowService.getSuggestions(detectedMood);
          
          // Add bot response
          if (mounted) {
            setState(() {
              _messages.add(ChatMessage(
                text: response,
                isBot: true,
                timestamp: DateTime.now(),
              ));
            });
          }

          // Add suggestions
          if (mounted) {
            setState(() {
              // Essential oil suggestion
              _messages.add(ChatMessage(
                text: 'Mình đề xuất bạn dùng tinh dầu ${suggestions['essential_oil']} để thư giãn. Hãy thắp nến trong 20–30 phút.',
                isBot: true,
                timestamp: DateTime.now(),
                suggestionType: 'essential_oil',
              ));

              // Music suggestion
              _messages.add(ChatMessage(
                text: 'Mình sẽ bật nhạc ${suggestions['music']} nhẹ nhàng giúp bạn bình tĩnh hơn nhé.',
                isBot: true,
                timestamp: DateTime.now(),
                suggestionType: 'music',
              ));

              // Light suggestion
              final lightMode = suggestions['light'] ?? 'warm';
              _messages.add(ChatMessage(
                text: 'Mình sẽ điều chỉnh ánh sáng ${ChatbotService.getLightLabel(lightMode)} để tạo không gian thư giãn cho bạn.',
                isBot: true,
                timestamp: DateTime.now(),
                suggestionType: 'light',
              ));
            });

            // Trigger callbacks for device control
            widget.onMusicSuggested?.call(suggestions['music'] ?? 'Thiền');
            widget.onLightSuggested?.call(suggestions['light'] ?? 'warm');
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
        // Mood already selected, just add response
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

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      _scrollToBottom();
      }
    } catch (e, stackTrace) {
      print('❌ Error handling user input: $e');
      print('Stack trace: $stackTrace');
      
      if (mounted) {
      setState(() {
          _isLoading = false;
          
          // Provide more specific error message
          String errorMessage = 'Xin lỗi, có lỗi xảy ra. Vui lòng thử lại sau.';
          final errorStr = e.toString().toLowerCase();
          
          if (errorStr.contains('api_key') || errorStr.contains('invalid')) {
            errorMessage = 'Xin lỗi, có lỗi với API key. Vui lòng kiểm tra cấu hình.';
          } else if (errorStr.contains('quota') || errorStr.contains('limit')) {
            errorMessage = 'Xin lỗi, API đã đạt giới hạn. Vui lòng thử lại sau.';
          } else if (errorStr.contains('network') || errorStr.contains('connection')) {
            errorMessage = 'Xin lỗi, không thể kết nối. Vui lòng kiểm tra internet.';
          }
          
        _messages.add(ChatMessage(
            text: errorMessage,
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
    widget.onMoodSelected?.call(mood);

    try {
      // Get response and suggestions from Dialogflow
      final response = await DialogflowService.getResponse('Tôi cảm thấy ${mood.label.toLowerCase()}');
      final suggestions = await DialogflowService.getSuggestions(mood);

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: response,
            isBot: true,
            timestamp: DateTime.now(),
          ));

          // Essential oil suggestion
          _messages.add(ChatMessage(
            text: 'Mình đề xuất bạn dùng tinh dầu ${suggestions['essential_oil']} để thư giãn. Hãy thắp nến trong 20–30 phút.',
            isBot: true,
            timestamp: DateTime.now(),
            suggestionType: 'essential_oil',
          ));

          // Music suggestion
          _messages.add(ChatMessage(
            text: 'Mình sẽ bật nhạc ${suggestions['music']} nhẹ nhàng giúp bạn bình tĩnh hơn nhé.',
            isBot: true,
            timestamp: DateTime.now(),
            suggestionType: 'music',
          ));

          // Light suggestion
          final lightMode = suggestions['light'] ?? 'warm';
          _messages.add(ChatMessage(
            text: 'Mình sẽ điều chỉnh ánh sáng ${ChatbotService.getLightLabel(lightMode)} để tạo không gian thư giãn cho bạn.',
            isBot: true,
            timestamp: DateTime.now(),
            suggestionType: 'light',
          ));

          _isLoading = false;
        });

        // Trigger callbacks
        final lightMode = suggestions['light'] ?? 'warm';
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
                      ChatBubble(message: message),
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

