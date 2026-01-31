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
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        _prefs = await SharedPreferences.getInstance();
        return _prefs;
      } catch (e2) {
        return null;
      }
    }
  }

  static Future<double> getTemperatureThreshold() async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return 50.0;
      return prefs.getDouble(_keyTemperatureThreshold) ?? 50.0;
    } catch (e) {
      return 50.0;
    }
  }

  static Future<void> setTemperatureThreshold(double threshold) async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return;
      await prefs.setDouble(_keyTemperatureThreshold, threshold);
    } catch (e) {}
  }

  static Future<bool> getNotificationsEnabled() async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return true;
      return prefs.getBool(_keyNotificationsEnabled) ?? true;
    } catch (e) {
      return true;
    }
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return;
      await prefs.setBool(_keyNotificationsEnabled, enabled);
    } catch (e) {}
  }

  static Future<bool> getAutoLightEnabled() async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return true;
      return prefs.getBool(_keyAutoLightEnabled) ?? true;
    } catch (e) {
      return true;
    }
  }

  static Future<void> setAutoLightEnabled(bool enabled) async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return;
      await prefs.setBool(_keyAutoLightEnabled, enabled);
    } catch (e) {}
  }

  static Future<bool> getAutoMusicEnabled() async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return true;
      return prefs.getBool(_keyAutoMusicEnabled) ?? true;
    } catch (e) {
      return true;
    }
  }

  static Future<void> setAutoMusicEnabled(bool enabled) async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return;
      await prefs.setBool(_keyAutoMusicEnabled, enabled);
    } catch (e) {}
  }

  static Future<bool> getBluetoothEnabled() async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return false;
      return prefs.getBool(_keyBluetoothEnabled) ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> setBluetoothEnabled(bool enabled) async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return;
      await prefs.setBool(_keyBluetoothEnabled, enabled);
    } catch (e) {}
  }

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
