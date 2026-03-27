import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_candles/features/schedule_repeat/models/weekly_time_schedule.dart';
import 'package:smart_candles/features/schedule_repeat/services/weekly_schedule_storage.dart';

class WeeklyScheduleScreen extends StatefulWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  State<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> {
  late WeeklyTimeSchedule _sch;
  bool _loading = true;

  static const _dayLabels = <int, String>{
    1: 'T2',
    2: 'T3',
    3: 'T4',
    4: 'T5',
    5: 'T6',
    6: 'T7',
    7: 'CN',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await WeeklyScheduleStorage.load();
    setState(() {
      _sch = s;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_sch.weekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn ít nhất một ngày trong tuần')),
      );
      return;
    }
    await WeeklyScheduleStorage.save(_sch);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu lịch lặp theo ngày')),
      );
    }
  }

  Future<void> _pickOn() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _sch.onHour, minute: _sch.onMinute),
    );
    if (t == null) return;
    setState(() {
      _sch = _sch.copyWith(onHour: t.hour, onMinute: t.minute);
    });
  }

  Future<void> _pickOff() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _sch.offHour, minute: _sch.offMinute),
    );
    if (t == null) return;
    setState(() {
      _sch = _sch.copyWith(offHour: t.hour, offMinute: t.minute);
    });
  }

  String _fmt(int h, int m) {
    return DateFormat('HH:mm').format(DateTime(2000, 1, 1, h, m));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lặp theo ngày (T2–CN)'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Lưu')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Bật lịch cố định'),
            subtitle:
                const Text('Ví dụ: 18:00 bật · 06:00 tắt (sáng hôm sau).'),
            value: _sch.enabled,
            onChanged: (v) => setState(() => _sch = _sch.copyWith(enabled: v)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: const Text('Giờ bật đèn'),
            subtitle: Text(_fmt(_sch.onHour, _sch.onMinute)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickOn,
          ),
          ListTile(
            leading: const Icon(Icons.lightbulb),
            title: const Text('Giờ tắt đèn'),
            subtitle: Text(_fmt(_sch.offHour, _sch.offMinute)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickOff,
          ),
          const SizedBox(height: 12),
          Text('Các ngày áp dụng',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _dayLabels.entries.map((e) {
              final selected = _sch.weekdays.contains(e.key);
              return FilterChip(
                label: Text(e.value),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    final next = Set<int>.from(_sch.weekdays);
                    if (v) {
                      next.add(e.key);
                    } else {
                      next.remove(e.key);
                    }
                    _sch = _sch.copyWith(weekdays: next);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'Gợi ý: nếu giờ tắt nhỏ hơn giờ bật (vd 18:00 bật, 06:00 tắt), '
            'hệ thống hiểu là tắt vào sáng hôm sau.',
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
        ],
      ),
    );
  }
}
