import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service UUID for ESP32
const String candleServiceUuid =
    '0000180f-0000-1000-8000-00805f9b34fb'; // SERVICE_UUID

/// Characteristic UUIDs
const String temperatureCharUuid =
    '00002a19-0000-1000-8000-00805f9b34fb'; // TEMP_UUID
const String lightControlCharUuid =
    '00002a1a-0000-1000-8000-00805f9b34fb'; // RELAY_UUID
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
  final Map<String, ble.ScanResult> _discovered = {};
  String _lastScanError = '';
  bool _enableLogs = true;

  // Getters
  bool get isConnected => _isConnected;
  ble.BluetoothDevice? get connectedDevice => _connectedDevice;
  double get currentTemperature => _currentTemperature;
  bool get isScanning => _isScanning;
  List<ble.ScanResult> get discoveredDevices => _discovered.values.toList();
  String get lastScanError => _lastScanError;

  void setLoggingEnabled(bool enabled) {
    _enableLogs = enabled;
  }

  void _log(String message) {
    if (_enableLogs) {
      debugPrint('[BLE] $message');
    }
  }

  bool _isValidDeviceName(String name) {
    return name.trim().isNotEmpty && name.toLowerCase() != 'unknown';
  }

  void _logCharacteristic(ble.BluetoothCharacteristic c, String serviceUuid) {
    final props = <String>[];
    if (c.properties.read) props.add('read');
    if (c.properties.write) props.add('write');
    if (c.properties.writeWithoutResponse) props.add('writeNoResp');
    if (c.properties.notify) props.add('notify');
    if (c.properties.indicate) props.add('indicate');
    _log('  chr=${c.uuid} svc=$serviceUuid props=${props.join(',')}');
  }

  String _normalizeUuid(String uuid) {
    return uuid.toLowerCase().replaceAll('-', '');
  }

  String _shortUuid(String uuid) {
    final cleaned = _normalizeUuid(uuid);
    // 16-bit UUID like "2a19"
    if (cleaned.length == 4) return cleaned;
    // 128-bit base UUID: 0000xxxx00001000800000805f9b34fb
    if (cleaned.length == 32 &&
        cleaned.startsWith('0000') &&
        cleaned.endsWith('00001000800000805f9b34fb')) {
      return cleaned.substring(4, 8);
    }
    return cleaned;
  }

  bool _isUuidMatch(String uuid, String target) {
    final u = _normalizeUuid(uuid);
    final t = _normalizeUuid(target);
    if (u == t) return true;
    return _shortUuid(uuid) == _shortUuid(target);
  }

  Future<bool> _ensurePermissions() async {
    if (!Platform.isAndroid) return true;

    final scanStatus = await Permission.bluetoothScan.status;
    final connectStatus = await Permission.bluetoothConnect.status;

    if (scanStatus.isGranted && connectStatus.isGranted) {
      return true;
    }

    final results = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final granted = (results[Permission.bluetoothScan]?.isGranted ?? false) &&
        (results[Permission.bluetoothConnect]?.isGranted ?? false);
    if (!granted) {
      _lastScanError = 'Bluetooth permissions denied';
      _log(_lastScanError);
    }
    return granted;
  }

  /// Initialize Bluetooth adapter
  Future<bool> initialize() async {
    try {
      // Check if Bluetooth is available
      if (await ble.FlutterBluePlus.isSupported == false) {
        // Removed print statement: '❌ Bluetooth không được hỗ trợ trên thiết bị này');
        return false;
      }

      // Check if Bluetooth is on
      ble.BluetoothAdapterState adapterState = await ble.FlutterBluePlus.adapterState.first;
      if (adapterState != ble.BluetoothAdapterState.on) {
        // Removed print statement: '⚠️ Bluetooth chưa được bật. Vui lòng bật Bluetooth.');
        return false;
      }

      _log('Bluetooth adapter ready');
      return true;
    } catch (e) {
      _log('Bluetooth init error: $e');
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
      _log('Bluetooth state check error: $e');
      return false;
    }
  }

  /// Start scanning for Smart Candle devices
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 10),
    String? namePattern,
    bool autoConnect = true,
  }) async {
    if (_isScanning) {
      _log('Scan already in progress');
      return;
    }

    try {
      _lastScanError = '';
      _discovered.clear();
      notifyListeners();

      final permissionsOk = await _ensurePermissions();
      if (!permissionsOk) {
        _isScanning = false;
        notifyListeners();
        throw Exception('Vui lòng cấp quyền Bluetooth cho ứng dụng');
      }

      // Check if Bluetooth is ready before scanning
      final isReady = await isBluetoothReady();
      if (!isReady) {
        _log('Bluetooth not ready');
        _isScanning = false;
        notifyListeners();
        throw Exception('Bluetooth chưa được bật hoặc không được hỗ trợ');
      }

      _isScanning = true;
      notifyListeners();

      _log('Start scanning for BLE devices');

      // Listen to scan results
      _scanSubscription = ble.FlutterBluePlus.scanResults.listen((results) {
        for (ble.ScanResult result in results) {
          final device = result.device;
          final deviceName = device.platformName;
          if (!_isValidDeviceName(deviceName)) {
            continue;
          }
          _discovered[device.remoteId.str] = result;
          notifyListeners();

          // Check if device name matches Smart Candle pattern
          final target = (namePattern ?? deviceNamePattern).toLowerCase();
          if (autoConnect && deviceName.toLowerCase().contains(target)) {
            _log('Auto-connect match: ${device.platformName} (${device.remoteId})');
            stopScan();
            connectToDevice(device);
            return;
          }
        }
      }, onError: (error) {
        _lastScanError = 'Scan error: $error';
        _log(_lastScanError);
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
          _lastScanError = 'Bluetooth chưa được bật hoặc không được hỗ trợ';
          _log(_lastScanError);
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
          _log('Scan timeout');
        }
      });
    } catch (e) {
      _lastScanError = 'Start scan error: $e';
      _log(_lastScanError);
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
      _log('Scan stopped');
    } catch (e) {
      _log('Stop scan error: $e');
    }
  }

  /// Connect to a Bluetooth device
  Future<bool> connectToDevice(ble.BluetoothDevice device) async {
    try {
      _log('Connecting to ${device.platformName}...');

      _connectedDevice = device;

      // Listen to connection state
      _connectionSubscription = device.connectionState.listen((state) async {
        if (state == ble.BluetoothConnectionState.connected) {
          _isConnected = true;
          _log('Connected to ${device.platformName}');
          
          // Discover services and characteristics
          await _discoverServices();
          
          // Notify listeners about connection
          notifyListeners();
          
          // Read initial temperature after a short delay to ensure services are discovered
          await Future.delayed(const Duration(milliseconds: 1000));
          if (_isConnected && _temperatureChar != null) {
            await readTemperature();
            // Removed print statement: '🌡️ Đã đọc nhiệt độ ban đầu: ${_currentTemperature.toStringAsFixed(1)}°C');
          }
        } else if (state == ble.BluetoothConnectionState.disconnected) {
          _isConnected = false;
          _log('Disconnected from ${device.platformName}');
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
      _log('Connect error: $e');
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  /// Discover services and characteristics
  Future<void> _discoverServices() async {
    if (_connectedDevice == null) return;

    try {
      _log('Discovering services/characteristics...');

      List<ble.BluetoothService> services =
          await _connectedDevice!.discoverServices();

      // Dump all services and characteristics for visibility
      for (ble.BluetoothService service in services) {
        final serviceUuid = service.uuid.toString();
        _log('svc=$serviceUuid');
        for (ble.BluetoothCharacteristic characteristic
            in service.characteristics) {
          _logCharacteristic(characteristic, serviceUuid);
        }
      }

      // Find by UUID across all services (no service filtering)
      for (ble.BluetoothService service in services) {
        for (ble.BluetoothCharacteristic characteristic
            in service.characteristics) {
          final uuid = characteristic.uuid.toString();

          if (_temperatureChar == null &&
              _isUuidMatch(uuid, temperatureCharUuid)) {
            _temperatureChar = characteristic;
            _log('Found temperature characteristic');
            _subscribeToTemperature();
          }

          if (_lightControlChar == null &&
              _isUuidMatch(uuid, lightControlCharUuid)) {
            _lightControlChar = characteristic;
            _log('Found light control characteristic');
          }

          if (_lightColorChar == null &&
              _isUuidMatch(uuid, lightColorCharUuid)) {
            _lightColorChar = characteristic;
            _log('Found light color characteristic');
          }

          if (_lightBrightnessChar == null &&
              _isUuidMatch(uuid, lightBrightnessCharUuid)) {
            _lightBrightnessChar = characteristic;
            _log('Found light brightness characteristic');
          }

          if (_musicControlChar == null &&
              _isUuidMatch(uuid, musicControlCharUuid)) {
            _musicControlChar = characteristic;
            _log('Found music control characteristic');
          }
        }
      }

      if (_temperatureChar == null) {
        _log('Temperature characteristic not found');
      }
      if (_lightControlChar == null) {
        _log('Relay characteristic not found');
      }

      _log('Services discovered: ${services.length}');
    } catch (e) {
      _log('Service discovery error: $e');
    }
  }

  /// Subscribe to temperature updates
  Future<void> _subscribeToTemperature() async {
    if (_temperatureChar == null) return;

    try {
      // Cancel existing subscription if any
      await _temperatureSubscription?.cancel();
      _temperatureSubscription = null;

      // Enable notifications if supported
      if (_temperatureChar!.properties.notify ||
          _temperatureChar!.properties.indicate) {
        await _temperatureChar!.setNotifyValue(true);
        _log('Temperature notifications enabled');
      } else {
        _log('Temperature characteristic has no notify/indicate');
      }

      // Listen to temperature updates
      _temperatureSubscription = _temperatureChar!.onValueReceived.listen((value) {
        if (value.isNotEmpty) {
          _parseTemperatureValue(value);
        }
      }, onError: (error) {
        _log('Temperature notification error: $error');
      });

      // Read initial temperature immediately after subscribing
      await Future.delayed(const Duration(milliseconds: 500));
      await readTemperature();

      _log('Temperature subscription ready');
    } catch (e) {
      _log('Temperature subscribe error: $e');
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
          // Removed print statement: '🌡️ Nhiệt độ (float): ${temperature.toStringAsFixed(1)}°C');
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
            // Removed print statement: '🌡️ Nhiệt độ (JSON): ${temperature.toStringAsFixed(1)}°C');
          } else if (json['temp'] != null) {
            temperature = (json['temp'] as num).toDouble();
            // Removed print statement: '🌡️ Nhiệt độ (JSON temp): ${temperature.toStringAsFixed(1)}°C');
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
            _log('Temperature string: ${temperature.toStringAsFixed(1)}');
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
          // Removed print statement: '🌡️ Nhiệt độ (int*10): ${temperature.toStringAsFixed(1)}°C');
        } catch (e) {
          // Not a 2-byte integer
        }
      }

      // Update temperature if successfully parsed
      if (temperature != null && temperature >= -50 && temperature <= 150) {
        // Validate temperature range (reasonable for candle)
        if (_currentTemperature != temperature) {
          _currentTemperature = temperature;
          _log('Temperature update: ${temperature.toStringAsFixed(1)}');
          notifyListeners();
        }
      } else {
        _log('Invalid temperature: $temperature');
      }
    } catch (e) {
      _log('Temperature parse error: $e, raw: $value');
    }
  }

  /// Turn light on/off
  Future<bool> setLightOn(bool on) async {
    if (_lightControlChar == null || !_isConnected) {
      // Removed print statement: '⚠️ Không thể điều khiển đèn: chưa kết nối hoặc characteristic không tồn tại');
      return false;
    }

    try {
      final command = on ? [0x01] : [0x00]; // 1 = on, 0 = off
      final canWrite = _lightControlChar!.properties.write;
      final canWriteNoResp = _lightControlChar!.properties.writeWithoutResponse;
      if (!canWrite && !canWriteNoResp) {
        _log('Relay characteristic not writable');
        return false;
      }
      await _lightControlChar!.write(
        command,
        withoutResponse: !canWrite,
      );
      // Removed print statement: '💡 Đèn ${on ? "BẬT" : "TẮT"}');
      return true;
    } catch (e) {
      // Removed print statement: '❌ Lỗi khi điều khiển đèn: $e');
      return false;
    }
  }

  /// Set light color (RGB)
  Future<bool> setLightColor(int red, int green, int blue) async {
    if (_lightColorChar == null || !_isConnected) {
      // Removed print statement: '⚠️ Không thể đổi màu đèn: chưa kết nối hoặc characteristic không tồn tại');
      return false;
    }

    try {
      // Clamp values to 0-255
      red = red.clamp(0, 255);
      green = green.clamp(0, 255);
      blue = blue.clamp(0, 255);

      final command = [red, green, blue];
      await _lightColorChar!.write(command, withoutResponse: false);
      // Removed print statement: '🎨 Đổi màu đèn: RGB($red, $green, $blue)');
      return true;
    } catch (e) {
      // Removed print statement: '❌ Lỗi khi đổi màu đèn: $e');
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
      // Removed print statement: '⚠️ Không thể chỉnh độ sáng: chưa kết nối hoặc characteristic không tồn tại');
      return false;
    }

    try {
      // Clamp brightness to 0.0-1.0 and convert to 0-255
      brightness = brightness.clamp(0.0, 1.0);
      final brightnessValue = (brightness * 255).round();

      final command = [brightnessValue];
      await _lightBrightnessChar!.write(command, withoutResponse: false);
      // Removed print statement: '💡 Độ sáng: ${(brightness * 100).toStringAsFixed(0)}%');
      return true;
    } catch (e) {
      // Removed print statement: '❌ Lỗi khi chỉnh độ sáng: $e');
      return false;
    }
  }

  /// Request temperature reading (manual read)
  Future<double?> readTemperature() async {
    if (_temperatureChar == null || !_isConnected) {
      _log('Read temperature failed: not connected or missing characteristic');
      return null;
    }

    try {
      // Removed print statement: '📖 Đang đọc nhiệt độ từ ESP32...');
      final value = await _temperatureChar!.read();
      if (value.isNotEmpty) {
        _parseTemperatureValue(value);
        return _currentTemperature;
      } else {
        _log('No temperature data received');
        return null;
      }
    } catch (e) {
      _log('Read temperature error: $e');
      return null;
    }
  }

  /// Control music playback
  Future<bool> setMusicControl(String command) async {
    if (_musicControlChar == null || !_isConnected) {
      _log('Music control failed: not connected or missing characteristic');
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
      _log('Music control: $command');
      return true;
    } catch (e) {
      _log('Music control error: $e');
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
        _log('Disconnected');
      }

      _clearCharacteristics();
      _isConnected = false;
      _connectedDevice = null;
      notifyListeners();
    } catch (e) {
      _log('Disconnect error: $e');
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
    
    _log('Cleared characteristics and subscriptions');
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
