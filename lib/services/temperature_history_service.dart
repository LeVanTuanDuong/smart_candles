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
      // Removed print statement: 'Error getting SharedPreferences: $e');
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        _prefs = await SharedPreferences.getInstance();
        return _prefs;
      } catch (e2) {
        // Removed print statement: 'Error getting SharedPreferences on retry: $e2');
        return null;
      }
    }
  }

  // Save a temperature history entry
  static Future<void> saveEntry(TemperatureHistoryEntry entry) async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) {
        // Removed print statement: 'SharedPreferences not available, cannot save entry');
        return;
      }

      // Load existing entries
      final entries = await loadEntries();

      // Remove entries older than 1 day
      _removeOldEntries(entries);

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

      // Removed print statement: '✅ Đã lưu entry nhiệt độ. Tổng số entries: ${entries.length}');
    } catch (e) {
      // Removed print statement: 'Error saving temperature history entry: $e');
    }
  }

  // Remove entries older than 1 day
  static void _removeOldEntries(List<TemperatureHistoryEntry> entries) {
    final now = DateTime.now();
    final oneDayAgo = now.subtract(const Duration(days: 1));

    final beforeCount = entries.length;
    entries.removeWhere((entry) {
      final isOld = entry.timestamp.isBefore(oneDayAgo);
      if (isOld) {
        // Removed print statement: '🗑️ Xóa entry cũ: ${entry.timestamp} (${entry.temperature}°C)');
      }
      return isOld;
    });

    final afterCount = entries.length;
    if (beforeCount > afterCount) {
      // Removed print statement: '✅ Đã xóa ${beforeCount - afterCount} entries cũ hơn 1 ngày');
    }
  }

  // Load all temperature history entries (only entries from last 24 hours)
  static Future<List<TemperatureHistoryEntry>> loadEntries() async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) {
        // Removed print statement: 'SharedPreferences not available, returning empty entries');
        return [];
      }

      final jsonString = prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      try {
        final List<dynamic> entriesList = jsonDecode(jsonString);
        final allEntries = entriesList
            .map((item) => TemperatureHistoryEntry.fromMap(item))
            .toList();

        // Filter entries to only keep those from last 24 hours
        final now = DateTime.now();
        final oneDayAgo = now.subtract(const Duration(days: 1));

        final recentEntries = allEntries.where((entry) {
          return entry.timestamp.isAfter(oneDayAgo);
        }).toList();

        // If we removed old entries, save the filtered list back
        if (recentEntries.length < allEntries.length) {
          // Save filtered entries back to storage
          final entriesListToSave =
              recentEntries.map((e) => e.toMap()).toList();
          final jsonStringToSave = jsonEncode(entriesListToSave);
          await prefs.setString(_storageKey, jsonStringToSave);
        }

        // Removed print statement: '📊 Load ${recentEntries.length} entries (trong 24 giờ qua)');
        return recentEntries;
      } catch (e) {
        // Removed print statement: 'Error parsing temperature history entries: $e');
        return [];
      }
    } catch (e) {
      // Removed print statement: 'Error loading temperature history entries: $e');
      return [];
    }
  }

  // Clear all history
  static Future<void> clearHistory() async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return;
      await prefs.remove(_storageKey);
      // Removed print statement: '✅ Đã xóa toàn bộ lịch sử nhiệt độ');
    } catch (e) {
      // Removed print statement: 'Error clearing temperature history: $e');
    }
  }

  // Clean up old entries (can be called periodically)
  static Future<void> cleanupOldEntries() async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return;

      final jsonString = prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        return;
      }

      final List<dynamic> entriesList = jsonDecode(jsonString);
      final allEntries = entriesList
          .map((item) => TemperatureHistoryEntry.fromMap(item))
          .toList();

      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(days: 1));

      final beforeCount = allEntries.length;
      allEntries.removeWhere((entry) => entry.timestamp.isBefore(oneDayAgo));
      final afterCount = allEntries.length;

      if (beforeCount > afterCount) {
        final entriesListToSave = allEntries.map((e) => e.toMap()).toList();
        final jsonStringToSave = jsonEncode(entriesListToSave);
        await prefs.setString(_storageKey, jsonStringToSave);
        // Removed print statement: '🧹 Đã dọn dẹp ${beforeCount - afterCount} entries cũ hơn 1 ngày');
      }
    } catch (e) {
      // Removed print statement: 'Error cleaning up old entries: $e');
    }
  }
}
