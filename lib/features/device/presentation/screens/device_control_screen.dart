import 'package:flutter/material.dart';
import 'package:smart_candles/shared/models/device_status.dart';
import 'package:smart_candles/features/device/presentation/widgets/temperature_status_widget.dart';

class DeviceControlScreen extends StatefulWidget {
  final DeviceStatus initialStatus;
  final Function(DeviceStatus)? onStatusChanged;

  const DeviceControlScreen({
    super.key,
    required this.initialStatus,
    this.onStatusChanged,
  });

  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  late DeviceStatus _deviceStatus;

  @override
  void initState() {
    super.initState();
    _deviceStatus = widget.initialStatus;
  }

  @override
  void didUpdateWidget(DeviceControlScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStatus != widget.initialStatus) {
      _deviceStatus = widget.initialStatus;
    }
  }

  void _updateStatus(DeviceStatus newStatus) {
    setState(() {
      _deviceStatus = newStatus;
    });
    widget.onStatusChanged?.call(newStatus);
  }

  void _toggleLight() {
    _updateStatus(_deviceStatus.copyWith(
      isLightOn: !_deviceStatus.isLightOn,
    ));
  }

  void _changeLightMode(String mode) {
    _updateStatus(_deviceStatus.copyWith(
      lightMode: mode,
      isLightOn: true,
    ));
  }

  void _toggleMusic() {
    _updateStatus(_deviceStatus.copyWith(
      isMusicPlaying: !_deviceStatus.isMusicPlaying,
      currentMusic: _deviceStatus.isMusicPlaying ? null : 'Piano chậm',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Điều Khiển Thiết Bị',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[50],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TemperatureStatusWidget(deviceStatus: _deviceStatus),
            const SizedBox(height: 24),
            _buildLightControlCard(),
            const SizedBox(height: 24),
            _buildMusicControlCard(),
            const SizedBox(height: 24),
            _buildBluetoothStatusCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildLightControlCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, size: 32, color: Colors.amber[700]),
                const SizedBox(width: 12),
                const Text(
                  'Đèn Ngủ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                _deviceStatus.isLightOn ? 'Đèn đang bật' : 'Đèn đang tắt',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              value: _deviceStatus.isLightOn,
              onChanged: (_) => _toggleLight(),
              activeColor: Colors.amber[600],
            ),
            if (_deviceStatus.isLightOn) ...[
              const SizedBox(height: 16),
              const Text(
                'Chế độ ánh sáng:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildLightModeButton(
                      'warm',
                      'Warm White',
                      'Thư giãn',
                      Colors.orange[300]!,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLightModeButton(
                      'amber',
                      'Amber',
                      'Hỗ trợ giấc ngủ',
                      Colors.amber[600]!,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLightModeButton(
                      'blue',
                      'Soft Blue',
                      'Bình tĩnh, thiền',
                      Colors.blue[300]!,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLightModeButton(
    String mode,
    String title,
    String subtitle,
    Color color,
  ) {
    final isSelected =
        _deviceStatus.lightMode == mode && _deviceStatus.isLightOn;
    return InkWell(
      onTap: () => _changeLightMode(mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicControlCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.music_note, size: 32, color: Colors.purple[600]),
                const SizedBox(width: 12),
                const Text(
                  'Nhạc Bluetooth',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                _deviceStatus.isMusicPlaying
                    ? 'Nhạc đang phát'
                    : 'Nhạc đang tắt',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: _deviceStatus.currentMusic != null
                  ? Text('Đang phát: ${_deviceStatus.currentMusic}')
                  : null,
              value: _deviceStatus.isMusicPlaying,
              onChanged: (_) => _toggleMusic(),
              activeColor: Colors.purple[600],
            ),
            const SizedBox(height: 12),
            const Text(
              'Gợi ý nhạc:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Ambient',
                'Piano chậm',
                'Nature sound',
                'Meditation music',
              ].map((genre) {
                return Chip(
                  label: Text(genre),
                  backgroundColor: Colors.purple[50],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBluetoothStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.bluetooth,
              size: 32,
              color: _deviceStatus.isBluetoothConnected
                  ? Colors.blue[600]
                  : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kết nối Bluetooth',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _deviceStatus.isBluetoothConnected
                        ? 'Đã kết nối với ESP32'
                        : 'Chưa kết nối',
                    style: TextStyle(
                      fontSize: 14,
                      color: _deviceStatus.isBluetoothConnected
                          ? Colors.green[700]
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _deviceStatus.isBluetoothConnected
                  ? Icons.check_circle
                  : Icons.cancel,
              color: _deviceStatus.isBluetoothConnected
                  ? Colors.green
                  : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
