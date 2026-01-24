import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/mood_type.dart';
import '../services/chatbot_service.dart';
import '../services/conversation_manager.dart';
import '../services/model_manager_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/mood_buttons_chat.dart';

class ChatbotScreen extends StatefulWidget {
  final Function(MoodType)? onMoodSelected;
  final Function(String)? onMusicSuggested;
  final Function(String)? onLightSuggested;
  final Function(String)? onEssentialOilSuggested;
  final String? initialMessage;

  const ChatbotScreen({
    super.key,
    this.onMoodSelected,
    this.onMusicSuggested,
    this.onLightSuggested,
    this.onEssentialOilSuggested,
    this.initialMessage,
  });

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final List<String> _conversationHistory = [];
  bool _hasSelectedMood = false;
  bool _isLoading = false;
  bool _gemmaReady = false;

  final ConversationManager _conversationManager = ConversationManager();

  double? _downloadProgress;

  @override
  void initState() {
    super.initState();
    // Reset conversation manager
    _conversationManager.reset();
    _loadGreeting();
  }

  @override
  bool get wantKeepAlive => true;

  Future<bool> _ensureGemmaReady() async {
    if (_gemmaReady) return true;
    if (mounted) {
      setState(() {
        _downloadProgress = 0.0;
      });
    }
    final isReady = await ModelManagerService().isGemmaModelReady(
      onProgress: (progress) {
        if (!mounted) return;
        setState(() {
          _downloadProgress = progress;
        });
      },
    );
    if (mounted) {
      setState(() {
        _downloadProgress = null;
        _gemmaReady = isReady;
      });
    }
    if (!isReady) {
      print("Error: Gemma model not found in assets or could not be copied.");
    } else {
      print("Gemma Model is ready.");
    }
    return isReady;
  }

  Future<void> _loadGreeting() async {
    setState(() {
      _isLoading = true;
    });

    // Use ChatbotService for greeting
    final greetingMessage = ChatbotService.getCheckInGreeting();
    if (mounted) {
      setState(() {
        _messages.add(
          ChatMessage(
              text: greetingMessage, isBot: true, timestamp: DateTime.now()),
        );
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
        // If there's an initial message, send it automatically after greeting
        if (widget.initialMessage != null &&
            widget.initialMessage!.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _sendMessage(widget.initialMessage!);
            }
          });
        }
      });
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

    // Add user message to conversation history
    _conversationHistory.add(input);

    try {
      await _ensureGemmaReady();
      // Process message using Pure AI ChatbotService
      final result = await ChatbotService.processUserMessage(input);
      final responseType = result['type'];
      final messageText = result['message'] as String;

      if (responseType == 'action') {
        final intent = result['intent'] as String;

        // Execute Action
        _executeIntentAction(intent);

        // Show confirmation message
        if (mounted) {
          setState(() {
            _messages.add(
              ChatMessage(
                text: messageText,
                isBot: true,
                timestamp: DateTime.now(),
              ),
            );
            _isLoading = false;
          });
          _scrollToBottom();
        }
      } else {
        // Normal text response
        if (mounted) {
          setState(() {
            _messages.add(
              ChatMessage(
                text: messageText,
                isBot: true,
                timestamp: DateTime.now(),
              ),
            );
            _isLoading = false;
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      print('Error in chatbot handling: $e');
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: "Xin lỗi, mình gặp chút vấn đề. Bạn thử lại nhé.",
              isBot: true,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
      }
    }
  }

  void _executeIntentAction(String intent) {
    // Map intent string to actual Service calls
    switch (intent) {
      case 'LIGHT_ON':
        widget.onLightSuggested?.call('warm'); // Default warm
        break;
      case 'LIGHT_OFF':
        // Implementing LIGHT_OFF might require sending specific command or brightness 0
        break;
      case 'LIGHT_COLOR':
        // Toggle or cycle colors?
        widget.onLightSuggested?.call('cool');
        break;
      case 'MUSIC_ON':
        widget.onMusicSuggested?.call('Thiền'); // Default logic
        break;
      case 'MUSIC_OFF':
        // Stop music logic
        break;
      case 'MUSIC_CHANGE':
        // Change track logic
        break;
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
    widget.onMoodSelected?.call(mood);

    // Skip encouragement, go straight to suggestions
    _handleUserInput('Tôi đang cảm thấy ${mood.label}');

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _handleConfirmation(bool confirmed) {
    if (confirmed) {
      _handleUserInput('Có');
    } else {
      _handleUserInput('Không');
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
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chatbot Tâm Lý',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        bottom: _downloadProgress != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4.0),
                child: LinearProgressIndicator(value: _downloadProgress),
              )
            : null,
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
