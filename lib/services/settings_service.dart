import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage app settings persistently
class SettingsService {
  static const String _keyTemperatureThreshold = 'temperature_threshold';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyAutoLightEnabled = 'auto_light_enabled';
  static const String _keyAutoMusicEnabled = 'auto_music_enabled';
  static const String _keyBluetoothEnabled = 'bluetooth_enabled';
  
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

  // Temperature threshold (default: 50.0°C)
  static Future<double> getTemperatureThreshold() async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return 50.0;
      return prefs.getDouble(_keyTemperatureThreshold) ?? 50.0;
    } catch (e) {
      // Removed print statement: 'Error loading temperature threshold: $e');
      return 50.0;
    }
  }

  static Future<void> setTemperatureThreshold(double threshold) async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return;
      await prefs.setDouble(_keyTemperatureThreshold, threshold);
    } catch (e) {
      // Removed print statement: 'Error saving temperature threshold: $e');
    }
  }

  // Notifications enabled (default: true)
  static Future<bool> getNotificationsEnabled() async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return true;
      return prefs.getBool(_keyNotificationsEnabled) ?? true;
    } catch (e) {
      // Removed print statement: 'Error loading notifications setting: $e');
      return true;
    }
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return;
      await prefs.setBool(_keyNotificationsEnabled, enabled);
    } catch (e) {
      // Removed print statement: 'Error saving notifications setting: $e');
    }
  }

  // Auto light enabled (default: true)
  static Future<bool> getAutoLightEnabled() async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return true;
      return prefs.getBool(_keyAutoLightEnabled) ?? true;
    } catch (e) {
      // Removed print statement: 'Error loading auto light setting: $e');
      return true;
    }
  }

  static Future<void> setAutoLightEnabled(bool enabled) async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return;
      await prefs.setBool(_keyAutoLightEnabled, enabled);
    } catch (e) {
      // Removed print statement: 'Error saving auto light setting: $e');
    }
  }

  // Auto music enabled (default: true)
  static Future<bool> getAutoMusicEnabled() async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return true;
      return prefs.getBool(_keyAutoMusicEnabled) ?? true;
    } catch (e) {
      // Removed print statement: 'Error loading auto music setting: $e');
      return true;
    }
  }

  static Future<void> setAutoMusicEnabled(bool enabled) async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return;
      await prefs.setBool(_keyAutoMusicEnabled, enabled);
    } catch (e) {
      // Removed print statement: 'Error saving auto music setting: $e');
    }
  }

  // Bluetooth enabled (default: false)
  static Future<bool> getBluetoothEnabled() async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return false;
      return prefs.getBool(_keyBluetoothEnabled) ?? false;
    } catch (e) {
      // Removed print statement: 'Error loading bluetooth setting: $e');
      return false;
    }
  }

  static Future<void> setBluetoothEnabled(bool enabled) async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return;
      await prefs.setBool(_keyBluetoothEnabled, enabled);
    } catch (e) {
      // Removed print statement: 'Error saving bluetooth setting: $e');
    }
  }

  // Load all settings at once
  static Future<Map<String, dynamic>> loadAllSettings() async {
    return {
      'temperatureThreshold': await getTemperatureThreshold(),
      'notificationsEnabled': await getNotificationsEnabled(),
      'autoLightEnabled': await getAutoLightEnabled(),
      'autoMusicEnabled': await getAutoMusicEnabled(),
      'bluetoothEnabled': await getBluetoothEnabled(),
    };
  }
}

