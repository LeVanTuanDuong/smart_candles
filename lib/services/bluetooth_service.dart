import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bluetooth Service for Smart Candle ESP32 (Classic Bluetooth)
class BluetoothService extends ChangeNotifier {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  BluetoothConnection? _connection;
  bool _isConnected = false;
  bool _isConnecting = false;

  // Data State
  double _currentTemperature = 0.0;
  double _currentHumidity = 0.0;
  bool _isOverheat = false;
  String _deviceIp = "";

  // Voice Data State (Simplified for now)
  String _lastUserText = "";
  String _lastAiResponse = "";
  String _lastDetectedEmotion = "";

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  double get currentTemperature => _currentTemperature;
  double get currentHumidity => _currentHumidity;
  bool get isOverheat => _isOverheat;
  String get deviceIp => _deviceIp;
  bool get hasWifiConnection => _deviceIp.isNotEmpty;

  String get lastUserText => _lastUserText;
  String get lastAiResponse => _lastAiResponse;
  String get lastDetectedEmotion => _lastDetectedEmotion;

  // Stream for raw data (optional)
  final StreamController<String> _dataStreamController =
      StreamController<String>.broadcast();
  Stream<String> get dataStream => _dataStreamController.stream;

  // Init method to match old API if needed (can be empty)
  Future<bool> initialize() async {
    return true;
  }

  Future<bool> isBluetoothReady() async {
    return (await FlutterBluetoothSerial.instance.state) ==
        BluetoothState.STATE_ON;
  }

  Future<void> startScan(
      {Duration timeout = const Duration(seconds: 10)}) async {
    // This method was for BLE. For classic, we use DiscoveryPage directly.
    // Keeping empty or throwing unsupported if called.
  }

  /// Connect to device by address
  Future<bool> connect(String address) async {
    if (_isConnected) return true;
    if (_isConnecting) return false;

    _isConnecting = true;
    notifyListeners();

    try {
      print('🔵 Connecting to $address...');
      _connection = await BluetoothConnection.toAddress(address);
      print('✅ Connected to $address');

      _isConnected = true;
      _isConnecting = false;
      notifyListeners();

      // Listen to incoming data
      _connection!.input!.listen(_onDataReceived).onDone(() {
        _isConnected = false;
        notifyListeners();
        print('❌ Disconnected remotely');
      });

      return true;
    } catch (e) {
      print('❌ Connection failed: $e');
      _isConnected = false;
      _isConnecting = false;
      notifyListeners();
      return false;
    }
  }

  /// Disconnect
  Future<void> disconnect() async {
    try {
      await _connection?.close();
      _connection = null;
      _isConnected = false;
      notifyListeners();
      print('🔌 Disconnected locally');
    } catch (e) {
      print('❌ Error disconnecting: $e');
    }
  }

  /// Send command to ESP32
  Future<bool> sendCommand(String command) async {
    if (!_isConnected || _connection == null) return false;
    try {
      _connection!.output.add(ascii.encode(command + "\n"));
      await _connection!.output.allSent;
      print('📤 Sent: $command');
      return true;
    } catch (e) {
      print('❌ Error sending command: $e');
      return false;
    }
  }

  // Buffer for data handling
  String _buffer = "";

  /// Handle incoming data
  void _onDataReceived(Uint8List data) {
    try {
      String message = ascii.decode(data);
      _buffer += message;

      if (_buffer.contains('\n')) {
        List<String> parts = _buffer.split('\n');
        if (_buffer.endsWith('\n')) {
          _buffer = "";
        } else {
          _buffer = parts.removeLast();
        }

        for (String part in parts) {
          if (part.trim().isNotEmpty) {
            _processMessage(part.trim());
          }
        }
      }
    } catch (e) {
      print('❌ Error processing data: $e');
    }
  }

  /// Process individual message (JSON or Text)
  void _processMessage(String message) {
    print('📥 Received: $message');
    _dataStreamController.add(message);

    try {
      // Parse JSON: {"temp": 25.0, "humi": 60.0, "alert": 0}
      if (message.startsWith('{') && message.endsWith('}')) {
        final Map<String, dynamic> json = jsonDecode(message);

        // Sensor Data
        if (json.containsKey('temp')) {
          _currentTemperature = json['temp']?.toDouble() ?? _currentTemperature;
        }
        if (json.containsKey('humi')) {
          _currentHumidity = json['humi']?.toDouble() ?? _currentHumidity;
        }
        if (json.containsKey('alert')) {
          _isOverheat = (json['alert'] == 1);
        }

        // Voice/AI Data
        if (json.containsKey('user_text')) {
          _lastUserText = json['user_text'];
        }
        if (json.containsKey('ai_text')) {
          _lastAiResponse = json['ai_text'];
        }
        if (json.containsKey('emotion')) {
          _lastDetectedEmotion = json['emotion'];
        }

        notifyListeners();
      } else if (message.contains("EMERGENCY")) {
        _isOverheat = true;
        notifyListeners();
      }
    } catch (e) {
      // Ignore parse errors
    }
  }

  // --- Convenience Methods Mapping for Compatibility ---

  Future<bool> setLightOn(bool on) =>
      sendCommand(on ? "LIGHT_ON" : "LIGHT_OFF");

  Future<bool> setLightBrightness(double value) {
    // 0.0 - 1.0
    int val = (value * 255).round().clamp(0, 255);
    return sendCommand("BRIGHT:$val");
  }

  Future<bool> setLightMode(String mode) {
    return sendCommand("MODE:$mode");
  }

  Future<bool> setMusicControl(String command) {
    String cmd = "MUSIC_STOP";
    if (command.toLowerCase() == 'play') cmd = "MUSIC_PLAY";
    if (command.toLowerCase() == 'pause') cmd = "MUSIC_PAUSE"; // If supported
    return sendCommand(cmd);
  }

  // WiFi Methods
  Future<void> setDeviceIp(String ip) async {
    _deviceIp = ip;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('candle_device_ip', ip);
    notifyListeners();
  }

  Future<bool> sendWifiCredentials(String jsonString) async {
    await sendCommand("WIFI:$jsonString"); // Custom protocol adaptation
    return true;
  }
}
