class ChatMessage {
  final String text;
  final bool isBot;
  final DateTime timestamp;
  final String? suggestionType; // 'essential_oil', 'music', 'light'
  final bool? needsConfirmation; // If true, show yes/no buttons
  final Map<String, dynamic>?
      suggestionData; // Data for suggestions (oil, music, light)

  ChatMessage({
    required this.text,
    required this.isBot,
    required this.timestamp,
    this.suggestionType,
    this.needsConfirmation,
    this.suggestionData,
  });

  ChatMessage copyWith({
    String? text,
    bool? isBot,
    DateTime? timestamp,
    String? suggestionType,
    bool? needsConfirmation,
    Map<String, dynamic>? suggestionData,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isBot: isBot ?? this.isBot,
      timestamp: timestamp ?? this.timestamp,
      suggestionType: suggestionType ?? this.suggestionType,
      needsConfirmation: needsConfirmation ?? this.needsConfirmation,
      suggestionData: suggestionData ?? this.suggestionData,
    );
  }
}
