class ChatMessage {
  final String text;
  final bool isBot;
  final DateTime timestamp;
  final String? suggestionType; // 'essential_oil', 'music', 'light'
  final bool? needsConfirmation; // If true, show yes/no buttons
  final Map<String, dynamic>? suggestionData; // Data for suggestions (oil, music, light)

  ChatMessage({
    required this.text,
    required this.isBot,
    required this.timestamp,
    this.suggestionType,
    this.needsConfirmation,
    this.suggestionData,
  });
}

