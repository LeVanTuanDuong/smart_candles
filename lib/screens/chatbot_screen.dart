import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/mood_type.dart';
import '../services/chatbot_service.dart';
import '../services/conversation_manager.dart';
import '../services/ai_inference_service.dart'; // Ensure this is imported for analyzeFaceEmotion
import '../services/chat_history_service.dart'; // Import History Service
import 'chat_history_screen.dart'; // Import History Screen
import '../widgets/chat_bubble.dart';
import '../widgets/mood_buttons_chat.dart';

class ChatbotScreen extends StatefulWidget {
  final Function(MoodType)? onMoodSelected;
  final Function(String)? onMusicSuggested;
  final Function(String, {double? brightness})? onLightSuggested;
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

  // Face Emotion State
  String? _detectedFaceEmotion;
  final ImagePicker _picker = ImagePicker();

  final ConversationManager _conversationManager = ConversationManager();

  @override
  void initState() {
    super.initState();
    // Reset conversation manager
    _conversationManager.reset();
    _loadGreeting();
  }

  // Helper to add and save message
  void _addMessage(ChatMessage msg) {
    if (mounted) {
      setState(() {
        _messages.add(msg);
      });
      _scrollToBottom();
      ChatHistoryService.saveMessage(msg); // Save persistence
    }
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _scanFace() async {
    try {
      final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front);
      if (photo == null) return;

      setState(() {
        _isLoading = true;
      });

      // Analyze Face
      final file = File(photo.path);
      final emotions = await AiInferenceService().analyzeFaceEmotion(file);

      // Get top emotion
      String? topEmotion;
      double topScore = 0.0;
      emotions.forEach((key, value) {
        if (value > topScore) {
          topScore = value;
          topEmotion = key;
        }
      });

      if (topEmotion != null) {
        setState(() {
          _detectedFaceEmotion = topEmotion;
          _isLoading = false;
        });

        // Notify user via chat (internal thought/monitor)
        // Or just let them know we saw it.
        setState(() {
          _messages.add(ChatMessage(
            text: "[Hệ thống] Đã nhận diện cảm xúc khuôn mặt: $topEmotion",
            isBot: true,
            timestamp: DateTime.now(),
          ));
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error scanning face: $e");
      setState(() {
        _isLoading = false;
      });
    }
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

    // Use helper for persistence
    _addMessage(ChatMessage(
        text: text.trim(), isBot: false, timestamp: DateTime.now()));

    _textController.clear();
    // Scroll handled by _addMessage

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

    // Add user message to conversation history for context (not UI logic)
    _conversationHistory.add(input);

    try {
      // Process message using Pure AI ChatbotService with Face Context
      final result = await ChatbotService.processUserMessage(input,
          faceEmotion: _detectedFaceEmotion);

      // Clear face emotion after use
      setState(() {
        _detectedFaceEmotion = null;
      });

      final responseType = result['type'];
      final messageText = result['message'] as String;

      if (mounted) {
        setState(() => _isLoading = false);

        if (responseType == 'suggestion') {
          _addMessage(
            ChatMessage(
              text: messageText,
              isBot: true,
              timestamp: DateTime.now(),
              needsConfirmation: true,
              suggestionData: result['suggestedActions'],
            ),
          );
        } else if (responseType == 'action') {
          final intent = result['intent'] as String;
          _executeIntentAction(intent);
          _addMessage(
            ChatMessage(
              text: messageText,
              isBot: true,
              timestamp: DateTime.now(),
            ),
          );
        } else {
          // Normal text response
          _addMessage(
            ChatMessage(
              text: messageText,
              isBot: true,
              timestamp: DateTime.now(),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in chatbot handling: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _addMessage(
          ChatMessage(
            text: "Xin lỗi, mình gặp chút vấn đề. Bạn thử lại nhé.",
            isBot: true,
            timestamp: DateTime.now(),
          ),
        );
      }
    }
  }

  void _handleSuggestionConfirmation(
      ChatMessage message, bool confirmed) async {
    // Remove confirmation buttons from the message (update specific message in list)
    // Actually, we can't mutate the 'message' object since it's final fields.
    // We should replace it in the list or just disable buttons?
    // For simplicity, we assume the Bubble handles "disabled" state or we just append new messages.
    // But ideally, we should update the UI to show decision was made.

    // For now, simple interaction:

    if (confirmed) {
      // YES Logic
      final data = message.suggestionData!;

      // 1. Light
      if (data['light'] != null) {
        String color = data['light']['color'];
        double brightness = (data['light']['brightness'] as num).toDouble();
        if (color == 'cool') color = 'blue'; // Map to valid mode
        if (color == 'neutral') color = 'warm'; // Map to valid mode
        widget.onLightSuggested?.call(color, brightness: brightness);
      }

      // 2. Music
      if (data['music'] != null) {
        widget.onMusicSuggested?.call(data['music']);
      }

      // 3. Scent
      if (data['scent'] != null) {
        widget.onEssentialOilSuggested?.call(data['scent']);
      }

      setState(() {
        _messages.add(ChatMessage(
          text:
              "Tuyệt vời, mình đã điều chỉnh giúp bạn rồi nhé. Chúc bạn thư giãn!",
          isBot: true,
          timestamp: DateTime.now(),
        ));
      });
    } else {
      // NO Logic -> Deep Conversation
      setState(() {
        _isLoading = true; // Show loading for AI response
      });

      try {
        final emotion = message.suggestionData?['label'] ?? 'normal';
        final userLastText =
            _conversationHistory.isNotEmpty ? _conversationHistory.last : "";

        final followUp = await ChatbotService.generateFollowUpConversation(
            userLastText, emotion);

        setState(() {
          _messages.add(ChatMessage(
            text: followUp,
            isBot: true,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
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
      // Removed manual _isLoading = true here to let _handleUserInput manage it
    });

    _hasSelectedMood = true;
    widget.onMoodSelected?.call(mood);

    // Skip encouragement, go straight to suggestions
    await _handleUserInput('Tôi đang cảm thấy ${mood.label}');

    if (mounted) {
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
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chatbot Tâm Lý',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black54),
            tooltip: 'Lịch sử tin nhắn',
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChatHistoryScreen()));
            },
          )
        ],
        bottom: null,
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
                        onConfirmation: (confirmed) =>
                            _handleSuggestionConfirmation(message, confirmed),
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
                    const SizedBox(width: 8),
                    _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.camera_alt,
                                    color: Colors.blueGrey),
                                onPressed: _scanFace,
                                tooltip: 'Quét cảm xúc khuôn mặt',
                              ),
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4FC3F7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_upward,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                onPressed: () =>
                                    _sendMessage(_textController.text),
                              ),
                            ],
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
