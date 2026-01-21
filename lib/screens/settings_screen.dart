import 'package:flutter/material.dart';
import '../models/device_status.dart';
import '../services/settings_service.dart';
import '../services/bluetooth_service.dart';
import '../services/auth_service.dart';
import '../services/wifi_service.dart';
import 'login_screen.dart';

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
  final BluetoothService _bluetoothService = BluetoothService();
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _deviceStatus = widget.deviceStatus;
    // Validate and fix lightMode if invalid
    final validLightMode = _getValidLightMode(_deviceStatus.lightMode);
    if (_deviceStatus.lightMode != validLightMode) {
      _deviceStatus = _deviceStatus.copyWith(lightMode: validLightMode);
    }
    _loadSettings();
    _initializeBluetooth();

    // Listen to Bluetooth connection changes
    _bluetoothService.addListener(_onBluetoothStateChanged);
  }

  @override
  void dispose() {
    _bluetoothService.removeListener(_onBluetoothStateChanged);
    super.dispose();
  }

  void _onBluetoothStateChanged() {
    if (mounted) {
      setState(() {
        _deviceStatus = _deviceStatus.copyWith(
          isBluetoothConnected: _bluetoothService.isConnected,
        );
      });
      widget.onStatusChanged(_deviceStatus);
    }
  }

  Future<void> _initializeBluetooth() async {
    final initialized = await _bluetoothService.initialize();
    if (!initialized && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng bật Bluetooth để kết nối với nến thông minh'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _connectToDevice() async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
    });

    try {
      // First, check if Bluetooth is ready
      final isReady = await _bluetoothService.isBluetoothReady();
      if (!isReady) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⚠️ Vui lòng bật Bluetooth trong Cài đặt và thử lại',
              ),
              duration: Duration(seconds: 4),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Start scanning for devices
      await _bluetoothService.startScan(timeout: const Duration(seconds: 10));

      // Show scanning message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đang tìm kiếm thiết bị Smart Candle...'),
            duration: Duration(seconds: 10),
          ),
        );
      }

      // Wait a bit for connection
      await Future.delayed(const Duration(seconds: 12));

      if (_bluetoothService.isConnected && mounted) {
        _updateStatus(_deviceStatus.copyWith(isBluetoothConnected: true));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã kết nối với Smart Candle'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '❌ Không tìm thấy thiết bị. Vui lòng đảm bảo nến đã bật và ở gần.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Lỗi kết nối: $e';

        // Provide user-friendly error messages
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('bluetooth must be turned on') ||
            errorStr.contains('cbmanagerstate') ||
            errorStr.contains('unsupported') ||
            errorStr.contains('bluetooth chưa được bật')) {
          errorMessage =
              'Vui lòng bật Bluetooth trong Cài đặt của thiết bị và thử lại';
        } else if (errorStr.contains('permission') ||
            errorStr.contains('quyền')) {
          errorMessage =
              'Vui lòng cấp quyền Bluetooth cho ứng dụng trong Cài đặt';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Đóng',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await SettingsService.loadAllSettings();
      setState(() {
        _temperatureThreshold = settings['temperatureThreshold'] as double;
        _notificationsEnabled = settings['notificationsEnabled'] as bool;
        _autoLightEnabled = settings['autoLightEnabled'] as bool;
        _autoMusicEnabled = settings['autoMusicEnabled'] as bool;
      });
    } catch (e) {
      // Removed print statement: 'Error loading settings: $e');
    }
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

  // Get valid light mode, fallback to 'warm' if invalid
  String _getValidLightMode(String? mode) {
    const validModes = ['warm', 'amber', 'blue'];
    if (mode != null && validModes.contains(mode)) {
      return mode;
    }
    return 'warm'; // Default fallback
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

  void _showWifiDialog() {
    final ssidController = TextEditingController();
    final passwordController = TextEditingController();
    bool isObscure = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Cấu hình WiFi cho Nến'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: ssidController,
                    decoration: const InputDecoration(
                      labelText: 'Tên WiFi (SSID)',
                      prefixIcon: Icon(Icons.wifi),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: isObscure,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            isObscure = !isObscure;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); // Close dialog first

                    if (!_deviceStatus.isBluetoothConnected) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Vui lòng kết nối Bluetooth trước')),
                      );
                      return;
                    }

                    // Show loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Đang gửi cấu hình WiFi...')),
                    );

                    final success = await WifiService().configureWifi(
                      ssidController.text,
                      passwordController.text,
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? '✅ Đã gửi cấu hình WiFi thành công!'
                                : '❌ Gửi cấu hình thất bại.',
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Kết nối'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showIpDialog() {
    final ipController =
        TextEditingController(text: _bluetoothService.deviceIp ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cấu hình IP thủ công'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Nhập địa chỉ IP của nến để điều khiển qua WiFi (nhanh hơn Bluetooth).',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ipController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ IP (VD: 192.168.1.100)',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _bluetoothService.setDeviceIp(ipController.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ipController.text.isNotEmpty
                            ? '✅ Đã lưu IP: ${ipController.text}'
                            : '🗑️ Đã xóa cấu hình IP',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Cài đặt',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
                  trailing: _isConnecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Switch(
                          value: _deviceStatus.isBluetoothConnected,
                          onChanged: (value) async {
                            await SettingsService.setBluetoothEnabled(value);
                            if (value) {
                              // Connect to ESP32
                              await _connectToDevice();
                            } else {
                              // Disconnect
                              await _bluetoothService.disconnect();
                              _updateStatus(
                                _deviceStatus.copyWith(
                                  isBluetoothConnected: false,
                                ),
                              );
                            }
                          },
                          activeColor: Colors.blue[600],
                        ),
                ),
                if (_deviceStatus.isBluetoothConnected) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.wifi, color: Colors.blue),
                    title: const Text('Cấu hình WiFi'),
                    subtitle: const Text('Kết nối nến với mạng WiFi'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showWifiDialog,
                  ),
                ],
                const Divider(),
                ListTile(
                  leading: Icon(Icons.settings_ethernet,
                      color: _bluetoothService.hasWifiConnection
                          ? Colors.green
                          : Colors.grey),
                  title: const Text('IP Thiết bị (WiFi Control)'),
                  subtitle: Text(
                    _bluetoothService.deviceIp != null &&
                            _bluetoothService.deviceIp!.isNotEmpty
                        ? _bluetoothService.deviceIp!
                        : 'Chưa cấu hình',
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: _showIpDialog,
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
                  onChanged: (value) async {
                    // 1. Update UI immediately for responsiveness
                    _updateStatus(_deviceStatus.copyWith(isLightOn: value));

                    // 2. Call Service to control device
                    final success = await _bluetoothService.setLightOn(value);

                    // 3. Revert if failed (optional, but good UX)
                    if (!success && mounted) {
                      _updateStatus(_deviceStatus.copyWith(isLightOn: !value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                '❌ Không thể điều khiển đèn (Kiểm tra kết nối)')),
                      );
                    }
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
                          _deviceStatus.copyWith(lightBrightness: value),
                        );
                      },
                      onChangeEnd: (value) async {
                        await _bluetoothService.setLightBrightness(value);
                      },
                      activeColor: _getLightColor(_deviceStatus.lightMode),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.palette, color: Colors.grey[700]),
                    title: const Text('Màu sáng'),
                    subtitle: DropdownButton<String>(
                      value: _getValidLightMode(_deviceStatus.lightMode),
                      isExpanded: true,
                      items: ['warm', 'amber', 'blue'].map((mode) {
                        return DropdownMenuItem(
                          value: mode,
                          child: Text(_getLightLabel(mode)),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        if (value != null) {
                          _updateStatus(
                            _deviceStatus.copyWith(lightMode: value),
                          );
                          await _bluetoothService.setLightMode(value);
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
                  onChanged: (value) async {
                    _updateStatus(
                      _deviceStatus.copyWith(isMusicPlaying: value),
                    );
                    final command = value ? 'play' : 'pause';
                    final success =
                        await _bluetoothService.setMusicControl(command);
                    if (!success && mounted) {
                      _updateStatus(
                          _deviceStatus.copyWith(isMusicPlaying: !value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('❌ Không thể điều khiển nhạc')),
                      );
                    }
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
                          _deviceStatus.copyWith(musicVolume: value),
                        );
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
                  subtitle: Text(
                    '${_temperatureThreshold.toStringAsFixed(1)}°C',
                  ),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Ngưỡng cảnh báo'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_temperatureThreshold.toStringAsFixed(1)}°C',
                            ),
                            Slider(
                              value: _temperatureThreshold,
                              min: 40,
                              max: 60,
                              divisions: 20,
                              label:
                                  '${_temperatureThreshold.toStringAsFixed(1)}°C',
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
                            onPressed: () async {
                              // Save temperature threshold
                              await SettingsService.setTemperatureThreshold(
                                _temperatureThreshold,
                              );
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Đã lưu ngưỡng cảnh báo: ${_temperatureThreshold.toStringAsFixed(1)}°C',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
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
                  onChanged: (value) async {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    await SettingsService.setNotificationsEnabled(value);
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
                  onChanged: (value) async {
                    setState(() {
                      _autoLightEnabled = value;
                    });
                    await SettingsService.setAutoLightEnabled(value);
                  },
                  activeColor: Colors.amber[600],
                ),
                const Divider(),
                SwitchListTile(
                  secondary: Icon(Icons.music_video, color: Colors.purple[600]),
                  title: const Text('Tự động phát nhạc'),
                  subtitle: const Text('Phát nhạc theo gợi ý của chatbot'),
                  value: _autoMusicEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _autoMusicEnabled = value;
                    });
                    await SettingsService.setAutoMusicEnabled(value);
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
                  leading: const Icon(
                    Icons.privacy_tip_outlined,
                    color: Colors.grey,
                  ),
                  title: const Text('Chính sách bảo mật'),
                  onTap: () {},
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Đăng xuất',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    final authService = AuthService();
                    try {
                      await authService.signOut();
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Lỗi đăng xuất: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
