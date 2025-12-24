import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mood_journal_entry.dart';

class JournalStorageService {
  static const String _storageKey = 'mood_journal_entries';
  static SharedPreferences? _prefs;

  // Get SharedPreferences instance with retry
  static Future<SharedPreferences?> _getPreferences() async {
    if (_prefs != null) return _prefs;

    try {
      // Add small delay to ensure Flutter engine is ready
      await Future.delayed(const Duration(milliseconds: 100));
      _prefs = await SharedPreferences.getInstance();
      return _prefs;
    } catch (e) {
      print('Error getting SharedPreferences: $e');
      // Retry once after a longer delay
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

  // Save all journal entries to storage
  static Future<void> saveEntries(
    Map<DateTime, MoodJournalEntry> entries,
  ) async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) {
        print('SharedPreferences not available, cannot save entries');
        return;
      }

      // Convert Map<DateTime, MoodJournalEntry> to List<Map>
      final entriesList = entries.entries.map((entry) {
        return {
          'date': entry.key.toIso8601String(),
          'entry': entry.value.toMap(),
        };
      }).toList();

      // Convert to JSON string
      final jsonString = jsonEncode(entriesList);

      // Save to SharedPreferences
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      // If saving fails, silently fail (data will be lost but app won't crash)
      print('Error saving journal entries: $e');
    }
  }

  // Load all journal entries from storage
  static Future<Map<DateTime, MoodJournalEntry>> loadEntries() async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) {
        print('SharedPreferences not available, returning empty entries');
        return {};
      }
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        return {};
      }

      try {
        // Parse JSON string
        final List<dynamic> entriesList = jsonDecode(jsonString);

        // Convert back to Map<DateTime, MoodJournalEntry>
        final Map<DateTime, MoodJournalEntry> entries = {};

        for (var item in entriesList) {
          final date = DateTime.parse(item['date']);
          final entry = MoodJournalEntry.fromMap(item['entry']);

          // Normalize date to remove time component
          final dateOnly = DateTime(date.year, date.month, date.day);
          entries[dateOnly] = entry;
        }

        return entries;
      } catch (e) {
        // If parsing fails, return empty map
        print('Error parsing journal entries: $e');
        return {};
      }
    } catch (e) {
      // If loading fails (e.g., platform exception), return empty map
      print('Error loading journal entries: $e');
      return {};
    }
  }

  // Save a single entry
  static Future<void> saveEntry(MoodJournalEntry entry) async {
    try {
      final entries = await loadEntries();
      final dateOnly = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      entries[dateOnly] = entry;
      await saveEntries(entries);
    } catch (e) {
      print('Error saving journal entry: $e');
    }
  }

  // Delete an entry
  static Future<void> deleteEntry(DateTime date) async {
    try {
      final entries = await loadEntries();
      final dateOnly = DateTime(date.year, date.month, date.day);
      entries.remove(dateOnly);
      await saveEntries(entries);
    } catch (e) {
      print('Error deleting journal entry: $e');
    }
  }
}
