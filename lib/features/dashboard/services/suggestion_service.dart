import 'package:flutter/foundation.dart';
import 'package:smart_candles/shared/models/mood_type.dart';

/// Service to share suggestions between ChatbotScreen and DashboardHomeScreen
class SuggestionService extends ChangeNotifier {
  static final SuggestionService _instance = SuggestionService._internal();
  factory SuggestionService() => _instance;
  SuggestionService._internal();

  MoodType? _detectedMood;
  String? _essentialOilSuggestion;
  String? _musicSuggestion;
  String? _lightSuggestion;

  // Getters
  MoodType? get detectedMood => _detectedMood;
  String? get essentialOilSuggestion => _essentialOilSuggestion;
  String? get musicSuggestion => _musicSuggestion;
  String? get lightSuggestion => _lightSuggestion;

  /// Update mood and suggestions from chatbot
  void updateSuggestions({
    MoodType? mood,
    String? essentialOil,
    String? music,
    String? light,
  }) {
    if (mood != null) {
      _detectedMood = mood;
    }
    if (essentialOil != null) {
      _essentialOilSuggestion = essentialOil;
    }
    if (music != null) {
      _musicSuggestion = music;
    }
    if (light != null) {
      _lightSuggestion = light;
    }
    notifyListeners();
  }

  /// Clear all suggestions
  void clearSuggestions() {
    _detectedMood = null;
    _essentialOilSuggestion = null;
    _musicSuggestion = null;
    _lightSuggestion = null;
    notifyListeners();
  }
}
