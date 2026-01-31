import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_candles/features/device/models/temperature_history_entry.dart';

class TemperatureHistoryService {
  static const String _storageKey = 'temperature_history_entries';
  static const int _maxEntries = 100;
  static SharedPreferences? _prefs;

  static Future<SharedPreferences?> _getPreferences() async {
    if (_prefs != null) return _prefs;
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      _prefs = await SharedPreferences.getInstance();
      return _prefs;
    } catch (e) {
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        _prefs = await SharedPreferences.getInstance();
        return _prefs;
      } catch (e2) {
        return null;
      }
    }
  }

  static Future<void> saveEntry(TemperatureHistoryEntry entry) async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return;
      final entries = await loadEntries();
      _removeOldEntries(entries);
      entries.insert(0, entry);
      if (entries.length > _maxEntries) {
        entries.removeRange(_maxEntries, entries.length);
      }
      final entriesList = entries.map((e) => e.toMap()).toList();
      await prefs.setString(_storageKey, jsonEncode(entriesList));
    } catch (e) {}
  }

  static void _removeOldEntries(List<TemperatureHistoryEntry> entries) {
    final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
    entries.removeWhere((entry) => entry.timestamp.isBefore(oneDayAgo));
  }

  static Future<List<TemperatureHistoryEntry>> loadEntries() async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return [];
      final jsonString = prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) return [];
      try {
        final List<dynamic> entriesList = jsonDecode(jsonString);
        final allEntries = entriesList
            .map((item) => TemperatureHistoryEntry.fromMap(item))
            .toList();
        final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
        final recentEntries =
            allEntries.where((e) => e.timestamp.isAfter(oneDayAgo)).toList();
        if (recentEntries.length < allEntries.length) {
          final toSave = recentEntries.map((e) => e.toMap()).toList();
          await prefs.setString(_storageKey, jsonEncode(toSave));
        }
        return recentEntries;
      } catch (e) {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<void> clearHistory() async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return;
      await prefs.remove(_storageKey);
    } catch (e) {}
  }

  static Future<void> cleanupOldEntries() async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return;
      final jsonString = prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) return;
      final List<dynamic> entriesList = jsonDecode(jsonString);
      final allEntries = entriesList
          .map((item) => TemperatureHistoryEntry.fromMap(item))
          .toList();
      final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
      allEntries.removeWhere((e) => e.timestamp.isBefore(oneDayAgo));
      final toSave = allEntries.map((e) => e.toMap()).toList();
      await prefs.setString(_storageKey, jsonEncode(toSave));
    } catch (e) {}
  }
}
