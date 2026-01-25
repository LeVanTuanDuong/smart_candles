import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';

class ChatHistoryService {
  static const String _key = 'chat_history';

  // Save a message
  static Future<void> saveMessage(ChatMessage message) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_key) ?? [];

    // Convert message to map/json
    // Since ChatMessage doesn't have toJson (assumption), let's create a map manually or update Model
    // Simple serialization
    final data = {
      'text': message.text,
      'isBot': message.isBot,
      'timestamp': message.timestamp.toIso8601String(),
    };

    history.add(jsonEncode(data));
    await prefs.setStringList(_key, history);
  }

  // Load history
  static Future<List<ChatMessage>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_key) ?? [];

    return history.map((e) {
      final data = jsonDecode(e);
      return ChatMessage(
        text: data['text'],
        isBot: data['isBot'],
        timestamp: DateTime.parse(data['timestamp']),
        // Note: suggestionData/needsConfirmation are transient, usually not saved for history view
        // unless we want to restore functional state. For "History View", user just wants text.
      );
    }).toList();
  }

  // Clear history
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
