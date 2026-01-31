import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:smart_candles/shared/services/bluetooth_service.dart';

class WifiService extends ChangeNotifier {
  static final WifiService _instance = WifiService._internal();
  factory WifiService() => _instance;
  WifiService._internal();

  final BluetoothService _bluetoothService = BluetoothService();
  bool _isConfiguring = false;

  bool get isConfiguring => _isConfiguring;

  Future<bool> configureWifi(String ssid, String password) async {
    if (!_bluetoothService.isConnected) {
      debugPrint('⚠️ Cannot configure WiFi: Device not connected');
      return false;
    }
    _isConfiguring = true;
    notifyListeners();
    try {
      final credentials = {'ssid': ssid, 'password': password};
      final jsonString = jsonEncode(credentials);
      final success =
          await _bluetoothService.sendWifiCredentials(jsonString);
      _isConfiguring = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('❌ Error configuring WiFi: $e');
      _isConfiguring = false;
      notifyListeners();
      return false;
    }
  }
}
