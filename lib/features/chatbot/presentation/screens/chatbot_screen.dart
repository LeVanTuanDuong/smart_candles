import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:smart_candles/features/chatbot/models/message.dart';
import 'package:smart_candles/shared/models/mood_type.dart';
import 'package:smart_candles/features/chatbot/services/chatbot_service.dart';
import 'package:smart_candles/features/chatbot/services/conversation_manager.dart';
import 'package:smart_candles/features/chatbot/services/ai_inference_service.dart';
import 'package:smart_candles/features/chatbot/services/chat_history_service.dart';
import 'package:smart_candles/features/chatbot/presentation/screens/chat_history_screen.dart';
import 'package:smart_candles/features/chatbot/presentation/widgets/chat_bubble.dart';
import 'package:smart_candles/features/chatbot/presentation/widgets/mood_buttons_chat.dart';

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

  final SpeechToText _speech = SpeechToText();
  bool _speechInitAttempted = false;
  String? _preferredSpeechLocale;
  bool _isListening = false;
  final ValueNotifier<String> _speechText = ValueNotifier<String>('');
  bool _speechDialogOpen = false;
  bool _speechAutoSent = false;
  bool _speechDialogActive = false;

  // Face Emotion State
  String? _detectedFaceEmotion;
  final ImagePicker _picker = ImagePicker();

  final ConversationManager _conversationManager = ConversationManager();
  final FlutterTts _tts = FlutterTts();
  bool _ttsEnabled = true;
  bool _ttsReady = false;

  @override
  void initState() {
    super.initState();
    // Reset conversation manager
    _conversationManager.reset();
    _initTts();
    _loadGreeting();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('vi-VN');
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.45);
      await _tts.awaitSpeakCompletion(true);
      _ttsReady = true;
    } catch (e) {
      _ttsReady = false;
      debugPrint('TTS init error: $e');
    }
  }

  // Helper to add and save message
  void _addMessage(ChatMessage msg) {
    if (mounted) {
      setState(() {
        _messages.add(msg);
      });
      _scrollToBottom();
      ChatHistoryService.saveMessage(msg); // Save persistence
      if (msg.isBot && _ttsEnabled && _ttsReady) {
        _speakBotMessage(msg.text);
      }
    }
  }

  Future<void> _speakBotMessage(String text) async {
    final speakText = text.trim();
    if (speakText.isEmpty) return;
    if (!_ttsReady) return;
    try {
      await _tts.stop();
      await _tts.speak(speakText);
    } catch (e) {
      _ttsReady = false;
      debugPrint('TTS speak error: $e');
    }
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _pickSpeechLocale() async {
    if (_preferredSpeechLocale != null) return;
    try {
      final locales = await _speech.locales();
      for (final l in locales) {
        if (l.localeId.toLowerCase().startsWith('vi')) {
          _preferredSpeechLocale = l.localeId;
          return;
        }
      }
      if (locales.isNotEmpty) {
        _preferredSpeechLocale = locales.first.localeId;
      }
    } catch (e) {
      debugPrint('speech locales: $e');
    }
  }

  Future<bool> _initSpeechIfNeeded() async {
    if (_speech.isAvailable) {
      await _pickSpeechLocale();
      return true;
    }
    if (_speechInitAttempted && !_speech.isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nhận dạng giọng nói chưa khả dụng. Kiểm tra quyền micro trong Cài đặt.',
            ),
          ),
        );
      }
      return false;
    }
    _speechInitAttempted = true;

    final ok = await _speech.initialize(
      onError: (e) {
        debugPrint('Speech error: ${e.errorMsg}');
        _finishListening(send: false);
      },
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'notListening' || status == 'done') {
          _finishListening(send: true);
        }
      },
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không bật được nhận dạng giọng nói. Hãy cấp quyền micro trong Cài đặt.',
          ),
        ),
      );
    }
    if (ok) await _pickSpeechLocale();
    return ok;
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _speechText.value = result.recognizedWords;
    if (result.finalResult) {
      _finishListening(send: true);
    }
  }

  Future<void> _showListeningPopup() async {
    if (!mounted || _speechDialogOpen) return;
    _speechDialogOpen = true;
    _speechDialogActive = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        // Mark active after first frame to avoid pop() race.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _speechDialogActive = true;
        });
        return PopScope(
          canPop: false,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 320,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Đang lắng nghe…',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Hủy',
                          onPressed: () async {
                            await _speech.cancel();
                            _finishListening(send: false);
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const _MicWave(),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<String>(
                      valueListenable: _speechText,
                      builder: (context, value, _) {
                        final text = value.trim();
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F7FA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            text.isEmpty ? 'Nói gì đó…' : text,
                            style: TextStyle(
                              color: text.isEmpty
                                  ? Colors.grey[600]
                                  : Colors.grey[900],
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _speech.stop();
                          _finishListening(send: true);
                        },
                        icon: const Icon(Icons.stop),
                        label: const Text('Dừng & gửi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4FC3F7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    _speechDialogOpen = false;
    _speechDialogActive = false;
  }

  void _closeListeningPopupIfOpen() {
    if (!mounted) return;
    if (!_speechDialogOpen) return;
    // Only pop if the dialog route is actually active; otherwise we risk popping
    // the page under it (causing a black screen / wrong route).
    if (_speechDialogActive &&
        Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _finishListening({required bool send}) {
    if (!mounted) return;
    if (_isListening) {
      setState(() => _isListening = false);
    }
    _closeListeningPopupIfOpen();

    if (!send) return;
    if (_speechAutoSent) return;
    final t = _speechText.value.trim();
    if (t.isNotEmpty) {
      _speechAutoSent = true;
      _sendMessage(t);
      _speechText.value = '';
      _textController.clear();
    }
  }

  Future<void> _toggleMic() async {
    if (_isLoading) return;

    if (_isListening) {
      await _speech.stop();
      if (!mounted) return;
      _finishListening(send: true);
      return;
    }

    final available = await _initSpeechIfNeeded();
    if (!available || !mounted) return;

    _speechAutoSent = false;
    _speechText.value = '';
    setState(() => _isListening = true);
    // ignore: unawaited_futures
    _showListeningPopup();

    try {
      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 4),
        localeId: _preferredSpeechLocale,
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
        ),
      );
    } catch (e) {
      debugPrint('Speech listen failed: $e');
      if (mounted) {
        _finishListening(send: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không mở được micro: $e')),
        );
      }
    }

    if (mounted && _speech.isNotListening && _isListening) {
      _finishListening(send: true);
    }
  }

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
    // Hide confirmation buttons after selection
    setState(() {
      final index = _messages.indexOf(message);
      if (index != -1) {
        _messages[index] = message.copyWith(needsConfirmation: false);
      }
    });

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
    _speech.stop();
    if (_ttsReady) {
      _tts.stop();
    }
    _speechText.dispose();
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
            icon: Icon(
              _ttsEnabled ? Icons.volume_up : Icons.volume_off,
              color: Colors.black54,
            ),
            tooltip: _ttsEnabled ? 'Tắt đọc phản hồi' : 'Bật đọc phản hồi',
            onPressed: () async {
              if (!_ttsReady) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'TTS chưa sẵn sàng. Hãy tắt app và chạy lại để tải plugin.',
                      ),
                    ),
                  );
                }
                return;
              }
              setState(() {
                _ttsEnabled = !_ttsEnabled;
              });
              if (!_ttsEnabled) {
                await _tts.stop();
              }
            },
          ),
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
                            hintText: _isListening
                                ? 'Đang nghe… (nhấn mic lần nữa để gửi)'
                                : 'Nhập tin nhắn...',
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
                                icon: Icon(
                                  _isListening ? Icons.stop_circle : Icons.mic,
                                  color: _isListening
                                      ? Colors.redAccent
                                      : Colors.blueGrey,
                                ),
                                onPressed: _toggleMic,
                                tooltip: _isListening
                                    ? 'Dừng và gửi tin nhắn'
                                    : 'Nói để nhập (nhấn lại để gửi)',
                              ),
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

class _MicWave extends StatefulWidget {
  const _MicWave();

  @override
  State<_MicWave> createState() => _MicWaveState();
}

class _MicWaveState extends State<_MicWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          double h(double phase) =>
              10 + (18 * (0.5 + 0.5 * math.sin((t + phase) * math.pi * 2)));
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _waveBar(height: h(0.0)),
              const SizedBox(width: 6),
              _waveBar(height: h(0.15)),
              const SizedBox(width: 6),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFF4FC3F7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic, color: Colors.white),
              ),
              const SizedBox(width: 6),
              _waveBar(height: h(0.30)),
              const SizedBox(width: 6),
              _waveBar(height: h(0.45)),
            ],
          );
        },
      ),
    );
  }

  Widget _waveBar({required double height}) {
    return Container(
      width: 6,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF4FC3F7).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
