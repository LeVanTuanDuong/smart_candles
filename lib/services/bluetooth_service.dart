import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:flutter/foundation.dart';

/// Service UUID for Smart Candle ESP32
const String candleServiceUuid = '0000180f-0000-1000-8000-00805f9b34fb'; // Battery Service (example, should match ESP32)

/// Characteristic UUIDs for Smart Candle
const String temperatureCharUuid = '00002a19-0000-1000-8000-00805f9b34fb'; // Temperature reading
const String lightControlCharUuid = '00002a1a-0000-1000-8000-00805f9b34fb'; // Light on/off
const String lightColorCharUuid = '00002a1b-0000-1000-8000-00805f9b34fb'; // Light color (RGB)
const String lightBrightnessCharUuid = '00002a1c-0000-1000-8000-00805f9b34fb'; // Light brightness (0-255)
const String musicControlCharUuid = '00002a1d-0000-1000-8000-00805f9b34fb'; // Music play/pause/stop

/// Device name pattern for Smart Candle
const String deviceNamePattern = 'CandleHub'; // ESP32 should advertise with this name

/// Bluetooth Service for Smart Candle ESP32
class BluetoothService extends ChangeNotifier {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  ble.BluetoothDevice? _connectedDevice;
  ble.BluetoothCharacteristic? _temperatureChar;
  ble.BluetoothCharacteristic? _lightControlChar;
  ble.BluetoothCharacteristic? _lightColorChar;
  ble.BluetoothCharacteristic? _lightBrightnessChar;
  ble.BluetoothCharacteristic? _musicControlChar;

  bool _isConnected = false;
  bool _isScanning = false;
  double _currentTemperature = 25.0;
  StreamSubscription<List<ble.ScanResult>>? _scanSubscription;
  StreamSubscription<ble.BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _temperatureSubscription;

  // Getters
  bool get isConnected => _isConnected;
  ble.BluetoothDevice? get connectedDevice => _connectedDevice;
  double get currentTemperature => _currentTemperature;
  bool get isScanning => _isScanning;

  /// Initialize Bluetooth adapter
  Future<bool> initialize() async {
    try {
      // Check if Bluetooth is available
      if (await ble.FlutterBluePlus.isSupported == false) {
        print('❌ Bluetooth không được hỗ trợ trên thiết bị này');
        return false;
      }

      // Check if Bluetooth is on
      ble.BluetoothAdapterState adapterState = await ble.FlutterBluePlus.adapterState.first;
      if (adapterState != ble.BluetoothAdapterState.on) {
        print('⚠️ Bluetooth chưa được bật. Vui lòng bật Bluetooth.');
        return false;
      }

      print('✅ Bluetooth adapter đã sẵn sàng');
      return true;
    } catch (e) {
      print('❌ Lỗi khởi tạo Bluetooth: $e');
      return false;
    }
  }

  /// Check if Bluetooth is ready for scanning
  Future<bool> isBluetoothReady() async {
    try {
      // Check if Bluetooth is available
      if (await ble.FlutterBluePlus.isSupported == false) {
        return false;
      }

      // Check if Bluetooth is on
      ble.BluetoothAdapterState adapterState = await ble.FlutterBluePlus.adapterState.first;
      return adapterState == ble.BluetoothAdapterState.on;
    } catch (e) {
      print('❌ Lỗi kiểm tra trạng thái Bluetooth: $e');
      return false;
    }
  }

  /// Start scanning for Smart Candle devices
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    if (_isScanning) {
      print('⚠️ Đang quét, vui lòng đợi...');
      return;
    }

    try {
      // Check if Bluetooth is ready before scanning
      final isReady = await isBluetoothReady();
      if (!isReady) {
        print('❌ Bluetooth chưa sẵn sàng. Vui lòng bật Bluetooth và thử lại.');
        _isScanning = false;
        notifyListeners();
        throw Exception('Bluetooth chưa được bật hoặc không được hỗ trợ');
      }

      _isScanning = true;
      notifyListeners();

      print('🔵 Bắt đầu quét thiết bị Smart Candle...');

      // Listen to scan results
      _scanSubscription = ble.FlutterBluePlus.scanResults.listen((results) {
        for (ble.ScanResult result in results) {
          final device = result.device;
          final deviceName = device.platformName.isNotEmpty 
              ? device.platformName 
              : 'Unknown';

          // Check if device name matches Smart Candle pattern
          if (deviceName.contains(deviceNamePattern)) {
            print('✅ Tìm thấy Smart Candle: ${device.platformName} (${device.remoteId})');
            stopScan();
            connectToDevice(device);
            return;
          }
        }
      }, onError: (error) {
        print('❌ Lỗi khi quét: $error');
        _isScanning = false;
        notifyListeners();
      });

      // Start scan with error handling
      try {
        await ble.FlutterBluePlus.startScan(
          timeout: timeout,
          withServices: [],
        );
      } catch (scanError) {
        // Handle specific scan errors
        final errorStr = scanError.toString().toLowerCase();
        if (errorStr.contains('bluetooth must be turned on') || 
            errorStr.contains('cbmanagerstate') ||
            errorStr.contains('unsupported')) {
          print('❌ Bluetooth chưa được bật hoặc không được hỗ trợ');
          _isScanning = false;
          notifyListeners();
          throw Exception('Vui lòng bật Bluetooth trong Cài đặt và thử lại');
        }
        rethrow;
      }

      // Auto stop after timeout
      Future.delayed(timeout, () {
        if (_isScanning) {
          stopScan();
          print('⏱️ Hết thời gian quét. Không tìm thấy thiết bị.');
        }
      });
    } catch (e) {
      print('❌ Lỗi khi bắt đầu quét: $e');
      _isScanning = false;
      notifyListeners();
      rethrow; // Re-throw để caller có thể xử lý
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    try {
      await ble.FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      _isScanning = false;
      notifyListeners();
      print('🛑 Đã dừng quét');
    } catch (e) {
      print('❌ Lỗi khi dừng quét: $e');
    }
  }

  /// Connect to a Bluetooth device
  Future<bool> connectToDevice(ble.BluetoothDevice device) async {
    try {
      print('🔵 Đang kết nối với ${device.platformName}...');

      _connectedDevice = device;

      // Listen to connection state
      _connectionSubscription = device.connectionState.listen((state) async {
        if (state == ble.BluetoothConnectionState.connected) {
          _isConnected = true;
          print('✅ Đã kết nối với ${device.platformName}');
          
          // Discover services and characteristics
          await _discoverServices();
          
          // Notify listeners about connection
          notifyListeners();
          
          // Read initial temperature after a short delay to ensure services are discovered
          await Future.delayed(const Duration(milliseconds: 1000));
          if (_isConnected && _temperatureChar != null) {
            await readTemperature();
            print('🌡️ Đã đọc nhiệt độ ban đầu: ${_currentTemperature.toStringAsFixed(1)}°C');
          }
        } else if (state == ble.BluetoothConnectionState.disconnected) {
          _isConnected = false;
          print('❌ Đã ngắt kết nối với ${device.platformName}');
          _clearCharacteristics();
          notifyListeners();
        }
      });

      // Connect to device
      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      return _isConnected;
    } catch (e) {
      print('❌ Lỗi khi kết nối: $e');
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  /// Discover services and characteristics
  Future<void> _discoverServices() async {
    if (_connectedDevice == null) return;

    try {
      print('🔍 Đang tìm kiếm services và characteristics...');

      List<ble.BluetoothService> services = await _connectedDevice!.discoverServices();

      for (ble.BluetoothService service in services) {
        // Find characteristics
        for (ble.BluetoothCharacteristic characteristic in service.characteristics) {
          final uuid = characteristic.uuid.toString().toLowerCase();

          // Temperature characteristic
          if (uuid.contains('temperature') || uuid.contains('temp') || 
              uuid == temperatureCharUuid.toLowerCase()) {
            _temperatureChar = characteristic;
            print('✅ Tìm thấy Temperature characteristic');
            _subscribeToTemperature();
          }

          // Light control characteristic
          if (uuid.contains('light') && uuid.contains('control') ||
              uuid == lightControlCharUuid.toLowerCase()) {
            _lightControlChar = characteristic;
            print('✅ Tìm thấy Light Control characteristic');
          }

          // Light color characteristic
          if (uuid.contains('color') || uuid == lightColorCharUuid.toLowerCase()) {
            _lightColorChar = characteristic;
            print('✅ Tìm thấy Light Color characteristic');
          }

          // Light brightness characteristic
          if (uuid.contains('brightness') || uuid == lightBrightnessCharUuid.toLowerCase()) {
            _lightBrightnessChar = characteristic;
            print('✅ Tìm thấy Light Brightness characteristic');
          }

          // Music control characteristic
          if (uuid.contains('music') || uuid == musicControlCharUuid.toLowerCase()) {
            _musicControlChar = characteristic;
            print('✅ Tìm thấy Music Control characteristic');
          }
        }
      }

      print('✅ Đã tìm thấy ${services.length} services');
    } catch (e) {
      print('❌ Lỗi khi tìm kiếm services: $e');
    }
  }

  /// Subscribe to temperature updates
  Future<void> _subscribeToTemperature() async {
    if (_temperatureChar == null) return;

    try {
      // Cancel existing subscription if any
      await _temperatureSubscription?.cancel();
      _temperatureSubscription = null;

      // Enable notifications
      await _temperatureChar!.setNotifyValue(true);
      print('✅ Đã bật notifications cho Temperature characteristic');

      // Listen to temperature updates
      _temperatureSubscription = _temperatureChar!.onValueReceived.listen((value) {
        if (value.isNotEmpty) {
          _parseTemperatureValue(value);
        }
      }, onError: (error) {
        print('❌ Lỗi khi nhận dữ liệu nhiệt độ: $error');
      });

      // Read initial temperature immediately after subscribing
      await Future.delayed(const Duration(milliseconds: 500));
      await readTemperature();

      print('✅ Đã đăng ký nhận cập nhật nhiệt độ');
    } catch (e) {
      print('❌ Lỗi khi đăng ký nhiệt độ: $e');
    }
  }

  /// Parse temperature value from different formats
  void _parseTemperatureValue(List<int> value) {
    try {
      double? temperature;

      // Try parsing as float (4 bytes) - most common for ESP32
      if (value.length >= 4) {
        try {
          final buffer = Uint8List.fromList(value).buffer.asByteData();
          temperature = buffer.getFloat32(0, Endian.little);
          print('🌡️ Nhiệt độ (float): ${temperature.toStringAsFixed(1)}°C');
        } catch (e) {
          // Not a float, try other formats
        }
      }

      // Try parsing as JSON string
      if (temperature == null) {
        try {
          final str = utf8.decode(value);
          final json = jsonDecode(str);
          if (json['temperature'] != null) {
            temperature = (json['temperature'] as num).toDouble();
            print('🌡️ Nhiệt độ (JSON): ${temperature.toStringAsFixed(1)}°C');
          } else if (json['temp'] != null) {
            temperature = (json['temp'] as num).toDouble();
            print('🌡️ Nhiệt độ (JSON temp): ${temperature.toStringAsFixed(1)}°C');
          }
        } catch (e) {
          // Not JSON, try plain string
        }
      }

      // Try parsing as plain string number
      if (temperature == null) {
        try {
          final str = utf8.decode(value).trim();
          temperature = double.tryParse(str);
          if (temperature != null) {
            print('🌡️ Nhiệt độ (string): ${temperature.toStringAsFixed(1)}°C');
          }
        } catch (e) {
          // Not a parseable string
        }
      }

      // Try parsing as 2-byte integer (temperature * 10, e.g., 350 = 35.0°C)
      if (temperature == null && value.length >= 2) {
        try {
          final buffer = Uint8List.fromList(value).buffer.asByteData();
          final tempInt = buffer.getUint16(0, Endian.little);
          temperature = tempInt / 10.0;
          print('🌡️ Nhiệt độ (int*10): ${temperature.toStringAsFixed(1)}°C');
        } catch (e) {
          // Not a 2-byte integer
        }
      }

      // Update temperature if successfully parsed
      if (temperature != null && temperature >= -50 && temperature <= 150) {
        // Validate temperature range (reasonable for candle)
        if (_currentTemperature != temperature) {
          _currentTemperature = temperature;
          print('🌡️ ✅ Cập nhật nhiệt độ: ${temperature.toStringAsFixed(1)}°C');
          notifyListeners();
        }
      } else {
        print('⚠️ Nhiệt độ không hợp lệ: $temperature');
      }
    } catch (e) {
      print('⚠️ Lỗi khi parse nhiệt độ: $e, Raw data: $value');
    }
  }

  /// Turn light on/off
  Future<bool> setLightOn(bool on) async {
    if (_lightControlChar == null || !_isConnected) {
      print('⚠️ Không thể điều khiển đèn: chưa kết nối hoặc characteristic không tồn tại');
      return false;
    }

    try {
      final command = on ? [0x01] : [0x00]; // 1 = on, 0 = off
      await _lightControlChar!.write(command, withoutResponse: false);
      print('💡 Đèn ${on ? "BẬT" : "TẮT"}');
      return true;
    } catch (e) {
      print('❌ Lỗi khi điều khiển đèn: $e');
      return false;
    }
  }

  /// Set light color (RGB)
  Future<bool> setLightColor(int red, int green, int blue) async {
    if (_lightColorChar == null || !_isConnected) {
      print('⚠️ Không thể đổi màu đèn: chưa kết nối hoặc characteristic không tồn tại');
      return false;
    }

    try {
      // Clamp values to 0-255
      red = red.clamp(0, 255);
      green = green.clamp(0, 255);
      blue = blue.clamp(0, 255);

      final command = [red, green, blue];
      await _lightColorChar!.write(command, withoutResponse: false);
      print('🎨 Đổi màu đèn: RGB($red, $green, $blue)');
      return true;
    } catch (e) {
      print('❌ Lỗi khi đổi màu đèn: $e');
      return false;
    }
  }

  /// Set light color by mode (warm, amber, blue)
  Future<bool> setLightMode(String mode) async {
    switch (mode.toLowerCase()) {
      case 'warm':
        // Warm white: RGB(255, 200, 150)
        return await setLightColor(255, 200, 150);
      case 'amber':
        // Amber: RGB(255, 191, 0)
        return await setLightColor(255, 191, 0);
      case 'blue':
        // Soft blue: RGB(135, 206, 250)
        return await setLightColor(135, 206, 250);
      default:
        return await setLightColor(255, 200, 150); // Default to warm
    }
  }

  /// Set light brightness (0.0 - 1.0)
  Future<bool> setLightBrightness(double brightness) async {
    if (_lightBrightnessChar == null || !_isConnected) {
      print('⚠️ Không thể chỉnh độ sáng: chưa kết nối hoặc characteristic không tồn tại');
      return false;
    }

    try {
      // Clamp brightness to 0.0-1.0 and convert to 0-255
      brightness = brightness.clamp(0.0, 1.0);
      final brightnessValue = (brightness * 255).round();

      final command = [brightnessValue];
      await _lightBrightnessChar!.write(command, withoutResponse: false);
      print('💡 Độ sáng: ${(brightness * 100).toStringAsFixed(0)}%');
      return true;
    } catch (e) {
      print('❌ Lỗi khi chỉnh độ sáng: $e');
      return false;
    }
  }

  /// Request temperature reading (manual read)
  Future<double?> readTemperature() async {
    if (_temperatureChar == null || !_isConnected) {
      print('⚠️ Không thể đọc nhiệt độ: chưa kết nối hoặc characteristic không tồn tại');
      return null;
    }

    try {
      print('📖 Đang đọc nhiệt độ từ ESP32...');
      final value = await _temperatureChar!.read();
      if (value.isNotEmpty) {
        _parseTemperatureValue(value);
        return _currentTemperature;
      } else {
        print('⚠️ Không nhận được dữ liệu nhiệt độ');
        return null;
      }
    } catch (e) {
      print('❌ Lỗi khi đọc nhiệt độ: $e');
      return null;
    }
  }

  /// Control music playback
  Future<bool> setMusicControl(String command) async {
    if (_musicControlChar == null || !_isConnected) {
      print('⚠️ Không thể điều khiển nhạc: chưa kết nối hoặc characteristic không tồn tại');
      return false;
    }

    try {
      List<int> cmd;
      switch (command.toLowerCase()) {
        case 'play':
          cmd = [0x01];
          break;
        case 'pause':
          cmd = [0x02];
          break;
        case 'stop':
          cmd = [0x00];
          break;
        default:
          return false;
      }

      await _musicControlChar!.write(cmd, withoutResponse: false);
      print('🎵 Nhạc: $command');
      return true;
    } catch (e) {
      print('❌ Lỗi khi điều khiển nhạc: $e');
      return false;
    }
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    try {
      await _connectionSubscription?.cancel();
      _connectionSubscription = null;

      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        print('🔌 Đã ngắt kết nối');
      }

      _clearCharacteristics();
      _isConnected = false;
      _connectedDevice = null;
      notifyListeners();
    } catch (e) {
      print('❌ Lỗi khi ngắt kết nối: $e');
    }
  }

  /// Clear all characteristics
  void _clearCharacteristics() {
    // Cancel temperature subscription
    _temperatureSubscription?.cancel();
    _temperatureSubscription = null;
    
    _temperatureChar = null;
    _lightControlChar = null;
    _lightColorChar = null;
    _lightBrightnessChar = null;
    _musicControlChar = null;
    
    print('🧹 Đã xóa tất cả characteristics và subscriptions');
  }

  /// Dispose resources
  @override
  void dispose() {
    stopScan();
    disconnect();
    _temperatureSubscription?.cancel();
    _temperatureSubscription = null;
    super.dispose();
  }
}

