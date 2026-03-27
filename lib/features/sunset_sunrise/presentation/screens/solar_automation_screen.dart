import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_candles/features/sunset_sunrise/models/solar_automation_config.dart';
import 'package:smart_candles/features/sunset_sunrise/services/solar_automation_storage.dart';
import 'package:smart_candles/features/sunset_sunrise/services/solar_times_helper.dart';

class SolarAutomationScreen extends StatefulWidget {
  const SolarAutomationScreen({super.key});

  @override
  State<SolarAutomationScreen> createState() => _SolarAutomationScreenState();
}

class _SolarAutomationScreenState extends State<SolarAutomationScreen> {
  late SolarAutomationConfig _cfg;
  bool _loading = true;
  final _latCtrl = TextEditingController();
  final _lonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await SolarAutomationStorage.load();
    setState(() {
      _cfg = c;
      _latCtrl.text = c.latitude.toStringAsFixed(4);
      _lonCtrl.text = c.longitude.toStringAsFixed(4);
      _loading = false;
    });
  }

  Future<void> _save() async {
    final lat =
        double.tryParse(_latCtrl.text.replaceAll(',', '.')) ?? _cfg.latitude;
    final lon =
        double.tryParse(_lonCtrl.text.replaceAll(',', '.')) ?? _cfg.longitude;
    _cfg = _cfg.copyWith(latitude: lat, longitude: lon);
    await SolarAutomationStorage.save(_cfg);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu lịch theo mặt trời')),
      );
    }
  }

  @override
  void dispose() {
    _latCtrl.dispose();
    _lonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final now = DateTime.now();
    final sr =
        SolarTimesHelper.sunriseLocal(now, _cfg.latitude, _cfg.longitude);
    final ss = SolarTimesHelper.sunsetLocal(now, _cfg.latitude, _cfg.longitude);
    final fmt = DateFormat('HH:mm');

    DateTime? onAt;
    DateTime? offAt;
    if (ss != null && _cfg.turnOnNearSunset) {
      onAt = ss.add(Duration(minutes: _cfg.sunsetOffsetMinutes));
    }
    if (sr != null && _cfg.turnOffNearSunrise) {
      offAt = sr.add(Duration(minutes: _cfg.sunriseOffsetMinutes));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo hoàng hôn / bình minh'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Lưu'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Bật tự động theo mặt trời'),
            subtitle: const Text(
                'Dùng cùng lịch lặp ngày nếu bạn bật ở màn “Lặp theo ngày”.'),
            value: _cfg.enabled,
            onChanged: (v) => setState(() => _cfg = _cfg.copyWith(enabled: v)),
          ),
          const Divider(),
          Text(
            'Hôm nay (ước tính)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.wb_sunny_outlined),
            title: Text(sr != null
                ? 'Bình minh: ${fmt.format(sr)}'
                : 'Không tính được bình minh'),
          ),
          ListTile(
            leading: const Icon(Icons.nights_stay_outlined),
            title: Text(ss != null
                ? 'Hoàng hôn: ${fmt.format(ss)}'
                : 'Không tính được hoàng hôn'),
          ),
          if (onAt != null)
            ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: Text('Gợi ý bật đèn: ${fmt.format(onAt)}'),
            ),
          if (offAt != null)
            ListTile(
              leading: const Icon(Icons.lightbulb),
              title: Text('Gợi ý tắt đèn: ${fmt.format(offAt)}'),
            ),
          const Divider(),
          const Text('Vị trí (kinh/vĩ độ)'),
          const SizedBox(height: 8),
          TextField(
            controller: _latCtrl,
            decoration: const InputDecoration(
              labelText: 'Vĩ độ (latitude)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lonCtrl,
            decoration: const InputDecoration(
              labelText: 'Kinh độ (longitude)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Bật đèn gần hoàng hôn'),
            value: _cfg.turnOnNearSunset,
            onChanged: (v) =>
                setState(() => _cfg = _cfg.copyWith(turnOnNearSunset: v)),
          ),
          Row(
            children: [
              const Expanded(child: Text('Lệch (phút) so với hoàng hôn')),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () => setState(() {
                  _cfg = _cfg.copyWith(
                      sunsetOffsetMinutes: _cfg.sunsetOffsetMinutes - 15);
                }),
              ),
              Text('${_cfg.sunsetOffsetMinutes}'),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => setState(() {
                  _cfg = _cfg.copyWith(
                      sunsetOffsetMinutes: _cfg.sunsetOffsetMinutes + 15);
                }),
              ),
            ],
          ),
          SwitchListTile(
            title: const Text('Tắt đèn gần bình minh'),
            value: _cfg.turnOffNearSunrise,
            onChanged: (v) =>
                setState(() => _cfg = _cfg.copyWith(turnOffNearSunrise: v)),
          ),
          Row(
            children: [
              const Expanded(child: Text('Lệch (phút) so với bình minh')),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () => setState(() {
                  _cfg = _cfg.copyWith(
                      sunriseOffsetMinutes: _cfg.sunriseOffsetMinutes - 15);
                }),
              ),
              Text('${_cfg.sunriseOffsetMinutes}'),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => setState(() {
                  _cfg = _cfg.copyWith(
                      sunriseOffsetMinutes: _cfg.sunriseOffsetMinutes + 15);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
