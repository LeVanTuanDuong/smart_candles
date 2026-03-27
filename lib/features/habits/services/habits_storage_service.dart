import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_candles/features/habits/models/user_habit.dart';

class HabitsStorageService {
  static const _key = 'user_habits_v1';

  static Future<List<UserHabit>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return _defaults();
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => UserHabit.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _defaults();
    }
  }

  static Future<void> save(List<UserHabit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(habits.map((h) => h.toJson()).toList()),
    );
  }

  static List<UserHabit> _defaults() {
    return [
      const UserHabit(
        id: 'wake',
        title: 'Thức dậy',
        iconName: 'wb_sunny',
        hour: 6,
        minute: 30,
        turnLightOn: true,
        brightness: 0.5,
      ),
      const UserHabit(
        id: 'rest',
        title: 'Thư giãn tối',
        iconName: 'nights_stay',
        hour: 20,
        minute: 0,
        turnLightOn: true,
        brightness: 0.35,
      ),
      const UserHabit(
        id: 'sleep',
        title: 'Đi ngủ',
        iconName: 'bedtime',
        hour: 23,
        minute: 0,
        turnLightOn: false,
        brightness: 0.0,
      ),
    ];
  }
}
