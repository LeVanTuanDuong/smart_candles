import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_candles/features/schedule_repeat/models/weekly_time_schedule.dart';

class WeeklyScheduleStorage {
  static const _key = 'weekly_time_schedule_v1';

  static Future<WeeklyTimeSchedule> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return const WeeklyTimeSchedule();
    }
    try {
      return WeeklyTimeSchedule.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const WeeklyTimeSchedule();
    }
  }

  static Future<void> save(WeeklyTimeSchedule schedule) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(schedule.toJson()));
  }
}
