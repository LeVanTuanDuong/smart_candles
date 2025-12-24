class ChatMessage {
  final String text;
  final bool isBot;
  final DateTime timestamp;
  final String? suggestionType; // 'essential_oil', 'music', 'light'

  ChatMessage({
    required this.text,
    required this.isBot,
    required this.timestamp,
    this.suggestionType,
  });
}

