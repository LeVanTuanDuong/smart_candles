import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/temperature_history_entry.dart';

class TemperatureHistoryService {
  static const String _storageKey = 'temperature_history_entries';
  static const int _maxEntries = 100; // Keep last 100 entries
  static SharedPreferences? _prefs;

  // Get SharedPreferences instance with retry
  static Future<SharedPreferences?> _getPreferences() async {
    if (_prefs != null) return _prefs;
    
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      _prefs = await SharedPreferences.getInstance();
      return _prefs;
    } catch (e) {
      print('Error getting SharedPreferences: $e');
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        _prefs = await SharedPreferences.getInstance();
        return _prefs;
      } catch (e2) {
        print('Error getting SharedPreferences on retry: $e2');
        return null;
      }
    }
  }

  // Save a temperature history entry
  static Future<void> saveEntry(TemperatureHistoryEntry entry) async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) {
        print('SharedPreferences not available, cannot save entry');
        return;
      }

      // Load existing entries
      final entries = await loadEntries();
      
      // Add new entry at the beginning (most recent first)
      entries.insert(0, entry);
      
      // Keep only the last _maxEntries entries
      if (entries.length > _maxEntries) {
        entries.removeRange(_maxEntries, entries.length);
      }

      // Convert to JSON
      final entriesList = entries.map((e) => e.toMap()).toList();
      final jsonString = jsonEncode(entriesList);

      // Save to SharedPreferences
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      print('Error saving temperature history entry: $e');
    }
  }

  // Load all temperature history entries
  static Future<List<TemperatureHistoryEntry>> loadEntries() async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) {
        print('SharedPreferences not available, returning empty entries');
        return [];
      }

      final jsonString = prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      try {
        final List<dynamic> entriesList = jsonDecode(jsonString);
        return entriesList
            .map((item) => TemperatureHistoryEntry.fromMap(item))
            .toList();
      } catch (e) {
        print('Error parsing temperature history entries: $e');
        return [];
      }
    } catch (e) {
      print('Error loading temperature history entries: $e');
      return [];
    }
  }

  // Clear all history
  static Future<void> clearHistory() async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return;
      await prefs.remove(_storageKey);
    } catch (e) {
      print('Error clearing temperature history: $e');
    }
  }
}

