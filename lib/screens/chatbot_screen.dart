import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/mood_type.dart';
import '../services/chatbot_service.dart';
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
  bool _hasSelectedMood = false;

  @override
  void initState() {
    super.initState();
    _messages.add(ChatbotService.getGreetingMessage());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
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

  void _handleUserInput(String input) {
    // Simple mood detection
    MoodType? detectedMood;
    final lowerInput = input.toLowerCase();

    if (lowerInput.contains('căng thẳng') || 
        lowerInput.contains('lo âu') ||
        lowerInput.contains('stress')) {
      detectedMood = MoodType.stressed;
    } else if (lowerInput.contains('buồn') || 
               lowerInput.contains('trầm')) {
      detectedMood = MoodType.sad;
    } else if (lowerInput.contains('mệt') || 
               lowerInput.contains('mệt mỏi')) {
      detectedMood = MoodType.tired;
    } else if (lowerInput.contains('khó ngủ') || 
               lowerInput.contains('mất ngủ')) {
      detectedMood = MoodType.insomnia;
    } else if (lowerInput.contains('tốt') || 
               lowerInput.contains('bình thường') ||
               lowerInput.contains('ok')) {
      detectedMood = MoodType.normal;
    }

    if (detectedMood != null && !_hasSelectedMood) {
      _hasSelectedMood = true;
      final suggestions = ChatbotService.analyzeMoodAndSuggest(detectedMood);
      
      setState(() {
        _messages.addAll(suggestions);
      });

      widget.onMoodSelected?.call(detectedMood);

      // Extract suggestions for device control
      for (var msg in suggestions) {
        if (msg.suggestionType == 'music' && msg.text.contains('bật nhạc')) {
          final musicMatch = RegExp(r'nhạc (\w+ [\w ]+)').firstMatch(msg.text);
          if (musicMatch != null) {
            widget.onMusicSuggested?.call(musicMatch.group(1) ?? '');
          }
        } else if (msg.suggestionType == 'light') {
          final lightMode = ChatbotService.getLightSuggestion(detectedMood);
          widget.onLightSuggested?.call(lightMode);
        }
      }

      _scrollToBottom();
    } else if (!_hasSelectedMood) {
      // Ask again if mood not detected
      setState(() {
        _messages.add(ChatMessage(
          text: 'Mình chưa hiểu rõ cảm xúc của bạn. Bạn có thể cho mình biết bạn đang cảm thấy căng thẳng, buồn, mệt mỏi, khó ngủ hay bình thường không?',
          isBot: true,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    }
  }

  void _selectMoodQuickly(MoodType mood) {
    if (_hasSelectedMood) return;

    setState(() {
      _messages.add(ChatMessage(
        text: '${mood.emoji} ${mood.label}',
        isBot: false,
        timestamp: DateTime.now(),
      ));
    });

    _hasSelectedMood = true;
    final suggestions = ChatbotService.analyzeMoodAndSuggest(mood);
    
    setState(() {
      _messages.addAll(suggestions);
    });

    widget.onMoodSelected?.call(mood);

    _scrollToBottom();
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
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_upward,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => _sendMessage(_textController.text),
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

