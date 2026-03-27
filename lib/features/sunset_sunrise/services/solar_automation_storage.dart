import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_candles/features/sunset_sunrise/models/solar_automation_config.dart';

class SolarAutomationStorage {
  static const _key = 'solar_automation_config_v1';

  static Future<SolarAutomationConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return const SolarAutomationConfig();
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return SolarAutomationConfig.fromJson(map);
    } catch (_) {
      return const SolarAutomationConfig();
    }
  }

  static Future<void> save(SolarAutomationConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(config.toJson()));
  }
}
