import 'package:flutter/material.dart';
import '../models/device_status.dart';

class SettingsScreen extends StatefulWidget {
  final DeviceStatus deviceStatus;
  final Function(DeviceStatus) onStatusChanged;

  const SettingsScreen({
    super.key,
    required this.deviceStatus,
    required this.onStatusChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late DeviceStatus _deviceStatus;
  bool _notificationsEnabled = true;
  bool _autoLightEnabled = true;
  bool _autoMusicEnabled = true;
  double _temperatureThreshold = 50.0;

  @override
  void initState() {
    super.initState();
    _deviceStatus = widget.deviceStatus;
  }

  void _updateStatus(DeviceStatus newStatus) {
    setState(() {
      _deviceStatus = newStatus;
    });
    widget.onStatusChanged(newStatus);
  }

  Color _getLightColor(String mode) {
    switch (mode) {
      case 'warm':
        return Colors.orange[300]!;
      case 'amber':
        return Colors.amber[600]!;
      case 'blue':
        return Colors.blue[300]!;
      default:
        return Colors.orange[300]!;
    }
  }

  String _getLightLabel(String mode) {
    switch (mode) {
      case 'warm':
        return 'Warm white - Thư giãn';
      case 'amber':
        return 'Amber - Hỗ trợ giấc ngủ';
      case 'blue':
        return 'Soft blue - Bình tĩnh, thiền';
      default:
        return 'Warm white';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Cài đặt',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bluetooth Connection
            _buildSectionCard(
              title: 'Kết nối',
              children: [
                ListTile(
                  leading: Icon(
                    Icons.bluetooth,
                    color: _deviceStatus.isBluetoothConnected
                        ? Colors.blue[600]
                        : Colors.grey,
                  ),
                  title: const Text('Bluetooth'),
                  subtitle: Text(
                    _deviceStatus.isBluetoothConnected
                        ? 'Đã kết nối với ESP32'
                        : 'Chưa kết nối',
                  ),
                  trailing: Switch(
                    value: _deviceStatus.isBluetoothConnected,
                    onChanged: (value) {
                      _updateStatus(_deviceStatus.copyWith(
                        isBluetoothConnected: value,
                      ));
                    },
                    activeColor: Colors.blue[600],
                  ),
                ),
              ],
            ),

            // Light Settings
            _buildSectionCard(
              title: 'Đèn ngủ',
              children: [
                SwitchListTile(
                  secondary: Icon(Icons.lightbulb, color: Colors.amber[700]),
                  title: const Text('Bật/Tắt đèn'),
                  value: _deviceStatus.isLightOn,
                  onChanged: (value) {
                    _updateStatus(_deviceStatus.copyWith(isLightOn: value));
                  },
                  activeColor: Colors.amber[600],
                ),
                if (_deviceStatus.isLightOn) ...[
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.brightness_6, color: Colors.grey[700]),
                    title: const Text('Độ sáng'),
                    subtitle: Slider(
                      value: _deviceStatus.lightBrightness,
                      onChanged: (value) {
                        _updateStatus(
                            _deviceStatus.copyWith(lightBrightness: value));
                      },
                      activeColor: _getLightColor(_deviceStatus.lightMode),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.palette, color: Colors.grey[700]),
                    title: const Text('Màu sáng'),
                    subtitle: DropdownButton<String>(
                      value: _deviceStatus.lightMode,
                      isExpanded: true,
                      items: ['warm', 'amber', 'blue'].map((mode) {
                        return DropdownMenuItem(
                          value: mode,
                          child: Text(_getLightLabel(mode)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _updateStatus(
                              _deviceStatus.copyWith(lightMode: value));
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),

            // Music Settings
            _buildSectionCard(
              title: 'Nhạc',
              children: [
                SwitchListTile(
                  secondary: Icon(Icons.music_note, color: Colors.purple[600]),
                  title: const Text('Phát nhạc'),
                  value: _deviceStatus.isMusicPlaying,
                  onChanged: (value) {
                    _updateStatus(
                        _deviceStatus.copyWith(isMusicPlaying: value));
                  },
                  activeColor: Colors.purple[600],
                ),
                if (_deviceStatus.isMusicPlaying) ...[
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.volume_up, color: Colors.grey[700]),
                    title: const Text('Âm lượng'),
                    subtitle: Slider(
                      value: _deviceStatus.musicVolume,
                      onChanged: (value) {
                        _updateStatus(
                            _deviceStatus.copyWith(musicVolume: value));
                      },
                      activeColor: Colors.purple[600],
                    ),
                  ),
                ],
              ],
            ),

            // Safety Settings
            _buildSectionCard(
              title: 'An toàn',
              children: [
                ListTile(
                  leading: Icon(Icons.warning, color: Colors.orange[700]),
                  title: const Text('Ngưỡng cảnh báo nhiệt độ'),
                  subtitle: Text('${_temperatureThreshold.toStringAsFixed(1)}°C'),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Ngưỡng cảnh báo'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${_temperatureThreshold.toStringAsFixed(1)}°C'),
                            Slider(
                              value: _temperatureThreshold,
                              min: 40,
                              max: 60,
                              divisions: 20,
                              label: '${_temperatureThreshold.toStringAsFixed(1)}°C',
                              onChanged: (value) {
                                setState(() {
                                  _temperatureThreshold = value;
                                });
                              },
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _temperatureThreshold = _temperatureThreshold;
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Lưu'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(),
                SwitchListTile(
                  secondary: Icon(Icons.notifications, color: Colors.blue[600]),
                  title: const Text('Thông báo'),
                  subtitle: const Text('Nhận cảnh báo khi nhiệt độ cao'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                  activeColor: Colors.blue[600],
                ),
              ],
            ),

            // Auto Features
            _buildSectionCard(
              title: 'Tự động',
              children: [
                SwitchListTile(
                  secondary: Icon(Icons.light_mode, color: Colors.amber[700]),
                  title: const Text('Tự động bật đèn'),
                  subtitle: const Text('Bật đèn theo gợi ý của chatbot'),
                  value: _autoLightEnabled,
                  onChanged: (value) {
                    setState(() {
                      _autoLightEnabled = value;
                    });
                  },
                  activeColor: Colors.amber[600],
                ),
                const Divider(),
                SwitchListTile(
                  secondary: Icon(Icons.music_video, color: Colors.purple[600]),
                  title: const Text('Tự động phát nhạc'),
                  subtitle: const Text('Phát nhạc theo gợi ý của chatbot'),
                  value: _autoMusicEnabled,
                  onChanged: (value) {
                    setState(() {
                      _autoMusicEnabled = value;
                    });
                  },
                  activeColor: Colors.purple[600],
                ),
              ],
            ),

            // About
            _buildSectionCard(
              title: 'Thông tin',
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.blue),
                  title: Text('Phiên bản'),
                  subtitle: Text('1.0.0'),
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.help_outline, color: Colors.grey),
                  title: Text('Trợ giúp'),
                  subtitle: Text('Hướng dẫn sử dụng'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined,
                      color: Colors.grey),
                  title: const Text('Chính sách bảo mật'),
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

