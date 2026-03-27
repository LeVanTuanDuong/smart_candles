import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_candles/features/habits/models/user_habit.dart';
import 'package:smart_candles/features/habits/services/habits_storage_service.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  List<UserHabit> _habits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await HabitsStorageService.load();
    setState(() {
      _habits = list;
      _loading = false;
    });
  }

  Future<void> _persist() async {
    await HabitsStorageService.save(_habits);
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'nights_stay':
        return Icons.nights_stay_outlined;
      case 'bedtime':
        return Icons.bedtime_outlined;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'star':
        return Icons.star_outline;
      default:
        return Icons.wb_sunny_outlined;
    }
  }

  Future<void> _pickTime(UserHabit h) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: h.hour, minute: h.minute),
    );
    if (t == null) return;
    setState(() {
      final i = _habits.indexWhere((e) => e.id == h.id);
      if (i >= 0) {
        _habits[i] = UserHabit(
          id: h.id,
          title: h.title,
          iconName: h.iconName,
          hour: t.hour,
          minute: t.minute,
          turnLightOn: h.turnLightOn,
          brightness: h.brightness,
        );
      }
    });
    await _persist();
  }

  Future<void> _addHabit() async {
    final titleCtrl = TextEditingController();
    var on = true;
    var icon = 'wb_sunny';
    final picked = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          title: const Text('Thói quen mới'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Tên'),
              ),
              SwitchListTile(
                title: const Text('Bật đèn'),
                value: on,
                onChanged: (v) => setD(() => on = v),
              ),
              DropdownButton<String>(
                value: icon,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                      value: 'wb_sunny', child: Text('Sáng — wb_sunny')),
                  DropdownMenuItem(
                      value: 'nights_stay', child: Text('Tối — nights_stay')),
                  DropdownMenuItem(
                      value: 'bedtime', child: Text('Ngủ — bedtime')),
                  DropdownMenuItem(
                      value: 'self_improvement',
                      child: Text('Thiền — self_improvement')),
                  DropdownMenuItem(
                      value: 'star', child: Text('Yêu thích — star')),
                ],
                onChanged: (v) => setD(() => icon = v ?? icon),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Huỷ')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Thêm')),
          ],
        ),
      ),
    );
    if (picked != true || titleCtrl.text.trim().isEmpty) return;
    final id = 'habit_${DateTime.now().microsecondsSinceEpoch}';
    setState(() {
      _habits.add(UserHabit(
        id: id,
        title: titleCtrl.text.trim(),
        iconName: icon,
        hour: 12,
        minute: 0,
        turnLightOn: on,
        brightness: 0.5,
      ));
    });
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final fmt = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thói quen trong ngày'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _habits.length,
        itemBuilder: (context, i) {
          final h = _habits[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(_iconFor(h.iconName)),
              ),
              title: Text(h.title),
              subtitle: Text(
                '${fmt.format(DateTime(2000, 1, 1, h.hour, h.minute))} · '
                '${h.turnLightOn ? "Bật đèn" : "Tắt đèn"} · '
                '${(h.brightness * 100).round()}%',
              ),
              trailing: const Icon(Icons.schedule),
              onTap: () => _pickTime(h),
            ),
          );
        },
      ),
    );
  }
}
